use strict;
use warnings;
use Test::More;

use Text::AAlib;

my $aa = Text::AAlib->new(
    file   => 'a.txt',
    width  => 100,
    height => 200,
);

can_ok $aa, "flush";

done_testing;
