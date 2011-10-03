#!/usr/bin/perl -w
use strict;
use Test::More;
use Finance::Quote;

if (not $ENV{ONLINE_TEST}) {
    plan skip_all => 'Set $ENV{ONLINE_TEST} to run this test';
}

plan tests => 9;

# Test Morningstar functions.

my $q      = Finance::Quote->new();
my $year   = (localtime())[5] + 1900;
my $lastyear = $year - 1;

my @stocks = ("0P0000G38D","BOGUS");

my %quotes = $q->fetch("morningstar",@stocks);
ok(%quotes);

# Check the nav values are defined.  These are the most
#  used and most reliable indicators of success.
ok($quotes{"0P0000G38D","nav"} > 0);
ok(length($quotes{"0P0000G38D","name"}) > 0);
ok($quotes{"0P0000G38D","success"});
ok($quotes{"0P0000G38D", "currency"} eq "SEK");
ok(substr($quotes{"0P0000G38D","isodate"},0,4) == $year ||
   substr($quotes{"0P0000G38D","isodate"},0,4) == $lastyear);
ok(substr($quotes{"0P0000G38D","date"},6,4) == $year ||
   substr($quotes{"0P0000G38D","date"},6,4) == $lastyear);

# Make sure we don't have spurious % signs.

ok($quotes{"0P0000G38D","p_change"} !~ /%/);

# Check that a bogus stock returns no-success.
ok(! $quotes{"BOGUS","success"});

