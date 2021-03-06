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

my $MODE    = defined $ENV{SERVER_NAME} ? 'CGI' : 'CLI';  # CLI or CGI
my $BINDIR  = $FindBin::Bin;
#my $ROOTDIR = sprintf '%s/..', $BINDIR;
(my $ROOTDIR = $BINDIR) =~ s{/[^/]+$}{};


my $CONTENT_TYPE = "Content-Type: text/plain; charset=utf-8\n";
my ($MESSAGE, @MESSAGES) = ('', ());

$CONTENT_TYPE = ''  if $MODE eq 'CLI';


#
# .saba が存在する場合，セットアップを中止する
#
if (-f "$ROOTDIR/.saba") {
    abort_setup();
}


my (
    $protocol,
    $server_name,
    $subdomain,
    $request_path,
    $cache_enabled,
);
#
#
#
if ($MODE eq 'CGI') {
    ($protocol = lc $ENV{SERVER_PROTOCOL}) =~ s{/.*$}{};
    $server_name = $ENV{SERVER_NAME};
    $subdomain = '';
    ($request_path = $ENV{SCRIPT_NAME}) =~ s{/saba/setup\.cgi}{};
}
else {
    (
        $protocol,
        $server_name,
        $subdomain,
        $request_path,
        $cache_enabled,
    ) = stdin_params();
}


$protocol      ||= 'http';
$server_name   ||= 'localhost';
$subdomain     ||= '';
$request_path  ||= '';
$cache_enabled = 1  unless defined $cache_enabled;

my $SKELDIR = "$BINDIR/skel/setup";
my $mt = Text::MicroTemplate::Extended->new(
    include_path  => [$SKELDIR],
    template_args => {
        ROOTDIR       => $ROOTDIR,
        env           => \%ENV,

        protocol      => $protocol,
        server_name   => $server_name,
        subdomain     => $subdomain,
        request_path  => $request_path,
        cache_enabled => $cache_enabled,
    },
);



my $t;
#
# .saba を生成する
#
$t = $mt->render('conf/saba')->as_string;
save_file("$ROOTDIR/.saba", $t);
#
msg("saved: $ROOTDIR/.saba");

#
# .urlmap を生成する
#
$t = $mt->render('conf/urlmap')->as_string;
save_file("$ROOTDIR/.urlmap", $t);
#
msg("saved: $ROOTDIR/.urlmap");

#
# .htaccess を生成する
#
$t = $mt->render('conf/htaccess')->as_string;
save_file("$ROOTDIR/.htaccess", $t);
#
msg("saved: $ROOTDIR/.htaccess");

#
# index.cgi を生成する
#
$t = $mt->render('cgi/index.cgi')->as_string;
save_file("$ROOTDIR/index.cgi", $t);
chmod 0755, "$ROOTDIR/index.cgi";
#
msg("saved: $ROOTDIR/index.cgi");
msg("chmod: $ROOTDIR/index.cgi as '755'");

#
# data ツリーを生成する
#
my $DATADIR = "$ROOTDIR/data";
make_path (map "$DATADIR/$_", qw/yaml sql/);
save_file("$DATADIR/yaml/sample.yml", read_skel('data/yaml.mt'));
save_file("$DATADIR/sql/sample.yml", read_skel('data/sql.mt'));
#
msg("mkdir: $DATADIR");
msg("saved: $DATADIR/yaml/sample.yml");
msg("saved: $DATADIR/sql/sample.yml");

#
# action ツリーを生成する
#
my $ACTIONDIR = "$ROOTDIR/action";
$t = $mt->render('action/default')->as_string;
make_path $ACTIONDIR;
save_file("$ACTIONDIR/default.pl", $t);
#
msg("mkdir: $ACTIONDIR");
msg("saved: $ACTIONDIR/default.pl");

#
# model ツリーを生成する
#
my $MODELDIR = "$ROOTDIR/model";
make_path $MODELDIR;
$t = $mt->render('model/yaml')->as_string;
save_file("$MODELDIR/sample.pl", $t);
#
msg("mkdir: $MODELDIR");
msg("saved: $MODELDIR/sample.pl");

#
# template ツリーを生成する
#
my $TEMPLATEDIR = "$ROOTDIR/template";
make_path $TEMPLATEDIR;
save_file("$TEMPLATEDIR/_base.mt", read_skel('template/_base.mt.mt'));
save_file("$TEMPLATEDIR/_error.mt", read_skel('template/_error.mt.mt'));
save_file("$TEMPLATEDIR/default.mt", read_skel('template/default.mt.mt'));
save_file("$TEMPLATEDIR/mail.mt", read_skel('template/mail.mt.mt'));
make_path "$TEMPLATEDIR/_status";
save_file("$TEMPLATEDIR/_status/403.mt", read_skel('template/_status/403.mt.mt'));
save_file("$TEMPLATEDIR/_status/404.mt", read_skel('template/_status/404.mt.mt'));
#
msg("mkdir: $TEMPLATEDIR");
msg("saved: $TEMPLATEDIR/_base.mt");
msg("saved: $TEMPLATEDIR/_error.mt");
msg("saved: $TEMPLATEDIR/default.mt");
msg("saved: $TEMPLATEDIR/mail.mt");
msg("mkdir: $TEMPLATEDIR/_status");
msg("saved: $TEMPLATEDIR/_status/403.mt");
msg("saved: $TEMPLATEDIR/_status/404.mt");

#
# css ツリーを生成する
#
my $CSSDIR = "$ROOTDIR/css";
make_path $CSSDIR;
save_file("$CSSDIR/_base.css", read_skel('css/_base.css.mt'));
save_file("$CSSDIR/_layout.css", '');
save_file("$CSSDIR/_layout-ie6.css", '');
#
msg("mkdir: $CSSDIR");
msg("saved: $CSSDIR/_base.css");
msg("saved: $CSSDIR/_layout.css");
msg("saved: $CSSDIR/_layout-ie6.css");

#
# js ツリーを生成する
#
my $JSDIR     = "$ROOTDIR/js";
my $JS_JQUERY = "jquery-1.4.1.min.js";
make_path $JSDIR;
save_file("$JSDIR/_base.js", read_skel('js/_base.js.mt'));
save_file("$JSDIR/_base-ie6.js", '');
save_file("$JSDIR/$JS_JQUERY", read_skel("js/$JS_JQUERY"));
#
msg("mkdir: $JSDIR");
msg("saved: $JSDIR/_base.js");
msg("saved: $JSDIR/_base-ie6.js");

#
# img ツリーを生成する
#
my $IMGDIR = "$ROOTDIR/img";
make_path $IMGDIR;
#
msg("mkdir: $IMGDIR");

#
# t ツリーを生成する
#
my $TESTDIR = "$ROOTDIR/t";
make_path $TESTDIR;
save_file("$TESTDIR/00_load.t", read_skel("t/load.t.mt"));
make_path "$TESTDIR/01_model", "$TESTDIR/02_action";
$t = $mt->render('t/prove.sh')->as_string;
save_file("$ROOTDIR/.prove.sh", $t);
chmod 0755, "$ROOTDIR/.prove.sh";
#
msg("mkdir: $TESTDIR");
msg("saved: $TESTDIR/00_load.t");
msg("mkdir: $TESTDIR/01_model");
msg("mkdir: $TESTDIR/02_action");
msg("saved: $ROOTDIR/.prove.sh");
msg("chmod: $ROOTDIR/.prove.sh as '755'");



$MESSAGE = join "\n", @MESSAGES;
print << "...";
$CONTENT_TYPE
$MESSAGE

Setup finished.
...
exit;



sub abort_setup {
    print << "...";
$CONTENT_TYPE
Already setup, abort.
...
    exit;
}


sub stdin_params {
    print "Install path: $ROOTDIR\n\n";

    print "* protocol? [http]: ";
    chomp(my $protocol = <STDIN>);

    print "* domain? [localhost]: ";
    chomp(my $server_name = <STDIN>);

    print "* subdomain? (ex. 'www.') []: ";
    chomp(my $subdomain = <STDIN>);
    if ($subdomain ne '' and $subdomain !~ /\.$/) {
        $subdomain .= '.';
    }

    print "* path? []: ";
    chomp(my $request_path = <STDIN>);

    print "* enable file-cache? (0 or 1) [0]: ";
    chomp(my $cache_enabled = <STDIN>);
    if ($cache_enabled !~ /^[01]$/) {
        $cache_enabled = 1;
    }

    (
        $protocol,
        $server_name,
        $subdomain,
        $request_path,
        $cache_enabled,
    );
}

sub msg {
    push @MESSAGES, sprintf(shift, @_);
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





__END__
