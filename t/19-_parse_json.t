use Test::More 'no_plan';
use strict;
use warnings;

use App::Sequence;

require_ok( 'JSON' );

my $t_dir = "t/19-_parse_json";
{
    my $file = "$t_dir/test1.json";
    my $conf = App::Sequence->_parse_json( $file );
    is_deeply( $conf, { name => 'kimoto', age => 1 }, 'ascii only' );
}

{
    my $file = "$t_dir/test3_utf8.json";
    my $conf = App::Sequence->_parse_json( $file );
    
    use utf8;
    is_deeply( $conf, { name => 'あ', age => 'い' }, 'utf8 parse' );
    no utf8;
}

{
    my $file = "$t_dir/test2_shift-jis.json";
    my $conf = App::Sequence->_parse_json( $file, 'shift-jis' );
    
    use utf8;
    is_deeply( $conf, { name => 'あ', age => 'い' }, 'shift-jis parse' );
    no utf8;
}

{
    my $file = "noexist";
    eval{ App::Sequence->_parse_json( $file ) };
    like( $@, qr/Cannot open/, 'not exist file' );
}
