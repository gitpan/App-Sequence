use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Sequence',
    license             => 'perl',
    dist_author         => 'Yuki <kimoto.yuki@gmail.com>',
    dist_version_from   => 'lib/App/Sequence.pm',
    build_requires => {
        'Test::More' => 0,
        'IO::Capture' => 0
    },
    requires => {
        'YAML' => 0,
        'Text::CSV' => 0,
        'Config::Tiny' => 0,
        'XML::Simple' => 0,
        'Object::Simple' => 2.1301,
        'JSON' => 2,
        'Encode' => 0
    },
    add_to_cleanup      => [ 'App-Sequence-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
