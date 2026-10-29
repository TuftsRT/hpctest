use strict;
use warnings;
use List::Util qw(sum max);
use POSIX qw(floor);
use Data::Dumper;
use JSON::PP;

my @x = map { $_ * $_ } 1 .. 10;
printf "sum = %d, max = %d, floor(pi) = %d\n", sum(@x), max(@x), floor(4 * atan2(1, 1));
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 0;
$Data::Dumper::Terse = 1;
print Dumper({ a => 1, b => [2, 3] }), "\n";
my $json = JSON::PP->new->canonical;
print $json->encode($json->decode('{"z": 26, "a": [1, 2]}')), "\n";
my %count;
$count{$_}++ for split //, "mississippi";
print join(" ", map { "$_=$count{$_}" } sort keys %count), "\n";
