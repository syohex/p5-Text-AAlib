use strict;
use warnings;
use Test::More;

use Text::AAlib::Palette;

my $palette = Text::AAlib::Palette->new;
ok($palette);
isa_ok($palette, 'Text::AAlib::Palette');

can_ok($palette, 'set');
eval {
    $palette->set(index => 0, r => 1, b => 255, g => 254);
};
ok !$@, 'success calling set method';

my @params = qw/index r b g/;
for my $param (@params) {
    my @args = map { $_ => 0 } grep { $_ ne $param } @params;
    eval {
        $palette->set(@args);
    };
    like $@, qr/missing mandatory parameter/, "missing parameter $param";
}

for my $param (@params) {
    my @args = map {
        do {
            if ($_ ne $param) {
                ($_ => 0);
            } else {
                ($_ => -1);
            }
        };
    } @params;
    eval {
        $palette->set(@args);
    };
    like $@, qr/Invalid index/, "Invalid index $param(< 0)";

    @args = map {
        do {
            if ($_ ne $param) {
                ($_ => 0);
            } else {
                ($_ => 256);
            }
        };
    } @params;
    eval {
        $palette->set(@args);
    };
    like $@, qr/Invalid index/, "Invalid index $param(> 255)";
}

done_testing;
