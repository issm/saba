# t/00_load.t
use strict;
use FindBin;
use lib "$FindBin::Bin/../saba/lib";
use Test::More;
plan tests => 1;


use_ok('Saba');
