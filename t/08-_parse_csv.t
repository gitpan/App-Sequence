use Test::More 'no_plan';
use strict;
use warnings;

use App::Sequence;

require_ok( 'Text::CSV' );

my $t_dir = "t/08-_parse_csv";
{
    my $file = "$t_dir/test1.csv";
    my $conf = App::Sequence::_parse_csv( $file );
    is_deeply( $conf, [{ name => 'kimoto', age => 1 },{ name => 'sirahama', age => 2 }], 'success pattern1' );
}

{
    my $file = "$t_dir/test2.csv";
    my $conf = App::Sequence::_parse_csv( $file );
    is_deeply( $conf, [{ name => 'kimoto', age => 1 }], 'success pattern2 no last \n' );
}

{
    my $file = "noexist";
    eval{ App::Sequence::_parse_csv( $file ) };
    like( $@, qr/Cannnot open/, 'not exist file' );
}

{
    my $file = "$t_dir/err_test1.csv";
    eval{ App::Sequence::_parse_csv( $file ) };
    like( $@ , qr#field count must be same as header count 2 : $file Line 2# ,'header count is diffrent from items' );
    
}
