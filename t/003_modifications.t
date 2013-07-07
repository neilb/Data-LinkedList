# -*- perl -*-

# t/003_modifications.t - test list modification subs

use strict;
use warnings;
use Test::More tests => 23;
use Data::LinkedList; 

my $list = Data::LinkedList->new();
my @collection = (1, 2, 3);

# Adding an element to the list
   $list->add('element');
ok $list->contains('element');

# Removing an element from the list
ok $list->remove('element');
ok not $list->contains('element');

# Modifying the first and last elements
# in the list.
   $list->add(2);
   $list->add_first(1);
   $list->add_last(3);
ok $list->get_first() eq 1;
ok $list->get_last() eq 3;
ok $list->remove_first() eq 1;
ok $list->remove_last() eq 3;
   $list->clear();
   
# Adding collections to the list
   $list->add_all(@collection);
ok $list->get_first() eq 1;
ok $list->get_last() eq 3;
   $list->add_all_at(1, @collection);
ok $list->get(1) eq 1;
ok $list->get(3) eq 3;
ok $list->get_first() eq 1;
ok $list->get_last() eq 3;
   $list->clear();
   
# Setting the value of an existing entry
   $list->add('element');
ok $list->set(0, 'replaced element') eq 'element';
ok $list->remove_first() eq 'replaced element';

# Inserting an element into the list
   $list->add(1);
   $list->add(3);
   $list->insert(1, 2);
ok $list->get_first() eq 1;
ok $list->get(1) eq 2;
ok $list->get_last() eq 3;
   $list->clear();
   
# Removing an element by its index
   $list->add_all(@collection);
ok $list->remove_at(1) eq 2;

# Removing the last occurrence of an element.
# No need to test the removal of the first
# element, the code is the same as the remove sub.
# The list hasn't been cleared yet, so this test
# is using working with the same elements as above.
   $list->add_last(3);
   $list->remove_last_occurrence(3);
ok $list->get(0) eq 1;
ok $list->get(1) eq 3;
   $list->clear();
   
# Ensure poll() and poll_last() return undef if
# the list is empty.
ok not defined $list->poll();
ok not defined $list->poll_last();