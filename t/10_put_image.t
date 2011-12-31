use strict;
use warnings;

use Test::More;
use Text::AAlib;

my $aa = Text::AAlib->new(
    width  => 100,
    height => 100,
);

can_ok $aa, "put_image";

eval {
    $aa->put_image;
};
like $@, qr/missing mandatory parameter/, "missing 'image' parameter";

eval {
    $aa->put_image(image => 10);
};
like $@, qr/should be is-a Imager/, "invalid 'image' parameter";

eval {
    $aa->put_image(image => );
};
like $@, qr/should be is-a Imager/, "invalid 'image' parameter";

done_testing;
