package Saba::Error::Model;
use base qw/Error::Simple/;
use strict;
use warnings;
use utf8;
use Encode;
use Saba::ClassBase qw/:base :debug/;



sub message {
    my $self = shift;
    sprintf '[%s] %s', $self->{-package}, $self->{-text};
}


1;
