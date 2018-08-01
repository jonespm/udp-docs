#!/usr/bin/perl -w

## Key assumptions:
##
## 1. You've loaded the UCDM relation schema locally
##    on your machine. The database is called 'ucdm'.
##
## 2. There's no username/password protecting access
##    to the local 'ucdm' database.
##
## 3. You're not deathly allergice to perl!
##
## 4. You've got the needed perl modules installed.
##
## 5. You've set your UDP_HOME environment variable.
##

use strict;
use utf8;
use open ':std', ':encoding(UTF-8)';
use DBI;

my $dbh = &connect_to_database('entity_store', '127.0.0.1', '5432', '', '');

$dbh->do("set search_path=public, ucdm;");

&ucdm_data_dictionary($dbh);
&ucdm_relational_schema($dbh);
&ucdm_event_schema($dbh);
&map_canvas_to_ucdm($dbh);
&sis_loading_schema($dbh);

&disconnect_from_database($dbh);

1;

sub ucdm_data_dictionary($) {
  my($dbh) = @_;

  ## Create data dictionary file
  my $fh = &file_handle('ucdm/data-dictionary.html');
  &start_html($fh, './', 'UCDM Data dictionary', 'Data dictionary', 'Unizin Common Data Model');

  ## Get the UCDM entities.
  my %entities = &get_ucdm_entities($dbh);

  ########################################
  ## Display the element tables for the ##
  ## entities in the UCDM.              ##
  ########################################
  print $fh "<h1>UCDM Entities</h1>";
  print $fh "<ul>";

  foreach my $entity (sort keys %entities) {
    print $fh "<li><a href=\"#$entities{$entity}->{code}\">$entity</a></li>";
  }
  print $fh "</ul>";

  ########################################
  ## Display the element tables for the ##
  ## entities in the UCDM.              ##
  ########################################
  foreach my $entity (sort keys %entities) {

    ## Get the elements for this entity.
    my $element_query = &q_ucdm_elements;
    my $element_sth = $dbh->prepare($element_query);
       $element_sth->execute($entity);

    ## Start a new entity table.
    print $fh "<a name=\"$entities{$entity}->{code}\"><h1>$entity</h1></a>";
    print $fh '<p>', $entities{$entity}->{description}, '(', $entities{$entity}->{jurisdiction}, ')</p>';
    print $fh "<table class='table is-bordered is-hoverable'>";
    print $fh "<thead>";
    &p_table_row($fh, 'th', ['Element', 'Code', 'Description'], 0);
    print $fh "</thead>";
    print $fh "<tbody>";

    while(my $element_row = $element_sth->fetchrow_hashref) {
      my $element       = defined $element_row->{element}            ? $element_row->{element} : '';
      my $elementcode   = defined $element_row->{elementcode}        ? $element_row->{elementcode} : '';
      my $elementdesc   = defined $element_row->{elementdescription} ? $element_row->{elementdescription} : '';
      my $optionset     = defined $element_row->{optionset}          ? $element_row->{optionset} : '';

      $elementcode = "<code>$elementcode</code>";

      ## Is there an option set for the
      ## element in this entity?
      if($optionset ne '') {
        my $filename = lc($optionset);
        $elementdesc .= "<br>Option set: <a href=\"../tables/${filename}.html\">$optionset</a>";
      }

      ## Display the element for this enitty.
      &p_table_row($fh, 'td', [ $element, $elementcode, $elementdesc], '');
    }

    print $fh "</tbody>";
    print $fh "</table>";
    print $fh "<a href=\"#top\">top</a>";
    print $fh "<br><br>";
  }

  &end_html($fh);

  close($fh);

  return 1;
}

sub ucdm_relational_schema($) {
  my($dbh) = @_;

  ## Create data dictionary file
  my $fh = &file_handle('ucdm/relational-schema.html');
  &start_html($fh, './', 'UCDM table definitions', 'Relational schema', 'Unizin Common Data Model');

  &section($fh, 'Data tables');
  &table_definitions_section($dbh, $fh, &q_ucdm_tables);

  &section($fh, 'Option set tables');
  &table_definitions_section($dbh, $fh, &q_os_tables);

  &section($fh, 'Catalog tables');
  &table_definitions_section($dbh, $fh, &q_catalog_tables);

#  &section($fh, 'UDP metadata tables');
#  &table_definitions_section($dbh, $fh, &q_md_tables);

#  &section($fh, 'UDP tenant config tables');
#  &table_definitions_section($dbh, $fh, &q_tenant_tables);

  &end_html($fh);

  close($fh);

  return 1;
}

sub ucdm_event_schema($) {
  my($dbh) = @_;

  ## Create data dictionary file
  my $fh = &file_handle('udp/lrs-event-record.html');
  &start_html($fh, './', 'Event record', 'Event record', 'UDP Learning Record Store');

  print $fh "<table class='table is-bordered is-hoverable'>";
  print $fh "<thead>";
  &p_table_row($fh, 'th', ['Column', 'Description'], 0);
  print $fh "</thead>";

  print $fh "<h1>Overview</h1>";
  print $fh "The UDP Learning Record Store's Event record is designed to facilitate common event query patterns. The LRS Event record captures identifiers extracted from the event payload. Where possible, the LRS event record also captures the commonly modeled identifiers for the commonly modeled data in the UDP relational store. These identifiers align event data with already-commonly modeled relational data in the UDP and, hence, with the Unizin Common Data Model. The 'UCDM' identifiers for an event make it convenient to join event and relational warehouse data in the UDP.";
  print $fh "</p>";
  print $fh "";
  print $fh "";
  print $fh "";
  print $fh "";
  print $fh "<h1>Event record schema</h1>";
  print $fh "<p>";
  print $fh "The follow table describes the Event record schema for the UDP Learning Record Store.";
  print $fh "</p>";

  &p_table_row($fh, 'td', ['id', 'The event UUID as generated by the Caliper sensor that emitted the event or, if no UUID was part of the event, as generated by the UDP Caliper endpoint.'], 0);
  &p_table_row($fh, 'td', ['event_type', 'The value of the Caliper 1.1 <code>type</code>, as required by the standard.'], 0);
  &p_table_row($fh, 'td', ['event_action', 'The value of the Caliper 1.1 <code>action</code>, as required by the standard.'], 0);
  &p_table_row($fh, 'td', ['event_actor_id', 'The value for the Actor identifier in the original event JSON.'], 0);
  &p_table_row($fh, 'td', ['event_course_offering_id', 'If available, the value for the Course offering identifier in the original event JSON.'], 0);
  &p_table_row($fh, 'td', ['ed_app', 'The value for the <code>edApp</code> attribute in the original event JSON.'], 0);
  &p_table_row($fh, 'td', ['ucdm_actor_id', 'The UCDM surrogate identifier for the Person. This identifier can be used to join event data with relational data in the <code>Person</code> table of the UCDM.'], 0);
  &p_table_row($fh, 'td', ['ucdm_course_offering_id', 'The UCDM surrogate identifier for the Course offering. This identifier can be used to join event data with relational data in the <code>Course</code> table of the UCDM.'], 0);
  &p_table_row($fh, 'td', ['event', 'The full JSON payload of the event. If it was eligible for enrichment, the full JSON payload will also include addition attributes in the <code>extensions</code> node of the JSON object.'], 0);

  print $fh "</tbody>";
  print $fh "</table>";

  &end_html($fh);

  close($fh);

  return 1;
}

sub map_canvas_to_ucdm($) {
  my($dbh) = @_;

  ## Create data dictionary file
  my $fh = &file_handle('ucdm/canvas-to-ucdm.html');
  &start_html($fh, './', 'Canvas to UCDM', 'Canvas to UCDM', 'Mapping from Camvas Data to UCDM');

  ##########################
  ## Some proviso and such.
  print $fh '<h1>Notes about the Canvas Data -> UCDM Mapping</h1>';
  print $fh '<ol>';
  print $fh '<li> The Canvas Data schema is a denormalized, Kimball-style data warehouse schema. The UCDM schema, by constrast, is a highly normalized relational warehouse schema. Given this, the majority of foreign keys in Canvas Data\'s dimensional and fact tables will not be mapped to a particular Element in the UCDM. This is important to keep in mind as you explore the mappings.</li>';
  print $fh '<li> The <code>id</code> and <code>canvas_id</code> values for each dimensional table are not mapped. This is because, upon ingestion, the UDP replaces source primary keys with UCDM surrogate keys.</li>';
  print $fh '<li> All <code>sis_source_id</code> values are not mapped. Again, all source data primary identifiers are collapsed into UCDM surrogate identifiers.</li>';
  print $fh '</ol>';

  #########################################
  ## Print the list of Canvas Data Tables
  my $query = &q_canvas_data_tables;
  my $sth = $dbh->prepare($query);
     $sth->execute;

  print $fh "<h1>Canvas data tables</h1>";
  print $fh "<ul>";
  while(my $row = $sth->fetchrow_hashref) {
    my $cdtable = defined $row->{cdtable} ? $row->{cdtable} : '-';
    print $fh "<li><a href=\"#$cdtable\">$cdtable</a></li>";
  }
  print $fh "</ul>";

  $sth->finish;
  ##################################
  ## Print each table one by one. ##
  $query = &q_canvas_data_tables;
  $sth = $dbh->prepare($query);
  $sth->execute;

  while(my $row = $sth->fetchrow_hashref) {
    my $cdtable = defined $row->{cdtable} ? $row->{cdtable} : '-';

    print $fh "<a name='$cdtable'></a>";
    print $fh "<h1>$cdtable</h1>";
    print $fh "<table class='table is-bordered is-hoverable'>";
    print $fh "<thead>";
    &p_table_row($fh, 'th', ['CD Column', 'Entity', 'Element', 'UCDM Table', 'UCDM Column'], 0);
    print $fh "</thead>";
    print $fh "<tbody>";

    my $table_query = &q_canvas_data_table_to_ucdm;
    my $table_sth = $dbh->prepare($table_query);
       $table_sth->execute($cdtable);

    while(my $t_row = $table_sth->fetchrow_hashref) {
      my $cdcolumn      = defined $t_row->{cdcolumn}      ? $t_row->{cdcolumn} : '-';
      my $entity        = defined $t_row->{entity}        ? $t_row->{entity} : '-';
      my $element       = defined $t_row->{element}       ? $t_row->{element} : '-';
      my $ucdmtable     = defined $t_row->{ucdmtable}     ? $t_row->{ucdmtable} : '-';
      my $ucdmcolumn    = defined $t_row->{ucdmcolumn}    ? $t_row->{ucdmcolumn} : '-';
      my $isingested    = defined $t_row->{isingested}    ? $t_row->{isingested} : '-';

      ## Does this element take an option set?
      ## If so, link to the option set table.
      if( &is_os_table($ucdmcolumn) ) {
        my $os = $ucdmcolumn;
           $os =~ s/Id$//i;
           $os = lc($os);
        $ucdmcolumn = "$ucdmcolumn (<a href=\"../tables/${os}.html\">option set</a>)";
      }

      if( $isingested ) {
        $ucdmtable  = "<code>$ucdmtable</code>" unless $ucdmtable eq '-';
        $ucdmcolumn = "<code>$ucdmcolumn</code>" unless $ucdmcolumn eq '-';
      }

      ## Do something here if the Entity/Element
      ## to UCDM Table/Column mapping is not yet
      ## supported.
      my $dim = $isingested ? 0 : 1;

      &p_table_row($fh, 'td', [$cdcolumn, $entity, $element, $ucdmtable, $ucdmcolumn], $dim);
    }

    print $fh "</tbody>";
    print $fh "</table>";
    print $fh "<a href=\"#top\">top</a>";
    print $fh "<br><br>";

    $table_sth->finish;
  }

  $sth->finish;

  &end_html($fh);

  close($fh);

  return 1;
}

################################################################################
################################################################################

sub sis_loading_schema($) {
  my($dbh) = @_;

  ########################################
  ## Find the SIS latest loading schema.
  my $latest_version = &get_latest_sis_loading_schema;

  return unless (defined $latest_version && $latest_version > 0);

  ###################################
  ## Create SIS Loading schema file
  my $fh = &file_handle('ucdm/sis-loading-schema.html');
  &start_html($fh, './', "SIS Loading schema v. $latest_version", "SIS Loading schema v. $latest_version", 'Documentation');

  ##############################################
  ## First, content describing how to use the
  ## SIS loading schema.
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

  ## Fetch the loading schema's entities.
  my %entities =
    &get_sis_loading_schema_ucdm_entities($dbh, $latest_version);

  ## Generate the table of contents
  print $fh "<h1>Entities</h1>";
  print $fh "<ol>";
  foreach my $entity (sort { $entities{$a}->{id} <=> $entities{$b}->{id} } keys %entities) {
    print $fh "<li><a href=\"#$entities{$entity}->{id}\">$entity</a></li>";
  }
  print $fh "</ol>";

  foreach my $entity (sort { $entities{$a}->{id} <=> $entities{$b}->{id} } keys %entities) {

    ## Get the entity elements in the Loading schema.
    my $entity_id = $entities{$entity}->{id};

    print $fh "<a name='$entity_id'></a>";
    print $fh "<h2>$entity</h2>";
    print $fh "<p>$entities{$entity}->{description}</p>";

    ## Make a filename
    my $filename = $entity;
       $filename =~ s/\s/_/g;
       $filename = lc($filename);

    print $fh "<p>The $entity file should be created in a comma-separated (CSV) format with the naming convention <code>$filename\_&lt;date&gt;.csv</code> , where <date> is the date on which the file was generated, and the following headers:</p>";

    print $fh "<table class='table is-bordered is-hoverable'>";
    print $fh "<thead>";
    &p_table_row($fh, 'th', ['Data element', 'Header', 'Description'], 0);
    print $fh "</thead>";
    print $fh "<tbody>";

    ## Required identifiers for the Loading schema,
    ## based on the entities.
    &sis_loading_schema_identifiers($fh, $entity);

    ## Get the Entity elements in the loading schema.
    my %elements =
      &get_sis_loading_schema_ucdm_elements_for_entity(
        $dbh,
        $latest_version,
        $entity_id
      );

    foreach my $element (sort { $elements{$a}->{id} <=> $elements{$b}->{id} } keys %elements) {
      my $code        = $elements{$element}->{code};
      my $name        = $elements{$element}->{name};
      my $description = $elements{$element}->{description};

      ## Codify code
      $code = "<code>$code</code>";

      ## Is there an option set?
      if( defined $elements{$element}->{optionset} &&
                  $elements{$element}->{optionset} ne '' ) {

        my $filename = lc($elements{$element}->{optionset});

        $description =
          "<p>$description</p>" .
          "<p>" .
          " Option set: " .
          " <a href=\"../tables/${filename}.html\">$elements{$element}->{optionset}</a>" .
          "</p>";
      } else {
        $description = "<p>$description</p>";
      }

      &p_table_row($fh, 'td', [$name, $code, $description], 0);
    }

    print $fh "</tbody>";
    print $fh "</table>";
    print $fh "<a href=\"#top\">top</a>";
    print $fh "<br><br>";
  }

  &end_html($fh);

  close($fh);

  return 1;
}

sub sis_loading_schema_identifiers($$) {
  my($fh, $entity) = @_;

  ## Need to have an entity.
  return unless defined $entity && $entity ne '';

  if($entity eq 'Person') {
    &p_table_row($fh, 'td', ['SIS Internal Person ID', '<code>SisIntId</code>', 'The internal primary key used by the SIS to define a person record. This ID may or may not be different than the external Person ID.'], 0);
    &p_table_row($fh, 'td', ['SIS External Person ID', ' <code>SisExtId</code>', 'The unique, global ID for a person that is generated by the SIS for use in external tools, such as the LMS, LTI tools, etc.'], 0);

  } elsif( $entity eq 'Institutional affiliation') {
    &p_table_row($fh, 'td', ['SIS Internal Person ID', '<code>PersonId</code>', 'The unique, SIS-generated internal Person ID for the person affiliated in an institution of higher education.'], 0);

  } elsif( $entity eq 'Academic term') {
    &p_table_row($fh, 'td', ['SIS Internal Term ID', '<code>SisIntId</code>', 'The unique primary key used internally by your SIS system to identify an academic term. This ID may or may not differ from the external id.'], 0);
    &p_table_row($fh, 'td', ['SIS External Term ID', '<code>SisExtId</code>', 'The unique, global ID for an academic term generated in your institutional SIS for use by external tools such as Canvas, LTI applications, etc.'], 0);

  } elsif( $entity eq 'Course offering') {
    &p_table_row($fh, 'td', ['SIS Internal Course offering ID', '<code>SisIntId</code>', 'The unique primary key used by your SIS to internally identify a Course Offering. This ID may or may not differ from the external id.'], 0);
    &p_table_row($fh, 'td', ['SIS External Course offering ID', '<code>SisExtId</code>', 'The unique, global id for the Course Offering generated for Canvas and other learning systems and tools.'], 0);
    &p_table_row($fh, 'td', ['SIS Internal Term ID', '<code>TermId</code>', 'The globally unique, SIS-generated internal ID for the term to which the Course Offering belongs.'], 0);

  } elsif( $entity eq 'Course section') {
    &p_table_row($fh, 'td', ['SIS Internal Course section ID', '<code>SisIntId</code>', 'The unique primary key used by your SIS to internally identify a Course Section. This ID may or may not differ from the external id.'], 0);
    &p_table_row($fh, 'td', ['SIS External Course section ID', '<code>SisExtId</code>', 'The globally unique, SIS-generated ID used by Canvas and other learning tools to identify a particular section.'], 0);
    &p_table_row($fh, 'td', ['SIS Internal Course offering ID', '<code>CourseId</code>', 'The unique, SIS-generated ID for the Course Offering of which the section is an instance.'], 0);
    &p_table_row($fh, 'td', ['SIS Internal Term ID', '<code>TermId</code>', 'The unique, SIS-generated ID for the academic term to which the Course Section belongs.'], 0);

  } elsif( $entity eq 'Course section enrollment') {
    &p_table_row($fh, 'td', ['SIS Internal Person ID', '<code>PersonId</code>', 'The unique, SIS-generated internal ID for the person who is enrolled in a Course Section.'], 0);
    &p_table_row($fh, 'td', ['SIS Internal Course section ID', '<code>SectionId</code>', 'The unique, SIS-generated internal ID for the Course Section in which a person is enrolled.'], 0);

  }

  return 1;
}

################################################################################
################################################################################

sub table_definitions_section($$) {
  my($dbh, $fh, $query) = @_;

  my $sth = $dbh->prepare($query);
     $sth->execute;

  print $fh "<table class='table is-bordered is-hoverable'>";
  print $fh "<thead>";
  &p_table_row($fh, 'th', ['Name', 'Jursidiction'], 0);
  print $fh "</thead>";

  print $fh "<tbody>";
  while(my $row = $sth->fetchrow_hashref) {
    my $name         = defined $row->{name}         ? $row->{name} : '';
    my $jurisdiction = defined $row->{jurisdiction} ? $row->{jurisdiction} : '';

    &f_create_ucdm_table($dbh, $name);

    my $filename = lc($name);

    $name = " <a href=\"../tables/$filename.html\">$name</a>";

    &p_table_row($fh, 'td', [$name, $jurisdiction], 0);
  }

  print $fh "</tbody>";
  print $fh "</table>";

  $sth->finish;
}

################################################################################
################################################################################


########################################################
## Pass this function a table name, it will create
## a file for that able that presents the table
## definition.
##
## If the table is an Option set table, this function
## will additionally include the presentation of the
## Option set table values.
##
sub f_create_ucdm_table($$) {
  my($dbh, $table) = @_;
  my @os_tables = (); ## Track OS tables for this table if they exist.

  my $filename = lc($table);

  my $fh = &file_handle("tables/${filename}.html");
  &start_html($fh, '../', "$table: definition", $table, '');

  my @table_header = ('Name', 'Definition', 'Jursidiction');
  push(@table_header, 'Option set') unless &is_os_table($table);

  ## Get the option set table definition
  my $query = &q_ucdm_table($table);
  my $sth   = $dbh->prepare($query);
     $sth->execute;

  print $fh "<b>Table definition</b>";
  print $fh "<table class='table is-bordered is-hoverable'>";
  print $fh "<thead>";
  &p_table_row($fh, 'th', \@table_header, 0);
  print $fh "</thead>";
  print $fh "<tbody>";

  ## Iterate over each column definition in
  ## this UCDM table.
  while(my $row = $sth->fetchrow_hashref) {
    my $name         = defined $row->{name} ? $row->{name} : '';
    my $column       = defined $row->{column} ? $row->{column} : '';
    my $jurisdiction = defined $row->{jurisdiction} ? $row->{jurisdiction} : '';
    my $option_set   = '';

    ## Construct the first required table columns
    ## that describe this UCDM table column.
    my @table_row = ($name, $column, $jurisdiction);

    ## If this table is itself an option set table,
    ## then do nothing.
    if( &is_os_table($table) ) {
      ## Do nothing.

    ## If this table's column takes an Option set,
    ## then present a link to the Option set table
    ## file itself.
    } elsif( $name =~ /^(Ref\w+)id$/i ) {
      my $filename = lc($1);
      $option_set = "<a href=\"${filename}.html\">$1</a>";
      push(@table_row, $option_set);

    ## If this is a normal UCDM element in the
    ## table, then present that!
    } elsif( ! &is_os_table($table) ) {
      push(@table_row, '');
    }

    ## Write the row describing the UCDM table
    ## column to disk.
    &p_table_row($fh, 'td', \@table_row, 0);
  }

  print $fh "</tbody>";
  print $fh "</table>";

  ## If we're presenting an option set
  ## table, then print the values.
  if( &is_os_table($table) ) {
    &p_option_set_values($fh, $table);
  } elsif( $table =~ /Role/i ) {
    &p_role_values($fh);
  }

  &end_html($fh);

  close($fh);
  return 1;
}

################################################################################
################################################################################
sub is_udp_table($) {
  my($x) = @_;

  if($x =~ /^Udp/i) {
    return 1;
  }

  return 0;
}

sub is_ucdm_table($) {
  my($x) = @_;

  if( ! &is_udp_table($x) &&
      ! &is_md_table($x)  &&
      ! &is_os_table($x) ) {

    return 1;
  }

  return 0;
}

sub is_md_table($) {
  my($x) = @_;

  if($x =~ /^Md/i) {
    return 1;
  }

  return 0;
}

sub is_os_table($) {
  my($x) = @_;

  if($x =~ /^Ref/i) {
    return 1;
  }

  return 0;
}


################################################################################
################################################################################

sub get_latest_sis_loading_schema($) {
  my($dbh) = @_;
  my $version = undef;

  my $query = &q_sis_latest_loading_schema;
  my $sth   = $dbh->prepare($query);
     $sth->execute;

  while( my $row = $sth->fetchrow_hashref ) {
    $version = $row->{version};
  }

  $sth->finish;

  return $version;
}

sub get_ucdm_entities($) {
  my($dbh) = @_;
  my %entities = ();

  my $query = &q_ucdm_entities;
  my $sth = $dbh->prepare($query);
     $sth->execute;

   while(my $row = $sth->fetchrow_hashref) {
     my $id           = defined $row->{id}           ? $row->{id} : '';
     my $name         = defined $row->{name}         ? $row->{name} : '';
     my $description  = defined $row->{description}  ? $row->{description} : '';
     my $jurisdiction = defined $row->{jurisdiction} ? $row->{jurisdiction} : '';

     my $code = lc($name);
        $code =~ s/\s/-/g;

     $entities{$name} = {
       id           => $id,
       code         => $code,
       description  => $description,
       jurisdiction => $jurisdiction
     };
   }

  $sth->finish;

  return %entities;
}

sub get_sis_loading_schema_ucdm_entities($$) {
  my($dbh, $version) = @_;
  my %entities = ();

  my $query = &q_sis_loading_schema_ucdm_entities;
  my $sth = $dbh->prepare($query);
     $sth->execute($version);

   while(my $row = $sth->fetchrow_hashref) {
     my $id           = defined $row->{id}           ? $row->{id} : '';
     my $name         = defined $row->{name}         ? $row->{name} : '';
     my $description  = defined $row->{description}  ? $row->{description} : '';
     my $jurisdiction = defined $row->{jurisdiction} ? $row->{jurisdiction} : '';

     my $code = lc($name);
        $code =~ s/\s/-/g;

     $entities{$name} = {
       id           => $id,
       code         => $code,
       description  => $description,
       jurisdiction => $jurisdiction
     };
   }

  $sth->finish;

  return %entities;
}

sub get_sis_loading_schema_ucdm_elements_for_entity($$$) {
  my($dbh, $version, $entity) = @_;
  my %elements = ();

  my $query = &q_sis_loading_schema_ucdm_elements_for_entity;
  my $sth   = $dbh->prepare($query);
     $sth->execute($version, $entity);

   while(my $row = $sth->fetchrow_hashref) {
     my $id           = defined $row->{id}           ? $row->{id} : '';
     my $name         = defined $row->{name}         ? $row->{name} : '';
     my $code         = defined $row->{code}         ? $row->{code} : '';
     my $description  = defined $row->{description}  ? $row->{description} : '';
     my $optionset    = defined $row->{optionset}    ? $row->{optionset} : '';

     $elements{$name} = {
       id           => $id,
       name         => $name,
       code         => $code,
       description  => $description,
       optionset    => $optionset
     };

   }

  $sth->finish;

  return %elements;
}

################################################################################
################################################################################

sub file_handle($) {
  my($x) = @_;
  my $udp_home = $ENV{'UDP_DOCS_HOME'};
  my $y = "$udp_home/udp/$x";
  open(my $fh, '>:encoding(UTF-8)', $y) or die "Could not open file '$y' $!";
  return $fh;
}

################################################################################
################################################################################

sub start_html($$$) {
  my($fh, $prefix, $title, $header, $subheader) = @_;

  print $fh '<!doctype html>';
  print $fh '<html lang="en">';
  print $fh '  <head>';
  print $fh "   <title>$title</title>";
  print $fh '   <meta charset="utf-8">';
  print $fh "   <link rel='stylesheet' href='../assets/base.css'>";
  print $fh ' </head>';
  print $fh '<body>';
  print $fh "<a name='top'></a>";

  &navigation($fh);

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

sub navigation($) {
  my($fh) = @_;

  print $fh "<!-- Navigation --><div class=\"container\"> <nav class=\"navbar is-transparent\"> <div class=\"navbar-brand\"> <div class=\"navbar-burger burger\" data-target=\"navbarExampleTransparentExample\"> <span></span> <span></span> <span></span> </div> </div> <div id=\"navbarExampleTransparentExample\" class=\"navbar-menu\"> <div class=\"navbar-start\"> <a class=\"navbar-item\" href=\"../index.html\"> Home </a> <!-- UDP documentation menu --> <div class=\"navbar-item has-dropdown is-hoverable\"> <a class=\"navbar-link\" href=\"\"> UDP </a> <div class=\"navbar-dropdown is-boxed\"> <a class=\"navbar-item\" href=\"../udp/access-udp-resources.html\"> Accessing UDP resources </a> <hr class=\"navbar-divider\"> <a class=\"navbar-item\" href=\"../udp/caliper-endpoint.html\"> Caliper endpoint </a> <a class=\"navbar-item\" href=\"../udp/event-processing.html\"> Event processing </a> <a class=\"navbar-item\" href=\"../udp/lrs-event-record.html\"> Event record </a> </div> </div> <!-- UCDM documentation menu --> <div class=\"navbar-item has-dropdown is-hoverable\"> <a class=\"navbar-link\" href=\"\"> UCDM </a> <div class=\"navbar-dropdown is-boxed\"> <a class=\"navbar-item\" href=\"../ucdm/data-dictionary.html\"> Data dictionary (ingested) </a> <a class=\"navbar-item\" href=\"../ucdm/data-dictionary-modeled.html\"> Data dictionary (modeled) </a> <a class=\"navbar-item\" href=\"../ucdm/relational-schema.html\"> Relational schema </a> <a class=\"navbar-item\" href=\"../ucdm/sis-loading-schema-v1.html\"> SIS Loading Schema for UCDM (v1) </a> <a class=\"navbar-item\" href=\"../ucdm/sis-loading-schema-v1p1.html\"> SIS Loading Schema proposed changes (v1.1) </a> <a class=\"navbar-item\" href=\"../ucdm/canvas-to-ucdm.html\"> Canvas Data to UCDM </a> <hr class=\"navbar-divider\"> <a class=\"navbar-item\" href=\"../ucdm/queries-relational-store.html\"> Sample Relational Store queries </a> <a class=\"navbar-item\" href=\"../ucdm/queries-event-store.html\"> Sample Learning Record Store queries </a> </div> </div> <!-- Developer menu --> <div class=\"navbar-item has-dropdown is-hoverable\"> <a class=\"navbar-link\" href=\"\"> Developers </a> <div class=\"navbar-dropdown is-boxed\"> <a class=\"navbar-item\" href=\"../developers/caliper-integration.html\"> Caliper sensor guidelines </a> </div> </div> </div> <div class=\"navbar-end\"> </div> </div> </nav></div><!-- /// Navigation -->";

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


########################################
## Present the values of an Option set
## as an HTML table.
sub p_option_set_values($$) {
  my($fh, $table) = @_;

  ## Get the option set values query.
  my $query = &q_os_table($table);
  my $sth   = $dbh->prepare($query);
     $sth->execute;

  print $fh "<b>Option set values</b>";
  print $fh "<table class='table is-bordered is-hoverable'>";
  print $fh "<thead>";
  &p_table_row($fh, 'th', ['Code', 'Description', 'Definition', 'Jurisdiction'], 0);
  print $fh "</thead>";
  print $fh "<tbody>";

  ## Iterate over each value in the Option set.
  while(my $row = $sth->fetchrow_hashref) {
    my $code         = defined $row->{code} ? $row->{code} : '';
    my $description  = defined $row->{description} ? $row->{description} : '';
    my $definition   = defined $row->{definition} ? $row->{definition} : '';
    my $jurisdiction = defined $row->{jurisdiction} ? $row->{jurisdiction} : '';

    $code = "<code>$code</code>";

    &p_table_row($fh, 'td', [$code, $description, $definition, $jurisdiction], 0);
  }

  print $fh "</tbody>";
  print $fh "</table>";

  return 1;
}

sub p_role_values($) {
  my($fh) = @_;

  ## Get the option set values query.
  my $query = &q_role_table;
  my $sth   = $dbh->prepare($query);
     $sth->execute;

  print $fh "<b>Option set values</b>";
  print $fh "<table class='table is-bordered is-hoverable'>";
  print $fh "<thead>";
  &p_table_row($fh, 'th', ['RoleId', 'Name', 'Jurisdiction'], 0);
  print $fh "</thead>";
  print $fh "<tbody>";

  ## Iterate over each value in the Option set.
  while(my $row = $sth->fetchrow_hashref) {
    my $roleid       = defined $row->{roleid} ? $row->{roleid} : '';
    my $name         = defined $row->{name} ? $row->{name} : '';
    my $jurisdiction = defined $row->{jurisdiction} ? $row->{jurisdiction} : '';

    $roleid = "<code>$roleid</code>";

    &p_table_row($fh, 'td', [$roleid, $name, $jurisdiction], 0);
  }

  print $fh "</tbody>";
  print $fh "</table>";

  return 1;
}

sub p_table_row($$$$) {
  my($fh, $type, $ref, $dim) = @_;
  my $dim_me = $dim ? ' style="color: #BBB"' : '';

  print $fh "<tr $dim_me><$type>", join("</$type><$type>", @$ref), "</$type></tr>";
  print $fh "\n";

  return 1;
}

################################################################################
################################################################################

sub q_table_exists($$) {
  my($dbh, $table) = @_;
  my $x = 0;

  my $query = 'SELECT * FROM ucdmtable WHERE name=?';
  my $sth   = $dbh->prepare($query);
     $sth->execute($table);

  while ($sth->fetch()) {
    $x = 1;
  }

  $sth->finish;

  return $x;
}

sub q_ucdm_elements {
  my $x =
    'SELECT' .
    '  UcdmEntity.Name as Entity, ' .
    '  UcdmElement.Name as Element, ' .
    '  UcdmElement.Code as ElementCode, ' .
    '  UcdmElement.Description as ElementDescription, ' .
    '  UcdmElement.OptionSet   as OptionSet,' .
    '  UcdmEntityTableMapping.UcdmTable as UcdmTable, ' .
    '  UcdmEntityTableMapping.UcdmColumn as UcdmColumn ' .
    'FROM UcdmElement ' .
    'LEFT JOIN UcdmEntity ON UcdmEntity.Id=UcdmElement.UcdmEntityId ' .
    'LEFT JOIN UcdmEntityTableMapping on UcdmElement.Id=UcdmEntityTableMapping.UcdmElementId ' .
    'WHERE UcdmEntity.Name = ? ' .
    'ORDER BY UcdmEntity.Id, UcdmElement.id';

  return $x;
}

sub q_canvas_data_tables {
  my $x =
    'SELECT DISTINCT(canvasdatatable) as CDTable ' .
    ' FROM CanvasDataUcdmMapping  ' .
    ' ORDER BY canvasdatatable ASC';

  return $x;
}

sub q_canvas_data_table_to_ucdm {
  my $x =
    ' SELECT ' .
      ' CanvasDataUcdmMapping.CanvasDataField CDColumn, ' .
      ' CanvasDataUcdmMapping.IsIngested as IsIngested, ' .
      ' UcdmEntity.name Entity, ' .
      ' UcdmElement.name Element, ' .
      ' UcdmEntityTableMapping.UcdmTable UcdmTable, ' .
      ' UcdmEntityTableMapping.UcdmColumn UcdmColumn, ' .
      ' UcdmElement.OptionSet OptionSet ' .
    ' FROM CanvasDataUcdmMapping' .
    ' LEFT JOIN UcdmElement on UcdmElement.Id=CanvasDataUcdmMapping.UcdmElementId' .
    ' LEFT JOIN UcdmEntity  on UcdmEntity.Id=UcdmElement.UcdmEntityId' .
    ' LEFT JOIN UcdmEntityTableMapping on UcdmEntityTableMapping.UcdmElementId=UcdmElement.Id' .
    ' WHERE CanvasDataTable=? ' .
    ' ORDER BY' .
    '  CanvasDataUcdmMapping.CanvasDataTable, CanvasDataUcdmMapping.Id';

  return $x;
}

sub q_sis_latest_loading_schema {
  my $x =
    'select max(version) as version from SisLoadingSchema';

  return $x;
}

sub q_sis_loading_schema_ucdm_entities {
  my $x =
    ' SELECT UcdmEntity.* ' .
    ' FROM SisLoadingSchemaElement ' .
    ' INNER JOIN UcdmElement  on UcdmElement.Id=SisLoadingSchemaElement.UcdmElementId ' .
    ' INNER JOIN UcdmEntity   on UcdmEntity.Id=UcdmElement.UcdmEntityId ' .
    ' WHERE SisLoadingSchemaId=? ' .
    ' GROUP BY UcdmEntity.Id ' .
    ' ORDER BY UcdmEntity.Id ASC';

  return $x;
}

sub q_sis_loading_schema_ucdm_elements_for_entity {
  my $x =
    ' SELECT ' .
    ' UcdmElement.Id as id, ' .
    ' UcdmElement.name as name,  ' .
    ' UcdmElement.code as code,  ' .
    ' UcdmElement.description as description, ' .
    ' UcdmElement.optionset as optionset ' .
    ' FROM SisLoadingSchemaElement ' .
    ' INNER JOIN UcdmElement on UcdmElement.Id=SisLoadingSchemaElement.UcdmElementId ' .
    ' INNER JOIN UcdmEntity  on UcdmEntity.Id=UcdmElement.UcdmEntityId ' .
    ' WHERE SisLoadingSchemaId=? ' .
    ' AND   UcdmEntity.Id=? ' .
    ' ORDER BY UcdmElement.UcdmEntityId, UcdmElement.Id ASC ';

  return $x;
}

sub q_os_tables {
  my $x =
    ' SELECT ' .
    "   UcdmTable.Name as Name, Organization.Name as Jurisdiction" .
    " FROM UcdmTable " .
    " INNER JOIN Organization on UcdmTable.RefJurisdictionId=Organization.OrganizationId" .
    " WHERE lower(UcdmTable.Name) like 'ref%' or lower(UcdmTable.Name) like 'role'";

  return $x;
}

sub q_os_table {
  my($table) = @_;

  my $x =
    'SELECT ' .
    '  *, Organization.Name as Jurisdiction ' .
    "FROM $table " .
    "INNER JOIN Organization on $table.RefJurisdictionId=Organization.OrganizationId";

  return $x;
}

sub q_role_table {
  my $x =
    'SELECT ' .
    '  Role.RoleId, Role.Name, Organization.Name as Jurisdiction ' .
    "FROM Role " .
    "INNER JOIN Organization on Role.RefJurisdictionId=Organization.OrganizationId";

  return $x;
}

sub q_catalog_tables {
  my $x =
    ' SELECT ' .
    "   UcdmTable.Name as Name, Organization.Name as Jurisdiction" .
    " FROM UcdmTable " .
    " INNER JOIN Organization on UcdmTable.RefJurisdictionId=Organization.OrganizationId" .
    " WHERE UcdmTable.Name like 'ucdm%' " .
    "    OR UcdmTable.Name like 'canvas%' " .
    "    OR UcdmTable.Name like 'sis%' ";

  return $x;
}


sub q_md_tables {
  my $x =
    ' SELECT ' .
    "   UcdmTable.Name as Name, Organization.Name as Jurisdiction" .
    " FROM UcdmTable " .
    " INNER JOIN Organization on UcdmTable.RefJurisdictionId=Organization.OrganizationId" .
    " WHERE UcdmTable.Name like 'md%'";

  return $x;
}

sub q_tenant_tables {
  my $x =
    ' SELECT ' .
    "   UcdmTable.Name as Name, Organization.Name as Jurisdiction" .
    " FROM UcdmTable " .
    " INNER JOIN Organization on UcdmTable.RefJurisdictionId=Organization.OrganizationId" .
    " WHERE UcdmTable.Name like 'udp%'";

  return $x;
}

sub q_ucdm_tables {
  my $x =
    ' SELECT ' .
    "   UcdmTable.Name as Name, Organization.Name as Jurisdiction" .
    " FROM UcdmTable " .
    " INNER JOIN Organization on UcdmTable.RefJurisdictionId=Organization.OrganizationId" .
    " WHERE UcdmTable.Name not like 'ucdm%' AND " .
    "       UcdmTable.Name not like 'udp%' AND " .
    "       UcdmTable.Name not like 'md%' AND " .
    "       UcdmTable.Name not like 'ref%' AND " .
    "       UcdmTable.Name not like 'canvas%' AND " .
    "       UcdmTable.Name not like 'sis%' AND " .
    "       UcdmTable.Name != 'roles'";

  return $x;
}

sub q_ucdm_table($) {
  my($table) = @_;

  my $x =
    ' SELECT ' .
    "   UcdmColumn.Name as Name, UcdmColumn.ColumnDefinition as Column, Organization.Name as Jurisdiction" .
    " FROM UcdmColumn " .
    " INNER JOIN Organization on UcdmColumn.RefJurisdictionId=Organization.OrganizationId" .
    " INNER JOIN UcdmTable on UcdmColumn.UcdmTableId=UcdmTable.Id" .
    " WHERE UcdmTable.Name='$table'";

  return $x;
}

sub q_ucdm_entities {
  my $x =
    'SELECT UcdmEntity.*, Organization.Name Jurisdiction FROM UCDMENTITY ' .
    ' INNER JOIN Organization on UcdmEntity.RefJurisdictionId=Organization.OrganizationId' .
    ' ORDER BY ID ASC';

  return $x;
}

sub q_ref_table($) {
  my($ref_table) = @_;

  my $x =
    ' SELECT ' .
      ' Description, Code, Definition, ' .
      ' Organization.Name' .
    " FROM $ref_table " .
    " INNER JOIN Organization on $ref_table.RefJurisdictionId=Organization.OrganizationId";

  return $x;
}

################################################################################
################################################################################

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
