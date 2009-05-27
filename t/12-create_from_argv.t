use Test::More 'no_plan';
use strict;
use warnings;
use App::Sequence;

my $t_dir = 't/12-create_from_argv';
{
    my @args = ( "$t_dir/conf.ini", "$t_dir/module1.pm", "$t_dir/test1.as" );
    my $as = App::Sequence->create_from_argv(@args);
    is( ref $as, 'App::Sequence', 'object create' );
    is_deeply( $as->confs, [{ s => { a => 1 } }], 'confs' );
    is_deeply( $as->sequences, [[{ package => 'main', name => 'a', args => [], ret => undef, }]], 'sequences' );
    
    eval{ 
        package main;
        a();
    };
    if( $@ ){ fail 'module import'; }
    
}
