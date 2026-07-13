#!/usr/bin/env perl
use strict;
use warnings;

use DBI qw(:sql_types);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename dirname);
use File::Find qw(find);
use File::Path qw(make_path);
use XML::LibXML;

my $output_dir = shift // 'reverse-engineering/capture-one-extracted';
my $app = shift // '/Applications/Capture One.app';
my $framework = "$app/Contents/Frameworks/ImageProcessing.framework/Versions/A";
my $core_path = "$framework/Resources/coreConfig.cdx";
my $lens_path = "$framework/Resources/lensDatabase.cdx";
my $profile_dir = "$framework/Resources/Profiles/Input";

make_path($output_dir);
my $database_path = "$output_dir/calibration.sqlite";
die "$database_path already exists; remove it explicitly before rebuilding\n" if -e $database_path;

my $camera_xml = decode_cdx($core_path);
my $lens_xml = decode_cdx($lens_path);
write_raw("$output_dir/camera-defaults.xml", $camera_xml);
write_raw("$output_dir/lens-database.xml", $lens_xml);

my $dbh = DBI->connect("dbi:SQLite:dbname=$database_path", '', '', {
    RaiseError => 1,
    AutoCommit => 1,
});
$dbh->do('PRAGMA journal_mode = OFF');
$dbh->do('PRAGMA synchronous = OFF');
$dbh->do('PRAGMA temp_store = MEMORY');
$dbh->begin_work;

create_schema($dbh);
insert_metadata($dbh, 'capture_one_app', $app);
insert_metadata($dbh, 'core_config_sha256', sha256_hex(read_raw($core_path)));
insert_metadata($dbh, 'lens_database_sha256', sha256_hex(read_raw($lens_path)));
insert_cameras($dbh, $camera_xml);
insert_lenses($dbh, $lens_xml);
insert_profiles($dbh, $profile_dir);
$dbh->commit;
$dbh->do('PRAGMA optimize');
$dbh->disconnect;

print "$database_path\n";

sub create_schema {
    my ($db) = @_;
    $db->do('CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    $db->do(q{
        CREATE TABLE camera (
            camera_pk INTEGER PRIMARY KEY,
            camera_id TEXT NOT NULL,
            record_ordinal INTEGER NOT NULL,
            create_date TEXT,
            update_date TEXT,
            UNIQUE (camera_id, record_ordinal)
        )
    });
    $db->do(q{
        CREATE TABLE camera_property (
            camera_pk INTEGER NOT NULL,
            ordinal INTEGER NOT NULL,
            name TEXT NOT NULL,
            value TEXT,
            PRIMARY KEY (camera_pk, ordinal),
            FOREIGN KEY (camera_pk) REFERENCES camera(camera_pk)
        )
    });
    $db->do(q{
        CREATE TABLE camera_iso_property (
            camera_pk INTEGER NOT NULL,
            iso TEXT NOT NULL,
            iso_ordinal INTEGER NOT NULL,
            property_ordinal INTEGER NOT NULL,
            name TEXT NOT NULL,
            value TEXT,
            PRIMARY KEY (camera_pk, iso_ordinal, property_ordinal),
            FOREIGN KEY (camera_pk) REFERENCES camera(camera_pk)
        )
    });
    $db->do('CREATE INDEX camera_id_lookup ON camera(camera_id)');
    $db->do('CREATE INDEX camera_property_name ON camera_property(name)');
    $db->do('CREATE INDEX camera_iso_lookup ON camera_iso_property(camera_pk, iso)');
    $db->do('CREATE INDEX camera_iso_property_name ON camera_iso_property(name)');

    $db->do(q{
        CREATE TABLE lens (
            lens_id TEXT PRIMARY KEY,
            type TEXT,
            full_name TEXT,
            short_name TEXT,
            brand TEXT,
            mount TEXT
        )
    });
    $db->do(q{
        CREATE TABLE lens_node (
            lens_id TEXT NOT NULL,
            node_id INTEGER NOT NULL,
            parent_id INTEGER,
            ordinal INTEGER NOT NULL,
            name TEXT NOT NULL,
            text_value TEXT,
            PRIMARY KEY (lens_id, node_id),
            FOREIGN KEY (lens_id) REFERENCES lens(lens_id)
        )
    });
    $db->do(q{
        CREATE TABLE lens_attribute (
            lens_id TEXT NOT NULL,
            node_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            value TEXT NOT NULL,
            PRIMARY KEY (lens_id, node_id, name),
            FOREIGN KEY (lens_id, node_id) REFERENCES lens_node(lens_id, node_id)
        )
    });
    $db->do('CREATE INDEX lens_node_name ON lens_node(name)');

    $db->do(q{
        CREATE TABLE icc_profile (
            profile_id INTEGER PRIMARY KEY,
            filename TEXT NOT NULL UNIQUE,
            byte_size INTEGER NOT NULL,
            sha256 TEXT NOT NULL,
            profile_size INTEGER,
            version_hex TEXT,
            device_class TEXT,
            color_space TEXT,
            pcs TEXT,
            created TEXT,
            manufacturer TEXT,
            model TEXT,
            tag_count INTEGER
        )
    });
    $db->do(q{
        CREATE TABLE icc_tag (
            profile_id INTEGER NOT NULL,
            ordinal INTEGER NOT NULL,
            signature TEXT NOT NULL,
            file_offset INTEGER NOT NULL,
            byte_size INTEGER NOT NULL,
            type_signature TEXT,
            payload BLOB NOT NULL,
            PRIMARY KEY (profile_id, ordinal),
            FOREIGN KEY (profile_id) REFERENCES icc_profile(profile_id)
        )
    });
    $db->do('CREATE INDEX icc_tag_signature ON icc_tag(signature)');
    $db->do(q{
        CREATE TABLE icc_xyz (
            profile_id INTEGER NOT NULL,
            tag_ordinal INTEGER NOT NULL,
            value_ordinal INTEGER NOT NULL,
            x REAL NOT NULL,
            y REAL NOT NULL,
            z REAL NOT NULL,
            PRIMARY KEY (profile_id, tag_ordinal, value_ordinal)
        )
    });
    $db->do(q{
        CREATE TABLE icc_curve (
            profile_id INTEGER NOT NULL,
            tag_ordinal INTEGER NOT NULL,
            value_ordinal INTEGER NOT NULL,
            value_u16 INTEGER NOT NULL,
            PRIMARY KEY (profile_id, tag_ordinal, value_ordinal)
        )
    });
    $db->do(q{
        CREATE TABLE icc_mft2 (
            profile_id INTEGER NOT NULL,
            tag_ordinal INTEGER NOT NULL,
            input_channels INTEGER NOT NULL,
            output_channels INTEGER NOT NULL,
            grid_points INTEGER NOT NULL,
            matrix_s15fixed16 BLOB NOT NULL,
            input_entries INTEGER NOT NULL,
            output_entries INTEGER NOT NULL,
            input_tables_u16be BLOB NOT NULL,
            clut_u16be BLOB NOT NULL,
            output_tables_u16be BLOB NOT NULL,
            PRIMARY KEY (profile_id, tag_ordinal)
        )
    });
}

sub insert_metadata {
    my ($db, $key, $value) = @_;
    $db->do('INSERT INTO metadata(key, value) VALUES (?, ?)', undef, $key, $value);
}

sub insert_cameras {
    my ($db, $xml) = @_;
    my $document = XML::LibXML->load_xml(string => $xml);
    my $camera_insert = $db->prepare(
        'INSERT INTO camera(camera_id, record_ordinal, create_date, update_date) VALUES (?, ?, ?, ?)');
    my $property_insert = $db->prepare(
        'INSERT INTO camera_property(camera_pk, ordinal, name, value) VALUES (?, ?, ?, ?)');
    my $iso_insert = $db->prepare(q{
        INSERT INTO camera_iso_property(
            camera_pk, iso, iso_ordinal, property_ordinal, name, value
        ) VALUES (?, ?, ?, ?, ?, ?)
    });

    my %occurrence;
    for my $camera ($document->findnodes('/cameraDefaults/cameraID')) {
        my $id = $camera->getAttribute('val');
        $camera_insert->execute(
            $id, $occurrence{$id} // 0,
            $camera->getAttribute('createDate'), $camera->getAttribute('updateDate'));
        $occurrence{$id}++;
        my $camera_pk = $db->sqlite_last_insert_rowid;
        my ($property_ordinal, $iso_ordinal) = (0, 0);
        for my $child ($camera->nonBlankChildNodes) {
            next unless $child->nodeType == XML_ELEMENT_NODE;
            if ($child->nodeName eq 'ISO') {
                my $iso = $child->getAttribute('val');
                my $within = 0;
                for my $property ($child->nonBlankChildNodes) {
                    next unless $property->nodeType == XML_ELEMENT_NODE;
                    $iso_insert->execute(
                        $camera_pk, $iso, $iso_ordinal, $within++, $property->nodeName,
                        attribute_or_text($property));
                }
                $iso_ordinal++;
            } else {
                $property_insert->execute(
                    $camera_pk, $property_ordinal++, $child->nodeName, attribute_or_text($child));
            }
        }
    }
}

sub insert_lenses {
    my ($db, $xml) = @_;
    my $document = XML::LibXML->load_xml(string => $xml);
    my $lens_insert = $db->prepare(q{
        INSERT INTO lens(lens_id, type, full_name, short_name, brand, mount)
        VALUES (?, ?, ?, ?, ?, ?)
    });
    my $node_insert = $db->prepare(q{
        INSERT INTO lens_node(lens_id, node_id, parent_id, ordinal, name, text_value)
        VALUES (?, ?, ?, ?, ?, ?)
    });
    my $attribute_insert = $db->prepare(q{
        INSERT INTO lens_attribute(lens_id, node_id, name, value) VALUES (?, ?, ?, ?)
    });

    for my $lens ($document->findnodes('/*[local-name()="lenses"]/*[local-name()="lens"]')) {
        my $id = $lens->getAttribute('ID');
        $lens_insert->execute(
            $id,
            $lens->getAttribute('type'),
            child_text($lens, 'fullName'),
            child_text($lens, 'shortName'),
            child_text($lens, 'brand'),
            child_text($lens, 'mount'));
        my $next_id = 0;
        flatten_lens_node(
            $lens, $id, undef, 0, \$next_id, $node_insert, $attribute_insert);
    }
}

sub flatten_lens_node {
    my ($node, $lens_id, $parent_id, $ordinal, $next_id, $node_insert, $attribute_insert) = @_;
    my $node_id = $$next_id;
    $$next_id = $$next_id + 1;
    my @element_children = grep { $_->nodeType == XML_ELEMENT_NODE } $node->nonBlankChildNodes;
    my $text = @element_children ? undef : normalized_text($node->textContent);
    $node_insert->execute($lens_id, $node_id, $parent_id, $ordinal, $node->localname, $text);
    for my $attribute ($node->attributes) {
        $attribute_insert->execute($lens_id, $node_id, $attribute->nodeName, $attribute->value);
    }
    my $child_ordinal = 0;
    for my $child (@element_children) {
        flatten_lens_node(
            $child, $lens_id, $node_id, $child_ordinal++, $next_id,
            $node_insert, $attribute_insert);
    }
}

sub insert_profiles {
    my ($db, $root) = @_;
    my @paths;
    find(sub { push @paths, $File::Find::name if -f $_ && /\.icm\z/i }, $root);
    @paths = sort @paths;

    my $profile_insert = $db->prepare(q{
        INSERT INTO icc_profile(
            filename, byte_size, sha256, profile_size, version_hex, device_class,
            color_space, pcs, created, manufacturer, model, tag_count
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    });
    my $tag_insert = $db->prepare(q{
        INSERT INTO icc_tag(
            profile_id, ordinal, signature, file_offset, byte_size, type_signature, payload
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
    });
    my $xyz_insert = $db->prepare(q{
        INSERT INTO icc_xyz(profile_id, tag_ordinal, value_ordinal, x, y, z)
        VALUES (?, ?, ?, ?, ?, ?)
    });
    my $curve_insert = $db->prepare(q{
        INSERT INTO icc_curve(profile_id, tag_ordinal, value_ordinal, value_u16)
        VALUES (?, ?, ?, ?)
    });
    my $mft2_insert = $db->prepare(q{
        INSERT INTO icc_mft2(
            profile_id, tag_ordinal, input_channels, output_channels, grid_points,
            matrix_s15fixed16, input_entries, output_entries, input_tables_u16be,
            clut_u16be, output_tables_u16be
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    });

    for my $path (@paths) {
        my $data = read_raw($path);
        next if length($data) < 132 || substr($data, 36, 4) ne 'acsp';
        my $tag_count = be32($data, 128);
        $profile_insert->execute(
            substr($path, length($root) + 1), length($data), sha256_hex($data),
            be32($data, 0), unpack('H8', substr($data, 8, 4)),
            substr($data, 12, 4), substr($data, 16, 4), substr($data, 20, 4),
            icc_date($data), substr($data, 48, 4), substr($data, 52, 4), $tag_count);
        my $profile_id = $db->sqlite_last_insert_rowid;

        for my $ordinal (0 .. $tag_count - 1) {
            my $entry = 132 + $ordinal * 12;
            last if $entry + 12 > length($data);
            my $signature = substr($data, $entry, 4);
            my $offset = be32($data, $entry + 4);
            my $size = be32($data, $entry + 8);
            next if $offset + $size > length($data);
            my $payload = substr($data, $offset, $size);
            my $type = length($payload) >= 4 ? substr($payload, 0, 4) : undef;
            execute_with_blobs(
                $tag_insert,
                [$profile_id, $ordinal, $signature, $offset, $size, $type, $payload],
                { 7 => 1 },
            );
            if (defined $type && $type eq 'XYZ ') {
                parse_xyz($profile_id, $ordinal, $payload, $xyz_insert);
            } elsif (defined $type && $type eq 'curv') {
                parse_curve($profile_id, $ordinal, $payload, $curve_insert);
            } elsif (defined $type && $type eq 'mft2') {
                parse_mft2($profile_id, $ordinal, $payload, $mft2_insert);
            }
        }
    }
}

sub parse_xyz {
    my ($profile_id, $tag_ordinal, $payload, $insert) = @_;
    my $count = int((length($payload) - 8) / 12);
    for my $index (0 .. $count - 1) {
        my $offset = 8 + $index * 12;
        $insert->execute(
            $profile_id, $tag_ordinal, $index,
            s15fixed16($payload, $offset),
            s15fixed16($payload, $offset + 4),
            s15fixed16($payload, $offset + 8));
    }
}

sub parse_curve {
    my ($profile_id, $tag_ordinal, $payload, $insert) = @_;
    return if length($payload) < 12;
    my $count = be32($payload, 8);
    return if 12 + $count * 2 > length($payload);
    for my $index (0 .. $count - 1) {
        $insert->execute($profile_id, $tag_ordinal, $index, be16($payload, 12 + $index * 2));
    }
}

sub parse_mft2 {
    my ($profile_id, $tag_ordinal, $payload, $insert) = @_;
    return if length($payload) < 52;
    my ($inputs, $outputs, $grid) = unpack('CCC', substr($payload, 8, 3));
    my $input_entries = be16($payload, 48);
    my $output_entries = be16($payload, 50);
    my $input_bytes = $inputs * $input_entries * 2;
    my $clut_values = ($grid ** $inputs) * $outputs;
    my $clut_bytes = $clut_values * 2;
    my $output_bytes = $outputs * $output_entries * 2;
    return if 52 + $input_bytes + $clut_bytes + $output_bytes > length($payload);
    my $input = substr($payload, 52, $input_bytes);
    my $clut = substr($payload, 52 + $input_bytes, $clut_bytes);
    my $output = substr($payload, 52 + $input_bytes + $clut_bytes, $output_bytes);
    execute_with_blobs(
        $insert,
        [
            $profile_id, $tag_ordinal, $inputs, $outputs, $grid,
            substr($payload, 12, 36), $input_entries, $output_entries,
            $input, $clut, $output,
        ],
        { 6 => 1, 9 => 1, 10 => 1, 11 => 1 },
    );
}

sub execute_with_blobs {
    my ($statement, $values, $blob_parameters) = @_;
    for my $index (0 .. $#$values) {
        my $parameter = $index + 1;
        if ($blob_parameters->{$parameter}) {
            $statement->bind_param($parameter, $values->[$index], SQL_BLOB);
        } else {
            $statement->bind_param($parameter, $values->[$index]);
        }
    }
    $statement->execute;
}

sub decode_cdx {
    my ($path) = @_;
    my $data = read_raw($path);
    $data =~ s/(.)/chr(ord($1) ^ 0x81)/gse;
    $data =~ s/^~~(?=<\?xml)//;
    return $data;
}

sub read_raw {
    my ($path) = @_;
    open my $file, '<:raw', $path or die "cannot open $path: $!\n";
    local $/;
    my $data = <$file>;
    close $file or die "cannot close $path: $!\n";
    return $data;
}

sub write_raw {
    my ($path, $data) = @_;
    open my $file, '>:raw', $path or die "cannot write $path: $!\n";
    print {$file} $data;
    close $file or die "cannot close $path: $!\n";
}

sub attribute_or_text {
    my ($node) = @_;
    return $node->getAttribute('val') if $node->hasAttribute('val');
    return normalized_text($node->textContent);
}

sub child_text {
    my ($node, $local_name) = @_;
    my ($child) = $node->findnodes('./*[local-name()="' . $local_name . '"]');
    return defined $child ? normalized_text($child->textContent) : undef;
}

sub normalized_text {
    my ($text) = @_;
    $text =~ s/^\s+|\s+$//g;
    $text =~ s/\s+/ /g;
    return $text;
}

sub be16 { return unpack('n', substr($_[0], $_[1], 2)); }
sub be32 { return unpack('N', substr($_[0], $_[1], 4)); }
sub s15fixed16 { return unpack('l>', substr($_[0], $_[1], 4)) / 65536.0; }

sub icc_date {
    my ($data) = @_;
    my @parts = unpack('n6', substr($data, 24, 12));
    return sprintf('%04d-%02d-%02dT%02d:%02d:%02d', @parts);
}
