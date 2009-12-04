? extends '_base'


? block content => sub {

<pre>
<?= $var->{hello} ?>


----------------
Try to access:
 ・<a href="hello/1234">hello/1234</a>
 ・<a href="date/2009-12-04">date/2009-12-04</a>

int:  <?= $q->{int} ?>
yyyy: <?= $q->{yyyy} ?>
mm:   <?= $q->{mm} ?>
dd:   <?= $q->{dd} ?>
----------------


----------------
? for (@{$var->{samplelist}}) {
id: <?= $_->{id} ?>, name: <?= $_->{name} ?>
? }
----------------


----------------
config data sample:
  LOCATION/DOMAIN = <?= $conf->{LOCATION}{DOMAIN} ?>

env variable sample:
  SCRIPT_NAME = <?= $ENV->{SCRIPT_NAME} ?>
----------------

</pre>

? }
# /block content
