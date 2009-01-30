use Test::More 'no_plan';
use strict;
use warnings;

use App::Sequence;

{
    my @argv = ( 'b.meta' );
    my $meta_file = App::Sequence->_meta_file_contain( @argv );
    is( $meta_file, $argv[0], 'only one meta file' );
}

{
    my @argv = ( 'b.meta', 'c' );
    my $warn;
    $SIG{__WARN__} = sub{
        $warn = shift;
    };
    
    my $meta_file = App::Sequence->_meta_file_contain( @argv );
    is( $meta_file, $argv[0], 'only one meta file' );
    like( $warn, qr/Only first meta file $meta_file is received\. Other arguments is ignored\./, 'warning first meta file is received' );
}

{
    my @argv = ( 'b' );
    my $meta_file = App::Sequence->_meta_file_contain( @argv );
    ok( !$meta_file, 'no meta file' );
}
