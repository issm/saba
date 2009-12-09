package Saba::Config;
use strict;
use warnings;
use utf8;

use FindBin;
use Encode qw/is_utf8 encode decode/;
use Saba::ClassBase qw/:base :debug/;

my $FILENAME_CONF = '.saba';

my $_conf = {};


sub new {
  my ($self, $class) = ({}, shift);
  bless $self, $class;
  $self->init(@_);
  $self;
}


sub init {
  my ($self) = @_;

  my $bindir  = $FindBin::Bin;
  my $YAML_MODULE = '';

  local $@;

  eval {use YAML::Syck;};
  # YAML::Syck
  unless ($@) {
    $YAML_MODULE = 'YAML::Syck';
  }
  # YAML
  else {
    eval {use YAML qw/LoadFile/;};
    $YAML_MODULE = 'YAML';
  }

  my $conffile = "$bindir/${FILENAME_CONF}";
  if (-f $conffile) {
    $_conf = LoadFile($conffile)  or  warn $!;
  }
  $_conf->{YAML_MODULE} = $YAML_MODULE;

  #
  $_conf->{URL_BASE} =
    sprintf('%s://%s%s%s/',
            $_conf->{LOCATION}{PROTOCOL}  || '',
            $_conf->{LOCATION}{SUBDOMAIN} || '',
            $_conf->{LOCATION}{DOMAIN}    || '',
            $_conf->{LOCATION}{PATH}      || '',
           );
  $_conf->{URL_ROOT} =
    sprintf('%s://%s%s/',
            $_conf->{LOCATION}{PROTOCOL}  || '',
            $_conf->{LOCATION}{SUBDOMAIN} || '',
            $_conf->{LOCATION}{DOMAIN}    || '',
           );

  #
  $_conf->{PATH} =
    {ROOT     => $bindir,
     CONF     => "$bindir/saba/etc",
     DATA     => "$bindir/data",
     ACTION   => "$bindir/action",
     MODEL    => "$bindir/model",
     TEMPLATE => "$bindir/template",
     TMP      => "$bindir/tmp",
    };
}





sub get {
  my ($self, @name) = @_;

  my $dumped = D([$_conf], ['_conf']);
  my $decoded
    = Encode::is_utf8($dumped) ? $dumped : decode('utf-8', $dumped);
  eval $decoded;

  if (@name) {
    # todo
  }
  else {
    return $_conf;
  }
}
