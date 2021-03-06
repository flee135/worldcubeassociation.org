<?php
#----------------------------------------------------------------------
#   Initialization and page contents.
#----------------------------------------------------------------------

$currentSection = 'misc';
require( 'includes/_header.php' );

?>

<p>This is a place for miscellaneous things having to do with the WCA results.</p>

<dl>
  <dt><a href='misc/evolution/'>Evolution of Records</a></dt>
  <dd>How the records evolved over time (as well as the #10 and #100).</dd>

  <dt><a href='misc/sum_of_ranks/'>Sum of Ranks</a></dt>
  <dd>Sum of ranks ranklist for each region.</dd>

  <dt><a href='misc/missing_averages/'>Missing Averages</a></dt>
  <dd>Lists for events without official averages.</dd>

  <dt><a href='misc/export.html'>WCA database export</a></dt>
  <dd>Export of the WCA database in several formats, allowing to analyze the data at large.</dd>
</dl>

<?php

require( 'includes/_footer.php' );

?>
