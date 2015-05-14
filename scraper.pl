#!/usr/bin/perl -w
use strict;
use open IO => ':locale';

use Web::Scraper;
use String::Similarity;
use URI;
use Digest::MD5 qw(md5_base64);

my ($uri, $period, $factor_limit) = @ARGV;

sub DATA { 'data' }

if(not defined $factor_limit or $period !~ /^\d+$/ or $factor_limit !~ /^\d+\.\d+$/) {
    print "Usage: $0 uri check_period similarity_factor\n";
    print " - check_period in seconds from the last check\n";
    print " - factor between 0.0 and 1.0\n";
    exit;
}

# setup

if ( ! -d DATA ) {
    mkdir DATA or die sprintf("Can't create data folder: %s.\n$!\n", DATA);
}

# action

my $file = sprintf("%s/%s", DATA, md5_base64 $uri);
my $mtime = file_mtime($file);
my $ctime = time;

exit if ($ctime < $mtime + $period);

my $content = get_uri_content($uri);

if ($mtime == 0) {
    save_file($file, $content);
    print "new: $uri\n";
    exit;
}

my $old_content = read_file($file); 
my $factor = similarity($content, $old_content);

# factor = 1 - is complete match

if ($factor < $factor_limit) {
    print "change: $factor $uri\n";
}

save_file($file, $content);
exit;

# library

sub get_uri_content {
    my ($uri) = @_;
    my $gen_scraper = scraper {
        process "*", text => 'TEXT';
    };
    my $stash = $gen_scraper->scrape( URI->new($uri) );
    return $stash->{text};
}


sub save_file {
    my ($name, $content) = @_;
    open(my $fh, ">", $name) or die "Can't open file: $name\n$!\n";
    print $fh $content or die "Can't write to file: $name\n$!\n";
    close $fh;
}

sub file_mtime {
    my ($name) = @_;
    my @stat = stat($name);
    return $stat[9] || 0;
}

sub read_file {
    my ($name) = @_;
    open(my $fh, "<", $name) or die "Can't open file: $name\n$!\n";
    my $content = join("", <$fh>);
    close $fh;
    return $content;
}
