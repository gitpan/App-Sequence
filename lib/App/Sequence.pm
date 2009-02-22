package App::Sequence;
use Simo;

our $VERSION = '0.03_05';

use Carp;
use Encode;

### accessors( by Simo )

# config file list
sub conf_files{ ac
    default => [],
    filter => \&_to_array_ref,
    trigger => \&_update_confs
}
# trigger method when conf_file is set
sub _update_confs{ $_->confs( $_->_rearrange_conf( $_->conf_files ) ) }

# config list
sub confs{ ac default => [], filter => \&_to_array_ref };

# sequence file list
sub sequence_files{ ac 
    default => [],
    filter => \&_to_array_ref,
    trigger => \&_update_sequences
}

# trigger method when sequence_files is set
sub _update_sequences{ $_->sequences( $_->_rearrange_sequence( $_->sequence_files ) ) }

# sequence list
sub sequences{ ac default => [], filter => \&_to_array_ref }

# module file list
sub module_files{ ac 
    default => [],
    filter => \&_to_array_ref,
    trigger =>  sub{ $_->_import_module( $_->module_files ) }
}

# retrun value
sub r{ ac default => {} }

# @ARGV
sub argv{ ac default => [], filter => \&_to_array_ref }

# convert to array ref
sub _to_array_ref{ ref eq 'ARRAY' ? $_ : [ $_ ] }


### method

# new is automaticaly created by Simo

# create object from @ARGV
sub create_from_argv{
    my $self = shift->SUPER::new;

    my $argv = $self->_rearrange_argv( @ARGV );
    
    $self->conf_files( $argv->{ conf_files } );
    $self->sequence_files( $argv->{ sequence_files } );
    $self->module_files( $argv->{ module_files } );
    
    return $self;
}

# .pm files import
sub _import_module{
    my ( $self, $module_files ) = @_;

    use lib '.';
    
    foreach my $module_file ( @{ $module_files } ){
        package main;
        require Carp;
        
        require $module_file;
        Carp::croak "$module_file is not exist" if $@;
    }
}

# run all sequences
sub run{
    my $self = shift;
    
    foreach my $conf ( @{ $self->confs } ){
        foreach my $sequence ( @{ $self->sequences } ){
            my $ret = {};
            $self->_run_sequence( $sequence, $conf, $ret );
        }
    }
}

# run each sequence
sub _run_sequence{
    my ( $self, $sequence, $conf, $ret ) = @_;
    foreach my $func_info ( @{ $sequence } ){
        $self->_run_function( $func_info, $conf, $ret );
    }
}

# run each function 
sub _run_function{
    my ( $self, $func_info, $conf, $ret ) = @_;
    my $func_name = $func_info->{ package } . '::' . $func_info->{ name };
    
    my @args;
    foreach my $arg ( @{ $func_info->{ args } } ){
        my $val = $self->_parse_string_data( $arg, $conf, $ret );
        push @args, $val;
        carp "$arg is undef value" if !defined( $val );
    }
    
    my $ret_key = $func_info->{ ret };
    if( $ret_key && $ret_key =~ /^r\.(.+)/ ){
        $ret_key = $1;
    }
    
    {
        no strict 'refs';
        my $ret_val = $func_name->( @args );
        
        if( $ret_key && $ret_key =~ /^stdout$/ ){
            print "$ret_val";
        }
        elsif( $ret_key ){
            $ret->{ $ret_key } = $ret_val;
        }
    }
}

# parse string data structure( c.name, c.age, etc )
sub _parse_string_data{
    my ( $self, $arg, $conf, $ret ) = @_;
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
    my ( $self, @argv ) = @_;

    my $rearranged_argv = { sequence_files => [], module_files => [], conf_files => [] };
    
    if( my $meta_file = $self->_meta_file_contain( @argv ) ){
        @argv = $self->_parse_meta_file( $meta_file );
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
               $arg =~ /\.ini$/ ||
               $arg =~ /\.json$/ )
        {
            push @{ $rearranged_argv->{ conf_files } }, $arg;
        }
        else{
            croak "'$arg' is invalid param. param must be in ( .as .pm .csv .yaml .yml .xml .ini .json )";
        }
    }
    
    croak ".as file must be passed" unless @{ $rearranged_argv->{ sequence_files } };
    croak "config file( .csv .yaml .yml .xml .ini .json ) must be passed"
        unless @{ $rearranged_argv->{ conf_files } };
    
    return $rearranged_argv;
}

# whether array contain meta file( .meta )
sub _meta_file_contain{
    my ( $self, @argv ) = @_;
    my $meta_file = ( grep { /\.meta$/ } @argv )[0];
    
    carp "Only first meta file $meta_file is received. Other arguments is ignored."
        if $meta_file && @argv != 1;
    
    return $meta_file;
}

# parse meta file, and convert @argv
sub _parse_meta_file{
    my ( $self, $file ) = @_;
    
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
    my ( $self, $exp ) = @_;
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

# parse sequence file and convert to sequence data.
sub _rearrange_sequence{
    my ( $self, $files ) = @_;
    my $sequences = [];
    
    foreach my $file ( @{ $files } ){
        open my $fh, "<", $file
            or croak "Cannot open $file : $!";
        
        my $sequence = [];
        while( my $line = <$fh> ){
            
            $line =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
            chomp $line;
            
            my $func_info = eval{ $self->_parse_func_expression( $line ) };
            croak "$file line $. : $@" if( $@ );
            
            push @{ $sequence }, $func_info;
        }
        push @{ $sequences }, $sequence;
    }
    return $sequences;
}

# parse many type config file, and convert hash ref.
sub _rearrange_conf{
    my ( $self, $conf ) = @_;
    
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
            $rearranged_conf = $self->_parse_xml( $conf );
        }
        elsif( $conf =~ /\.ya?ml$/ ){
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
            $rearranged_conf = $self->_parse_csv( $conf );
        }
        elsif( $conf =~ /\.json$/ ){
            $rearranged_conf = $self->_parse_json( $conf );
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
    my ( $self, $conf, $charset ) = @_;
    $charset ||= 'utf8';
    
    open my $fh, "<", $conf
        or croak "Cannot open $conf: $!";
    
    require Text::CSV;
    # my $parser = Text::CSV->new({ binary => 1 });
    my $parser = Text::CSV->new;
    
    my $is_first_line = 1;
    my @header;
    my $rearranged_confs = [];
    while( my $line = <$fh> ){
        $line = decode( 'utf8', $line );
        
        $line =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
        chomp $line;
        
        next if $line =~ /^$/;
        
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
    close $fh;
    
    return $rearranged_confs;
}

sub _parse_xml{
    my ( $self, $conf ) = @_;
    
    require XML::Simple;
    my $parser = XML::Simple->new;
    my $rearranged_conf;
    
    croak "File '$conf' not exists" unless -f $conf;
    
    eval{ $rearranged_conf =  $parser->XMLin( $conf ) };
    croak "File '$conf': $@" if $@;
    
    return $rearranged_conf;
}

sub _parse_json{
    my ( $self, $conf, $charset ) = @_;
    $charset ||= 'utf8';
    
    open my $fh, "<", $conf
        or croak "Cannot open $conf: $!";
    
    my $content = do{ local $/; <$fh> }
        or croak "Cannot read $conf: $!";
    
    $content = decode( $charset, $content );
    
    require JSON;
    my $rearranged_conf = JSON::from_json( $content );
    
    close $fh;
    return $rearranged_conf;
}

=head1 NAME

App::Sequence - pluggable subroutine engine.

=head1 VERSION

Version 0.03_05

This version is alpha version. It is experimental stage.
I have many works yet( charctor set, error handling, log outputting, some bugs )

=cut

=head1 SYNOPSIS

    apseq sequence.as module.pm config.csv
    
or

    apseq argument.meta

=head1 FEATURES

=over 4

=item 1. Your subroutines can be execute in any combination.

=item 2. Usage is very simple and flexible.

=item 3. Config file is load automatically.

=back

=head1 Using apseq script

When you install App::Sequence, apseq script is install at the same time.
you can use apseq script on command line as the following way.

    apseq sequence.as module.pm config.csv

apseq script receive three type of files.

=over 4

=item 1. Sequence file( .as ), which contain subroutine names you want to execute.

=item 2. Module file( .pm ), which contain subroutine definitions called by Sequence file.

=item 3. Config file( .csv, .yml, .xml, .ini ), which contain data or setting.

=back

apseq script receive three type of file, and execute subroutines.

File must be written by utf8.

=head1 Three type of file

=head2 Sequence file

=over 4

Sequence file must be end with .as

Sequence file format is

    get_html( c.id, c.passwd ) : r.html
    edit( r.html, c.encoding ) : stdout

I assume that you want to get html file on the web and edit the html file by using an encoding
and print STDOUT.

you pass argumet to subroutine and save return value. and saved return value is used in next subroutine.

=back

=head2 Module file

=over 4

Module file must be end with .pm

Module file is perl script that subroutine is defined.

    sub get_html{
        my ( $id, $passwd ) = @_;
        my $html;
        # ...
        return $html;
    }
    
    sub edit{
        my ( $html, $encoding ) = @_;
        my $output;
        # ...
        return $output;
    }
    1; # must be true value.

Do not forget that last line must be true value.

=back

=head2 Config file

Config file must be end with .csv, .yml, .xml, or .ini

=over 4

=item 1. CSV file( .csv )

CSV file first line is header.

CSV file format is

    name,age
    kimoto,29
    ken,13

This is converted to

    [
        { name => 'kimoto', age => '29' },
        { name => 'ken', age => '13' }
    ]

This is used in Sequence file. c.name, c.age, etc.

CSV file is useful to run same sequence repeatedly.This sample repeat sequence two times.

=item 2. YAML file( .yml )

YAML file is loaded by L<YAML>::LoadFile.

YAML format is 

    name: kimoto
    age: 29
    # last line is needed!
    
Do not forget that space is needed after colon( : ) and last line is need;

This is converted to 
    
    { name => 'kimoto', age => '29' }

This is used in Sequence file. c.name, c.age, etc.

See also L<YAML>

=item 3. XML file( .xml )

XML file is loaded by L<XML::Simple>::XML

    <?xml version="1.0" encoding="UTF-8" ?>
    <config>
      <name>kimoto</name>
      <age>29</age>
    </config>

/This is converted to

    { name => 'kimoto', age => '29' }

This is used in Sequence file. c.name, c.age, etc.

=item 4. Windows ini file( .ini )

Windows ini file is loaded by L<Config::Tiny>

Windows ini format is

    [person]
    name=kimoto
    age=29

This is used in Sequence file. c.person.name, c.person.age, etc.

See also L<Config::Tiny>

=back

=head1 Meta file( .meta )

You can write argument of apseq in Meta file.

Meta file must be end with .meta

Meta file format is

    sequence.as
    module.pm
    config.csv

You can apseq script by passing Meta file.

    apseq argumets.meta

=head1 FUNCTIONS

App::Sequence is used through apseq script. so I do not explain each method.

=head2 argv

no explaination

=cut

=head2 conf_files

no explaination

=cut

=head2 confs

no explaination

=cut

=head2 create_from_argv

no explaination

=cut

=head2 module_files

no explaination

=cut

=head2 new

no explaination

=cut

=head2 r

no explaination

=cut

=head2 run

no explaination

=cut

=head2 sequence_files

no explaination

=cut

=head2 sequences

no explaination

=cut

=head1 AUTHOR

Yuki Kimoto C<< <kimoto.yuki at gmail.com> >>

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


=head1 SEE ALSO

L<Plugger>, L<YAML>, L<XML::Simple>, L<Config::Tiny>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Yuki, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of App::Sequence
