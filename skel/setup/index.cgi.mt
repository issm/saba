#!/usr/bin/perl
use strict;
use warnings;
use utf8;

BEGIN {
  unshift @INC, qw(saba/lib saba/extlib);
}
use Saba;

Saba->run;

__END__
