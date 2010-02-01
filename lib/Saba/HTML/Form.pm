package Saba::HTML::Form;
use strict;
use warnings;
use utf8;

use Saba::HTML::Form::Form;
use Saba::ClassBase qw/:base :debug/;

my $_conf;
my $_form = {};
my $_req;

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
    $_req  = $self->{_req};
}


# get($name);
sub get {
    my ($self, $name) = @_;

    $_form->{$name} = Saba::HTML::Form::Form->new(
        name => $name,
        conf => $_conf,
        req  => $_req,
    );
}



1;
