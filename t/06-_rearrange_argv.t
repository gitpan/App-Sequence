use Test::More 'no_plan';
use strict;
use warnings;
use App::Sequence;

my $t_dir = 't/06-_rearrange_argv';

{
    local @ARGV = qw( a.as b.as a.pm b.pm a.csv b.yaml c.yml d.xml e.ini );
    my $argv = App::Sequence->_rearrange_argv( @ARGV );
    is_deeply( $argv, { sequence_files => [ 'a.as', 'b.as' ],
                        module_files => [ 'a.pm', 'b.pm' ],
                        conf_files => [ 'a.csv', 'b.yaml', 'c.yml', 'd.xml', 'e.ini' ] },
                        'success pattern' );
}

{
    local @ARGV = qw( a.iii );
    {
        eval{ App::Sequence->_rearrange_argv( @ARGV ) };
    }
    like( $@,
          qr/'a\.iii' is invalid param\. param must be in \( \.as \.pm \.csv \.yaml \.yml \.xml \.ini \)/, 
          'invalid param' );
}

{
    local @ARGV = qw( a.pm a.yml );
    {
        eval{ App::Sequence->_rearrange_argv( @ARGV ) };
    }
    like( $@, qr/\.as file must be passed/, '.as file not passed' );
}

{
    local @ARGV = qw( a.as a.pm );
    {
        eval{ App::Sequence->_rearrange_argv( @ARGV ) };
    }
    like( $@, qr/config file\( \.csv \.yaml \.yml \.xml \.ini \) must be passed/, 'config file not passed' );
}

{
    local @ARGV = ( "$t_dir/test1.meta" );
    my $argv = App::Sequence->_rearrange_argv( @ARGV );
    is_deeply( $argv, { sequence_files => [ 't/06-_rearrange_argv/a.as' ],
                        module_files => [ 't/06-_rearrange_argv/a.pm' ],
                        conf_files => [ 't/06-_rearrange_argv/a.csv' ] },
                        'read meta file' );
}
