package Text::AAlib;
use 5.008_001;

use strict;
use warnings;

use Carp ();
use POSIX ();
use Scalar::Util qw(looks_like_number blessed);

use XSLoader;

use Text::AAlib::RenderParams;

our $VERSION = '0.01';

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

    my $attr_str = delete $args{attribute} || 'none';
    $attr_str = lc $attr_str;

    my $attr;
    if ($attr_str eq 'none') {
        $attr = Text::AAlib::AA_NONE();
    } elsif ($attr_str eq 'errordistrib') {
        $attr = Text::AAlib::AA_DITHERTYPES();
    } elsif ($attr_str eq 'floyd_s') {
        $attr = Text::AAlib::AA_FLOYD_S();
    } else {
        my $options = "'none' or 'errordistrib' or 'floyd_s'";
        Carp::croak("'attribute' parameter should be $options");
    }

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

=head2 Instance Methods

=head3 C<< $aalib->putpixel(%args) >>

=head3 C<< $aalib->puts(%args) >>

=head3 C<< $aalib->fastrender(%args) >>

=head3 C<< $aalib->render(%args) >>

=head3 C<< $aalib->flush(%args) >>

=head3 C<< $aalib->close(%args) >>

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
