use strict;
use warnings;
use Test::More;

use Text::AAlib;
use Text::AAlib::RenderParams;

my $renderparam = Text::AAlib::RenderParams->new(
    bright    => 1,
    contrast  => 1,
    gamma     => 1,
    dither    => 1,
    inversion => 1,
);
ok $renderparam, 'Text::AAlib::RenderParams constructor';

my @PARAMS = qw/bright contrast gamma dither inversion/;
for my $param (@PARAMS) {
    is $renderparam->{$param}, 1, "set '$param' parameter";
}
is $renderparam->{randomval}, 0, "set default 'randomval' parameter";

for my $param (@PARAMS) {
    my %args = map { $_ => 1 } grep { $_ ne $param } @PARAMS;
    eval {
        my $renderparam = Text::AAlib::RenderParams->new(%args);
    };
    like $@, qr/missing mandatory parameter/, "missing '$param' parameter";
}

for my $param (@PARAMS, 'randomval') {
    my %args = map { $_ => 1 } grep { $_ ne $param } @PARAMS;
    $args{$param} = 'aaa';
    eval {
        my $renderparam = Text::AAlib::RenderParams->new(%args);
    };
    like $@, qr/should be number/, "invalid '$param' parameter type";
}

{
    my %args = map { $_ => 1 } @PARAMS;
    eval {
        $args{bright} = 256;
        my $renderparam = Text::AAlib::RenderParams->new(%args);
    };
    like $@, qr/parameter is 0..255/, 'invalid bright parameter1';

    eval {
        $args{bright} = -1;
        my $renderparam = Text::AAlib::RenderParams->new(%args);
    };
    like $@, qr/parameter is 0..255/, 'invalid bright parameter2';
}

{
    my %args = map { $_ => 1 } @PARAMS;
    eval {
        $args{contrast} = 128;
        my $renderparam = Text::AAlib::RenderParams->new(%args);
    };
    like $@, qr/parameter is 0..127/, 'invalid bright parameter1';

    eval {
        $args{contrast} = -1;
        my $renderparam = Text::AAlib::RenderParams->new(%args);
    };
    like $@, qr/parameter is 0..127/, 'invalid bright parameter2';
}

done_testing;
