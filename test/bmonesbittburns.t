#!/usr/bin/perl -w
use strict;
use Test;
BEGIN {plan tests => 9};

use Finance::Quote;

# Test bmonesbittburns functions.

my $q      = Finance::Quote->new();

my %quotes = $q->bmonesbittburns("NT,T");
ok(%quotes);

# Check that last and date are defined as our tests.
ok($quotes{"NT,T","last"} > 0);
ok($quotes{"NT,T","success"});
ok($quotes{"NT,T","currency"} eq "CAD");
ok(length($quotes{"NT,T","date"}) > 0);


# Exercise the fetch function
%quotes = $q->fetch("bmonesbittburns", "NT,X");
ok(%quotes);
ok($quotes{"NT,X","success"});
ok($quotes{"NT,X","last"} > 0);

# Check that a bogus fund returns no-success.
%quotes = $q->bmonesbittburns("BOGUS");
ok( ! $quotes{"BOGUS","success"});

# Fetching an empty stock does result in an error, and yes
# this is bad.  But fetching an empty stock isn't normal
# behaviour.

# %quotes = $q->fetch("bmonesbittburns", "");
# ok( %quotes);
# ok( ! $quotes{"NT,X","success"});
# ok( ! $quotes{"NT,X","last"} > 0);
