# -*- perl -*-

# t/007_exceptions.t - test if we get exceptions at the appropriate time

use strict;
use warnings;
use Test::More tests => 19;
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
ok not eval { $list->get_first(); };
ok not eval { $list->get_last(); };
ok not eval { $list->remove_first(); };
ok not eval { $list->remove_last(); };

# Out of bounds.
ok not eval { $list->add_at_all(0, (1, 2, 3)); };
ok not eval { $list->get(0); };
ok not eval { $list->set(0, 1); };
ok not eval { $list->insert(1, 1); };
ok not eval { $list->remove_at(0); };


# Iterator exceptions
# Concurrent modification.
   $list->add(1);
ok not eval { $iterator->next(); };
ok not eval {$desc_iterator->next() };
   $list->clear();
# Iterator should be on position 0. next() and previous() should throw 
# no such element; the list is empty.
ok $iterator->next_index() == 0;
ok not eval { $iterator->next(); };
ok not eval { $iterator->previous(); };
ok not eval { $desc_iterator->next(); };
ok not eval { $desc_iterator->previous(); };

# The iterator hasn't returned an element. The last_reurned property
# is still undefined; subroutine called at innappropriate time.
ok not eval { $iterator->remove(); };
ok not eval { $iterator->set(1); };
ok not eval { $desc_iterator->remove(); };