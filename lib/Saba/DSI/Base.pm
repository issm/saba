package Saba::DSI::Base;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Fast/;


__PACKAGE__->mk_accessors(qw/ config /);


sub init {
  my $self = shift;
  $self;
}



1;
__END__
