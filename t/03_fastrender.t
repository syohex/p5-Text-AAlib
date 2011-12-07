use strict;
use warnings;
use Test::More;

use Text::AAlib;

my $aa = Text::AAlib->new(
    file   => 'a.txt',
    width  => 100,
    height => 100,
);

can_ok $aa, "fastrender";

eval {
    $aa->fastrender(
        start_x => 'aaa',
    );
};
like $@, qr/parameter should be number/, "parameter is not number";

done_testing;
