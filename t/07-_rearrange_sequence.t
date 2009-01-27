use Test::More 'no_plan';
use strict;
use warnings;
use App::Sequence;

my $t_dir = 't/07-_rearrange_sequence';

{
    my $files = [ "$t_dir/test1.as", "$t_dir/test2.as" ];
    my $sequences = App::Sequence::_rearrange_sequence( $files );
    
    is_deeply( $sequences, 
             [ [{ package => 'main', name => 'a', args => [], ret => undef, }],
               [{ package => 'main', name => 'b', args => [], ret => undef, }],
             ], 'success pattern 1' );
}


{
    my $files = [ "$t_dir/test1_win.as"];
    my $sequences = App::Sequence::_rearrange_sequence( $files );
    
    is_deeply( $sequences, 
             [ 
               [{ package => 'main', name => 'a', args => [], ret => undef, }],
             ], 'success pattern 1(windows return code' );
}

{
    my $files = [ "noexist" ];
    eval{ App::Sequence::_rearrange_sequence( $files ) };
    like( $@, qr/Cannot open noexist/, 'Cannot open file' );
}

{
    my $files = [ "$t_dir/err_test1.as" ];
    eval{ App::Sequence::_rearrange_sequence( $files ) };
    like( $@, qr#$t_dir/err_test1.as line 1#, 'parse error' )
}