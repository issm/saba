#!/usr/bin/perl
use strict;
use warnings;
use utf8;

BEGIN {
  unshift @INC, qw/lib extlib/;
}

use FindBin;
use File::Path qw/make_path/;
use Text::MicroTemplate::Extended;
use Data::Dumper;

my $MODE    = 'CLI';  # CLI or CGI
my $BINDIR  = $FindBin::Bin;
my $ROOTDIR = sprintf '%s/..', $BINDIR;

#
# .saba が存在する場合，セットアップを中止する
#
if (-f "$ROOTDIR/.saba") {
  abort_setup();
}


my ($protocol, $server_name, $subdomain, $request_path);
#
#
#
if (defined $ENV{SERVER_NAME}) {
  $MODE = 'CGI';
  ($protocol = lc $ENV{SERVER_PROTOCOL}) =~ s{/.*$}{};
  $server_name = $ENV{SERVER_NAME};
  $subdomain = '';
  ($request_path = $ENV{SCRIPT_NAME}) =~ s{/saba/setup\.cgi}{};
}
else {
  ($protocol,
   $server_name,
   $subdomain,
   $request_path,
  ) = stdin_params();
}


$protocol     ||= 'http';
$server_name  ||= 'localhost';
$subdomain    ||= '';
$request_path ||= '';


my $SKELDIR = "$BINDIR/skel/setup";
my $mt = Text::MicroTemplate::Extended->new(
    include_path  => [$SKELDIR],
    template_args => {
        protocol     => $protocol,
        server_name  => $server_name,
        subdomain    => $subdomain,
        request_path => $request_path,
        env          => \%ENV,
    },
);



my $t;
#
# .saba を生成する
#
$t = $mt->render('conf/saba')->as_string;
save_file("$ROOTDIR/.saba", $t);

#
# .urlmap を生成する
#
$t = $mt->render('conf/urlmap')->as_string;
save_file("$ROOTDIR/.urlmap", $t);

#
# .htaccess を生成する
#
$t = $mt->render('conf/htaccess')->as_string;
save_file("$ROOTDIR/.htaccess", $t);

#
# index.cgi を生成する
#
$t = $mt->render('cgi/index.cgi')->as_string;
save_file("$ROOTDIR/index.cgi", $t);
chmod 0755, "$ROOTDIR/index.cgi";

#
# data ツリーを生成する
#
my $DATADIR = "$ROOTDIR/data";
make_path (map "$DATADIR/$_", qw/yaml sql/);
save_file("$DATADIR/yaml/sample.yml",
          read_skel('data/yaml.mt'),
         );
save_file("$DATADIR/sql/sample.yml",
          read_skel('data/sql.mt'),
         );

#
# action ツリーを生成する
#
my $ACTIONDIR = "$ROOTDIR/action";
$t = $mt->render('action/default')->as_string;
make_path $ACTIONDIR;
save_file("$ACTIONDIR/default.pl", $t);

#
# model ツリーを生成する
#
my $MODELDIR = "$ROOTDIR/model";
make_path $MODELDIR;
$t = $mt->render('model/yaml')->as_string;
save_file("$MODELDIR/sample.pl", $t);

#
# template ツリーを生成する
#
my $TEMPLATEDIR = "$ROOTDIR/template";
make_path $TEMPLATEDIR;
save_file("$TEMPLATEDIR/_base.mt",
          read_skel('template/_base.mt.mt'),
         );
save_file("$TEMPLATEDIR/_error.mt",
          read_skel('template/_error.mt.mt'),
         );
save_file("$TEMPLATEDIR/default.mt",
          read_skel('template/default.mt.mt'),
         );
save_file("$TEMPLATEDIR/mail.mt",
          read_skel('template/mail.mt.mt'),
         );

#
# css ツリーを生成する
#
my $CSSDIR = "$ROOTDIR/css";
make_path $CSSDIR;
save_file("$CSSDIR/_base.css",
          read_skel('css/_base.css.mt'),
         );
save_file("$CSSDIR/_layout.css", '');
save_file("$CSSDIR/_layout-ie6.css", '');

#
# js ツリーを生成する
#
my $JSDIR = "$ROOTDIR/js";
make_path $JSDIR;
save_file("$JSDIR/_base.js",
          read_skel('js/_base.js.mt'),
         );
save_file("$JSDIR/_base-ie6.js", '');

#
# img ツリーを生成する
#
my $IMGDIR = "$ROOTDIR/img";
make_path $IMGDIR;

#
# t ツリーを生成する
#
my $TESTDIR = "$ROOTDIR/t";
make_path $TESTDIR;
make_path "$TESTDIR/model", "$TESTDIR/action";


print <DATA>;
exit;



sub abort_setup {
  print << "...";
Content-Type: text/plain; charset=utf-8

Already setup, abort.
...
  exit;
}


sub stdin_params {
  print "protocol? [http]: ";
  chomp(my $protocol = <STDIN>);

  print "domain? [localhost]: ";
  chomp(my $server_name = <STDIN>);

  print "subdomain? (if specify, include '.' at end, ex. 'www.') []: ";
  chomp(my $subdomain = <STDIN>);
  if ($subdomain ne '' and $subdomain !~ /\.$/) {
    $subdomain .= '.';
  }

  print "path? []: ";
  chomp(my $request_path = <STDIN>);

  ($protocol, $server_name, $subdomain, $request_path);
}


sub read_skel {
  my ($f) = @_;
  local $/;
  open my $fh, '<', "$SKELDIR/$f"  or  die $!;
  my $t = <$fh>;
  close $fh;
  $t;
}

sub save_file {
  my ($f, $t) = @_;
  return undef  unless defined $f && defined $t;
  open my $fh, '>', $f;
  print $fh $t;
  close $fh;
  1;
}





__DATA__
Content-Type: text/plain; charset=utf-8


Setup finished.
