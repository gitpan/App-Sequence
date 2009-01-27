use Test::More qw( no_plan );
use strict;
use warnings;

BEGIN{
    use_ok( 'YAML' );
    use_ok( 'Text::CSV' );
    use_ok( 'Config::Tiny' );
    use_ok( 'XML::Simple' );
    use_ok( 'Simo' );
    
    use_ok( 'App::Sequence' );
}
require_ok( 'YAML' );
require_ok( 'Text::CSV' );
require_ok( 'Config::Tiny' );
require_ok( 'XML::Simple' );
require_ok( 'Simo' );

require_ok( 'App::Sequence' );

can_ok( 'App::Sequence', 
    qw(
        _rearrange_argv
        _rearrange_conf
        _parse_string_data
        _parse_func_expression
        _import_module
        _rearrange_sequence
        _parse_csv
        
        confs
        sequences
                
        module_files
        r
        argv
        
        _update_confs
        conf_files
                
        sequence_files
        _update_sequences

        new
        run
    )
);

{
    my $as = App::Sequence->new;
    is_deeply( $as->r, {}, "default r" );
    $as->r( 1 );
    is( $as->r, 1, "accossor r" );
}

{
    my $as = App::Sequence->new;
    
    my @accessors = qw( confs sequences module_files argv );
    foreach my $ac ( @accessors  ){
        no strict 'refs';
        is_deeply( $as->$ac, [], "default $ac" );
        $as->$ac( 1 );
        is_deeply( $as->$ac, [1], "accossor $ac scalar" );
        $as->$ac( [2] );
        is_deeply( $as->$ac, [2], "accossor $ac array_ref" );
    }
}

__END__
