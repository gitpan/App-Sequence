use Test::More qw( no_plan );
use strict;
use warnings;

use App::Sequence;

my $t_dir = 't/02-_rearrange_conf';

{
    my $conf = App::Sequence::_rearrange_conf( { a => 1 } );
    is_deeply( $conf, [{ a => 1 }], 'conf hash ref' );
}

{
    my $conf = App::Sequence::_rearrange_conf( [{ a => 1 }, { a => 2 }] );
    is_deeply( $conf, [{ a => 1 }, { a => 2 }], 'conf array ref of hash ref ' );
}

{
    eval{ App::Sequence::_rearrange_conf( 1 ) };
    like( $@, qr/is unacceptable as conf setting/, "conf unacceptable" );
}

{
    my $conf = App::Sequence::_rearrange_conf( "$t_dir/conf.xml" );
    is_deeply( $conf, [{ name => 'a'}], 'conf xml' );
}

{
    eval{
        my $conf = App::Sequence::_rearrange_conf( "noexist.xml" );
    };
    ok( $@, 'conf no xml file' );
}

{
    my $conf = App::Sequence::_rearrange_conf( "$t_dir/conf.yml" );

    is_deeply( $conf, [{ name => 'a', age => 'b' }], 'conf yml' );
}

{
    eval{
        my $conf = App::Sequence::_rearrange_conf( "noexist.yml" );
    };
    
    ok( $@, 'conf no yml file' );
   
}

{
    my $conf = App::Sequence::_rearrange_conf( "$t_dir/conf.ini" );
    is_deeply( $conf, [ { s => { a => 1 } } ], 'conf ini' );
}

{

    eval{ App::Sequence::_rearrange_conf( "noexist.ini" ) };
    ok( $@, 'conf no ini file' );
}

{
    my $conf = App::Sequence::_rearrange_conf( ["$t_dir/conf.yml", "$t_dir/conf2.yml"] );

    is_deeply( $conf, [{ name => 'a', age => 'b' }, { name => 'c', age => 'd' }], 'two files' );
}

{
    my $conf = App::Sequence::_rearrange_conf( "$t_dir/conf.csv" );
    is_deeply( $conf, [ { a => 1, b => 2 } ], 'conf csv' );
}


