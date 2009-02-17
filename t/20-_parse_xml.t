use Test::More 'no_plan';
use strict;
use warnings;

use App::Sequence;

require_ok( 'JSON' );

my $t_dir = "t/20-_parse_xml";
{
    my $file = "$t_dir/test1.xml";
    my $conf = App::Sequence->_parse_xml( $file );
    is_deeply( $conf, { name => 'Kimoto', age => 1 }, 'ascii only' );
}

{
    my $file = "$t_dir/test3_utf8.xml";
    my $conf = App::Sequence->_parse_xml( $file );
    
    use utf8;
    is_deeply( $conf, { name => 'あ', age => 'い' }, 'utf8 parse' );
    no utf8;
}

SKIP:{
    skip "Windows only", 1 if $^O ne 'MSWin32';
    my $file = "$t_dir/test2_shift-jis.xml";
    my $conf = App::Sequence->_parse_xml( $file, 'shift-jis' );
    
    use utf8;
    is_deeply( $conf, { name => 'あ', age => 'い' }, 'shift-jis parse' );
    no utf8;
}

{
    my $file = "noexist";
    eval{ App::Sequence->_parse_xml( $file ) };
    like( $@ , qr/File 'noexist' not exist/,  'not exist file' );
}

{
    my $file = "$t_dir/test4_parse_error.xml";
    eval{ App::Sequence->_parse_xml( $file ) };
    like( $@ , qr#File 't/20-_parse_xml/test4_parse_error.xml': #, 'xml parse error' );
}
