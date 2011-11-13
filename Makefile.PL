use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::XSUtil;

name 'Text-AAlib';
all_from 'lib/Text/AAlib.pm';

test_requires 'Test::More' => '0.88';

cc_warnings;
cc_append_to_libs '-laa';

use_ppport 3.20;
cc_src_paths 'xs-src';

author_tests('xt');
WriteAll;
