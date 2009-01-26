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
    my $sequence = [
        { package => 'main', name => 'a', args => [ 'c.a', 'c.b' ], ret => 'r.a', },
        { package => 'main', name => 'a', args => [ 'c.a', 'r.a' ], ret => 'r.b', }
    ];
    
    App::Sequence::_run_sequence( $sequence, $conf, $ret );
    is( $ret->{ b }, 4, '_run_sequence success' );
}

{
    my $ret = {};
    my $conf = { a => 1, b => 2 };
    my $sequence = [
        { package => 'main', name => 'a', args => [ 'c.a', 'c.b' ], ret => 'r.a', },
        { package => 'main', name => 'a', args => [ 'c.a', 'r.a' ], ret => 'stdout', }
    ];
    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    App::Sequence::_run_sequence( $sequence, $conf, $ret );
    $capture->stop;
    my $stdout = $capture->read;
    
    is( $stdout, 4, 'stdout' );
}
