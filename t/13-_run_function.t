use Test::More 'no_plan';
use IO::Capture::Stdout;

use strict;
use warnings;;
use App::Sequence;


sub a{
    my ( $x, $y ) = @_;
    return $x + $y;
}


{
    my $ret = {};
    my $conf = { a => 1, b => 2 };
    my $func_info = { package => 'main', name => 'a', args => [ 'c.a', 'c.b' ], ret => 'r.a', };
    App::Sequence::_run_function( $func_info, $conf, $ret );
    is( $ret->{ a }, 3, '_run_function success' );
}

{
    my $ret = {};
    my $conf = { a => 1, b => 2 };
    my $func_info = { package => 'main', name => 'a', args => [ 'c.a', 'c.b' ], ret => 'stdout' };
    
    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    App::Sequence::_run_function( $func_info, $conf, $ret );
    $capture->stop;
    my $stdout = $capture->read;
    
    is( $stdout, "3", 'stdout' );
    
}

