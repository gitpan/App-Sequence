use Test::More 'no_plan';
use strict;
use warnings;

use App::Sequence;

require_ok( 'JSON' );

my $t_dir = "t/19-_parse_json";
{
    my $file = "$t_dir/test1.json";
    my $conf = App::Sequence->_parse_json( $file );
    is_deeply( $conf, { name => 'kimoto', age => 1 }, 'success pattern1' );
}

{
    my $file = "noexist";
    eval{ App::Sequence->_parse_csv( $file ) };
    like( $@, qr/Cannot open/, 'not exist file' );
}
