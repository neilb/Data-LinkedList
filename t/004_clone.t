# -*- perl -*-

# t/004_clone.t - test the cloning of a list

use strict;
use warnings;
use Test::More tests => 3;
use Data::LinkedList;

my $list = Data::LinkedList->new();
   $list->add_all(1, 2, 3, 4, 5);
my $clone = $list->clone();

ok join(' ', $clone->to_array()) eq join(' ', $list->to_array());
ok $list != $clone; $list->clear();
ok $list->size() != $clone->size(); $clone->clear();
