package App::Sequence;
use Simo;

our $VERSION = '0.01_05';

use Carp;
use FindBin;

### accessors

# config file list
sub conf_files{ ac 
    default => [],
    filter => \&_to_array_ref,
    trigger => \&_update_confs
}
# trigger method when conf_file is set
sub _update_confs{ $_->confs( _rearrange_conf( $_->conf_files ) ) }

# config list
sub confs{ ac default => [], filter => \&_to_array_ref };

# sequence file list
sub sequence_files{ ac 
    default => [],
    filter => \&_to_array_ref,
    trigger => \&_update_sequences
}

# trigger method when sequence_files is set
sub _update_sequences{ $_->sequences( _rearrange_sequence( $_->sequence_files ) ) }

# sequence list
sub sequences{ ac default => [], filter => \&_to_array_ref }

# module file list
sub module_files{ ac default => [], filter => \&_to_array_ref }

# retrun value
sub r{ ac default => {} }

# @ARGV
sub argv{ ac default => [], filter => \&_to_array_ref }

# callback run

sub _to_array_ref{ ref eq 'ARRAY' ? $_ : [ $_ ] }



### method

# new
sub new{
    my $self = shift->SUPER::new( @_ );
    
    _import_module( $self->module_files );
    return $self;
}

# create object from @ARGV
sub create_from_argv{
    my $self = shift->SUPER::new;

    my $argv = _rearrange_argv( @ARGV );
    
    $self->conf_files( $argv->{ conf_files } );
    $self->sequence_files( $argv->{ sequence_files } );
    $self->module_files( $argv->{ module_files } );
    
    _import_module( $self->module_files );
    
    return $self;
}

# .pm files import
sub _import_module{
    my $module_files = shift;
    my $self = shift;
    use lib '.';
    
    foreach my $module_file ( @{ $module_files } ){
        package main;
        require Carp;
        
        require $module_file;
        Carp::croak "$module_file is not exist" if $@;
    }
}

# run subroutine list registed by resist method
sub run{
    my $self = shift;
    
    foreach my $conf ( @{ $self->confs } ){
        foreach my $sequence ( @{ $self->sequences } ){
            my $ret = {};
            _run_sequence( $sequence, $conf, $ret );
        }
    }
}

sub _run_sequence{
    my ( $sequence, $conf, $ret ) = @_;
    foreach my $func_info ( @{ $sequence } ){
        _run_function( $func_info, $conf, $ret );
    }
}

sub _run_function{
    my ( $func_info, $conf, $ret ) = @_;
    my $func_name = $func_info->{ package } . '::' . $func_info->{ name };
    
    my @args;
    foreach my $arg ( @{ $func_info->{ args } } ){
        my $val = _parse_string_data( $arg, $conf, $ret );
        push @args, $val;
        carp "$arg is undef value" if !defined( $val );
    }
    
    my $ret_key;
    if( $func_info->{ ret } =~ /^r\.(.+)/ ){
        $ret_key = $1;
    }
    
    {
        no strict 'refs';
        my $ret_val = $func_name->( @args );
        
        if( $ret_key ){
            $ret->{ $ret_key } = $ret_val;
        }
        
        if( $func_info->{ ret } =~ /^stdout$/ ){
            print "$ret_val";
        }
    }
}

sub _parse_string_data{
    my ( $arg, $conf, $ret ) = @_;
    my $val;
    if( $arg =~ s/^c\.// ){
        my @keys = split /\./, $arg;
        
        my $current = $conf;
        foreach my $key ( @keys ){
            $current = $current->{ $key };
        }
        $val = $current;
    }
    elsif( $arg =~ /r\.(.+)/ ){
        $val = $ret->{ $1 };
    }
    return $val;
}

# rearrange @ARGV
sub _rearrange_argv{
    my @argv = @_;

    my $rearranged_argv = { sequence_files => [], module_files => [], conf_files => [] };
    
    if( my $meta_file = _meta_file_contain( @argv ) ){
        @argv = _parse_meta_file( $meta_file );
    }
    
    foreach my $arg ( @argv ){
        if( $arg =~ /\.as/ ){
            push @{ $rearranged_argv->{ sequence_files } }, $arg;
        }
        elsif( $arg =~ /\.pm/ ){
            push @{ $rearranged_argv->{ module_files } }, $arg;
        }
        elsif( $arg =~ /\.csv$/ ||
               $arg =~ /\.ya?ml$/ ||
               $arg =~ /\.xml$/ ||
               $arg =~ /\.ini$/ )
        {
            push @{ $rearranged_argv->{ conf_files } }, $arg;
        }
        else{
            croak "'$arg' is invalid param. param must be in ( .as .pm .csv .yaml .yml .xml .ini )";
        }
    }
    
    croak ".as file must be passed" unless @{ $rearranged_argv->{ sequence_files } };
    croak "config file( .csv .yaml .yml .xml .ini ) must be passed"
        unless @{ $rearranged_argv->{ conf_files } };
    
    return $rearranged_argv;
}

# whether array contain meta file( .meta )
sub _meta_file_contain{
    my @argv = @_;
    my $meta_file = ( grep { /\.meta$/ } @argv )[0];
    
    carp "Only first meta file $meta_file is received. Other arguments is ignored."
        if $meta_file && @argv != 1;
    
    return $meta_file;
}

# parse meta file, and convert @argv
sub _parse_meta_file{
    my $file = shift;
    
    open my $fh, "<", $file
        or croak "Cannot open $file: $!";
    my $content;
    
    {
        local $/ = undef;
        defined( $content = <$fh> ) or croak "Cannot read $file: $!";
    }
    
    $content =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
    $content =~ s/#.*\n//g;
    
    my @argv = split /\s+/, $content;
    
    require File::Basename;
    
    my $dir = File::Basename::dirname( $file );
    foreach my $arg ( @argv ){
        if( $arg =~ /\.\w+$/ ){
            $arg = $dir . '/' . $arg;
        }
    }
    
    return @argv;
}


# parse .as file line
sub _parse_func_expression{
    my $exp = shift;
    my $original_exp = $exp;
    
    my $func_info = { package => 'main', name => undef, args => [], ret => undef };
    
    # delete first space;
    $exp =~ s/^\s*//;
    $exp =~ s/\s*$//;
    # function name
    if( $exp =~ s/^((?:\w+::)*)(\w+\b)// ){
        if( $1 ){
            my $package = $1;
            $package =~ s/::$//;
            $func_info->{ package } = $package;
        }
        $func_info->{ name } = $2;
    }
    else{
        croak "function name is invalid. '$original_exp'";
    }
    
    # args
    if( $exp =~ s/^\s*\((.*)\)\s*// ){
        my $args_exp = $1;
        
        $args_exp =~ s/^\s*//;
        $args_exp =~ s/\s*$//;
        
        my @args = split /\s*,\s*/, $args_exp;
        foreach my $i ( 0 .. @args - 1 ){
            unless( $args[$i] =~ /^[c|r]\.\w+$/ ){
                croak "arg '$args[$i]' is invalid. arg must be like c.name or r.age, etc";
            }
        }
        $func_info->{ args } = [@args];
    }
    
    # retrun value
    if( $exp =~ s/^\s*:\s*(.+)\s*$// ){
        my $ret = $1;
        if( $ret =~ /^(r\..+)$/ || $ret =~ /^(stdout)$/ ){
            $func_info->{ ret } = $1;
        }
        else{
            croak "ret '$ret' is invalid. arg must be like r.age, etc";
        }
    }
    
    # unknown error
    if( $exp ){
        croak "parse error '$original_exp'. expression must be like 'func_name( c.name, r.age, .. ) : r.content'";
    }
    return $func_info;
}

sub _rearrange_sequence{
    my $files = shift;
    my $sequences = [];
    
    foreach my $file ( @{ $files } ){
        open my $fh, "<", $file
            or croak "Cannot open $file : $!";
        
        my $sequence = [];
        while( my $line = <$fh> ){
            
            $line =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
            chomp $line;
            
            my $func_info = eval{ _parse_func_expression( $line ) };
            croak "$file line $. : $@" if( $@ );
            
            push @{ $sequence }, $func_info;
        }
        push @{ $sequences }, $sequence;
    }
    return $sequences;
}

sub _rearrange_conf{
    my $conf = shift;
    
    # convert array ref
    my $confs = ref $conf eq 'ARRAY' ? $conf : [ $conf ];
    
    #various conf rearrange
    my $rearranged_confs = [];
    my $rearranged_conf;
    foreach my $conf ( @{ $confs } ){
        # todo test
        if( ref $conf eq 'HASH' ){
            $rearranged_conf = [ $conf ];
        }
        elsif( $conf =~ /\.xml$/ ){
            require XML::Simple;
            my $parser = XML::Simple->new;
            eval{
                $rearranged_conf =  $parser->XMLin( $conf );
            };
            croak $@ if $@;
        }
        elsif( $conf =~ /\.yml$/ ){
            require YAML;
            eval{
                $rearranged_conf = YAML::LoadFile( $conf );
            };
            croak $@ if $@;
        }
        elsif( $conf =~ /\.ini$/ ){
            require Config::Tiny;
            my $ct = Config::Tiny->new;
            my $tiny_obj = $ct->read( $conf );

            croak $ct->errstr unless $tiny_obj;
            $rearranged_conf = {};
            %{ $rearranged_conf } = %{ $tiny_obj };
        }
        elsif( $conf =~ /\.csv$/ ){
            $rearranged_conf = _parse_csv( $conf );
        }
        else{
            croak "$conf is unacceptable as conf setting";
        }
        
        $rearranged_conf = ref $rearranged_conf eq 'ARRAY' ? $rearranged_conf :
                           [ $rearranged_conf ];
        
        push @{ $rearranged_confs }, @{ $rearranged_conf };
    }
    return $rearranged_confs;
}

# csv file arrange
sub _parse_csv{
    my $conf = shift;
    require Text::CSV;
    my $parser = Text::CSV->new({ binary => 1 });
    
    open my $fh, "<", $conf
        or croak "Cannnot open $conf: $!";
    
    my $is_first_line = 1;
    my @header;
    my $rearranged_confs = [];
    while( my $line = <$fh> ){
        
        $line =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
        chomp $line;
        
        next if $line =~ /^$/;
        
        $line =~ s/(\r|\n)//g;
        $parser->parse( $line );

        if( !$parser->status ){
            croak $parser->error_diag . ': ' . $parser->error_input;
        }
        
        my @items = $parser->fields;
        if( $is_first_line ){
            @header = @items;
            $is_first_line = 0;
        }
        else{
            my $header_count = @header;
            croak "field count must be same as header count $header_count : $conf Line $."
                if @header != @items;
            my $rearranged_conf = {};
            @{ $rearranged_conf }{ @header } = @items;
            push @{ $rearranged_confs }, $rearranged_conf;
        }
    }
    return $rearranged_confs;
}

=head1 NAME

App::Sequence - useful plaggable subroutine engine.

=head1 VERSION

Version 0.01_05

=cut

=head1 SYNOPSIS

You use this module as the following,

    use App::Sequence;

    App::Sequence->create_from_argv->run;

But usually this module is used through apseq script.

apseq script is installed with this module.

It is better using apseq script than using this module by yourself.

=head1 FUNCTIONS

=head2 argv

todo

=cut

=head2 conf_files

todo

=cut

=head2 confs

todo

=cut

=head2 create_from_argv

todo

=cut

=head2 module_files

todo

=cut

=head2 new

todo

=cut

=head2 r

todo

=cut

=head2 run

todo

=cut

=head2 sequence_files

todo

=cut

=head2 sequences

todo

=cut

=head1 AUTHOR

Yuki, C<< <kimoto.yuki at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-sequence at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Sequence>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Sequence


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Sequence>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Sequence>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Sequence>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Sequence/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Yuki, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of App::Sequence
