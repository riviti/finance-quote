package Finance::Quote::Morningstar;
require 5.004;

use strict;
use warnings;

use vars qw($VERSION $MORNINGSTAR_SE_FUNDS_URL $PRICE_PATH $NAME_PATH $DATE_PATH $PCHANGE_PATH);

use HTML::TreeBuilder::XPath;
use Encode;
use LWP::UserAgent;
use HTTP::Request::Common;

$VERSION = '1.17';
$MORNINGSTAR_SE_FUNDS_URL = 
    'http://morningstar.se/Funds/Quicktake/Overview.aspx?perfid=';
$PRICE_PATH = '//tr[td=\'Senaste NAV\']/td[2]';
$DATE_PATH = '//tr[td=\'Senaste NAV\']/td[3]';
$NAME_PATH = '//div/div/div/div/div/div/div/h2';
$PCHANGE_PATH = 
    decode_utf8 '//div[h6=\'Ändring NAV en dag (SEK)\']/span[1]';

sub methods { return (morningstar => \&morningstar); }

{
  my @labels = qw/date isodate method source name currency price/;

  sub labels { return (morningstar => \@labels); }
}

sub write_log
{
  my $msg = shift;
  open LOGFILE, ">>$ENV{HOME}/morningstar.log";
  print LOGFILE $msg . "\n";
  close LOGFILE or print LOGFILE "Error closing log file";
}

sub fail_document
{
  my ($funds, $symbol, $reason) = @_;
  $$funds{$symbol, "success"}  = 0;
  $$funds{$symbol, "errormsg"} =
      "Invalid document, could not find the " . $reason . ".";
  write_log $$funds{$symbol, "errormsg"};
}

sub morningstar {
  my $quoter  = shift;
  my @symbols = @_;

  return unless @symbols;
  my ($ua, $reply, $url, %funds, $tree, $data, $raw_nav, $nav, $raw_date, $date, $raw_name, $name, $raw_p_change, $p_change, $navCurrency);

  foreach my $symbol (@symbols) {
    write_log "\nFetching symbol: " . $symbol;
    $url = $MORNINGSTAR_SE_FUNDS_URL . $symbol;
    $ua    = $quoter->user_agent;
    $reply = $ua->request(GET $url);
    unless ($reply->is_success) {
      $funds{$symbol, "success"}  = 0;
      $funds{$symbol, "errormsg"} = "HTTP failure: " . $reply->status_line;
      write_log $funds{$symbol, "errormsg"};
      return wantarray ? %funds : \%funds;
    }

    $tree = HTML::TreeBuilder::XPath->new;
    $data = decode_utf8($reply->content);
    $tree->parse_content($data);
    
    #Verify the existence of the data that we want

    #Check for the price
    $raw_nav = $tree->findvalue($PRICE_PATH);
    write_log "raw_nav: " . $raw_nav;
    if ($raw_nav eq '') {
      fail_document \%funds, $symbol, "price";
      return wantarray ? %funds : \%funds;
    }

    #Check for the name of the symbol
    $raw_name = $tree->findvalue($NAME_PATH); 
    if ($raw_name eq '') {
      fail_document \%funds, $symbol, "name";
      return wantarray ? %funds : \%funds;
    }

    #Check for the date
    $raw_date = $tree->findvalue($DATE_PATH);
    if ($raw_date eq '') {
      fail_document \%funds, $symbol, "date";
      return wantarray ? %funds : \%funds;
    }

    #Check for the % change
    $raw_p_change = $tree->findvalue($PCHANGE_PATH);
    if ($raw_p_change eq '') {
      fail_document \%funds, $symbol, "procentual change";
      return wantarray ? %funds : \%funds;
    }

    $name = $raw_name;

    $p_change = $raw_p_change;
    $p_change =~ s/ //;
    $p_change =~ s/%//;
    $p_change =~ tr/,/./;
    
    #Example contents (between ||): | 1 234,56 SEK|
    $nav = $raw_nav;
    $nav =~ /\s+(.*)\s+(\S+)/;
    $nav = $1;
    $navCurrency = $2;
    $nav =~ s/ //; #Remove spaces from inside the number. This is for GNUCash.
    #Convert between swedish and english number format
    #123,45 <=> 123.45
    $nav =~ tr/,/./;
    
    write_log "NAV: |" . $nav . "|\t\tCurrency: " . $navCurrency;
    $funds{$symbol, 'method'}   = 'morningstar_funds';
    $funds{$symbol, 'nav'}    = $nav;
    $funds{$symbol, 'currency'} = $navCurrency;
    $funds{$symbol, 'success'}  = 1;
    $funds{$symbol, 'symbol'}  = $symbol;
    $funds{$symbol, 'source'}   = 'Finance::Quote::Morningstar';
    $funds{$symbol, 'name'}   = $name;
    $funds{$symbol, 'p_change'} = $p_change;
    
    $date = substr($raw_date,0,10);
    $quoter->store_date(\%funds, $symbol, {isodate => $date});
    
    $tree->delete;
  }
  return %funds if wantarray;
  return \%funds;
}

1;

=head1 NAME

Finance::Quote::Morningstar - Fetch fund prices the from the swedish Morningstar

=head1 SYNOPSIS

    use Finance::Quote;

    $q = Finance::Quote->new;

    %fundinfo = $q->fetch("morningstar","fund name");

=head1 DESCRIPTION

This module obtains information about funds from www.morningstar.se.

=head1 FUND NAMES

The fund names used are a part of the url to the morningstar site.

For example:

http://morningstar.se/Funds/Quicktake/Overview.aspx?perfid=0P00000RSZ&programid=

Here, the fund name to use is "0P00000RSZ", while this is not exactly a
friendly name, it is the id that morningstar uses on their website.  

=head1 LABELS RETURNED

Information available from this module include the following labels:
date name currency nav p_change method success

The prices are updated at the end of each bank day.

=head1 COPYRIGHT

  Copyright 2009, 2011, Simon Lindgren

=head1 AUTHORS

  Simon Lindgren <simon.n.lindgren@gmail.com>

=head1 SEE ALSO

The Finance::Quote module as well as the morningstar website
at http://morningstar.se

=cut
