#!/usr/bin/env perl
use strict;
use warnings;

use DBI qw(:sql_types);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename);
use File::Path qw(make_path);

my $output_path = shift // 'data/calibration/banksia-calibration-v1.sqlite3';
my $source_database = shift
    // 'reverse-engineering/capture-one-extracted/calibration.sqlite';
my $film_csv = shift
    // 'reverse-engineering/capture-one-extracted/film-curves.csv';
my $capture_app = shift // '/Applications/Capture One.app';
my $schema_path = 'data/calibration/schema.sql';

my $bundle_id = 'calibration.capture-one-16.7.3.31.initial-canon.v1';
my $capture_version = '16.7.3.31';
my $framework = "$capture_app/Contents/Frameworks/ImageProcessing.framework/Versions/A";
my $profile_dir = "$framework/Resources/Profiles/Input";

my @cameras = (
    {
        source_id => 'CanonEOS1DX2',
        camera_id => 'camera.capture-one.canon-eos-1d-x-mark-ii.v1',
        make => 'Canon',
        model => 'EOS-1D X Mark II',
        profile_name => 'CanonEOS1DX2-ProStandard.icm',
        profile_id => 'profile.capture-one.CanonEOS1DX2-ProStandard.v1',
        curve_name => 'CanonEOS1DX2-Auto.fcrv',
        curve_id => 'curve.capture-one.CanonEOS1DX2-Auto.v1',
        aliases => [
            ['Canon', 'EOS-1D X Mark II'],
            ['Canon Inc.', 'EOS-1D X Mark II'],
        ],
    },
    {
        source_id => 'CanonEOSR3',
        camera_id => 'camera.capture-one.canon-eos-r3.v1',
        make => 'Canon',
        model => 'EOS R3',
        profile_name => 'CanonEOSR3-ProStandard.icm',
        profile_id => 'profile.capture-one.CanonEOSR3-ProStandard.v1',
        curve_name => 'CanonEOSR3-Auto.fcrv',
        curve_id => 'curve.capture-one.CanonEOSR3-Auto.v1',
        aliases => [
            ['Canon', 'EOS R3'],
            ['Canon Inc.', 'EOS R3'],
        ],
    },
);

my @lens_source_ids = (
    'D52D61FC-82C8-4E2F-96AF-70BBA6538D40',
    '66B9FA28-EFDB-4C38-ABEE-654C84967049',
    'A57EBD6F-86D3-47FC-A295-F75DC0EA3B7C',
);

die "$output_path already exists; remove it explicitly before rebuilding\n"
    if -e $output_path;
for my $required ($source_database, $film_csv, $schema_path) {
    die "missing required input: $required\n" if !-f $required;
}

make_path('data/calibration');
my $source = DBI->connect("dbi:SQLite:dbname=$source_database", '', '', {
    RaiseError => 1,
    PrintError => 0,
    sqlite_open_flags => 0x00000001,
});
my $target = DBI->connect("dbi:SQLite:dbname=$output_path", '', '', {
    RaiseError => 1,
    PrintError => 0,
    AutoCommit => 1,
});

$target->do('PRAGMA journal_mode = OFF');
$target->do('PRAGMA synchronous = OFF');
$target->do('PRAGMA temp_store = MEMORY');
$target->do('PRAGMA page_size = 4096');
execute_schema($target, read_raw($schema_path));
$target->begin_work;

insert_metadata($target, 'bundle_id', $bundle_id);
insert_metadata($target, 'processing_graph_id', 'graph.banksia.calibrated.v1');
insert_metadata($target, 'schema_version', '1');
insert_metadata($target, 'capture_one_version', $capture_version);
insert_metadata($target, 'schema_sha256', sha256_file($schema_path));
insert_metadata($target, 'extraction_tool_sha256', sha256_file(__FILE__));
insert_metadata($target, 'source_database_sha256', sha256_file($source_database));
insert_metadata($target, 'film_curves_csv_sha256', sha256_file($film_csv));
copy_source_metadata($source, $target);

for my $camera (@cameras) {
    insert_icc_profile($target, $profile_dir, $camera);
}
insert_film_curves($target, $film_csv, \@cameras);
for my $camera (@cameras) {
    insert_camera($source, $target, $camera);
}
for my $source_lens_id (@lens_source_ids) {
    insert_lens($source, $target, $source_lens_id);
}

insert_row_counts($target);
$target->commit;
$target->do('PRAGMA user_version = 1');
$target->do('PRAGMA application_id = 1111577163');
$target->do('PRAGMA optimize');
$target->do('VACUUM');

my ($integrity) = $target->selectrow_array('PRAGMA integrity_check');
die "generated database failed integrity_check: $integrity\n" if $integrity ne 'ok';
$source->disconnect;
$target->disconnect;

print "$output_path\n";

sub execute_schema {
    my ($database, $schema) = @_;
    for my $statement (split /;\s*(?:\n|\z)/, $schema) {
        next if $statement !~ /\S/;
        $database->do($statement);
    }
}

sub insert_metadata {
    my ($database, $key, $value) = @_;
    $database->do(
        'INSERT INTO bundle_metadata(key, value) VALUES (?, ?)',
        undef,
        $key,
        $value,
    );
}

sub copy_source_metadata {
    my ($source_database, $target_database) = @_;
    my $rows = $source_database->selectall_arrayref(
        'SELECT key, value FROM metadata ORDER BY key',
    );
    for my $row (@$rows) {
        insert_metadata($target_database, "source_$row->[0]", $row->[1]);
    }
}

sub insert_camera {
    my ($source_database, $target_database, $camera) = @_;
    my $source_row = $source_database->selectrow_hashref(q{
        SELECT camera_pk, create_date, update_date
        FROM camera
        WHERE camera_id = ? AND record_ordinal = 0
    }, undef, $camera->{source_id});
    die "missing source camera $camera->{source_id}\n" if !defined $source_row;

    $target_database->do(q{
        INSERT INTO camera(
            camera_id, source_camera_id, make, model, create_date, update_date,
            input_profile_id, film_curve_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    }, undef,
        $camera->{camera_id}, $camera->{source_id}, $camera->{make}, $camera->{model},
        $source_row->{create_date}, $source_row->{update_date},
        $camera->{profile_id}, $camera->{curve_id});

    for my $alias (@{$camera->{aliases}}) {
        $target_database->do(q{
            INSERT INTO camera_alias(camera_id, make_normalized, model_normalized)
            VALUES (?, ?, ?)
        }, undef, $camera->{camera_id}, normalize($alias->[0]), normalize($alias->[1]));
    }

    copy_rows(
        $source_database,
        $target_database,
        q{SELECT ordinal, name, value FROM camera_property
          WHERE camera_pk = ? ORDER BY ordinal},
        'INSERT INTO camera_property(camera_id, ordinal, name, value) VALUES (?, ?, ?, ?)',
        [$source_row->{camera_pk}],
        [$camera->{camera_id}],
    );
    my $iso_rows = $source_database->selectall_arrayref(q{
        SELECT DISTINCT CAST(iso AS REAL), iso_ordinal
        FROM camera_iso_property WHERE camera_pk = ?
        ORDER BY iso_ordinal
    }, undef, $source_row->{camera_pk});
    for my $iso_row (@$iso_rows) {
        my ($iso, $iso_ordinal) = @$iso_row;
        my $iso_text = $iso == int($iso) ? int($iso) : $iso;
        my $iso_record_id = "$camera->{camera_id}.iso.$iso_text.v1";
        $target_database->do(q{
            INSERT INTO camera_iso(
                iso_record_id, camera_id, iso, iso_ordinal
            ) VALUES (?, ?, ?, ?)
        }, undef, $iso_record_id, $camera->{camera_id}, $iso, $iso_ordinal);
    }
    copy_rows(
        $source_database,
        $target_database,
        q{SELECT CAST(iso AS REAL), iso_ordinal, property_ordinal, name, value
          FROM camera_iso_property WHERE camera_pk = ?
          ORDER BY iso_ordinal, property_ordinal},
        q{INSERT INTO camera_iso_property(
              camera_id, iso, iso_ordinal, property_ordinal, name, value
          ) VALUES (?, ?, ?, ?, ?, ?)},
        [$source_row->{camera_pk}],
        [$camera->{camera_id}],
    );
}

sub insert_lens {
    my ($source_database, $target_database, $source_lens_id) = @_;
    my $lens = $source_database->selectrow_hashref(
        'SELECT * FROM lens WHERE lens_id = ?',
        undef,
        $source_lens_id,
    );
    die "missing source lens $source_lens_id\n" if !defined $lens;
    my $lens_id = "lens.capture-one.$source_lens_id.v1";
    $target_database->do(q{
        INSERT INTO lens(lens_id, type, full_name, short_name, brand, mount)
        VALUES (?, ?, ?, ?, ?, ?)
    }, undef,
        $lens_id, $lens->{type}, $lens->{full_name}, $lens->{short_name},
        $lens->{brand}, $lens->{mount});

    my %aliases;
    $aliases{normalize($lens->{full_name})} = 1;
    $aliases{normalize($lens->{short_name})} = 1;
    my $detect_rows = $source_database->selectall_arrayref(q{
        SELECT text_value FROM lens_node
        WHERE lens_id = ? AND name = 'fileDetectID'
    }, undef, $source_lens_id);
    for my $row (@$detect_rows) {
        next if !defined $row->[0];
        if ($row->[0] =~ /S\[([^]]+)\]/) {
            $aliases{normalize($1)} = 1;
            $aliases{normalize("Canon $1")} = 1;
        }
    }
    for my $alias (sort keys %aliases) {
        next if $alias eq '';
        $target_database->do(
            'INSERT OR IGNORE INTO lens_alias(lens_id, name_normalized) VALUES (?, ?)',
            undef,
            $lens_id,
            $alias,
        );
    }

    copy_rows(
        $source_database,
        $target_database,
        q{SELECT node_id, parent_id, ordinal, name, text_value FROM lens_node
          WHERE lens_id = ? ORDER BY node_id},
        q{INSERT INTO lens_node(
              lens_id, node_id, parent_id, ordinal, name, text_value
          ) VALUES (?, ?, ?, ?, ?, ?)},
        [$source_lens_id],
        [$lens_id],
    );
    copy_rows(
        $source_database,
        $target_database,
        q{SELECT node_id, name, value FROM lens_attribute
          WHERE lens_id = ? ORDER BY node_id, name},
        q{INSERT INTO lens_attribute(lens_id, node_id, name, value)
          VALUES (?, ?, ?, ?)},
        [$source_lens_id],
        [$lens_id],
    );
}

sub copy_rows {
    my ($source_database, $target_database, $select_sql, $insert_sql,
        $select_values, $insert_prefix) = @_;
    my $select = $source_database->prepare($select_sql);
    $select->execute(@$select_values);
    my $insert = $target_database->prepare($insert_sql);
    while (my $row = $select->fetchrow_arrayref) {
        $insert->execute(@$insert_prefix, @$row);
    }
    $select->finish;
    $insert->finish;
}

sub insert_icc_profile {
    my ($database, $root, $camera) = @_;
    my $path = "$root/$camera->{profile_name}";
    die "missing input profile $path\n" if !-f $path;
    my $data = read_raw($path);
    die "invalid ICC profile $path\n"
        if length($data) < 132 || substr($data, 36, 4) ne 'acsp';
    my $tag_count = be32($data, 128);

    $database->do(q{
        INSERT INTO input_profile(
            profile_id, byte_size, sha256, profile_size, version_hex,
            device_class, color_space, pcs, created, manufacturer, model, tag_count
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    }, undef,
        $camera->{profile_id}, length($data), sha256_hex($data), be32($data, 0),
        unpack('H8', substr($data, 8, 4)), trim_signature(substr($data, 12, 4)),
        trim_signature(substr($data, 16, 4)), trim_signature(substr($data, 20, 4)),
        icc_date($data), trim_signature(substr($data, 48, 4)),
        trim_signature(substr($data, 52, 4)), $tag_count);

    for my $ordinal (0 .. $tag_count - 1) {
        my $entry = 132 + $ordinal * 12;
        die "truncated ICC tag table in $path\n" if $entry + 12 > length($data);
        my $signature = trim_signature(substr($data, $entry, 4));
        my $offset = be32($data, $entry + 4);
        my $size = be32($data, $entry + 8);
        die "invalid ICC tag extent in $path\n" if $offset + $size > length($data);
        my $payload = substr($data, $offset, $size);
        my $type = length($payload) >= 4
            ? trim_signature(substr($payload, 0, 4))
            : undef;
        insert_profile_tag(
            $database, $camera->{profile_id}, $ordinal, $signature,
            $offset, $size, $type, $payload,
        );
        if (defined $type && $type eq 'XYZ') {
            insert_xyz($database, $camera->{profile_id}, $ordinal, $payload);
        } elsif (defined $type && $type eq 'curv') {
            insert_profile_curve($database, $camera->{profile_id}, $ordinal, $payload);
        } elsif (defined $type && $type eq 'mft2') {
            insert_mft2($database, $camera->{profile_id}, $ordinal, $payload);
        }
    }
}

sub insert_profile_tag {
    my ($database, $profile_id, $ordinal, $signature, $offset, $size, $type,
        $payload) = @_;
    my $insert = $database->prepare(q{
        INSERT INTO input_profile_tag(
            profile_id, ordinal, signature, file_offset, byte_size,
            type_signature, payload
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
    });
    $insert->bind_param(1, $profile_id);
    $insert->bind_param(2, $ordinal);
    $insert->bind_param(3, $signature);
    $insert->bind_param(4, $offset);
    $insert->bind_param(5, $size);
    $insert->bind_param(6, $type);
    $insert->bind_param(7, $payload, SQL_BLOB);
    $insert->execute;
    $insert->finish;
}

sub insert_xyz {
    my ($database, $profile_id, $tag_ordinal, $payload) = @_;
    my $count = int((length($payload) - 8) / 12);
    my $insert = $database->prepare(q{
        INSERT INTO input_profile_xyz(
            profile_id, tag_ordinal, value_ordinal, x, y, z
        ) VALUES (?, ?, ?, ?, ?, ?)
    });
    for my $index (0 .. $count - 1) {
        my $offset = 8 + $index * 12;
        $insert->execute(
            $profile_id, $tag_ordinal, $index,
            s15fixed16($payload, $offset),
            s15fixed16($payload, $offset + 4),
            s15fixed16($payload, $offset + 8),
        );
    }
    $insert->finish;
}

sub insert_profile_curve {
    my ($database, $profile_id, $tag_ordinal, $payload) = @_;
    return if length($payload) < 12;
    my $count = be32($payload, 8);
    die "invalid ICC curve payload\n" if 12 + $count * 2 > length($payload);
    my $insert = $database->prepare(q{
        INSERT INTO input_profile_curve(
            profile_id, tag_ordinal, value_ordinal, value_u16
        ) VALUES (?, ?, ?, ?)
    });
    for my $index (0 .. $count - 1) {
        $insert->execute(
            $profile_id,
            $tag_ordinal,
            $index,
            be16($payload, 12 + $index * 2),
        );
    }
    $insert->finish;
}

sub insert_mft2 {
    my ($database, $profile_id, $tag_ordinal, $payload) = @_;
    die "invalid mft2 payload\n" if length($payload) < 52;
    my ($inputs, $outputs, $grid) = unpack('CCC', substr($payload, 8, 3));
    my $input_entries = be16($payload, 48);
    my $output_entries = be16($payload, 50);
    my $input_bytes = $inputs * $input_entries * 2;
    my $clut_bytes = ($grid ** $inputs) * $outputs * 2;
    my $output_bytes = $outputs * $output_entries * 2;
    die "truncated mft2 payload\n"
        if 52 + $input_bytes + $clut_bytes + $output_bytes > length($payload);

    my @values = (
        $profile_id,
        $tag_ordinal,
        $inputs,
        $outputs,
        $grid,
        substr($payload, 12, 36),
        $input_entries,
        $output_entries,
        substr($payload, 52, $input_bytes),
        substr($payload, 52 + $input_bytes, $clut_bytes),
        substr($payload, 52 + $input_bytes + $clut_bytes, $output_bytes),
    );
    my $insert = $database->prepare(q{
        INSERT INTO input_profile_mft2(
            profile_id, tag_ordinal, input_channels, output_channels, grid_points,
            matrix_s15fixed16, input_entries, output_entries, input_tables_u16be,
            clut_u16be, output_tables_u16be
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    });
    for my $index (0 .. $#values) {
        my $parameter = $index + 1;
        if ($parameter == 6 || $parameter >= 9) {
            $insert->bind_param($parameter, $values[$index], SQL_BLOB);
        } else {
            $insert->bind_param($parameter, $values[$index]);
        }
    }
    $insert->execute;
    $insert->finish;
}

sub insert_film_curves {
    my ($database, $path, $camera_records) = @_;
    my %wanted = map { $_->{curve_name} => $_ } @$camera_records;
    my %headers;
    my %inserted;
    my $point_insert = $database->prepare(q{
        INSERT INTO film_curve_point(curve_id, component, point_index, x, y)
        VALUES (?, ?, ?, ?, ?)
    });

    open my $file, '<', $path or die "cannot open $path: $!\n";
    while (my $line = <$file>) {
        chomp $line;
        next if $line eq 'source,component,index,x,y';
        if ($line =~ /^# (source|name|description|version|flags)=(.*)$/) {
            $headers{$1} = $2;
            next;
        }
        next if $line !~ /^"([^"]+)",(film|ccd|contrast),(\d+),([^,]+),([^,]+)$/;
        my ($source_name, $component, $index, $x, $y) = ($1, $2, $3, $4, $5);
        my $curve_name = basename($source_name);
        next if !exists $wanted{$curve_name};
        my $camera = $wanted{$curve_name};
        if (!$inserted{$curve_name}) {
            die "film curve header mismatch for $curve_name\n"
                if !defined $headers{source} || basename($headers{source}) ne $curve_name;
            $database->do(q{
                INSERT INTO film_curve(
                    curve_id, source_name, display_name, description,
                    format_version, flags
                ) VALUES (?, ?, ?, ?, ?, ?)
            }, undef,
                $camera->{curve_id}, $curve_name, $headers{name}, $headers{description},
                int($headers{version}), int($headers{flags}));
            $inserted{$curve_name} = 1;
        }
        $point_insert->execute(
            $camera->{curve_id}, $component, int($index), 0.0 + $x, 0.0 + $y,
        );
    }
    close $file or die "cannot close $path: $!\n";
    $point_insert->finish;
    for my $curve_name (sort keys %wanted) {
        die "film curve not found in export: $curve_name\n" if !$inserted{$curve_name};
    }
}

sub insert_row_counts {
    my ($database) = @_;
    my @tables = qw(
        camera camera_alias camera_property camera_iso camera_iso_property input_profile
        input_profile_tag input_profile_xyz input_profile_curve input_profile_mft2
        film_curve film_curve_point lens lens_alias lens_node lens_attribute
    );
    for my $table (@tables) {
        my ($count) = $database->selectrow_array("SELECT COUNT(*) FROM $table");
        insert_metadata($database, "row_count.$table", "$count");
    }
}

sub normalize {
    my ($value) = @_;
    return '' if !defined $value;
    $value = lc $value;
    $value =~ s/[^a-z0-9]+//g;
    return $value;
}

sub trim_signature {
    my ($value) = @_;
    $value =~ s/\s+\z//;
    return $value;
}

sub read_raw {
    my ($path) = @_;
    open my $file, '<:raw', $path or die "cannot open $path: $!\n";
    local $/;
    my $data = <$file>;
    close $file or die "cannot close $path: $!\n";
    return $data;
}

sub sha256_file {
    my ($path) = @_;
    open my $file, '<:raw', $path or die "cannot open $path: $!\n";
    my $digest = Digest::SHA->new(256);
    $digest->addfile($file);
    close $file or die "cannot close $path: $!\n";
    return $digest->hexdigest;
}

sub be16 { return unpack('n', substr($_[0], $_[1], 2)); }
sub be32 { return unpack('N', substr($_[0], $_[1], 4)); }
sub s15fixed16 { return unpack('l>', substr($_[0], $_[1], 4)) / 65536.0; }

sub icc_date {
    my ($data) = @_;
    my @parts = unpack('n6', substr($data, 24, 12));
    return sprintf('%04d-%02d-%02dT%02d:%02d:%02d', @parts);
}
