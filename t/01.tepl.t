use strict;
use warnings;
use Test::Base tests => 7;
use Text::Tepl;

can_ok 'Text::Tepl', 'compose';
can_ok 'Text::Tepl', 'call';

ok ! eval {__PACKAGE__->can('compose') }, '! export compose';
ok ! eval {__PACKAGE__->can('call') }, '! export call';

Text::Tepl->import('compose', 'call');
can_ok __PACKAGE__, 'compose';
can_ok __PACKAGE__, 'call';

is Text::Tepl::call('<?pl: shift ?>', 'a'), 'a', 'call <?pl: shift ?>';

sub filter_ { return shift; }

