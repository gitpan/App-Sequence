#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Sequence' );
}

diag( "Testing App::Sequence $App::Sequence::VERSION, Perl $], $^X" );
