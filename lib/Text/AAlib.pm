package Text::AAlib;
use 5.008_001;

use strict;
use warnings;

use POSIX qw();

use XSLoader;

our $VERSION = '0.01';

XSLoader::load __PACKAGE__, $VERSION;

sub new {
    my ($class, $file, $opt) = @_;

    my $width;
    if (exists $opt->{width}) {
        $width = POSIX::ceil($opt->{width} / 2);
    }

    my $height;
    if (exists $opt->{height}) {
        $height = POSIX::ceil($opt->{height} / 2);
    }

    return $class->_new($file, $width, $height);
}

sub putpixel {
    my ($self, $x, $y, $color) = @_;

    die "Can't specified 'x' parameter" unless defined $x;
    die "Can't specified 'y' parameter" unless defined $y;
    die "Can't specified 'color' parameter" unless defined $color;

    $self->_putpixel($x, $y, int($color * 256));
}

sub fastrender {
    my ($self, $x1, $y1, $x2, $y2) = @_;

    $x1 ||= 0;
    $y1 ||= 0;

    $self->_fastrender($x1, $y1, $x2, $y2);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Text::AAlib - Perl Binding for AAlib

=head1 SYNOPSIS

  use Text::AAlib;

=head1 DESCRIPTION

Text::AAlib is perl binding for AAlib. AAlib is a library for creating
ascii art(AA).

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2011- Syohei YOSHIDA

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://aa-project.sourceforge.net/aalib/>

=cut
