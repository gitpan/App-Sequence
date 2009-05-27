use Test::More 'no_plan';
use strict;
use warnings;

use App::Sequence;

my $t_dir = 't/21-_parse_directory';

1;

{
    my $files = App::Sequence->_parse_directory( $t_dir );
    is_deeply($files->{conf_files}, ["$t_dir/conf.csv"], 'parse directory 1');
    is_deeply([sort @{$files->{module_files}}], [sort ("$t_dir/module1.pm", "$t_dir/module2.pm")],'parse directory 2');
    is_deeply($files->{sequence_files}, ["$t_dir/test1.as" ], 'parse directory 3');
}

{
     eval{App::Sequence->_parse_directory( 'no_exist' )};
     like($@, qr/Cannot open/, 'connot open directory');
}
