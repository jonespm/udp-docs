################################################################################
################################################################################

sub start_html($$$) {
  my($fh, $doc_dir, $prefix, $title, $header, $subheader) = @_;

  print $fh '<!doctype html>';
  print $fh '<html lang="en">';
  print $fh '  <head>';
  print $fh "   <title>$title</title>";
  print $fh '   <meta charset="utf-8">';
  print $fh "   <link rel='stylesheet' href='../assets/base.css'>";
  print $fh ' </head>';
  print $fh '<body>';
  print $fh "<a name='top'></a>";

  &ls_navigation_to_file($fh, $doc_dir, 1);

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

sub p_table_row($$$$) {
  my($fh, $type, $ref, $dim) = @_;
  my $dim_me = $dim ? ' style="color: #BBB"' : '';

  print $fh "<tr $dim_me><$type>", join("</$type><$type>", @$ref), "</$type></tr>";
  print $fh "\n";

  return 1;
}

1;
