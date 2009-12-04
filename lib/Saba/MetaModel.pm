package Saba::MetaModel;
use strict;
use warnings;
use utf8;

use Saba::Model;
use Saba::ClassBase qw/:base :debug/;

my $_conf;
my $_dsi   = {};
my $_model = {};


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
  $self->init_dsi;
}


sub init_dsi {
  my ($self) = @_;
  my @dsi = grep {$_conf->{DSI}{$_}} keys %{$_conf->{DSI} || {}};
  for my $dsi (@dsi) {
    my $eval = sprintf(<< '...',
use Saba::DSI::%s;
Saba::DSI::%s->new(conf => $_conf);
...
                       $dsi,
                       $dsi,
                      );
    local $@;
    $_dsi->{$dsi} = eval $eval;
    warn $@  if $@;
  }
}


# get_model($name);
sub get_model {
  my ($self, $name) = @_;
  return undef  unless defined $name;

  if (exists $_model->{$name}) {
    return $_model->{$name};
  }
  else {
    return $self->create_model($name);
  }
}


# create_model($name);
sub create_model {
  my ($self, $name) = @_;
  return undef  unless defined $name;

  $_model->{$name} =
    Saba::Model->new(name => $name,
                     dsi  => $_dsi,
                     conf => $_conf,
                    );
  $_model->{$name};
}




__END__
use base qw/Class::Accessor::Fast/;
use Saba::ClassBase qw/:base :debug/;

our $DSI_DBI  = 'Saba::DSI::DBI';
our $DSI_YAML = 'Saba::DSI::YAML';

my $_dsi = [];


__PACKAGE__->mk_accessors(qw/ config __inc /);


sub init {
  my $self = shift;

  # モデルインクルードを初期化する
  $self->__inc({});

  #
  # DSIを初期化する
  #
  #my @dsi_use = grep { $self->config->{DSI}{$_}; } keys %{$self->config->{DSI}};
  my $@dsi_use = qw/DBI YAML/;
  for my $dsi (@dsi_use) {
    local $@;
    my $dsi_class = ($dsi =~ m{::})
      ?  $dsi  :  sprintf('Saba::DSI::%s', $dsi);

    eval qq{use ${dsi_class};};
    if ($@) {
      warn $@;
      warn sprintf '%s: %s is not supported.', __PACKAGE__, $dsi_class;
      next;
    }
    push(
      @$_dsi,
      eval qq{
        ${dsi_class}->new(
          conf => \$self->config,
        );
      }  ||  undef,
    );
  } # /for my $dsi ...
  @$_dsi = grep { defined $_; } @$_dsi;
  $self;
}


#
#  inc( type => 'User', name => 'user' )                    # Sabae::Model::User
#  inc( type => 'MyProject::Model::User', name => 'user' )  # MyProject::Model::User
#
sub inc {
  local $@;
  my $self = shift;
  @_  ?  $self->inc__set( @_ )  :  $self->inc__get;
}
sub inc__get {
  #shift->__inc;
  1;
}
sub inc__set {
  local $@;
  my ( $self, $param ) = self_param( @_ );
  my $type = $param->{type};
  my $name = $param->{name};
  my $inc  = $self->__inc;

  return 0  unless $type  &&  $name;

  if (exists $inc->{$name}) {
    warn sprintf('%s: the model named as "%s" already exists.',
                 __PACKAGE__,
                 $name,
                );
    return $inc->{$name};
  }

  # $type: ex. User -> <PROJECT_NAME>::Model::User or Sabae::Model::User
  my @target_eval = $type =~ /::/
    ?  ($type)
    :  map {sprintf '%s::Model::%s', $_, $type;} ($self->config->{PROJECT_NAME},
                                                  'Sabae',
                                                 )
  ;
  my $use_ok = 0;
  for my $type_ ( @target_eval ) {
    eval qq{ use $type_; };
    if( $@ ) {
      warn $@;
      warn sprintf( '%s: %s is not supported.', __PACKAGE__, $type_ )  if $Sabae::DEBUG;
    }
    else {
      $use_ok = 1;
      $type = $type_;
      last;
    }
  }
  return 0  unless $use_ok;

  my $dsi_required = eval qq{\$${type}::DSI_REQUIRED}  ||  '(undefined)';
  for my $dsi ( @$_dsi ) {
    # $_dsi に $dsi_required が示すクラスが含まれるときのみ
    if( $dsi_required eq ref $dsi ) {
      local $@;
      eval qq{
        \$inc->{$name} = ${type}->new({
          name   => \$name,
          config => \$self->config,
          dsi     => \$dsi,
        })->init;
      };
      warn $@  if $@  &&  $Sabae::DEBUG;
      #$self->mk_accessors( $name );
      #$self->$name( $inc->{$name} );
      $self->__inc( $inc );
      #return 1;
      return $inc->{$name};
    }
  }
  warn sprintf '%s requires %s, but not supported.', $type, $dsi_required  if $Sabae::DEBUG;
  0;
}


#
#  inc したモデルを取得する
#
#  get( 'user' )
#  get( name => 'user' )
#
sub get {
  my $self = shift;
  my $name;
  
  if( scalar @_ % 2 ) { $name = shift; }         # 引数が奇数個: 名前なし引数を想定
  else                { $name = {@_}->{name}; }  # 引数が偶数個: 名前付き引数を想定

  $self->__inc->{$name}  ||  undef;
}



1;
__END__
