package Text::AAlib;
use 5.008_001;

use strict;
use warnings;

use base qw/Exporter/;

use Carp ();
use POSIX ();
use Scalar::Util qw(looks_like_number blessed);

use XSLoader;

use Text::AAlib::RenderParams;

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

    unless (exists $args{file}) {
        Carp::croak("missing mandatory parameter 'file'");
    }

    my $width;
    if (exists $args{width}) {
        $width = POSIX::ceil($args{width} / 2);
    }

    my $height;
    if (exists $args{height}) {
        $height = POSIX::ceil($args{height} / 2);
    }

    my $context = Text::AAlib::xs_init($args{file}, $width, $height);

    bless {
        _xs_aa_info => $context,
        width       => $args{width},
        height      => $args{height},
        is_rendered => 0,
        is_flushed  => 0,
        is_closed   => 0,
    }, $class;
}

sub _check_width {
    my ($self, $x) = @_;

    unless ($x >= 0 && $x < $self->{width}) {
        Carp::croak("'x' param should be 0 <= x < $self->{width}");
    }
}

sub _check_height {
    my ($self, $y) = @_;

    unless ($y >= 0 && $y < $self->{height}) {
        Carp::croak("'y' param should be 0 <= y < $self->{height}");
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

    Text::AAlib::xs_putpixel($self->{_xs_aa_info},
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

    Text::AAlib::xs_puts($self->{_xs_aa_info}, $args{x}, $args{y},
                         $attr, $args{string});
}

sub _check_render_area {
    my ($self, %args) = @_;

    for my $param (qw/start_x start_y end_x end_y/) {
        if ($param eq 'end_x' || $param eq 'end_y') {
            next unless exists $args{$param};
        }

        unless (looks_like_number($args{$param})) {
            Carp::croak("'$param' parameter should be number");
        }

        if ($param =~ m/_x$/) {
            $self->_check_width($args{$param});
        } else {
            $self->_check_height($args{$param});
        }
    }

    for my $p (qw/x y/) {
        my ($start, $end) = map { $_ . $p } qw/start_ end_/;
        if (defined $args{$start} && defined $args{$end}) {
            if ($args{$start} > $args{$end}) {
                Carp::croak("'$end' parameter less than '$start' parameter");
            }
        }
    }
}

sub fastrender {
    my ($self, %args) = @_;

    $args{start_x} ||= 0;
    $args{start_y} ||= 0;

    $self->_check_render_area(%args);

    Text::AAlib::xs_fastrender($self->{_xs_aa_info},
                               $args{start_x}, $args{start_y},
                               $args{end_x}, $args{end_y});
}

sub render {
    my ($self, %args) = @_;

    unless (exists $args{render_params}) {
        Carp::croak("Not specified 'render_params' parameter");
    }

    $args{start_x} ||= 0;
    $args{start_y} ||= 0;

    $self->_check_render_area(%args);

    unless (blessed $args{render_params}
            && blessed $args{render_params} eq 'Text::AAlib::RenderParams') {
        Carp::croak("'render_params' parameter should be"
                    . "is-a Text::AAlib::RenderParams");
    }

    Text::AAlib::xs_render($self->{_xs_aa_info}, $args{render_params},
                           $args{start_x}, $args{start_y},
                           $args{end_x}, $args{end_y});
}

sub resize {
    my $self = shift;
    Text::AAlib::xs_resize($self->{_xs_aa_info});
}

sub flush {
    my $self = shift;

    Text::AAlib::xs_flush($self->{_xs_aa_info});
    $self->{is_flushed} = 1;
}

sub close {
    my $self = shift;

    Text::AAlib::xs_close($self->{_xs_aa_info});
    $self->{is_closed} = 1;
}

sub DESTROY {
    my $self = shift;

    if ($self->{is_rendered} == 1) {
        Text::AAlib::xs_flush($self->{_xs_aa_info}) unless $self->{is_flushed};
        Text::AAlib::xs_close($self->{_xs_aa_info}) unless $self->{is_closed};
    }

    Text::AAlib::xs_DESTROY($self->{_xs_aa_info});
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

=item file :Str

Output file name.

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

=head3 C<< $aalib->fastrender(%args) >>

=over

=item start_x :Int = 0

=item start_y :Int = 0

=item end_x :Int = I<width of output>

=item end_y :Int = I<height of output>

=back

=head3 C<< $aalib->render(%args) >>

=over

=item start_x :Int = 0

=item start_y :Int = 0

=item end_x :Int = I<width of output>

=item end_y :Int = I<height of output>

=item render_params :Text::AAlib::RenderParams

Please see L<Text::AAlib::RenderParams>

=back

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

=cut
