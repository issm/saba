package Saba::HTML::Form::Form;
use strict;
use warnings;
use utf8;

use HTML::AutoForm;
use CGI::Simple;
use Saba::ClassBase qw/:base :debug/;

my $_conf;
my $_form;
my $_req;

$HTML::AutoForm::DEFAULT_LANG = 'ja';
BEGIN {
    $HTML::AutoForm::Error::Errors{ja} = {
        %{$HTML::AutoForm::Error::Errors{en}},
        CHOICES_TOO_FEW => sub {
            my $self = shift;
            return $self->field->label . 'を入力／選択してください'
                unless $self->field->allow_multiple;
            $self->field->label . 'の選択が少なすぎます';
        },
        CHOICES_TOO_MANY => sub {
            my $self = shift;
            $self->field->label . 'の選択が多すぎます';
        },
        NO_SELECTION => sub {
            my $self = shift;
            $self->field->label . 'を選択してください',
        },
        INVALID_INPUT => sub {
            my $self = shift;
            '不正な入力値です (' . $self->field->label . ')';
        },
        IS_EMPTY => sub {
            my $self = shift;
            $self->field->label . 'を入力してください';
        },
        TOO_SHORT => sub {
            my $self = shift;
            $self->field->label . 'が短すぎます';
        },
        TOO_LONG => sub {
            my $self = shift;
            $self->field->label . 'が長すぎます';
        },
        INVALID_DATA => sub {
            my $self = shift;
            $self->field->label . 'の入力を確認してください',
        },
    };
};



sub new {
    my ($self, $class, %param) = ({}, shift, @_);
    bless $self, $class;
    $self->{"_$_"} = $param{$_}  for keys %param;
    $self->init(@_);
    $self;
}


sub init {
    my ($self, $param) = self_param @_;
    $_conf = $self->{_conf};
    $_req  = $self->{_req};

    my $name = $param->{name};
    my $fields = $_conf->{FORM}{$name};

    $_form = HTML::AutoForm->new(
        action => '',
        fields => [map %$_, @$fields],
    );
}


sub validate {
    my ($self) = @_;

    $_form->validate(
        $_req,
    );
}


sub validate_and_list {
    my ($self) = @_;

    my $list = [
        map {
            my $f = {
                type  => $_->type,
                label => $_->label,
                #class => $_->class,
                #value => $_->value,

                html  => $_->render,
            };

            my $err = $_->validate($_req);
            if ($err) {
                $f->{error} = $err;
            }

            $f;
        }
        @{$_form->fields}
    ];
}


sub render {
    my ($self) = @_;

    $_form->render(
        $_req,
        generate_random_key(2),
    );
}


1;

