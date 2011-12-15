package Text::AAlib::Palette;
use strict;
use warnings;

use Carp ();

sub new {
    my $class = shift;
    bless [], $class;
}

sub set {
    my ($self, $index, $r, $g, $b) = @_;

    unless ($index >= 0 && $index <= 255) {
        Carp::croak("Invalid index($index). (0 <= index <= 255)");
    }

    $self->[$index] = ($r * 30 + $g * 59 + $b * 11) >> 8;
}

1;

__END__
