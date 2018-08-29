

sub ls_config($) {
  my($file) = @_;

  ## Only proceed if we have some value
  ## for the loading schema directory.
  return 0 unless $file && $file ne '';

  ## Die if the file doesn't exist.
  die "Could not open $file" unless -f $file;

  ## Open the loading schema
  my $yaml = YAML::Tiny->read($file);

  ## Configuration for this UCDM Loading schema
  my $config = $yaml->[0]{configuration};

  return $config;
}

sub load_navigation($) {
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

  ## Iterate through each loading schema once
  ## to build the navigation.
  my $ls_index = {};

  foreach my $file (@files) {
    my $ls_file = $ls_dir . '/' . $file;

    my $config = &ls_config($ls_file);

    ## Create an entry for this type of system
    ## loading schema.
    $ls_index->{$config->{system}} = {}
      unless defined($ls_index->{$config->{system}});

    ## Create an entry for this version of the
    ## system's loading schema.
    $ls_index->{$config->{system}}{$config->{version}} =
      {
        label => "v$config->{version} ($config->{status})",
        file  => "$config->{system}-$config->{version}.html"
      }
      unless defined ($ls_index->{$config->{system}}{$config->{version}});
  }

  return $ls_index;
}

sub navigation_as_html($$) {
  my($doc_dir, $index) = @_;
  my $html   = '';

  ## Navigation
  my $nav_template = $doc_dir . '/udp/assets/navigation.html';

  open(my $fh, "<$nav_template")
    or die "Couldn't open $nav_template\n";

  while(my $line = <$fh> ) {

    ## Replace the template's navigation
    ## with real navigation.
    if($line =~ m|<!-- Loading schema menu -->|) {

      $html .= "<div class='navbar-item has-dropdown is-hoverable'>\n";
      $html .= "  <a class='navbar-link' href=''>\n";
      $html .= "    Loading schemas\n";
      $html .= "  </a>\n";
      $html .= "  <div class='navbar-dropdown is-boxed'>\n";

      foreach my $system (keys %$index) {
        my $versions = $index->{$system};

        foreach my $version (keys %$versions) {

          $html .= "    <a class='navbar-item' href='$versions->{$version}->{file}'>\n";
          $html .= "      $versions->{$version}->{label}";
          $html .= "\n";
          $html .= "    </a>\n";
        }
      }

      $html .= "  </div>\n";
      $html .= "</div>\n";


    } else {
      $html .= $line;
    }
  }

  close($fh);

  return $html;
}

sub ls_navigation_to_html($$) {
  my($doc_dir) = @_;

  my $nav_html =
    &navigation_as_html(
      $doc_dir,
      &load_navigation($doc_dir)
    );

  return $nav_html;
}

sub ls_navigation_to_file($$) {
  my($fh, $doc_dir) = @_;

  my $nav_html =
    &navigation_as_html(
      $doc_dir,
      &load_navigation($doc_dir)
    );

  print $fh $nav_html;

  return 1;
}

1;
