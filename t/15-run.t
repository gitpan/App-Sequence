use Test::More 'no_plan';
use IO::Capture::Stdout;
use strict;
use warnings;

use App::Sequence;
my $t_dir = 't/15-run';
{
    my @args = ( 
        "$t_dir/conf.csv",
        "$t_dir/module1.pm", "$t_dir/module2.pm",
        "$t_dir/test1.as",
    );
    
    my $as = App::Sequence->create_from_argv(@args);
    
    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    $as->run;
    $capture->stop;
    
    my @stdout = $capture->read;
    is_deeply( [@stdout], ['{b{a12}1}','{b{a34}3}'], 'success pattern1' );
}

{
    my @args = ( 
        "$t_dir/conf.csv", "$t_dir/conf.yml",
        "$t_dir/module1.pm", "$t_dir/module2.pm", "$t_dir/module3.pm",
        "$t_dir/test1.as", "$t_dir/test2.as"
    );
    
    my $as = App::Sequence->create_from_argv(@args);
    
    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    $as->run;
    $capture->stop;
    my @stdout = $capture->read;
    is_deeply( [@stdout], ['{b{a12}1}', '{c{b12}1}',
                           '{b{a34}3}', '{c{b34}3}',
                           '{b{a56}5}', '{c{b56}5}' ], 'success pattern1' );
}

{
    my @args = ( 
        "$t_dir/conf.json",
        "$t_dir/module1.pm", "$t_dir/module2.pm",
        "$t_dir/test1.as",
    );
    
    my $as = App::Sequence->create_from_argv(@args);
    
    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    $as->run;
    $capture->stop;
    
    my @stdout = $capture->read;
    is_deeply( [@stdout], ['{b{a56}5}'], 'success pattern1' );
}

{
    my @args = ( 
        "$t_dir/conf.yaml",
        "$t_dir/module1.pm", "$t_dir/module2.pm",
        "$t_dir/test1.as",
    );
    
    my $as = App::Sequence->create_from_argv(@args);
    
    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    $as->run;
    $capture->stop;
    
    my @stdout = $capture->read;
    is_deeply( [@stdout], ['{b{a56}5}'], 'success pattern1' );
}