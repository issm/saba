package Saba::Config;
use strict;
use warnings;
use utf8;

use FindBin;
use Encode qw/is_utf8 encode decode/;
use Data::Recursive::Encode;
use Error qw/:try/;
use File::Basename;
use Digest::SHA::PurePerl qw/sha1_hex/;
use Cache::FileCache;
use Saba::ClassBase qw/:base :debug/;

my $FILENAME_CONF    = '.saba';
my $CACHE_NAME       = 'saba_conf';
my $CACHE_EXPIRES_IN = 60;
my $CACHED = 0;

my $_conf = {};
my $_cache;

sub new {
  my ($self, $class) = ({}, shift);
  bless $self, $class;
  $self->init(@_);
  $self;
}


sub init {
  my ($self) = @_;

  my $bindir  = $ENV{SABA_EXEC_ROOT} || $FindBin::Bin;
  my $YAML_MODULE = '';

  try {
      eval {use YAML::Syck;};
      $YAML_MODULE = 'YAML::Syck';
  }
  catch Error with {
      eval {use YAML;};
      $YAML_MODULE = 'YAML';
  }

  $_cache = Cache::FileCache->new({
      namespace          => sha1_hex(dirname __FILE__),
      default_expires_in => $CACHE_EXPIRES_IN,
  });


  if ($self->_check_cache) {
      #$self->_cache;
      $_conf->{YAML_MODULE} = $YAML_MODULE;
      return;
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

  # PATH
  $_conf->{PATH} =
    {ROOT     => $bindir,
     CONF     => "$bindir/saba/etc",
     DATA     => "$bindir/data",
     ACTION   => "$bindir/action",
     MODEL    => "$bindir/model",
     TEMPLATE => "$bindir/template",
     TMP      => "$bindir/tmp",
    };

  # COOKIE
  unless (defined $_conf->{COOKIE}{DOMAON}) {
      $_conf->{COOKIE}{DOMAIN} = sprintf(
          '%s%s',
          $_conf->{LOCATION}{SUBDOMAIN},
          $_conf->{LOCATION}{DOMAIN},
      );
  }
  unless (defined $_conf->{COOKIE}{PATH}) {
      $_conf->{COOKIE}{PATH} =
          sprintf '%s/', $_conf->{LOCATION}{PATH};
      $_conf->{COOKIE}{PATH} =~ s{^/(.+/)$}{$1};
  }

  try {
      $_conf = Data::Recursive::Encode->decode('utf-8', $_conf);
  }
  finally {
      $self->_cache;
  };
}

# returns $1_or_0
sub _check_cache {
    my ($self) = @_;
    $_conf = $_cache->get($CACHE_NAME);
    $CACHED = defined $_conf ? 1 : 0;
}

#
sub _cache {
    my ($self) = @_;
    $_cache->set($CACHE_NAME, $_conf);
}


#
sub get {
    my ($self, @name) = @_;
    if (@name) {
        # todo
    }
    else {
        return $_conf;
    }
}


1;
