#!/usr/bin/perl -w

## The purpose of this script is to generate the
## data mart documentation.
##

use strict;
use YAML::Tiny;
use utf8;
use open ':std', ':encoding(UTF-8)';
use DBI;
use Data::Dumper;
use Getopt::Long;

require 'navigation.pl';
require 'html.pl';

################################################################################

my $doc_dir = '';

my $db_name = '';
my $db_user = '';
my $db_pass = '';
my $db_port = '';
my $db_host = '';

&fetch_and_verify_options;

################################################################################

my $dbh = &connect_to_database($db_name, $db_host, $db_port, $db_user, $db_pass);

$dbh->do("set search_path=entity, features;");

my @schemas   = ('entity', 'features');
my $mart_data = {};

## Iterate over the data mart schemas.
foreach my $schema (@schemas) {
  &do_schema($schema);
}

&disconnect_from_database($dbh);

exit;

################################################################################
################################################################################

sub do_schema($) {
  my($schema) = @_;

  ## Schema stats
  $mart_data->{$schema} =
    {
      num_tables  => 0,
      num_columns => 0,
      num_data    => 0
    };

  my $file = "$doc_dir/udp/data-projects/$schema.html";

  open my $fh, '>:encoding(UTF-8)', $file
    or die "Could not open file '$file' $!";

  my $uc_schema = ucfirst($schema);
  &start_html($fh, $doc_dir, './', "Data project DB: $uc_schema", "$uc_schema tables", 'Data projects DB');

  ## Get the tables in the schema.
  my @tables = &get_tables($dbh, $schema);

  &document_tables($fh, $mart_data, $schema, \@tables);

  &end_html($fh);

  close $fh;

  return 1;
}

sub document_tables($$) {
  my($fh, $mart_data, $schema, $tables) = @_;

  ## Count the number of tables in the schema.
  $mart_data->{$schema}->{num_tables} = scalar(@$tables);

  ## Total features
  my $total_features = 0;

  ## Iterate over the tables to print
  ## the list at the top of the page.
  print $fh '<a name=top></a>';
  print $fh '<ol>';
  foreach my $table (sort { lc($a) cmp lc($b) } @$tables) {
    my @columns = &get_table_columns($dbh, $schema, $table);

    $total_features += scalar(@columns);

    print $fh
      "<li><a href='#$table'>" . &table_label($table) . '</a> (' . scalar(@columns). ')</li>'
        unless $table =~ m|^test|i;
  }
  print $fh '</ol>';
  print $fh "<p>Total data points: $total_features</p>";

  foreach my $table (@$tables) {
    &me_table($fh, $schema, $table)
      unless $table =~ m|^test|i;
  }

  return 1;
}

sub me_table($$$) {
  my($fh, $schema, $table) = @_;

  my @columns = &get_table_columns($dbh, $schema, $table);

  print $fh '<p>';
  print $fh "<a name='$table'></a>";
  print $fh '<h2>' . &table_label($table) . '</h2>';
  print $fh 'Table name: <code>' . $table . '</code>';
  print $fh '<br><br>';
  print $fh "<table class='table is-bordered is-hoverable'>";
  print $fh "<thead>";
  &table_row($fh, 'th', ['Position', 'Name', 'Data type']);
  print $fh "</thead>";

  print $fh "<tbody>";

  foreach my $column (sort {$a->{ordinal_position} <=> $b->{ordinal_position}} @columns) {

    ## Document the table row
    &table_row(
      $fh,
      'td',
      [
        $column->{ordinal_position},
        $column->{column_name},
        $column->{data_type}
      ]
    );

    ## Count this column if it's not likely
    ## to be a foreign key.
#      $mart_data->{$schema}->{num_data}++
#        if $column->{column_name} !~ m|id$|i;

    ## Count the number of columns in this table.
#    $mart_data->{$schema}->{num_columns} += scalar(@columns);

  }

  print $fh "</tbody>";
  print $fh "</table>";
  print $fh '<a href="#top">top</a>';
  print $fh '</p>';

  return 1;
}

################################################################################
################################################################################


sub table_row($$$$) {
  my($fh, $type, $ref) = @_;

  print $fh '<tr>';

  print $fh "<$type width=80>$ref->[0]</$type>";
  print $fh "<$type width=350>$ref->[1]</$type>";
  print $fh "<$type>$ref->[2]</$type>";

  print $fh "</tr>";
  print $fh "\n";

  return 1;
}

################################################################################
################################################################################

sub table_label($) {
  my($x) = @_;

  my $label = ucfirst join(' ', split('_', $x));

  return $label;
}

sub get_tables($$) {
  my($dbh, $schema) = @_;
  my @tables = ();

  my $query =
    ' SELECT table_name FROM information_schema.tables' .
    " WHERE table_type = 'BASE TABLE'" .
    " AND table_schema = ?";

  my $sth = $dbh->prepare($query);
     $sth->execute($schema);

  while(my $row = $sth->fetchrow_hashref) {
      push(@tables, $row->{table_name});
  }

  $sth->finish;

  return @tables;
}

sub get_table_columns($$$) {
  my($dbh, $schema, $table) = @_;
  my @columns = ();

  my $query =
    ' SELECT ordinal_position, column_name, data_type ' .
    ' FROM information_schema.columns ' .
    ' WHERE table_schema=? and table_name=?';

  my $sth = $dbh->prepare($query);
     $sth->execute($schema, $table);

  while(my $row = $sth->fetchrow_hashref) {
    push(
      @columns,
      {
        ordinal_position => $row->{ordinal_position},
        column_name      => $row->{column_name},
        data_type        => $row->{data_type}
      }
    );
  }

  $sth->finish;

  return @columns;
}

################################################################################
################################################################################

sub fetch_and_verify_options {

  GetOptions(
    'doc_dir=s'        => \$doc_dir,
    'db_name=s'         => \$db_name,
    'db_host=s'         => \$db_host,
    'db_port=i'         => \$db_port,
    'db_user:s'         => \$db_user,
    'db_pass:s'         => \$db_pass
  );

  ## Must have some variables to function
  if(
    $doc_dir      eq '' ||
    $db_name      eq '' ||
    $db_host      eq '' ||
    $db_port      == 0
  ) {

    print "\n\nFATAL: One or more required params is missing.\n";

    die;
  }

  return 1;
}

sub connect_to_database {
  my( $db_name, $db_host, $db_port, $db_user, $db_pass ) = @_;

  my $dbh = DBI->connect("dbi:Pg:dbname=$db_name;host=$db_host;port=$db_port", $db_user, $db_pass)
    || die "Could not connect to database\n";

  $dbh->{AutoCommit} = 0;
  $dbh->{RaiseError} = 1;
  $dbh->do("SET TIME ZONE 'UTC'");

  return $dbh;
}

sub disconnect_from_database {
  my($dbh) = @_;

  $dbh->disconnect;

  return 1;
}
