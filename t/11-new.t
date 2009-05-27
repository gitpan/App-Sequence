use Test::More 'no_plan';
use strict;
use warnings;
use App::Sequence;

my $t_dir = 't/11-new';
{
    
    my $as = App::Sequence->new(
        module_files => [ "$t_dir/module1.pm" ]
    );
    
    is( ref $as, 'App::Sequence', 'new' );
    eval{
        package main;
        a();
    };
    ok(!$@, 'import module' );
}
