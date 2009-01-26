use Test::More 'no_plan';
use strict;
use warnings;
use App::Sequence;

my $t_dir = 't/09-conf_files';
{
    my $as = App::Sequence->new;
    $as->conf_files( "$t_dir/conf.ini" );
    is_deeply( $as->confs, [{ s => { a => 1 } }], 'conf_files scalar' );

    $as->conf_files( [ "$t_dir/conf.ini", "$t_dir/conf.ini" ] );
    is_deeply( $as->confs, [{ s => { a => 1 } }, { s => { a => 1 } }], 'conf_files array' );

}
