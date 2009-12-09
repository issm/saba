package Saba::Controller;
use strict;
use warnings;
use utf8;

use Saba::Config;
use Saba::URLMapper;
use Saba::Action;
use Saba::View;
use Saba::HTTP;
use Saba::MetaModel;
use URI::Escape;
use Encode;
use Saba::ClassBase qw/:base :debug/;

my $_conf  = {};
my $_query = {};
my $_mm;
my $_http;


sub new {
  my ($self, $class, %param) = ({}, shift, @_);
  bless $self, $class;
  $self->{"_$_"} = $param{$_}  for keys %param;
  $self->init;
  $self;
}


sub init {
  my ($self) = self_param @_;
  $_conf = Saba::Config->new->get;
  $_http = Saba::HTTP->new(conf => $_conf);
  $_mm   = Saba::MetaModel->new(conf => $_conf);
}




sub go {
  my ($self, $param) = self_param @_;

  #
  $_query = $self->{_req}->Vars;

  #
  my $mapper = Saba::URLMapper->new(conf => $_conf);
  my $action = $mapper->get_action;
  $_query->{$_} = decode('utf-8',
                         uri_unescape($action->{param}{$_})
                        )
    for keys %{$action->{param}};  # クエリをアペンドする

  #
  my $action_name = $action->{name};
  my $view =
    $self->_action($action_name);

  #
  $self->_view($view);

}


sub _model {
  my ($self) = @_;
}


sub _action {
  my ($self, $action_name) = @_;
  my $view = { name        => $action_name,
               action_name => $action_name,
               var         => {},
               query       => $_query,
             };
  my $action = Saba::Action->new(name  => $action_name,
                                 conf  => $_conf,
                                 mm    => $_mm,
                                 http  => $_http,
                                 query => $_query,
                                );
  my $view_ = $action->go;
  $view->{$_} = $view_->{$_}  for qw/name query var/;

  $view;
}


sub _view {
  my ($self, $v) = @_;

  my $view = Saba::View->new(name        => $v->{name},
                             action_name => $v->{action_name},
                             conf        => $_conf,
                             http        => $_http,
                             query       => $v->{query},
                             var         => $v->{var},
                            );
  $view->go;
}




1;