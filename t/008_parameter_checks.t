# -*- perl -*-

# t/008_parameter_checking.t - check parameter errors are thrown at an appropriate time

use strict;
use warnings;
use Test::More tests => 17;
use Data::LinkedList;
use Data::LinkedList::Iterator::ListIterator;

my $list = Data::LinkedList->new();

# All of these subroutines expect at least 2
# parameters (the object always being first).
ok not eval { $list->add_first(); };
ok not eval { $list->contains(); };
ok not eval { $list->remove(); };
ok not eval { $list->add_all(); };
ok not eval { $list->add_all_at(); };
ok not eval { $list->get(); };
ok not eval { $list->set(); };
ok not eval { $list->insert(); };
ok not eval { $list->remove_at(); };
ok not eval { $list->index_of(); };
ok not eval { $list->last_index_of(); };
ok not eval { $list->remove_last_occurrence(); };
ok not eval { $list->write_object(); };
ok not eval { $list->read_object(); };
ok not eval { $list->list_iterator(); };
ok not eval { $list->list_iterator(0)->add(); };
ok not eval { $list->list_iterator(0)->set(); };