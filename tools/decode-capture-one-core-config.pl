#!/usr/bin/env perl
use strict;
use warnings;

my $path = shift //
    '/Applications/Capture One.app/Contents/Frameworks/ImageProcessing.framework/' .
    'Versions/A/Resources/coreConfig.cdx';

open my $input, '<:raw', $path or die "cannot open $path: $!\n";
my $first = 1;
while (read $input, my $buffer, 65536) {
    $buffer =~ s/(.)/chr(ord($1) ^ 0x81)/gse;
    $buffer =~ s/^~~(?=<\?xml)// if $first;
    $first = 0;
    print $buffer;
}
close $input or die "cannot close $path: $!\n";
