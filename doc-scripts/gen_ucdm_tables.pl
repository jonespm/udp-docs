#!/usr/bin/perl -w

## The purpose of this script is to provision the
## UcdmTable and UcdmColumn tables with data.
##
## The script accomplishes this mainly through SQL,
## by reading the DB and Table schemas, parsing the
## values, and upserting data into the UcdmTable and
## UcdmColumn tables.
##

use strict;
use DBI;

my $dbh = &connect_to_database('entity_store', '127.0.0.1', '5432', '', '');

$dbh->do("set search_path=public, ucdm;");

## Iterate over each UCDM table.
foreach my $table ( &get_tables($dbh) ) {

  ## Upsert the data (i.e. name) for that
  ## table.
  &upsert_table($dbh, $table);

  ## Fetch all of the columns in the table
  ## definition.
  my $query =
    "SELECT * FROM information_schema.columns WHERE table_name = ?";

  my $sth = $dbh->prepare($query);
     $sth->execute($table);

  ## Iterate over each table column.
  while(my $row = $sth->fetchrow_hashref) {

    ## Pull out some data about the column.
    my $column_name              = &clean($row->{column_name});
    my $ordinal_position         = &clean($row->{ordinal_position});
    my $data_type                = &clean($row->{data_type});
    my $character_maximum_length = &clean($row->{character_maximum_length});
    my $is_nullable              = &clean($row->{is_nullable});

    ## Create a better data type definition.
    my $definition = &definition($data_type, $character_maximum_length);

    ## Upsert the table column
    &upsert_table_column(
      $table,
      $ordinal_position,
      $column_name,
      $definition,
      $is_nullable
    );
  }

  ## Done!
  $sth->finish;
}

&disconnect_from_database($dbh);

exit;

sub upsert_table {
  my($dbh, $name) = @_;

  ## Guess at jurisdiction.
  my $jurisdiction = &jurisdiction($name);

  my $query =
    ' INSERT INTO UcdmTable (Name, RefJurisdictionId) VALUES (?,?) ' .
    ' ON CONFLICT (Name) DO UPDATE ' .
    ' SET Name              = excluded.Name, ' .
    '     RefJurisdictionId = excluded.RefJurisdictionId ';

  my $sth = $dbh->prepare($query);
     $sth->execute($name, $jurisdiction);
     $sth->finish;
     $dbh->commit;

   return 1;
}

sub upsert_table_column {
  my($table, $ordinal_position, $column_name, $definition, $is_nullable) = @_;

  my $query =
    ' INSERT INTO UcdmColumn (UcdmTableId, Name, Position, ColumnDefinition, IsNullable) ' .
    " VALUES ((SELECT Id from UcdmTable where Name=?), ?, ?, ?, ?) " .
    ' ON CONFLICT (UcdmTableId, Name) DO UPDATE ' .
    ' SET Position         = excluded.Position, ' .
    '     ColumnDefinition = excluded.ColumnDefinition, ' .
    '     IsNullable       = excluded.IsNullable  ';

  my $sth = $dbh->prepare($query);
     $sth->execute($table, $column_name, $ordinal_position, $definition, $is_nullable);
     $sth->finish;
     $dbh->commit;

   return 1;
}

sub get_tables {
  my($dbh) = @_;
  my @tables = ();

  my $query =
    ' SELECT table_name FROM information_schema.tables' .
    " WHERE table_type = 'BASE TABLE'" .
    " AND table_schema NOT IN " .
    " ('pg_catalog', 'information_schema'); ";

  my $sth = $dbh->prepare($query);
     $sth->execute;

  while(my $row = $sth->fetchrow_hashref) {
      push(@tables, $row->{table_name});
  }

  $sth->finish;

  return @tables;
}

sub jurisdiction($) {
  my($table) = @_;

  return 2 if (
    $table =~ m/RefEventType/i ||
    $table =~ m/RefLearnerActivityScoreType/i ||
    $table =~ m/RefOverrideType/i ||
    $table =~ m/RefResponseType/i ||
    $table =~ m/RefResultDataType/i ||
    $table =~ m/RefWorkflowState/i ||
    $table =~ m/LearnerActivitySession/i ||
    $table =~ m/LearnerGroup/i ||
    $table =~ m/CourseGrade/i ||
    $table =~ m/LearnerActivityGroup/i ||
    $table =~ m/LearnerActivityOverride/i ||
    $table =~ m/LearnerActivityResult/i ||
    $table =~ m/UcdmEntity/i ||
    $table =~ m/UcdmElement/i ||
    $table =~ m/UcdmEntityTableMapping/i ||
    $table =~ m/UcdmColumn/i ||
    $table =~ m/UcdmTable/i ||
    $table =~ m/Canvas/i ||
    $table =~ m/Sis/i
  );

  return 1;
}

sub clean($) {
  my($x) = @_;
  return defined $x ? $x : '-';
}

sub definition($$) {
  my($type, $length) = @_;
  my $x = '';

  $type = uc($type);

  if( defined $length && $length ne '-' && $length ne '' ) {
    return "$type ($length)";
  } else {
    return $type;
  }
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
