package Text::AAlib::Palette;
use strict;
use warnings;

use Carp ();

use Text::AAlib;

sub new {
    my $class = shift;

    my $palette = Text::AAlib::xs_palette_init();
    bless \$palette, $class;
}

sub set {
    my ($self, %args) = @_;

    for my $param (qw/index r g b/) {
        unless (exists $args{$param}) {
            Carp::croak("missing mandatory parameter '$param'");
        }

        my $val = $args{$param};
        unless ($val >= 0 && $val <= 255) {
            Carp::croak("Invalid index($val). (0 <= $param <= 255)");
        }
    }

    Text::AAlib::xs_set_palette($$self, $args{index}, $args{r}, $args{g}, $args{b});
}

# for debugging
sub get {
    my ($self, $index) = @_;
    return Text::AAlib::xs_get_palette($$self, $index);
}

sub DESTROY {
    my $self = shift;
    Text::AAlib::xs_palette_DESTROY($$self);
}

1;

__END__
