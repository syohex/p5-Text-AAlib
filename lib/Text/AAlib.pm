package Text::AAlib;
use 5.008_001;

use strict;
use warnings;

use Carp ();
use POSIX ();

use XSLoader;

use Text::AAlib::RenderParams;

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

    my $context = Text::AAlib::xs_init($file, $width, $height);

    bless {
        _context    => $context,
        is_rendered => 0,
        is_flushed  => 0,
        is_closed   => 0,
    }, $class;
}

sub putpixel {
    my ($self, %args) = @_;

    for my $param (qw/x y color/) {
        unless (exists $args{$param}) {
            Carp::croak("missing mandatory parameter '$param'");
        }

        unless (looks_like_number($args{$param})) {
            Carp::croak("'$param' parameter shou be Number");
        }
    }

    my $color = ($args{color} * 256);
    Text::AAlib::xs_putpixel($self->{_context}, $args{x}, $args{y}, $color);
}

sub puts {
    my ($self, %args) = @_;

    for my $param (qw/x y string/) {
        unless (exists $args{$param}) {
            Carp::croak("missing mandatory parameter '$param'");
        }
    }

    my $attr = delete $args{attribute} || 'normal';

    Text::AAlib::xs_puts($self->{_context}, $args{x}, $args{y},
                         $attr, $args{string});
}

sub fastrender {
    my ($self, %args) = @_;

    for my $param (qw/end_x end_y/) {
        unless (exists $args{$param}) {
            Carp::croak("missing mandatory parameter '$param'");
        }
    }

    $args{start_x} ||= 0;
    $args{start_y} ||= 0;

    for my $param (qw/start_x start_y end_x end_y/) {
        unless (looks_like_number($args{$param})) {
            Carp::croak("'$param' parameter should be number");
        }
    }

    Text::AAlib::xs_fastrender($self->{_context},
                               $args{start_x}, $args{start_y},
                               $args{end_x}, $args{end_y});
}

sub flush {
    my $self = shift;

    Text::AAlib::_flush($self->{_context});
    $self->{is_flushed} = 1;
}

sub close {
    my $self = shift;

    Text::AAlib::xs_close($self->{_context});
    $self->{is_closed} = 1;
}

sub DESTROY {
    my $self = shift;

    if ($self->{is_rendered} == 1) {
        Text::AAlib::xs_flush($self->{_context}) unless $self->{is_flushed};
        Text::AAlib::xs_close($self->{_context}) unless $self->{is_closed};
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

=head2 Instance Methods

=head3 C<< $aalib->putpixel(%args) >>

=head3 C<< $aalib->puts(%args) >>

=head3 C<< $aalib->fastrender(%args) >>

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
