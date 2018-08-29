#!/usr/bin/env perl -w

# ./gen_navigation.pl  \
#   -doc_dir=/path/to/udp-docs
#   -depth=1

use strict;
use YAML::Tiny;
use utf8;
use open ':std', ':encoding(UTF-8)';
use DBI;
use Getopt::Long;

require 'navigation.pl';

################################################################################

my $doc_dir = '';
my $depth   = 1;

&fetch_and_verify_options;

$depth = $depth ? $depth : 1;

################################################################################

print &ls_navigation_to_html($doc_dir, $depth);

exit 1;

################################################################################
################################################################################

sub fetch_and_verify_options {

  GetOptions(
    'doc_dir=s' => \$doc_dir,
    'depth=i'   => \$depth
  );

  ## Must have some variables to function
  if( $doc_dir eq ''  ) {

    print "\n\nFATAL: One or more required params is missing.\n";

    die;
  }

  return 1;
}
