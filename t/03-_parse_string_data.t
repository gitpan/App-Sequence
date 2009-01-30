use Test::More 'no_plan';
use strict;
use warnings;
use App::Sequence;

{
    my $conf = { a => 1 };
    my $ret = { b => 2 };
    
    
    my $args1 = App::Sequence->_parse_string_data( 'c.a', $conf, $ret );
    is( $args1, 1, 'parse conf attribute 1' );
    
    my $args2 = App::Sequence->_parse_string_data( 'r.b', $conf, $ret );
    is( $args2, 2, 'parse ret attribute 2' );

    my $conf2 = { a => { b => 3 } };
    my $arg3 = App::Sequence->_parse_string_data( 'c.a.b', $conf2, $ret );
    is( $arg3, 3, 'parse ret attribute 3' );
}

{
    my $conf = { a => 1, b => 2 };
    my $ret = {};
    
    my $args1 = App::Sequence->_parse_string_data( 'c.a', $conf, $ret );
    is( $args1, 1, 'parse conf attribute 4' );
}

