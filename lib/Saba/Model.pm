package Saba::Model;
use strict;
use warnings;
use utf8;

use Encode;
use Saba::ClassBase qw/:base :debug/;
use Error qw/:try/;
use Saba::Error::Model;

my $_conf = {};
my $_dsi  = {};


sub new {
  my ($self, $class, %param) = ({}, shift, @_);
  bless $self, $class;
  $self->{"_$_"} = $param{$_}  for keys %param;
  $self->init;
#  $self;
}


sub init {
  my ($self) = self_param @_;
  $_conf = $self->{_conf};
  $_dsi  = $self->{_dsi};
  $self->create;
}


sub create {
  my ($self) = @_;
  eval $_conf;
  eval $_dsi;

  my $modelfile = sprintf('%s/%s.pl',
                          $_conf->{PATH}{MODEL},
                          name2path($self->{_name}),
                         );
  my $model_pl = '1;';
  if (-f $modelfile) {
    $model_pl = read_file $modelfile;
  }

  my $namespace = sprintf('Saba::Model::%s',
                          ucfirst $self->{_name},
                         );

  $model_pl = sprintf(<< '...',
{
package %s;
use strict;
use warnings;
use utf8;

use Encode;
use Saba::ClassBase qw/:base :debug/;

my $DSI;
my ($_conf, $_dsi);


sub new {
  my ($self, $class, %%param) = ({}, shift, @_);
  bless $self, $class;
  $self->{"_$_"} = $param{$_}  for keys %%param;
  $self->init;
  $self;
}

sub init {
  my ($self) = self_param @_;
  $DSI = eval { $self->dsi_type; }  ||  'YAML';
  $_conf = $self->{_conf};
  $_dsi  = $self->{_dsi};
  $_dsi  = $_dsi->{$DSI} || undef;
}


# プラグインコード
%s

1;
}

%s->new(conf => $_conf, dsi => $_dsi);
...
                      $namespace,
                      $model_pl,
                      $namespace,
                     );
  local $@;
  my $model = eval $model_pl;
  warn $@  if $@;

  $model;
}


1;

