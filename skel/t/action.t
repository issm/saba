# skel/t/action.t
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../../saba/lib", "$FindBin::Bin/../../saba/extlib";

use Test::More qw/no_plan/;
#plan tests => 2;

use Error qw/:try/;
use Saba::ClassBase qw/:base :debug/;
use Saba::Config;
use Saba::MetaModel;
use Saba::Action;


ok 1;