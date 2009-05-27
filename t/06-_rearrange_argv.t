use Test::More 'no_plan';
use strict;
use warnings;
use App::Sequence;

my $t_dir = 't/06-_rearrange_argv';

{
    my @argv = qw( a.as b.as a.pm b.pm a.csv b.yaml c.yml d.xml e.ini );
    my $argv = App::Sequence->_rearrange_argv( @argv );
    is_deeply( $argv, { sequence_files => [ 'a.as', 'b.as' ],
                        module_files => [ 'a.pm', 'b.pm' ],
                        conf_files => [ 'a.csv', 'b.yaml', 'c.yml', 'd.xml', 'e.ini' ] },
                        'success pattern' );
}

{
    my @argv = qw( a.iii );
    {
        eval{ App::Sequence->_rearrange_argv( @argv ) };
    }
    like( $@,
          qr/'a\.iii' is invalid param\. param must be in \( \.as \.pm \.csv \.yaml \.yml \.xml \.ini \.json \)/, 
          'invalid param' );
}

{
    my @argv = qw( a.pm a.yml );
    {
        eval{ App::Sequence->_rearrange_argv( @argv ) };
    }
    like( $@, qr/\.as file must be passed/, '.as file not passed' );
}

{
    my @argv = qw( a.as a.pm );
    {
        eval{ App::Sequence->_rearrange_argv( @argv ) };
    }
    like( $@, qr/config file\( \.csv \.yaml \.yml \.xml \.ini \.json \) must be passed/, 'config file not passed' );
}

