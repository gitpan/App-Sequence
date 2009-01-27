use Test::More 'no_plan';
use strict;
use warnings;
use App::Sequence;
my $t_dir = 't/05-_import_module';

{
    my $files = [ "$t_dir/module1.pm", "$t_dir/module2.pm" ];
    package AAA;
    App::Sequence::_import_module( $files );
    
    package main;
    eval{ a() };
    ok( !$@, 'import module1 ok' );
    
    eval{ b() };
    ok( !$@, 'import module2 ok' );
}

