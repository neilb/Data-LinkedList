package Data::LinkedList;

use strict;
use warnings;
use Carp;
use Storable;
use Iterator::Util;
use Data::LinkedList::Entry;
use Data::LinkedList::Iterator::ListIterator;
use Data::LinkedList::Iterator::DescendingIterator;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw();
our $VERSION = '0.1';

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
        $self->{first} = $self->{last} = undef;
    } elsif ($entry == $self->{first}) {
        $self->{first} = $entry->{next};
        $entry->{next}->{previous} = undef;
    } elsif ($entry == $self->{last}) {
        $self->{last} = $entry->{previous};
        $entry->{previous}->{next} = undef;
    } else {
        $entry->{next}->{previous} = $entry->{previous};
        $entry->{previous}->{next} = $entry->{next};
    }
}

sub __add_last_entry {
    my ($self, $entry) = @_;

    if ($self->{size} == 0) {
        $self->{first} = $self->{last} = $entry;
    } else {
        $entry->{previous} = $self->{last};
        $self->{last}->{next} = $entry;
        $self->{last} = $entry;
    }

    $self->{size}++;
}

sub __check_bounds_inclusive {
    my ($self, $index) = @_;

    if ($index < 0 or $index > $self->{size}) {
        croak(
            'Index out of bounds: The index provided was out of range. . "\n" .
             Index: ' . $index . ' Size :' . $self->{size}
        );
    }
}

sub __check_bounds_exclusive {
    my ($self, $index) = @_;

    if ($index < 0 or $index >= $self->{size}) {
        croak(
            'Index out of bounds: The index provided was out of range.' . "\n" .
            'Index: ' . $index . ' Size :' . $self->{size}
        );
    }
}

sub __check_parameter_count {
    my ($self, $expected, $actual) = @_;
    
    if ($actual < $expected) {
        croak (
            'Expected ' . $expected . ' parameters, got ' . $actual
        );
    }
}

sub get_first {
    my $self = shift;

    if ($self->{size} == 0) {
        croak 'No such element in list.';
    } else {
        return $self->{first}->{data};
    }
}

sub get_last {
    my $self = shift;

    if ($self->{size} == 0) {
        croak 'No such element in list.';
    } else {
        return $self->{last}->{data};
    }
}

sub remove_first {
    my $self = shift;

    if ($self->{size} == 0) {
        croak 'No such element in list.';
    } else {
        my $removed = $self->{first}->{data};
        $self->{mod_count}++;
        $self->{size}--;

        if (defined $self->{first}->{next}) {
            $self->{first}->{next}->{previous} = undef;
        } else {
            $self->{last} = undef;
        }

        $self->{first} = $self->{first}->{next};
        return $removed;
    }
}

sub remove_last {
    my $self = shift;

    if ($self->{size} == 0) {
        croak 'No such element in list.';
    } else {
        my $removed = $self->{last}->{data};
        $self->{mod_count}++;
        $self->{size}--;

        if (defined $self->{last}->{previous}) {
            $self->{last}->{previous}->{next} = undef;
        } else {
            $self->{first} = undef;
        }

        $self->{last} = $self->{last}->{previous};
        return $removed;
    }
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

    if ($size == 0) {
        return 0;
    }

    my ($iterator, $after, $before) = (
        Iterator::Util::ilist(@array), undef, undef
    );

    if ($index != $self->{size}) {
        $after = $self->__get_entry($index);
        $before = $after->{previous};
    } else {
        $before = $self->{last};
    }

    my $entry = Data::LinkedList::Entry->new(data => $iterator->value());
    my ($previous, $first_new) = ($entry, $entry);
    $entry->{previous} = $before;

    for (my $position = 1; ($position < $size); $position++) {
        $entry = Data::LinkedList::Entry->new(data => $iterator->value());
        $entry->{previous} = $previous;
        $previous->{next} = $entry;
        $previous = $entry;
    }

    $previous->{next} = $after;
    $self->{mod_count}++;
    $self->{size} += $size;

    if (defined $after) {
        $after->{previous} = $entry;
    } else {
        $self->{last} = $entry;
    }

    if (defined $before) {
        $before->{next} = $first_new;
    } else {
        $self->{first} = $first_new;
    }

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
        my $after = $self->__get_entry($index);
        $entry->{next} = $after;
        $entry->{previous} = $after->{previous};
        $self->{mod_count}++;

        if (not defined $after->{previous}) {
            $self->{first} = $entry;
        } else {
            $after->{previous}->{next} = $entry;
        }

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
    $self->{size} == 0 ? return undef : return $self->get_first();
}

sub poll {
    my $self = shift;
    $self->{size} == 0 ? return undef : return $self->remove_first();
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
    $self->{size} == 0 ? return undef : return $self->get_last();
}

sub poll_first {
    return shift->poll();
}

sub poll_last {
    my $self = shift;
    $self->{size} == 0 ? return undef : return $self->remove_last();
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

=head1 DESCRIPTION

This module provides a doubly linked list data structure, as well as 
iterators to walk through the list.

=head1 METHODS

=head3 new
Create an instance of an empty doubly linked list.

=head3 get_first
Return the first element in the list.

=head3 get_last
Return the last element in the list.

=head3 remove_first
Remove and return the first element in the list.

=head3 remove_last
Remove and return the last element in the list.

=head3 add_first
Insert an element at the front of the list.

=head3 add_last
Insert an element at the end of the list.

=head3 contains
Return true if the list contains the given value.

=head3 size
Return the current size of the list.

=head3 add
Adds an element to the end of the list.

=head3 remove
Removes and returns the first element of the list.

=head3 add_all
Append a list of elements to the end of the list.

=head3 add_all_at
Add a list of elements at the given position of the list.

=head3 clear
Remove all elements from the list.

=head3 get
Return the element which is at the given index.

=head3 set
Replace the element at the given index of the list.

=head3 insert
Inserts an element into the given position of the list.

=head3 remove_at
Remove an element from the given position.

=head3 index_of
Returns the first index of the given element.

=head3 last_index_of
Returns the last index of the given element.

=head3 to_array
Returns an array which contains the elements of the list in order.

=head3 offer
Add an element to the end of the list.

=head3 element
Returns the first element in the list without removing it.

=head3 peek
Returns the first element in the list without removing it.

=head3 poll
Removes and returns the first element of the list.

=head3 offer_first
Inserts an element at the front of the list.

=head3 offer_last
Inserts an element at the end of the list.

=head3 peek_first
Returns the first element of the list without removing it.

=head3 peek_last
Returns the last element of the list without removing it.

=head3 poll_first
Removes and returns the first element of the list.

=head3 poll_last
Removes and returns the last element of the list.

=head3 pop
Pops an element from the stack by removing and returning
the first element in the list. Equivalent to remove_first.

=head3 push
Pushes an element on to the stack by adding it to the front
of the list. Equivalent to add_first.

=head3 remove_first_occurrence
Removes the first occurrence of the specified element.

=head3 remove_last_occurrence
Removes the last occurrence of the specified element.

=head3 clone
Create a copy of the linked list.

=head3 write_object
Serializes this object to the given file name.

=head3 read_object
Deserializes this object from the given file name.

=head3 list_iterator
Obtain a list iterator over this list, starting at a given index.

=head3 descending_iterator
Obtain an Iterator over this list in reverse sequential order.

=head1 BUGS

Please report any bugs or feature requests to lloydg@cpan.org

=head1 AUTHOR

Lloyd Griffiths

=head1 COPYRIGHT

Copyright (c) 2013 Lloyd Griffiths

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
