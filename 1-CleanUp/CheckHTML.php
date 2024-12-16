<?php
$docpath = $argv[1]; // Command argument Path to the HTML document to process
require_once __DIR__.'/htmlpurifier/library/HTMLPurifier.auto.php';
$ja_html = file_get_contents($docpath);
// Customize HTML Purifier. See http://htmlpurifier.org/live/configdoc/plain.html
$config = HTMLPurifier_Config::createDefault();
$config->set('Core.CollectErrors',1);
$config->set('Attr.EnableID', 1);
$config->set('HTML.Doctype', 'XHTML 1.0 Strict');
$config->set('HTML.Allowed', 'div[class],h1[class],br,p[id],i,strong[class]');

// Run the checker and collect the errors
$purifier = new HTMLPurifier($config);
$pure_html = $purifier->purify($ja_html); 
$collector = $purifier->context->get('ErrorCollector');
//print_r($collector->getRaw());
// Format the output
$nb_error = 0;
foreach ($collector->getRaw() as $error) {
  $severity = "Info";
  switch ($error[1]) {
    case "1":
      $severity = "Error";
      break;
    case "2":
      $severity = "Warning";
  };
  
  // If a line number is referenced in the error, add the word 'line' in the message
  $line = $error[0]?' line ':'';
  // Display errors if they are relevant
  if (strcasecmp($error[2], 'Removed document metadata tags')) {
	print "$severity$line$error[0]: $error[2]\n";
	$nb_error = $nb_error+1;
  }
};
switch ($nb_error) {
  case "0":
    print "Info: No error found";
    break;
  case "1":
    print "Info: 1 error found";
    break;
  default:
    print "Info: $nb_error errors found";
}
// If you want to see what HTMLpurifier would have output, uncomment the next line.
// echo $pure_html;
