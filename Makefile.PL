use strict;
use warnings;
use inc::Module::Install;

name 'Saba';
all_from 'lib/Saba.pm';

requires 'YAML';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';

WriteAll;

