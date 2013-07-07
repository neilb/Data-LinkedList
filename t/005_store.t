# -*- perl -*-

# t/005_store.t - tests for writing and reading the list object

use strict;
use warnings;
use Test::More tests => 2;
use Data::LinkedList;

my $list = Data::LinkedList->new();
my @collection = (1, 2, 3, 4, 5);

# Just have a quick cleanup first.
   unlink 'data.txt' if -e 'data.txt';

ok $list->write_object('data.txt');
my $clone = $list->clone();
   $list->read_object('data.txt');

# Clean up after also.
   unlink 'data.txt' if -e 'data.txt';
   
# To test that the file written was the same as the one
# read we have to place the elements which we have been 
# written into the clone of the list (parentheses needed).
ok join(' ', (($clone->to_array()) x 2)) eq join(' ', $list->to_array());
   $list->clear();