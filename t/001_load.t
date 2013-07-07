# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use strict;
use warnings;
use Test::More tests => 10;

BEGIN {
    use_ok 'Data::LinkedList'; 
    use_ok 'Data::LinkedList::Entry'; 
    use_ok 'Data::LinkedList::Iterator::ListIterator'; 
    use_ok 'Data::LinkedList::Iterator::DescendingIterator'; 
}

my $list = Data::LinkedList->new();
my $entry = Data::LinkedList::Entry->new();

isa_ok $list, 'Data::LinkedList';
isa_ok $entry, 'Data::LinkedList::Entry';
isa_ok $list->list_iterator(0), 'Data::LinkedList::Iterator::ListIterator';
isa_ok $list->descending_iterator(), 'Data::LinkedList::Iterator::DescendingIterator';

ok $list->size() == 0;
ok $list->list_iterator(0)->next_index() == 0;