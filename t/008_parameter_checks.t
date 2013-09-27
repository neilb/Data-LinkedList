# -*- perl -*-

# t/008_parameter_checking.t - check parameter errors are thrown at an appropriate time

use strict;
use warnings;
use Test::More tests => 17;
use Test::Exception;
use Data::LinkedList;
use Data::LinkedList::Iterator::ListIterator;

my $list = Data::LinkedList->new();

# All of these subroutines expect at least 2
# parameters (the invocant always being first).
dies_ok sub { $list->add_first(); };
dies_ok sub { $list->contains(); };
dies_ok sub { $list->remove(); };
dies_ok sub { $list->add_all(); };
dies_ok sub { $list->add_all_at(); };
dies_ok sub { $list->get(); };
dies_ok sub { $list->set(); };
dies_ok sub { $list->insert(); };
dies_ok sub { $list->remove_at(); };
dies_ok sub { $list->index_of(); };
dies_ok sub { $list->last_index_of(); };
dies_ok sub { $list->remove_last_occurrence(); };
dies_ok sub { $list->write_object(); };
dies_ok sub { $list->read_object(); };
dies_ok sub { $list->list_iterator(); };
dies_ok sub { $list->list_iterator(0)->add(); };
dies_ok sub { $list->list_iterator(0)->set(); };
