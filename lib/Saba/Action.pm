package Saba::Action;
use strict;
use warnings;
use utf8;

use FindBin;
use Encode;
use Saba::ClassBase qw/:base :debug/;
use JSON;
use Error qw/:try/;
use Saba::HTML::Form;
use Saba::Error::Action;
use Saba::Error::Model;


my $_conf  = {};
my $_mm    = {};
my $_query = {};
my $_var   = {};
my $_form;
my $_http;
my $_cache;

my $_view_no_escape = 0;

sub new {
    my ($self, $class, %param) = ({}, shift, @_);
    bless $self, $class;
    $self->{"_$_"} = $param{$_}  for keys %param;
    $self->init(@_);
    $self;
}


sub init {
    my ($self) = @_;
    $_conf  = $self->{_conf};
    $_mm    = $self->{_mm};
    $_query = $self->{_query};
    $_http  = $self->{_http};
    $_form  = Saba::HTML::Form->new(
        req => $_http->{_req},
        conf => $_conf,
    );
    $_cache = $self->{_cache};
    $self;
}


sub go {
    my ($self) = @_;
    eval [
        $_mm,
        $_query,
        $_form,
        $_http,
        $_cache,
    ];

    local $@;
    my $common_pl = '';
    my $action_pl = '1;';

    my $actionfile = sprintf(
        '%s/%s.pl',
        $_conf->{PATH}{ACTION},
        name2path($self->{_name}),
    );

    my @commonfiles = ();
    {
        (my $dir = $actionfile) =~ s{/[^/]*$}{};
        do {
            push @commonfiles, "$dir/_common.pl";
            last if $dir eq $_conf->{PATH}{ACTION};
        } while ($dir =~ s{/[^/]*$}{});
    }
    for my $pl (reverse @commonfiles) {
        next  unless -f $pl;
        $common_pl .= read_file $pl;
    }


    if (-f $actionfile) {
        $action_pl = $common_pl;
        $action_pl .= read_file $actionfile;
    }
    eval $action_pl;
    warn $@  if $@;

    my $ret_action = '';

    my $METH_IF = {
        GET  => 1,
        POST => 1,
    };
    for my $meth (qw/BEFORE GET POST AFTER/) {
        my $cond = $METH_IF->{$meth}
            ?  sprintf(q|$ENV{REQUEST_METHOD} eq '%s'|, $meth)
            :  sprintf(q|1|)
        ;
        my $meth_pl  = sprintf '%s($self)', $meth;
        my $meth_alt = sprintf '$self->_%s_ALT()', $meth;

        my $eval = sprintf(
            << '...',
if (%s) {
  local $@;
  eval {
    $ret_action = %s;
  };
  if ($@) {
    warn "[action error] $@"  if $@ !~ /undefined subroutine/i;
    $ret_action = %s;
  }
}
...
            $cond,
            $meth_pl,
            $meth_alt,
        );
        eval $eval;
        last  if defined $ret_action  &&  $ret_action ne '';
    }

    if (!defined $ret_action
            ||  $ret_action eq ''
            ||  $ret_action eq $Saba::FINISH_ACTION
        ) {
        $ret_action = $self->{_name};
    }

    return +{
        name      => $ret_action,
        no_escape => $_view_no_escape,
        query     => $_query,
        var       => $_var,
    };

#  # BEFORE
#  {
#    local $@;
#    eval {
#      $ret_action = BEFORE($self);
#    };
#    if ($@) {
#      $ret_action = $self->_BERORE_ALT;
#    }
#  }
#
#  # GET
#  if ($ENV{REQUEST_METHOD} eq 'GET') {
#    local $@;
#    eval {
#      $ret_action = GET($self);
#    };
#    if ($@) {
#      $ret_action = $self->_GET_ALT;
#    }
#  }
#
#  # POST
#  if ($ENV{REQUEST_METHOD} eq 'POST') {
#    local $@;
#    eval {
#      $ret_action = POST($self);
#    };
#    if ($@) {
#      $ret_action = $self->_POST_ALT;
#    }
#  }
#
#  # AFTER
#  {
#    local $@;
#    eval {
#      $ret_action = AFTER($self);
#    };
#    if ($@) {
#      $ret_action = $self->_AFTER_ALT;
#    }
#  }
}



sub _BEFORE_ALT {
    '';
}


sub _GET_ALT {
    '';
}


sub _POST_ALT {
    '';
}


sub _AFTER_ALT {
    '';
}


sub finish {
    $Saba::FINISH_ACTION;
}


sub set_var {
    my ($self, @pairs) = @_;
    while (@pairs) {
        my ($name, $value) = (shift @pairs, shift @pairs);
        last  unless $name && $value;
        $_var->{$name} = $value;
    }
}

sub get_var {
    my ($self, @names) = @_;
    # length == 1
    if ($#names == 0) {
        return $_var->{$names[0]};
    }
    # length > 1
    else {
        return
            map $_var->{$_}, @names;
    }
}


sub view_no_escape {
    my ($self, $value) = @_;
    $value = 1  unless defined $value;
    $_view_no_escape = $value ? 1 : 0;
}


1;
