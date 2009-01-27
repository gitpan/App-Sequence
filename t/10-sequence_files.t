use Test::More 'no_plan';
use strict;
use warnings;
use App::Sequence;

my $t_dir = 't/10-sequence_files';
{
    my $as = App::Sequence->new;
    $as->sequence_files( "$t_dir/test1.as" );
    is_deeply( $as->sequences, [[{ package => 'main', name => 'a', args => [], ret => undef, }]], 'conf_files' );

    $as->sequence_files( [ "$t_dir/test1.as", "$t_dir/test1.as" ] );
    is_deeply( $as->sequences, [[{ package => 'main', name => 'a', args => [], ret => undef, }], 
                                [{ package => 'main', name => 'a', args => [], ret => undef, }]], 'conf_files' );
}