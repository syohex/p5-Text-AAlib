package Text::AAlib::RenderParams;
use strict;
use warnings;

use Carp ();
use Scalar::Util qw(looks_like_number);

sub new {
    my ($class, %args) = @_;

    for my $param (qw/bright contrast gamma dither inversion/) {
        unless ($args{$param}) {
            Carp::croak("missing mandatory parameter '$param'");
        }

        unless (looks_like_number($args{$param})) {
            Carp::croak("'$param' parameter should be Int");
        }
    }

    unless ($args{bright} >= 0 && $args{bright} <= 255) {
        Carp::croak("'bright' parameter is 0..255");
    }

    unless ($args{contrast} >= 0 && $args{contrast} <= 127) {
        Carp::croak("'contrast' parameter is 0..127");
    }

    my $randomval;
    if ($randomval = delete $args{randomval}) {
        unless (looks_like_number($randomval)) {
            Carp::croak("'randomval' parameter should be Int");
        }
    } else {
        $randomval = 0;
    }

    bless {
        randomval => $randomval,
        %args,
    }, $class;
}

1;

__END__

=head1 NAME

Text::AAlib::RenderParams - Perl class of C<< struct aa_renderparams >>

=head1 SYNOPSIS

=head1 DESCRIPTION

Text::AAlib::RenderParams is

=head1 INTERFACES

=head2 Class Methods

=head3 C<< Text::AAlib::RenderParams->new(%arg) >>

I<%args> might be:

=over

=item bright :Int(0..255)

=item contrast :Int(0..127)

=item gamma :Float

=item dither:Enum{}

=item inversion

=back

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2011 - Syohei YOSHIDA

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
