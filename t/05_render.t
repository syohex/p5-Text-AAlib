use strict;
use warnings;
use Test::More;

use Text::AAlib;
use Text::AAlib::RenderParams;

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

can_ok $aa, "render";

for my $key (qw/start_x start_y end_x end_y/) {
    eval {
        $aa->render(
            $key => $key,
            render_params => $rp,
        );
    };
    like $@, qr/parameter should be number/, "$key parameter is not number";
}

eval {
    $aa->render(
        start_x => 100,
        render_params => $rp,
    );
};
like $@, qr/'x' param should be/, "invalid start_x(>= width)";

eval {
    $aa->render(
        start_y => -1,
        render_params => $rp,
    );
};
like $@, qr/'y' param should be/, "invalid start_y(< 0)";

eval {
    $aa->render(
        start_y => 200,
        render_params => $rp,
    );
};
like $@, qr/'y' param should be/, "invalid start_y(>= height)";

eval {
    $aa->render(
        start_x => 5,
        end_x   => 1,
        render_params => $rp,
    );
};
like $@, qr/parameter less than/, "invalid rendering area(width)";

eval {
    $aa->render(
        start_y => 100,
        end_y   => 1,
        render_params => $rp,
    );
};
like $@, qr/parameter less than/, "invalid rendering area(height)";

{
    eval {
        $aa->render(
            start_y => 100,
            end_y   => 1,
        );
    };
    like $@, qr/Not specified 'render_params'/, "not specified render_params";
}

{
    eval {
        $aa->render(
            render_params => 10,
        );
    };
    like $@, qr/is-a Text::AAlib::RenderParams/, "invalid 'render_params' param";
}

done_testing;
