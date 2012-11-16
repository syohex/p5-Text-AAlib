use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::XSUtil;
use Module::Install::CheckLib;

name 'Text-AAlib';
all_from 'lib/Text/AAlib.pm';

checklibs lib => 'aa', header => 'aalib.h';

test_requires 'Test::More' => '0.88';

requires "Term::ANSIColor";
recommends "Imager" => '0.81';

cc_warnings;
cc_append_to_libs '-laa';

use_ppport 3.20;
cc_src_paths 'xs-src';

author_tests('xt');
WriteAll;
