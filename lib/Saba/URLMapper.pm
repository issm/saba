package Saba::URLMapper;
use strict;
use warnings;
use utf8;

use FindBin;
use URI::Escape;
use Saba::ClassBase qw/:base :debug/;

my $FILENAME_MAP = '.urlmap';
my $bin = $FindBin::Bin;

my $_conf     = {};
my $_map_rule = [];
my $_map_var  = {};

sub new {
  my ($self, $class, %param) = ({}, shift, @_);
  bless $self, $class;
  $self->{"_$_"} = $param{$_}  for keys %param;
  $self->init;
  $self;
}


sub init {
  my ($self) = self_param @_;
  $_conf = $self->{_conf};

  local $@;
  eval sprintf 'use %s qw/LoadFile/;', $_conf->{YAML_MODULE};
  my $urlmapfile = "$bin/${FILENAME_MAP}";
  my $map = LoadFile($urlmapfile);
  $_map_rule = $map->{ACTION} || {};
  $_map_var  = $map->{VAR}  || {};
}


sub _get_request_path {
  my ($self) = self_param @_;
  my $req_path = de uri_unescape $ENV{REQUEST_URI};
  $req_path =~ s/$_conf->{URL_ROOT}//;
  $req_path =~ s/$_conf->{LOCATION}{PATH}//;
  $req_path =~ s/\?.*$//;
  $req_path =~ s|^/||;
  $req_path;
}


sub get_action {
  my ($self, $param) = @_;
  my $req_path = $self->_get_request_path;
  my $action = { name  => '',
                 param => {},
               };

  for my $_a (@$_map_rule) {
    my $_last = 0;
    my $name = $_a->{name};

    for my $_r (@{$_a->{rule}}) {
      my $path_re = de $_r->{path_re};
      for my $_k_var (keys %$_map_var) {
          $path_re =~ s{
                           (?: \$$_k_var | \$\{$_k_var\} )
                       }{
                           de $_map_var->{$_k_var};
                       }gex;
      }

      if (my @m = $req_path =~ /$path_re/x) {
        my $param = {};
        #
        if (defined $_r->{param}) {
          for my $i (0 .. scalar @{$_r->{param}}-1) {
            $param->{$_r->{param}[$i]} = $m[$i] || '';
          }
        }
        #
        if (defined $_r->{const}) {
          for my $k (keys %{$_r->{const}}) {
            $param->{$k} = $_r->{const}{$k};
          }
        }
        $action->{name}  = $name;
        $action->{param} = $param;
        $_last = 1;
        last;
      }
    }
    last  if $_last;
  }

  my $a = d $action;

  $action;
}




1;
