use Test::More 'no_plan';
use strict;
use warnings;
use App::Sequence;

my $t_dir = 't/10-sequence_files';
{
    my $as = App::Sequence->new;
    eval{$as->sequence_files( "$t_dir/test1.as" )};
    ok($@);
}