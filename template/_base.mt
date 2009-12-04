<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
  <base href="<?= $conf->{URL_BASE} ?>" />
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>Saba - a simple? cgi framework</title>

? # css
? for my $css (@{$var->{CSS_IMPORT}}) {
  <link rel="stylesheet" type="text/css" href="<?= $css ?>" charset="utf-8" />
? }

? # javascript
? for my $js (@{$var->{JS_IMPORT}}) {
  <script type="text/javascript" src="<?= $js ?>" charset="utf-8"></script>
? }

? # for IE
? for my $ie (reverse(6..9, '')) {
  <!--[if IE <?=$ie?> ]>
? # css for IE
? for my $css (@{$var->{CSS_IMPORT_IE}{"ie$ie"}}) {
  <link rel="stylesheet" type="text/css" href="<?= $css ?>" charset="utf-8" />
? }
? # javascript for IE
? for my $js (@{$var->{JS_IMPORT_IE}{"ie$ie"}}) {
  <script type="text/javascript" src="<?= $js ?>" charset="utf-8"></script>
? }
  <![endif]-->
? }

</head>
<body>

? block head => sub {
<div id="head">
<pre>
----------------------------------------------------------------

<a href="">Saba - a simple? cgi framework</a>

----------------------------------------------------------------
</pre>
</div>
? }


<div id="content">
? block content => sub {}
</div>


? block foot => sub {
<div id="foot">
<pre>
  <address>&copy; <a href="http://www.meganelab.net/">LLP meganelab</a></address>
</pre>
</div>
? }

</body>
</html>

