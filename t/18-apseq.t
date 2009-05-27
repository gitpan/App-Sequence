use Test::More 'no_plan';
use strict;
use warnings;
use File::Spec;

my $t_dir = "t/18-apseq";
my $script = File::Spec->catfile( 'blib', 'script', 'apseq' );

{
    my $command = "$script $t_dir/conf.csv $t_dir/module1.pm $t_dir/module2.pm $t_dir/test1.as";
    my $stdout = `$command`;
    is( $stdout, "{b{a12}1}{b{a34}3}", 'success pattern' );
}

{
    my $command = "$script $t_dir/test1.meta";
    my $stdout = `$command`;
    is( $stdout, "{b{a12}1}{b{a34}3}", 'success pattern' );
}

{
    my $command = "$script $t_dir";
    my $stdout = `$command`;
    is( $stdout, "{b{a12}1}{b{a34}3}", 'success pattern' );
}

