use Test::More 'no_plan';
use strict;
use warnings;

use App::Sequence;

my $t_dir = 't/17-_parse_meta_file';

{
    my @argv = App::Sequence::_parse_meta_file( "$t_dir/test1.meta" );
    is_deeply( [ @argv ], [ qw( conf.csv module1.pm module2.pm test1.as ) ], 'parse meta file and get argv' );
}

{
    my @argv = App::Sequence::_parse_meta_file( "$t_dir/test1_win.meta" );
    is_deeply( [ @argv ], [ qw( conf.csv module1.pm module2.pm test1.as ) ], 'parse meta file and get argv' );
}
