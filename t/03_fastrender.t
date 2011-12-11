use strict;
use warnings;
use Test::More;

use Text::AAlib;

my $aa = Text::AAlib->new(
    file   => 'a.txt',
    width  => 100,
    height => 200,
);

can_ok $aa, "fastrender";

for my $key (qw/start_x start_y end_x end_y/) {
    eval {
        $aa->fastrender(
            $key => $key,
        );
    };
    like $@, qr/parameter should be number/, "$key parameter is not number";
}

eval {
    $aa->fastrender(
        start_x => 100,
    );
};
like $@, qr/'x' param should be/, "invalid start_x(>= width)";

eval {
    $aa->fastrender(
        start_y => -1,
    );
};
like $@, qr/'y' param should be/, "invalid start_y(< 0)";

eval {
    $aa->fastrender(
        start_y => 200,
    );
};
like $@, qr/'y' param should be/, "invalid start_y(>= height)";

eval {
    $aa->fastrender(
        start_x => 5,
        end_x   => 1,
    );
};
like $@, qr/parameter less than/, "invalid rendering area(width)";

eval {
    $aa->fastrender(
        start_y => 100,
        end_y   => 1,
    );
};
like $@, qr/parameter less than/, "invalid rendering area(height)";

done_testing;
