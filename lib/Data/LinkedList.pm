#############################################
# docs
#############################################

package Data::LinkedList;

use strict;
use warnings;
use Carp;
use Iterator::Util;
use Storable;
use Data::LinkedList::Entry;
use Data::LinkedList::Iterator::ListIterator;
use Data::LinkedList::Iterator::DescendingIterator;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw();
our $VERSION = '0.01';

sub new {
    my ($class, %params) = @_;
    my ($self) = {
        first     => undef,
        last      => undef,
        size      => 0,
        mod_count => 0,
    };

    return bless $self, $class;
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

    if (($index < 0) || ($index > $self->{size})) {
        croak(
            'Index out of bounds: The index provided was out of range.
             Index: ' . $index . ' Size :' . $self->{size}
        );
    }
}

sub __check_bounds_exclusive {
    my ($self, $index) = @_;

    if (($index < 0) || ($index >= $self->{size})) {
        croak
            'Index out of bounds: The index provided was out of range.' . "\n" .
            'Index: ' . $index . ' Size :' . $self->{size};
    }
}

sub get_first {
    my ($self) = shift;

    if ($self->{size} == 0) {
        croak 'No such element in list.';
    } else {
        return $self->{first}->{data};
    }
}

sub get_last {
    my ($self) = shift;

    if ($self->{size} == 0) {
        croak 'No such element in list.';
    } else {
        return $self->{last}->{data};
    }
}

sub remove_first {
    my ($self) = shift;

    if ($self->{size} == 0) {
        croak 'No such element in list.';
    } else {
        $self->{mod_count}++;
        $self->{size}--;
        my ($removed) = $self->{first}->{data};

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
    my ($self) = shift;

    if ($self->{size} == 0) {
        croak 'No such element in list.';
    } else {
        $self->{mod_count}++;
        $self->{size}--;
        my ($removed) = $self->{last}->{data};

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
    my ($entry) = Data::LinkedList::Entry->new(
        data => $element
    );
    $self->{mod_count}++;

    if ($self->{size} == 0) {
        $self->{first} = $self->{last} = $entry;
    } else {
        $entry->{next} = $self->{first};
        $self->{first}->{previous} = $entry;
        $self->{first} = $entry;
    }

    $self->{size}++;
}

sub add_last {
    shift->__add_last_entry(
        Data::LinkedList::Entry->new(data => shift)
    );
}

sub contains {
    my ($self, $element) = @_;
    my ($entry) = $self->{first};

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
    my ($entry) = $self->{first};

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
    return $self->add_all_at($self->{size}, @array);
}

sub add_all_at {
    my ($self, $index, @array) = @_;
    $self->__check_bounds_inclusive($index);
    my ($size) = scalar @array;

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

    my ($entry) = Data::LinkedList::Entry->new(
        data => $iterator->value()
    );
    $entry->{previous} = $before;
    my ($previous, $first_new) = ($entry, $entry);

    for (my $position = 1; ($position < $size); $position++) {
        $entry = Data::LinkedList::Entry->new(
            data => $iterator->value()
        );
        $entry->{previous} = $previous;
        $previous->{next} = $entry;
        $previous = $entry;
    }

    $self->{mod_count}++;
    $self->{size} += $size;
    $previous->{next} = $after;

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
    my ($self) = shift;

    if ($self->{size} > 0) {
        $self->{mod_count}++;
        $self->{first} = undef;
        $self->{last} = undef;
        $self->{size} = 0;
    }
}

sub get {
    my ($self, $index) = @_;
    $self->__check_bounds_exclusive($index);
    return $self->__get_entry($index)->{data};
}

sub set {
    my ($self, $index, $element) = @_;
    $self->__check_bounds_exclusive($index);
    my ($entry) = $self->__get_entry($index);
    my ($old) = $entry->{data};
    $entry->{data} = $element;

    return $old;
}

sub insert {
    my ($self, $index, $element) = @_;
    $self->__check_bounds_inclusive($index);
    my ($entry) = Data::LinkedList::Entry->new(data => $element);

    if ($index < $self->{size}) {
        $self->{mod_count}++;
        my ($after) = $self->__get_entry($index);
        $entry->{next} = $after;
        $entry->{previous} = $after->{previous};

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
    $self->__check_bounds_exclusive($index);
    my ($entry) = $self->__get_entry($index);
    $self->__remove_entry($entry);

    return $entry->{data};
}

sub index_of {
    my ($self, $element) = @_;
    my ($index) = 0;
    my ($entry) = $self->{first};

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
    my ($index) = ($self->{size} - 1);
    my ($entry) = $self->{last};

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
    my ($self) = shift;
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
    my ($self) = shift;
    ($self->{size} == 0) ? return undef : return $self->get_first();
}

sub poll {
    my ($self) = shift;
    ($self->{size} == 0) ? return undef : return $self->remove_first();
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
    my ($self) = shift;
    ($self->{size} == 0) ? return undef : return $self->get_last();
}

sub poll_first {
    return shift->poll();
}

sub poll_last {
    my ($self) = shift;
    ($self->{size} == 0) ? return undef : return $self->remove_last();
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
    my ($entry) = $self->{last};

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
    Storable::store \shift, shift;
}

sub read_object {
    my ($self, $filename) = @_;
    my ($entry) = ${Storable::retrieve $filename, 1}->{first};

    while (defined $entry) {
        $self->__add_last_entry($entry);
        $entry = $entry->{next};
    }
}

sub list_iterator {
    my ($self, $index) = @_;
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