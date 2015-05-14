#!/usr/bin/perl -w
use strict;
use open IO => ':locale';

use Web::Scraper;
use String::Similarity;
use URI;
use Digest::MD5 qw(md5_base64);
use File::Path qw( make_path);

my ($uri, $period, $factor_limit, $selector) = @ARGV;

sub DATA { 'data' }

if(not defined $factor_limit or $period !~ /^\d+$/ or $factor_limit !~ /^\d+\.\d+$/) {
    print "Usage: $0 uri check_period similarity_factor [selector]\n";
    print " - check_period in seconds from the last check\n";
    print " - factor between 0.0 and 1.0\n";
    print " - selector is CSS/XPath expression to select nodes\n";
    exit;
}

# defaults

$selector ||= "*";

# action

my ($cache1, $cache2, $digest) = (md5_base64($uri) =~ /^(\w)(\w)(\w+)$/);
my $path = sprintf("%s/%s/%s", DATA, $cache1, $cache2);
my $file = sprintf("%s/%s", $path, $digest);

make_path($path);

my $mtime = file_mtime($file);
my $ctime = time;

exit if ($ctime < $mtime + $period);

my $content = get_uri_content($uri, $selector);

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
    my ($uri, $selector) = @_;
    my $gen_scraper = scraper {
        process $selector, text => 'TEXT';
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
