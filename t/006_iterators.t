# -*- perl -*-

# t/006_iterators.t - test our iterators

use strict;
use warnings;
use Test::More tests => 17;
use Data::LinkedList;

my $list = Data::LinkedList->new();
   $list->add_all((1, 2, 3, 4, 5));
my $iterator = $list->list_iterator(0);

# Check position is correct.
ok $iterator->next_index() == 0;
ok $iterator->previous_index() == -1;

# Check next() returns correct element.
ok $iterator->has_next();
ok not $iterator->has_previous();
ok $iterator->next() eq 1;

# Make sure positions are updated.
ok $iterator->next_index() == 1;
ok $iterator->previous_index() == 0;

# We should now have a previous element.
ok $iterator->has_previous();
ok $iterator->previous();

# Make sure we're able to remove the current
# element.
   $iterator->next();
   $iterator->remove();
ok $iterator->next_index() == 0;
ok $iterator->next() eq 2;
   $iterator->previous();

# Add an element.
   $iterator->add(1);
ok $iterator->has_previous();
ok $iterator->previous() eq 1;


# Setting the element that was last returned.
   $iterator->set(0);
ok $iterator->next() eq 0;
   $iterator = undef;

# Descending iterator. Need to test this after
# to avoid any concurrent modifications.
my $desc_iterator = $list->descending_iterator();
ok $desc_iterator->has_next();
ok $desc_iterator->next() eq 5;
   $desc_iterator->next();
   $desc_iterator->remove();
ok $desc_iterator->next() eq 3;
