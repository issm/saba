# t/00_load.t
use strict;
use FindBin;
use lib "$FindBin::Bin/../saba/lib", "$FindBin::Bin/../saba/extlib";
use Test::More;
plan tests => 1;


use_ok('Saba');
