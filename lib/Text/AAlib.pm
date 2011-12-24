package Text::AAlib;
use 5.008_001;

use strict;
use warnings;

use base qw/Exporter/;

use Carp ();
use POSIX ();
use Scalar::Util qw(looks_like_number blessed);
use Term::ANSIColor qw(:constants);

use XSLoader;

our $VERSION = '0.01';

our @EXPORT_OK = qw(
    AA_NONE
    AA_ERRORDISTRIB
    AA_FLOYD_S
    AA_DITHERTYPES

    AA_NORMAL
    AA_BOLD
    AA_DIM
    AA_BOLDFONT
    AA_REVERSE
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

XSLoader::load __PACKAGE__, $VERSION;

sub new {
    my ($class, %args) = @_;

    my $width;
    if (exists $args{width}) {
        $width = POSIX::ceil($args{width} / 2);
    }

    my $height;
    if (exists $args{height}) {
        $height = POSIX::ceil($args{height} / 2);
    }

    my $context = Text::AAlib::xs_init($width, $height);

    bless {
        _context    => $context,
        is_closed   => 0,
    }, $class;
}

sub _check_width {
    my ($self, $x) = @_;

    my $width = Text::AAlib::xs_render_width($self->{_context});
    unless ($x >= 0 && $x < $width) {
        Carp::croak("'x' param should be 0 <= x < $width");
    }
}

sub _check_height {
    my ($self, $y) = @_;

    my $height = Text::AAlib::xs_render_height($self->{_context});
    unless ($y >= 0 && $y < $height) {
        Carp::croak("'y' param should be 0 <= y < $height");
    }
}

sub putpixel {
    my ($self, %args) = @_;

    for my $param (qw/x y color/) {
        unless (exists $args{$param}) {
            Carp::croak("missing mandatory parameter '$param'");
        }

        unless (looks_like_number($args{$param})) {
            Carp::croak("'$param' parameter should be number");
        }
    }

    $self->_check_width($args{x});
    $self->_check_height($args{y});

    unless ($args{color} >= 0 && $args{color} <= 255) {
        Carp::croak("'color' parameter should be 0 <= color <= 255");
    }

    Text::AAlib::xs_putpixel($self->{_context},
                             $args{x}, $args{y}, $args{color});
}

sub _is_valid_attribute {
    my $attr = shift;

    my @attrs = (Text::AAlib::AA_NORMAL(), Text::AAlib::AA_BOLD(),
                 Text::AAlib::AA_DIM(), Text::AAlib::AA_BOLDFONT(),
                 Text::AAlib::AA_REVERSE());
    unless (grep { $attr == $_} @attrs) {
        Carp::croak("Invalid attribute(not 'enum aa_attribute')");
    }
}

sub _is_valid_dithering {
    my $mode = shift;

    my @ditherings = (Text::AAlib::AA_NONE(), Text::AAlib::AA_ERRORDISTRIB(),
                 Text::AAlib::AA_FLOYD_S(), Text::AAlib::AA_DITHERTYPES());
    unless (grep { $mode == $_} @ditherings) {
        Carp::croak("Invalid dithering mode(not 'enum aa_dithering_mode')");
    }
}

sub puts {
    my ($self, %args) = @_;

    for my $param (qw/x y string/) {
        unless (exists $args{$param}) {
            Carp::croak("missing mandatory parameter '$param'");
        }

        unless ($param eq 'string') {
            unless (looks_like_number($args{$param})) {
                Carp::croak("'$param' parameter should be number");
            }
        }
    }

    $self->_check_width($args{x});
    $self->_check_height($args{y});

    my $attr = delete $args{attribute} || Text::AAlib::AA_NONE();
    _is_valid_attribute($attr);

    Text::AAlib::xs_puts($self->{_context}, $args{x}, $args{y},
                         $attr, $args{string});
}

sub put_image {
    my ($self, %args) = @_;

    unless (exists $args{image}) {
        Carp::croak("missing mandatory parameter 'image'");
    }

    my $image = delete $args{image};
    unless (blessed $image && blessed $image eq 'Imager') {
        Carp::croak("Argument should be is-a Imager");
    }

    my $start_x = delete $args{start_x} || 0;
    my $start_y = delete $args{start_y} || 0;

    my ($img_width, $img_height)  = ($image->getwidth, $image->getheight);

    my $render_width  = Text::AAlib::xs_render_width($self->{_context});
    my $render_height = Text::AAlib::xs_render_height($self->{_context});

    my $end_x = $img_width > $render_width ? $img_width : $render_width;
    my $end_y = $img_height > $render_height ? $img_height : $render_height;

    for my $i ($start_x..($end_x-1)) {
        for my $j ($start_y..($end_y-1)) {
            my $color = $image->getpixel(x => $i, y => $j);
            my $value = int(($color->hsv)[2] * 255);

            Text::AAlib::xs_putpixel($self->{_context}, $i, $j, $value);
        }
    }
}

sub render {
    my ($self, %args) = @_;

    my $render_width  = Text::AAlib::xs_render_width($self->{_context});
    my $render_height = Text::AAlib::xs_render_width($self->{_context});

    my $render_param = Text::AAlib::xs_copy_default_parameter();
    for my $param (qw/bright contrast gamma dither inversion/) {
        if (exists $args{$param}) {
            $render_param->{$param} = $args{$param};
        }
    }

    _check_render_param($render_param);

    Text::AAlib::xs_render($self->{_context}, $render_param,
                           0, 0, $render_width, $render_height);

    my $text_ref = Text::AAlib::xs_text($self->{_context});
    my $attr_ref = Text::AAlib::xs_attrs($self->{_context});

    $self->{text} = $text_ref;
    $self->{attr} = $attr_ref;

    return $self->_buffer_to_string;
}

sub as_string {
    my ($self, $with_attr) = @_;

    if ($with_attr) {
        return $self->_buffer_to_string_with_attr;
    } else {
        return $self->_buffer_to_string;
    }
}

sub _buffer_to_string_with_attr {
    my $self = shift;

    my %aa_attrs;
    $aa_attrs{ Text::AAlib::AA_BOLD() }    = BOLD;
    $aa_attrs{ Text::AAlib::AA_DIM() }     = "\x1b[30;1m";
    $aa_attrs{ Text::AAlib::AA_REVERSE() } = REVERSE;

    my $width  = Text::AAlib::xs_render_width($self->{_context});
    my $height = Text::AAlib::xs_render_height($self->{_context});

    my ($text, $attr) = ($self->{text}, $self->{attr});
    my $str = '';
    for my $i (0..($width-1)) {
        for my $j (0..($height-1)) {
            my $c = chr $text->[$i]->[$j];
            my $attr = $attr->[$i]->[$j];
            if (exists $aa_attrs{$attr}) {
                $c = $aa_attrs{$attr} . $c . RESET;
            }
            $str .= $c;
        }
        $str .= "\n";
    }

    return $str;
}

sub _buffer_to_string {
    my $self = shift;

    my $str = '';
    for my $row (@{$self->{text}}) {
        for my $elm (@{$row}) {
            $str .= chr $elm;
        }
        $str .= "\n";
    }

    return $str;
}

sub _check_render_param {
    my $rp = shift;

    unless ($rp->{bright} >= 0 && $rp->{bright} <= 255) {
        Carp::croak("'bright' parameter is 0..255");
    }

    unless ($rp->{contrast} >= 0 && $rp->{contrast} <= 127) {
        Carp::croak("'contrast' parameter is 0..127");
    }
}

sub resize {
    my $self = shift;
    Text::AAlib::xs_resize($self->{_context});
}

sub flush {
    my $self = shift;

    Text::AAlib::xs_flush($self->{_context});
}

sub close {
    my $self = shift;

    Text::AAlib::xs_close($self->{_context});
    $self->{is_closed} = 1;
}

sub DESTROY {
    my $self = shift;

    unless ($self->{_context}) {
        Carp::croak("Not initialized");
    }

    unless ($self->{is_closed}) {
        Text::AAlib::xs_close($self->{_context});
    }
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

=head1 INTERFACE

=head2 Class Methods

=head3 C<< Text::AAlib->new(%args) >>

Creates and returns a new Text::AAlib instance.

C<%args> is:

=over

=item width :Int

Width of output file.

=item height :Int

Height of output file.

=back

=head2 Instance Methods

=head3 C<< $aalib->putpixel(%args) >>

=over

=item x :Int

x-coordinate of pixel. C<x> parameter should be 0 E<lt>= C<x> E<lt>= C<width>.
C<width> is parameter of constructor.

=item y :Int

y-coordinate of pixel. C<y> parameter should be 0 E<lt>= C<y> E<lt>= C<height>.
C<height> is parameter of constructor.

=item color :Int

Brightness of pixel. C<color> parameter should be 0 E<lt>= C<color> E<lt>= 255.

=back

=head3 C<< $aalib->puts(%args) >>

=over

=item x :Int

x-coordinate.

=item y :Int

y-coordinate

=item string :Str

=item attribute :Enum(enum aa_attribute)

Buffer attribute. This parameter should be AA_NORMAL, AA_BOLD, AA_DIM,
AA_BOLDFONT, AA_REVERSE.

=back

=head3 C<< $aalib->render(%args) :Str >>

Render buffer and return it as plain text.
You can specify render parameter following

=over

=item bright :Int

=item contrast :Int

=item gamma :Float

=item dither :Enum

=item inversion :Int

=back

=head3 C<< $aalib->as_string($with_attr) :Str >>

Return AA as string.
If C<$with_attr> is true, text attribute(BOLD, DIM REVERSE) is enable.

=head3 C<< $aalib->resize() >>

Resize buffers at runtime.

=head3 C<< $aalib->flush() >>

Flush buffers.

=head3 C<< $aalib->close() >>

Close AAlib context.

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2011- Syohei YOSHIDA

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://aa-project.sourceforge.net/aalib/>

L<http://jwilk.net/software/python-aalib>

=cut
