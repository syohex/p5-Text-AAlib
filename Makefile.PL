use inc::Module::Install;
use Module::Install::AuthorTests;

name 'Text-AAlib';
all_from 'lib/Text/AAlib.pm';

author_tests('xt');
WriteAll;
