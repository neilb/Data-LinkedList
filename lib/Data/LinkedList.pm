package Data::LinkedList;

use strict;
use warnings;

use Carp;
use Storable;
use Iterator::Util;
use Data::LinkedList::Entry;
use Data::LinkedList::Iterator::ListIterator;
use Data::LinkedList::Iterator::DescendingIterator;

our $VERSION = '0.01';

sub new {
    return bless {
        first     => undef,
        last      => undef,
        size      => 0,
        mod_count => 0,
    }, shift;
}

sub __get_entry {
    my ($self, $number, $entry) = (shift, shift, undef);

    # We can work out if we should traverse the list
    # from the beginning or end depending on the
    # element number
    if ($number < ($self->{size} / 2)) {
        $entry = $self->{first};
        $entry = $entry->{next} while $number-- > 0;
    } else {
        $entry = $self->{last};
        $entry = $entry->{previous} while ++$number < $self->{size};
    }

    return $entry;
}

sub __remove_entry {
    my ($self, $entry) = @_;

    $self->{mod_count}++;
    $self->{size}--;

    if ($self->{size} == 0) {
        # Undefine the first element in the list
        $self->{first} = $self->{last} = undef;
    } elsif ($entry == $self->{first}) {
        # Reassign the first entry to the next in the list
        $self->{first} = $entry->{next};
        # Undefine the reference to the previous entry
        # which was the previous first entry
        $entry->{next}->{previous} = undef;
    } elsif ($entry == $self->{last}) {
        # Reassign the last entry to the previous in the list
        $self->{last} = $entry->{previous};
        # Undefine the reference to the next entry which
        # was the previous last entry
        $entry->{previous}->{next} = undef;
    } else {
        # Reassign the previous of the next entry to this previous entry
        $entry->{next}->{previous} = $entry->{previous};
        # Reassign the next of the previous entry to this next entry
        $entry->{previous}->{next} = $entry->{next};
    }
}

sub __add_last_entry {
    my ($self, $entry) = @_;

    if ($self->{size} == 0) {
        # Assign the entry to the first and last entries
        $self->{first} = $self->{last} = $entry;
    } else {
        # Assign the current last entry as the entry before
        # the new entry
        $entry->{previous} = $self->{last};
        # Assign the new entry to the last entry in the list
        $self->{last}->{next} = $entry;
        $self->{last} = $entry;
    }

    $self->{size}++;
}

sub __check_bounds_inclusive {
    my ($self, $index) = @_;

    croak(qq(
        Index out of bounds: The index provided was out of range.
        Index: $index Size: $self->{size}
    )) if ($index < 0) or ($index > $self->{size});
}

sub __check_bounds_exclusive {
    my ($self, $index) = @_;

    croak(qq(
        Index out of bounds: The index provided was out of range.
        Index: $index Size: $self->{size}
    )) if ($index < 0) or ($index >= $self->{size});
}

sub __check_parameter_count {
    my ($self, $expected, $actual) = @_;

    croak(qq(
        Expected $expected parameters but got $actual
    )) if $actual < $expected;
}

sub get_first {
    my $self = shift;

    ($self->{size} == 0)
        ? croak 'No such element in list.'
        : return $self->{first}->{data};
}

sub get_last {
    my $self = shift;

    ($self->{size} == 0)
        ? croak 'No such element in list.'
        : return $self->{last}->{data};
}

sub remove_first {
    my $self = shift;

    croak 'No such element in list.' if $self->{size} == 0;

    my $removed = $self->{first}->{data};
    $self->{mod_count}++;
    $self->{size}--;

    (defined $self->{first}->{next})
        ? $self->{first}->{next}->{previous} = undef
        : $self->{last} = undef;

    $self->{first} = $self->{first}->{next};
    return $removed;
}

sub remove_last {
    my $self = shift;

    croak 'No such element in list.' if $self->{size} == 0;

    my $removed = $self->{last}->{data};
    $self->{mod_count}++;
    $self->{size}--;

    (defined $self->{last}->{previous})
        ? $self->{last}->{previous}->{next} = undef
        : $self->{first} = undef;

    $self->{last} = $self->{last}->{previous};
    return $removed;
}

sub add_first {
    my ($self, $element) = @_;

    $self->__check_parameter_count(2, scalar @_);
    my $entry = Data::LinkedList::Entry->new(data => $element);

    if ($self->{size} == 0) {
        $self->{first} = $self->{last} = $entry;
    } else {
        $entry->{next} = $self->{first};
        $self->{first}->{previous} = $entry;
        $self->{first} = $entry;
    }

    $self->{mod_count}++;
    $self->{size}++;
}

sub add_last {
    shift->__add_last_entry(
        Data::LinkedList::Entry->new(data => shift)
    );
}

sub contains {
    my ($self, $element) = @_;

    $self->__check_parameter_count(2, scalar @_);
    my $entry = $self->{first};

    while (defined $entry) {
        if ($element eq $entry->{data}) {
            return 1;
        } else {
            $entry = $entry->{next};
        }
    }

    return 0;
}

sub size {
    return shift->{size};
}

sub add {
    shift->__add_last_entry(
        Data::LinkedList::Entry->new(data => shift)
    );
}

sub remove {
    my ($self, $element) = @_;

    $self->__check_parameter_count(2, scalar @_);
    my $entry = $self->{first};

    while (defined $entry) {
        if ($element eq $entry->{data}) {
            $self->__remove_entry($entry);
            return 1;
        } else {
            $entry = $entry->{next};
        }
    }

    return 0;
}

sub add_all {
    my ($self, @array) = @_;

    $self->__check_parameter_count(2, scalar @_);
    return $self->add_all_at($self->{size}, @array);
}

sub add_all_at {
    my ($self, $index, @array) = @_;

    $self->__check_parameter_count(3, scalar @_);
    $self->__check_bounds_inclusive($index);

    my $size = scalar @array;
    return 0 if $size == 0;

    my ($iterator, $after, $before) = (
        Iterator::Util::ilist(@array), undef, undef
    );

    if ($index != $self->{size}) {
        # The index is not the same as the last element in the list
        # so we need to get the element which will go after the inserted
        # elements
        $after = $self->__get_entry($index);
        # The element which will be before the inserted elements
        $before = $after->{previous};
    } else {
        # The elements are being inserted at the end of the list so
        # we get the current element that is at the end of the list
        $before = $self->{last};
    }

    # Create a new entry with the data of the first element to add
    my $entry = Data::LinkedList::Entry->new(data => $iterator->value());
    my ($previous, $first_new) = ($entry, $entry);

    # Set the previous entry of the new entry to the element that it is
    # being inserted after
    $entry->{previous} = $before;

    for (my $position = 1; ($position < $size); $position++) {
        # Link each of the elements that are in the array
        $entry = Data::LinkedList::Entry->new(data => $iterator->value());
        $entry->{previous} = $previous;
        $previous->{next} = $entry;
        $previous = $entry;
    }

    # Link the remaing elements of the list to the last new entry of the list
    $previous->{next} = $after;

    $self->{mod_count}++;
    $self->{size} += $size;

    (defined $after)
        # Link the elements which follow the newly added array
        ? $after->{previous} = $entry
        # Otherwise the lastest entry is the last in the list
        : $self->{last} = $entry;

    (defined $before)
        # Link the element before the array to the first element
        # in the array
        ? $before->{next} = $first_new
        # Otherwise the first element in the list is the first element
        # in the array
        : $self->{first} = $first_new;

    return 1;
}

sub clear {
    my $self = shift;

    if ($self->{size} > 0) {
        $self->{first} = undef;
        $self->{last} = undef;
        $self->{mod_count}++;
        $self->{size} = 0;
    }
}

sub get {
    my ($self, $index) = @_;

    $self->__check_parameter_count(2, scalar @_);
    $self->__check_bounds_exclusive($index);
    return $self->__get_entry($index)->{data};
}

sub set {
    my ($self, $index, $element) = @_;

    $self->__check_parameter_count(3, scalar @_);
    $self->__check_bounds_exclusive($index);

    my $entry = $self->__get_entry($index);
    my $old = $entry->{data};
    $entry->{data} = $element;
    return $old;
}

sub insert {
    my ($self, $index, $element) = @_;

    $self->__check_parameter_count(3, scalar @_);
    $self->__check_bounds_inclusive($index);
    my $entry = Data::LinkedList::Entry->new(data => $element);

    if ($index < $self->{size}) {
        # Store the element that will follow the inserted element
        my $after = $self->__get_entry($index);

        # Link the following entry to the new entry
        $entry->{next} = $after;
        # Set the previous entry for the new entry
        $entry->{previous} = $after->{previous};
        $self->{mod_count}++;

        (not defined $after->{previous})
            # If there is no previous element assign
            # the entry as the first in the list
            ? $self->{first} = $entry
            # Otherwise set the next entry of the previous
            # to the new entry
            : $after->{previous}->{next} = $entry;

        $after->{previous}->{next} = $entry;
        $after->{previous} = $entry;
        $self->{size}++;
    } else {
        $self->__add_last_entry($entry);
    }
}

sub remove_at {
    my ($self, $index) = @_;

    $self->__check_parameter_count(2, scalar @_);
    $self->__check_bounds_exclusive($index);

    my $entry = $self->__get_entry($index);
    $self->__remove_entry($entry);
    return $entry->{data};
}

sub index_of {
    my ($self, $element) = @_;

    $self->__check_parameter_count(2, scalar @_);
    my ($index, $entry) = (0, $self->{first});

    while (defined $entry) {
        if ($element eq $entry->{data}) {
            return $index;
        } else {
            $index++;
            $entry = $entry->{next};
        }
    }

    return -1;
}

sub last_index_of {
    my ($self, $element) = @_;

    $self->__check_parameter_count(2, scalar @_);
    my ($index, $entry) = (($self->{size} - 1), $self->{last});

    while (defined $entry) {
        if ($element eq $entry->{data}) {
            return $index;
        } else {
            $index--;
            $entry = $entry->{previous};
        }
    }

    return -1;
}

sub to_array {
    my $self = shift;
    my ($entry, @array) = ($self->{first}, ());

    for (my $i = 0; ($i < $self->{size}); $i++) {
        $array[$i] = $entry->{data};
        $entry = $entry->{next};
    }

    return @array;
}

sub offer {
    return shift->add(shift);
}

sub element {
    return shift->get_first();
}

sub peek {
    my $self = shift;

    $self->{size} == 0
        ? return undef
        : return $self->get_first();
}

sub poll {
    my $self = shift;

    $self->{size} == 0
        ? return undef
        : return $self->remove_first();
}

sub offer_first {
    shift->add_first(shift);
}

sub offer_last {
    return shift->add(shift);
}

sub peek_first {
    return shift->peek();
}

sub peek_last {
    my $self = shift;

    $self->{size} == 0
        ? return undef
        : return $self->get_last();
}

sub poll_first {
    return shift->poll();
}

sub poll_last {
    my $self = shift;

    $self->{size} == 0
        ? return undef
        : return $self->remove_last();
}

sub pop {
    return shift->remove_first();
}

sub push {
    shift->add_first(shift);
}

sub remove_first_occurrence {
    return shift->remove(shift);
}

sub remove_last_occurrence {
    my ($self, $element) = @_;

    $self->__check_parameter_count(2, scalar @_);
    my $entry = $self->{last};

    while (defined $entry) {
        if ($element eq $entry->{data}) {
            $self->__remove_entry($entry);
            return 1;
        } else {
            $entry = $entry->{previous};
        }
    }

    return 0;
}

sub clone {
    return ${Storable::dclone(\shift)};
}

sub write_object {
    my ($self, $filename) = @_;

    $self->__check_parameter_count(2, scalar @_);
    Storable::store \$self, $filename;
}

sub read_object {
    my ($self, $filename) = @_;

    $self->__check_parameter_count(2, scalar @_);
    my $entry = ${Storable::retrieve $filename, 1}->{first};

    while (defined $entry) {
        $self->__add_last_entry($entry);
        $entry = $entry->{next};
    }
}

sub list_iterator {
    my ($self, $index) = @_;

    $self->__check_parameter_count(2, scalar @_);
    $self->__check_bounds_inclusive($index);
    return Data::LinkedList::Iterator::ListIterator->new(
        index => $index,
        list  => $self
    );
}

sub descending_iterator {
    return Data::LinkedList::Iterator::DescendingIterator->new(
        list => shift
    );
}

1;

__END__

=head1 NAME

Data::LinkedList - Perl implementation of the GNU Classpath LinkedList.

=head1 SYNOPSIS

    #!/usr/bin/env perl -w

    use strict;
    use Data::LinkedList;

    my $list = Data::LinkedList->new();

    $list->add({ name => 'Lloyd', age => undef });
    $list->add({ name => 'Gary', age => undef });

    CORE::say $list->get_first()->{name}; # Lloyd
    CORE::say $list->get_last()->{name};  # Gary

    $list->add_first({ name => 'Lisa', age => undef });
    $list->add_last({ name => 'Bob', age => undef });

    my $lisa = $list->remove_first(); # HashRef stored in $lisa
    my $bob  = $list->remove_last();  # HashRef stored in $bob

    $list->offer_last($lisa);
    CORE::say $list->remove_first_occurrence($lisa); # 1 (true)

    CORE::say $list->size(); # 2

    $list->add_all_at(1, ($lisa, $bob));

    CORE::say $_->{name} for $list->to_array(); # Lloyd, Lisa, Bob, Gary

    $list->set(1, "simple element");
    CORE::say $list->get(1); # "simple element"

    $list->write_object("list.txt");

=head1 DESCRIPTION

This module provides a doubly linked list data structure, as well as
iterators to walk through the list.

=head1 METHODS

=head3 new

Create an instance of an empty doubly linked list.

    my $list = Data::LinkedList->new();

=head3 get_first

Return the first element in the list.

    $list->get_first();

=head3 get_last

Return the last element in the list.

    $list->get_last();

=head3 remove_first

Remove and return the first element in the list.

    $list->remove_first();

=head3 remove_last

Remove and return the last element in the list.

    $list->remove_last();

=head3 add_first

Insert an element at the front of the list.

    $list->add_first($element);

=head3 add_last

Insert an element at the end of the list.

    $list->add_last($element);

=head3 contains

Return true if the list contains the given value.

    $list->contains($element);

=head3 size

Return the current size of the list.

    $list->size();

=head3 add

Adds an element to the end of the list.

    $list->add($element);

=head3 remove

Removes and returns the first element of the list.

    $list->remove();

=head3 add_all

Append a list of elements to the end of the list.

    $list->add_all(@elements);

=head3 add_all_at

Add a list of elements at the given position of the list.

    $list->add_all_at($index, @elements);

=head3 clear

Remove all elements from the list.

    $list->clear();

=head3 get

Return the element which is at the given index.

    $list->get($index);

=head3 set

Replace the element at the given index of the list.

    $list->set($index, $element);

=head3 insert

Inserts an element into the given position of the list.

    $list->insert($index, $element);

=head3 remove_at

Remove an element from the given position.

    $list->remove_at($index);

=head3 index_of

Returns the first index of the given element.

    $list->index_of($element);

=head3 last_index_of

Returns the last index of the given element.

    $list->last_index_of($element);

=head3 to_array

Returns an array which contains the elements of the list in order.

    $list->to_array();

=head3 offer

Add an element to the end of the list. An alias of C<add>.

    $list->offer($element);

=head3 element

Returns the first element in the list without removing it. An alias of C<get_first>.

    $list->element();

=head3 peek

Returns the first element in the list without removing it. Doesn't complain
if the list has a size of zero.

    $list->peek();

=head3 poll

Removes and returns the first element of the list. Doesn't complain
if the list has a size of zero.

    $list->poll();

=head3 offer_first

Inserts an element at the front of the list. Alias of C<add_first>.

    $list->offer_first($element);

=head3 offer_last

Inserts an element at the end of the list. Alias of C<add>.

    $list->offer_last($element);

=head3 peek_first

Returns the first element of the list without removing it. Doesn't complain
if the list has a size of zero. Alias of C<peek>.

    $list->peek_first();

=head3 peek_last

Returns the last element of the list without removing it. Doesn't complain
if the list has a size of zero.

    $list->peek_last();

=head3 poll_first

Removes and returns the first element of the list. Doesn't complain
if the list has a size of zero. Alias of C<poll>.

    $list->poll_first();

=head3 poll_last

Removes and returns the last element of the list. Doesn't complain
if the list has a size of zero.

    $list->poll_last();

=head3 pop

Pops an element from the stack by removing and returning the first element
in the list. Equivalent to remove_first. Alias of C<remove_first>.

    $list->pop();

=head3 push

Pushes an element on to the stack by adding it to the front
of the list. Equivalent to add_first. Alias of C<add_first>.

    $list->push($element);

=head3 remove_first_occurrence

Removes the first occurrence of the specified element. Alias of C<remove>.

    $list->remove_first_occurrence($element);

=head3 remove_last_occurrence

Removes the last occurrence of the specified element.

    $list->remove_last_occurrence($element);

=head3 clone

Create a deep clone of the linked list.

    $list->clone();

=head3 write_object

Serializes the object and writes it to the given file name.

    $list->write_object($filename);

=head3 read_object

Deserializes the object which is read from the given file name.

    $list->read_object($filename);

=head3 list_iterator

Obtain a list iterator for list that starts at a given index.

    $list->list_iterator($index);

=head3 descending_iterator

Obtain an Iterator for the list that traverses in reverse sequential order.

    $list->descending_iterator();

=head1 BUGS

Please report any bugs to lloydg@cpan.org

=head1 CREDITS

Credits go to the authors of the GNU classpath implementation of
java.util.LinkedList class. The majority of this modules code has
been based on their prior work.

=head1 SEE ALSO

LinkedList::Single
Data::LinkedList::Entry
Data::LinkedList::Iterator::ListIterator
Data::LinkedList::Iterator::DescendingIterator

=head1 AUTHOR

Lloyd Griffiths

=head1 COPYRIGHT

Copyright (c) 2013 Lloyd Griffiths

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut