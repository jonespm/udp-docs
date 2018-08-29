#!/usr/bin/env perl -w

# ./gen_ls.pl  \
#   -db_name=entity_store -db_user= -db_user= -db_host=127.0.0.1 -db_port=5432 \
#   -doc_dir=/path/to/udp-docs

use strict;
use YAML::Tiny;
use Data::Dumper;
use DBI;
use Getopt::Long;

require 'navigation.pl';

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
   $dbh->do("set search_path=public, ucdm;");

&document_loading_schemas($doc_dir);

&disconnect_from_database($dbh);

exit 1;

################################################################################

sub document_loading_schemas($) {
  my($doc_dir) = @_;

  my $ls_dir = $doc_dir . '/udp/loading_schemas/src';

  ## Only proceed if we have some value
  ## for the loading schema directory.
  return 0 unless $ls_dir && $ls_dir ne '';

  ## Open the loading schemas directory.
  opendir(DIR, $ls_dir) or
    die "Cannot open ls_dir: $ls_dir\n";

  ## Fetch all of the loading schema files.
  my @files = grep(/^[a-zA-Z]+/, readdir(DIR));

  ## Iterate through each loading schema and
  ## generate the documentation.
  foreach my $file (@files) {
    my $ls_file = $ls_dir . '/' . $file;

    &document_loading_schema($doc_dir, $ls_file);
  }

  closedir DIR;
}

sub document_loading_schema($) {
  my($doc_dir, $file) = @_;

  ## Only proceed if we have some value
  ## for the loading schema directory.
  return 0 unless $file && $file ne '';

  ## Die if the file doesn't exist.
  die "Could not open $file" unless -f $file;

  ## Open the loading schema
  my $yaml = YAML::Tiny->read($file);

  ## Configuration for this UCDM Loading schema
  my $config = $yaml->[0]{configuration};

  my $system  = $config->{system};
  my $version = $config->{version};
  my $ucdmVersion = $config->{ucdmVersion};
  my $status = $config->{status};

  my $ls_label = "${system} ${version}";

  ## Entities of this schema
  my $entities = $yaml->[0]{entities};

  ## Create the HTML file representing
  ## the loading schema.
  my $outfile = $doc_dir . '/udp/loading_schemas/html/' . "${system}-${version}.html";
  open(my $fh, ">$outfile") or die "Couldn't create $outfile\n";

  ## Start the HTML in the documentation.
  &start_html($doc_dir, $fh, './', "Loading schema: $ls_label", $ls_label, 'UDP Loading schema');

  ## Status of the loading schema
  &ls_status($fh, $status);

  ## LS entities
  &ls_entity_menu($fh, $entities);

  foreach my $entity (@$entities) {

    ## Get the entity data
    my $entity_data = &get_entity_by_name($entity->{name});

    print $fh "<a name='$entity->{name}'></a>";
    print $fh "<h2>$entity_data->{name}</h2>\n";
    print $fh "<p>$entity_data->{description}</p>\n";

    print $fh '<table class="table is-bordered is-hoverable">';

    print $fh '<thead>';
    &ls_row($fh, 'Data element', 'Header', 'Description', 1);
    print $fh '</thead>';

    print $fh '<tbody>';

    ## Iterate through each element code
    ## for this entity.
    my $elements = $entity->{elements};

    ## Iterate through each element in the loading schema.
    foreach my $element_ls (@$elements) {

      next unless
        (
          defined $element_ls->{code} &&
          $element_ls->{code} ne ''
        );

      ## Get element data by its entity and code.
      my $element_data =
        &get_element_by_code(
          $entity_data->{id},
          $element_ls->{code}
        );

      ## Present element metadata from the schema
      ## if it exists. Otherwise, we default to what
      ## is in the YAML definition.
      if( defined $element_data->{name} && $element_data->{name} ne '' ) {

        &ls_row(
          $fh,
          $element_data->{name},
          "<code>$element_data->{code}</code>",
          $element_data->{description},
          0
        );

      } else {

        my $element_name = $element_ls->{name};
        my $element_code = $element_ls->{code};
        my $element_desc = $element_ls->{description};

        &ls_row(
          $fh,
          $element_name,
          "<code>$element_code</code>",
          $element_desc,
          0
        );
      }
    }

    print $fh '</tbody>';
    print $fh '</table>';
    print $fh "<a href=\"#top\">top</a>";
  }

  ## Logistics
  &ls_logistics($fh);

  ## End the HTML (footer)
  &end_html($fh);

  close($fh);

  return 1;
}

sub get_entity_by_name($) {
  my($name) = @_;
  my %data  = ();

  my $query = "SELECT * FROM UCDMENTITY WHERE name=?";
  my $sth   = $dbh->prepare($query);
     $sth->execute($name);

  while( my $entity = $sth->fetchrow_hashref ) {
    %data = (
      id => $entity->{id},
      name => $entity->{name},
      description => $entity->{description}
    );
  }

  $sth->finish;

  return \%data;
}

sub get_element_by_code($$) {
  my($entity_id, $name) = @_;
  my %data = ();

  my $query = "SELECT * FROM UCDMELEMENT WHERE ucdmentityid=? AND code=?";
  my $sth   = $dbh->prepare($query);
     $sth->execute($entity_id, $name);

  while( my $element = $sth->fetchrow_hashref ) {
    %data = (
      id => $element->{id},
      name => $element->{name},
      code => $element->{code},
      description => $element->{description},
      optionset => $element->{optionset}
    );
  }

  $sth->finish;

  return \%data;
}

sub ls_row {
  my($fh, $element, $header, $desc, $is_head) = @_;

  my $row_type = $is_head ? 'th' : 'td';

  $element = '' unless $element && $element ne '';
  $header  = '' unless $header && $header ne '';
  $desc    = '' unless $desc && $desc ne '';

  print $fh '<tr>';
  print $fh "<${row_type}>$element</${row_type}>";
  print $fh "<${row_type}>$header</${row_type}>";
  print $fh "<${row_type}>$desc</${row_type}>";
  print $fh '</tr>';

  return 1;
}

sub ls_entity_menu($$) {
  my($fh, $entities) = @_;

  ## Generate the table of contents
  print $fh "<h1>Entities</h1>";
  print $fh "<ol>";
  foreach my $entity (@$entities) {
    print $fh "<li><a href=\"#$entity->{name}\">$entity->{name}</a></li>";

  }
  print $fh "</ol>";

  return 1;
}

sub ls_logistics($) {
  my($fh) = @_;

  print $fh "<h2>What is a loading schema?</h1>";

  print $fh "<p>It is a document that defines the data and formatting requirements necessary to load data into the Unizin Data Platform. In addition, the documentation below guides decisions you must make about aligning SIS data at your Institution to the Unizin Common Data Model.</p>";

  print $fh "<p>During your UDP implementation, Unizin will provide guidance about the meaning of the data below and help you identify how to align your SIS data to the Unizin Common Data model. </p>";

  print $fh "<h1>How much data is required for each entity?</h1>";

  print $fh "<p><strong>Person</strong>. The intent is to capture all individuals who have any relationship to teaching and learning practices, and who generate data in any digital tool used in teaching and learning. This includes advisors, tutors, students, instructors, instructional designers, faculty, teaching assistants, and other actors whose behaviors generate data in a teaching & learning environment or about whom data is generated in a teaching and learning environment.</p>";

  print $fh "<p><strong>Course</strong>, <strong>Academic Term</strong>, <strong>Course Section</strong>, and <strong>Enrollment</strong>. It is expected that <em>all</em> records for these entities in your SIS are relevant to the UDP. These entities provide essential contextual information that describe your teaching and learning environments and individuals’ membership in those environments. Enrollments include not only student, but also instructors (with teaching assignments), TA, etc.</p>";

  print $fh "<h1>What are my next steps?</h1>";

  print $fh "<p>The first step in producing data to that model is correlating data in the SIS loading schema to data in your SIS. While some data is easy to correlate (e.g., a Person's first, middle, and last name), other data may not correspond exactly how data is modeled in your SIS. In these latter cases, please open a dialog with Unizin to determine how to proceed.</p>";

  print $fh "<p>Second, many data elements in the Unizin Data Common Model have are limited to a finite set of predefined values, called \"Option sets.\" When a particular element in the loading schema uses an Option set, you will need to translate your SIS data <em>values</em> to UCDM data values. For example, email addresses in UCDM have a <code>EmailType</code> data element whose values can be <code>Home</code>, <code>Work</code>, <code>Organizational</code>, and <code>Other</code>. If your SIS models an email's \"type,\" its possible values may or may not perfectly overlap with the values in the UCDM Option set for <code>EmailType</code>. When you produce the SIS data for ingestion in the UDP, you will need to align the values of data elements that use an option set to the appropriate code in that Option set.</p>";

  print $fh "<h1>Data type formats</h1>";

  print $fh "<p>When data of type <code>date</code> is requested, the format is <code>YYYY-MM-DD</code>. When data of type <code>time</code> is requested, the format is <code>hh14:mm:ss</code>. If the data does not exist for a particular record, or the mapping between your SIS and the UCDM is insufficient, leave the value blank.</p>";

  print $fh "<h1>File formats</h1>";

  print $fh "<p>Your data files must be UTF-8 encoded, comma-separated value (CSV) files with column headers. The header strings are described in the SIS Loading Schema document.</p>";

  print $fh "<ul>";
  print $fh "<li>Produce one data file for each UCDM Entity below.</li>";
  print $fh "<li>Data files are full dumps (not deltas).</li>";
  print $fh "<li>Data files are generated and pushed daily to the UDP.</li>";
  print $fh "<li>The field delimiter is a comma (,)</li>";
  print $fh "<li>The value quoting character is a double quotes (\")</li>";
  print $fh "<li>The quote escape character is a backslash (\\)</li>";
  print $fh "</ul>";

  return 1;
}

sub ls_status($$) {
  my($fh, $status) = @_;

  my $css_status = '';

  if($status eq 'Final') {
    $css_status = 'is-primary';
  } elsif($status eq 'Candidate') {
    $css_status = 'is-warning';
  } elsif($status eq 'Draft') {
    $css_status = 'is-info';
  }

  print $fh '<div class="tags has-addons">';
  print $fh '<span class="tag is-medium">Status</span>';
  print $fh "<span class='tag is-medium $css_status'>$status</span>";
  print $fh '</div>';

  return 1;
}

################################################################################
################################################################################

sub start_html($$$$$) {
  my($doc_dir, $fh, $prefix, $title, $header, $subheader) = @_;

  print $fh '<!doctype html>';
  print $fh '<html lang="en">';
  print $fh '  <head>';
  print $fh "   <title>$title</title>";
  print $fh '   <meta charset="utf-8">';
  print $fh "   <link rel='stylesheet' href='../../assets/base.css'>";
  print $fh ' </head>';
  print $fh '<body>';
  print $fh "<a name='top'></a>";

  &ls_navigation_to_file($fh, $doc_dir);

  &header($fh, $header, $subheader);

  print $fh "<div class=\"content\"><br>";
  print $fh "<div class=\"container\">";


  return 1;
}

sub header($$) {
  my($fh, $x, $y) = @_;

  print $fh '<section class="hero is-primary">';
  print $fh '  <div class="hero-body">';
  print $fh '    <div class="container">';
  print $fh '      <h1 class="title">';
  print $fh "        <b>$x</b>";
  print $fh '       </h1>';
  print $fh '      <h1 class="subtitle">';
  print $fh "        $y";
  print $fh '      </h1>';
  print $fh '    </div>';
  print $fh '  </div>';
  print $fh '</section>';

  return 1;
}

sub footer($) {
  my($fh) = @_;

  print $fh "<!-- Footer --><footer class=\"footer\"> <div class=\"container\"> <div class=\"content\"> <p> Questions about the documentation? <a href='mailto:udp\@unizin.org'>Contact us</a>.<br> Unizin Data Platform by <a href=\"http://unizin.org\">Unizin, Ltd.</a> </p> </div> </div></footer><!-- ///Footer -->";

  return 1;
}

sub section($$) {
  my($fh, $x) = @_;

  print $fh "    <h1 class=\"title\">$x</h1>";

  return 1;
}

sub end_html($) {
  my($fh) = @_;
  print $fh "<br><br><br><br>";
  print $fh "</div></div>";
  &footer($fh);
  print $fh "</body>";
  print $fh "</html>";
  return 1;
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
