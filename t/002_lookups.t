# -*- perl -*-

# t/003_lookups.t - test list lookup subs

use strict;
use warnings;
use Test::More tests => 10;
use Data::LinkedList;

my $list = Data::LinkedList->new();
my @collection = (1, 2, 3);

# Retrieving an element from the list
   $list->add(1);
   $list->add(2);
   $list->add(3);
ok $list->get(0) eq 1;
ok $list->get($list->size() - 1) eq 3;
   $list->clear();

# Looking for an element within the list
   $list->add(1);
   $list->add(2);
   $list->add(3);
ok $list->contains(2);
   $list->clear();

# Looking up the index of a given element
   $list->add_all(@collection);
   $list->add(3);
ok $list->index_of(3) eq 2;
ok $list->last_index_of(3) eq 3;
   $list->clear();

# Looking up the first element of the list
   $list->add(1);
   $list->add(2);
ok $list->get_first() eq 1;
   $list->clear();

# Ensure peek() and peek_last() return undef if
# the list if empty.
ok not defined $list->peek();
ok not defined $list->peek_last();

# Looking up the last elements of the list
   $list->add(3);
ok $list->peek_last() eq 3;
ok $list->get_last() eq 3;
   $list->clear();
