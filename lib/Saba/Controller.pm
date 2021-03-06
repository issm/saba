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
use Cache::FileCache;
use Saba::ClassBase qw/:base :debug/;

my $_conf  = {};
my $_query = {};
my $_http;
my $_mm;
my $_cache;


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
    $_http = Saba::HTTP->new(req => $self->{_req}, conf => $_conf);
    $_mm   = Saba::MetaModel->new(conf => $_conf);

    if ($_conf->{CACHE}{ENABLED}) {
        my $opts = {
            namespace          => $_conf->{CACHE}{NAMESPACE} || 'saba',
            default_expires_in => $_conf->{CACHE}{EXPIRES}   || 600,
        };

        if (my $root = $_conf->{CACHE}{ROOT}) {
            $opts->{cache_root} = ($root =~ m{^/})
                ? $root
                : sprintf('%s/%s', $_conf->{PATH}{ROOT}, $root);
            # ^ '/' で始まる場合は絶対パス，でなければ相対パス

            my @dirs;
            for my $d (split '/', $opts->{cache_root}) {
                next  if $d eq '.';
                if ($d eq '..') { pop @dirs; next; }
                push @dirs, $d;
            }
            $opts->{cache_root} = join '/', @dirs;
        }

        $_cache = Cache::FileCache->new($opts);
    }
}




sub go {
    my ($self, $param) = self_param @_;

    #
    $_query = $self->{_req}->Vars;
    # クエリパラメータの値をデコードする
    for my $k (grep $_ !~ /^\./, keys %$_query) {
        $_query->{$k} = de $_query->{$k};
    }

    #
    my $mapper = Saba::URLMapper->new(conf => $_conf);
    my $action = $mapper->get_action;
    # v クエリをアペンドする
    for my $k (keys %{$action->{param}}) {
        my $v = uri_unescape $action->{param}{$k};
        $v = de($v)  unless Encode::is_utf8($v);
        $_query->{de $k} = $v;
    }

    #
    my $action_name = $action->{name};
    my $view;

    if (defined $action_name && $action_name ne '') {
        $view = $self->_action($action_name);
    }
    else {
        $view = $_http->status(404);
    }

    $self->_view($view);
}


sub _model {
    my ($self) = @_;
}


sub _action {
    my ($self, $action_name) = @_;
    my $view = {
        name        => $action_name,
        action_name => $action_name,
        no_escape   => 0,
        var         => {},
        query       => $_query,
        cache       => $_cache,
    };
    my $action = Saba::Action->new(
        name  => $action_name,
        conf  => $_conf,
        mm    => $_mm,
        http  => $_http,
        query => $_query,
        cache => $_cache,
    );
    my $view_ = $action->go;
    $view->{$_} = $view_->{$_}  for qw/name no_escape query var/;

    $view;
}


sub _view {
    my ($self, $v) = @_;

    my $view = Saba::View->new(
        name        => $v->{name},
        action_name => $v->{action_name},
        no_escape   => $v->{no_escape},
        conf        => $_conf,
        http        => $_http,
        query       => $v->{query},
        var         => $v->{var},
    );
    $view->go;
}




1;
