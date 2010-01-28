# skel/t/model.t
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../../saba/lib", "$FindBin::Bin/../../saba/extlib";

use Test::More qw/no_plan/;
#plan tests => 1;

use Error qw/:try/;
use Saba::ClassBase qw/:base :debug/;
use Saba::Config;
use Saba::MetaModel;

my $conf = Saba::Config->new->get;
my $mm   = Saba::MetaModel->new(conf => $conf);
my $m    = $mm->get_model('entry');


ok 1;
