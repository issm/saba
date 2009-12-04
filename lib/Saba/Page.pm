package Saba::Page;
use strict;
use warnings;
use utf8;

use Saba::ClassBase qw/:base :debug/;

my ($COMMON_CSS, $COMMON_JS);
my ($CSS_IMPORT, $JS_IMPORT) = ([], []);
my ($CSS_IMPORT_IE, $JS_IMPORT_IE) = ({}, {});

my @IE = map 'ie'.$_, reverse 6..9, '';

my $DIR_CSS = '';
my $DIR_JS  = '';
my $DIR_IMG = '';

my $_conf   = {};


sub new {
  my ($self, $class, %param) = ({}, shift, @_);
  bless $self, $class;
  $self->{"_$_"} = $param{$_}  for keys %param;
  $self->init(@_);
  $self;
}


sub init {
  my ($self) = @_;
  $_conf = $self->{_conf};

  $COMMON_CSS = $_conf->{PAGE}{COMMON_CSS};
  $COMMON_JS  = $_conf->{PAGE}{COMMON_JS};

  for my $ie (@IE) {
    $CSS_IMPORT_IE->{$ie} = [];
    $JS_IMPORT_IE->{$ie}  = [];
  }

  $DIR_CSS = sprintf '%s/css', $_conf->{PATH}{ROOT};
  $DIR_JS  = sprintf '%s/js',  $_conf->{PATH}{ROOT};
  $DIR_IMG = sprintf '%s/img', $_conf->{PATH}{ROOT};

  $self;
}


sub import_css {
  my ($self) = @_;

  # common
  for my $n_c (@$COMMON_CSS) {
    my $path = sprintf '%s/%s.css', $DIR_CSS, $n_c;
    my $url  = sprintf '%scss/%s.css', $_conf->{URL_BASE}, $n_c;
    push @$CSS_IMPORT, $url  if -f $path;

    for my $ie (@IE) {
      my $path_ie = sprintf '%s/%s-%s.css', $DIR_CSS, $n_c, $ie;
      my $url_ie  = sprintf '%scss/%s-%s.css', $_conf->{URL_BASE}, $n_c, $ie;
      push @{$CSS_IMPORT_IE->{$ie}}, $url_ie  if -f $path_ie;
    }
  }

  # page
  my $name2path = name2path $self->{_name};

  my @common_page = ();
  my @dir_ = split '/', $name2path;
  pop @dir_;  # '*.css' を取り除く
  do {
    my $css_ = sprintf('%s/_common',
                       join('/', @dir_),
                      );
    $css_ =~ s{^/}{};
    push @common_page, $css_;
  } while (pop @dir_);

  for my $n_p (reverse(@common_page), $name2path) {
    my $path = sprintf '%s/%s.css', $DIR_CSS, $n_p;
    my $url  = sprintf '%scss/%s.css', $_conf->{URL_BASE}, $n_p;
    push @$CSS_IMPORT, $url  if -f $path;

    for my $ie (@IE) {
      my $path_ie = sprintf '%s/%s-%s.css', $DIR_CSS, $n_p, $ie;
      my $url_ie  = sprintf '%scss/%s-%s.css', $_conf->{URL_BASE}, $n_p, $ie;
      push @{$CSS_IMPORT_IE->{$ie}}, $url_ie  if -f $path_ie;
    }
  }

  [$CSS_IMPORT, $CSS_IMPORT_IE];
}


sub import_js {
  my ($self) = @_;

  # common
  for my $n_c (@$COMMON_JS) {
    my $path = sprintf '%s/%s.js', $DIR_JS, $n_c;
    my $url  = sprintf '%sjs/%s.js', $_conf->{URL_BASE}, $n_c;
    push @$JS_IMPORT, $url  if -f $path;

    for my $ie (@IE) {
      my $path_ie = sprintf '%s/%s-%s.js', $DIR_JS, $n_c, $ie;
      my $url_ie  = sprintf '%sjs/%s-%s.js', $_conf->{URL_BASE}, $n_c, $ie;
      push @{$JS_IMPORT_IE->{$ie}}, $url_ie  if -f $path_ie;
    }
  }

  # page
  my $name2path = name2path $self->{_name};

  my @common_page = ();
  my @dir_ = split '/', $name2path;
  pop @dir_;  # '*.js' を取り除く
  do {
    my $js_ = sprintf('%s/_common',
                       join('/', @dir_),
                      );
    $js_ =~ s{^/}{};
    push @common_page, $js_;
  } while (pop @dir_);

  for my $n_p (reverse(@common_page), $name2path) {
    my $path = sprintf '%s/%s.js', $DIR_JS, $n_p;
    my $url  = sprintf '%sjs/%s.js', $_conf->{URL_BASE}, $n_p;
    push @$JS_IMPORT, $url  if -f $path;

    for my $ie (@IE) {
      my $path_ie = sprintf '%s/%s-%s.js', $DIR_JS, $n_p, $ie;
      my $url_ie  = sprintf '%sjs/%s-%s.js', $_conf->{URL_BASE}, $n_p, $ie;
      push @{$JS_IMPORT_IE->{$ie}}, $url_ie  if -f $path_ie;
    }
  }

  [$JS_IMPORT, $JS_IMPORT_IE];
}


1;

