package builder::MyBuilder;
use strict;
use warnings;
use 5.008001;
use base 'Module::Build::XSUtil';
use Devel::CheckLib;

Devel::CheckLib::check_lib_or_exit(lib => ['aa'], header => ['aalib.h']);

sub new {
    my ( $class, %args ) = @_;
    my $self = $class->SUPER::new(
        %args,
        c_source => 'xs-src',
        xs_files => {
            './xs-src/AAlib.xs' => './lib/Text/AAlib.xs',
        },
        generate_ppport_h  => 'lib/Text/ppport.h',
        needs_compiler_c99 => 1,
        extra_linker_flags => ['-laa'],
    );
    return $self;
}

1;

