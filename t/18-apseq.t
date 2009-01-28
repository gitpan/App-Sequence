use Test::More 'no_plan';
use strict;
use warnings;

#use IO::Capture;

my $t_dir = "t/18-apseq";
{
    
    my $command = "blib/script/apseq $t_dir/conf.csv $t_dir/module1.pm $t_dir/module2.pm $t_dir/test1.as";
    my $stdout = `$command`;
    is( $stdout, "{b{a12}1}{b{a34}3}", 'success pattern' );
}

{
    my $command = "blib/script/apseq $t_dir/test1.meta";
    my $stdout = `$command`;
    is( $stdout, "{b{a12}1}{b{a34}3}", 'success pattern' );
}

