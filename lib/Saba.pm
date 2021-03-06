package Saba;
use strict;
use warnings;
use utf8;

our $VERSION = '0.001';

use CGI::Simple;
use Saba::Controller;
use Saba::ClassBase qw/:base :debug/;


our $FINISH_ACTION = '__FINISH_ACTION__';


sub run {
  my $self = shift;
  my $req = CGI::Simple->new;
  my $c =
    Saba::Controller->new(req => $req);
  $c->go;
}

1;
