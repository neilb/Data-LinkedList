# -*- perl -*-

# t/007_exceptions.t - test if we get exceptions at the appropriate time

use strict;
use warnings;
use Test::More tests => 19;
use Test::Exception;
use Data::LinkedList;
use Data::LinkedList::Iterator::ListIterator;
use Data::LinkedList::Iterator::DescendingIterator;

my $list = Data::LinkedList->new();
my $iterator = Data::LinkedList::Iterator::ListIterator->new(
    index => 0,
    list  => $list
);
my $desc_iterator = Data::LinkedList::Iterator::DescendingIterator->new(
    list => $list
);

# LinkedList exceptions
# No such element.
dies_ok sub { $list->get_first(); };
dies_ok sub { $list->get_last(); };
dies_ok sub { $list->remove_first(); };
dies_ok sub { $list->remove_last(); };

# Out of bounds.
dies_ok sub { $list->add_at_all(0, (1, 2, 3)); };
dies_ok sub { $list->get(0); };
dies_ok sub { $list->set(0, 1); };
dies_ok sub { $list->insert(1, 1); };
dies_ok sub { $list->remove_at(0); };


# Iterator exceptions
# Concurrent modification.
   $list->add(1);
dies_ok sub { $iterator->next(); };
dies_ok sub { $desc_iterator->next() };
   $list->clear();
# Iterator should be on position 0. next() and previous() should throw
# no such element; the list is empty.
ok $iterator->next_index() == 0;
dies_ok sub { $iterator->next(); };
dies_ok sub { $iterator->previous(); };
dies_ok sub { $desc_iterator->next(); };
dies_ok sub { $desc_iterator->previous(); };

# The iterator hasn't returned an element. The last_reurned property
# is still undefined; subroutine called at innappropriate time.
dies_ok sub { $iterator->remove(); };
dies_ok sub { $iterator->set(1); };
dies_ok sub { $desc_iterator->remove(); };
