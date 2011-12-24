use strict;
use warnings;
use Test::More;

use Text::AAlib;
use Text::AAlib::RenderParams;
use Text::AAlib::Palette;

my $aa = Text::AAlib->new(
    width  => 100,
    height => 200,
);

my $rp = Text::AAlib::RenderParams->new(
    bright    => 1,
    contrast  => 1,
    gamma     => 0.5,
    dither    => 1,
    inversion => 1,
);

my $palette = Text::AAlib::Palette->new;

can_ok $aa, "renderpalette";

my @mandatory_params = qw/render_params palette/;
for my $param (@mandatory_params) {
    my @kyes = grep { $_ ne $param } @mandatory_params;
    my %args = map { $_ => 1 } @kyes;
    eval {
        $aa->renderpalette(%args);
    };
    like $@, qr/missing mandatory parameter/, "missing parameter '$param'";
}

eval {
    $aa->renderpalette(
        render_params => 1,
        palette => $palette,
    );
};
like $@, qr/should be is-a/, "invalid 'render_params' param";

eval {
    $aa->renderpalette(
        render_params => $rp,
        palette => 1,
    );
};
like $@, qr/should be is-a/, "invalid 'palette' param";

done_testing;
