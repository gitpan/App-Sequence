use Test::More 'no_plan';
use strict;
use warnings;
use App::Sequence;

my $t_dir = 't/09-conf_files';
{
    my $as = App::Sequence->new;
    eval{$as->conf_files( "$t_dir/conf.ini" )};
    ok($@);
}