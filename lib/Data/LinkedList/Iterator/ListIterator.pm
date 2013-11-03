package Data::LinkedList::Iterator::ListIterator;

use strict;
use warnings;
use Carp;
use Data::LinkedList;
use Data::LinkedList::Entry;

our $VERSION = '0.01';

sub new {
    my ($class, %params) = @_;
    my $self = {
        index         => undef,
        known_mod     => undef,
        next          => undef,
        previous      => undef,
        last_returned => undef,
        position      => undef,
        list          => undef,
    };

    while (my ($key, $value) = each %params) {
        $self->{$key} = $value if exists $self->{$key};
    }

    if ($self->{index} == $self->{list}->{size}) {
        $self->{next} = undef;
        $self->{previous} = $self->{list}->{last};
    } else {
        $self->{next} = $self->{list}->__get_entry($self->{index});
        $self->{previous} = $self->{next}->{previous};
    }

    $self->{known_mod} = $self->{list}->{mod_count};
    $self->{position} = $self->{index};
    return bless $self, $class;
}

sub __check_mod {
    my $self = shift;

    croak(qq(
        Concurrent modification. Object modified whilst not in a permissible state.
    )) if $self->{known_mod} != $self->{list}->{mod_count};
}

sub next_index {
    return shift->{position};
}

sub previous_index {
    return (shift->{position} - 1);
}

sub has_next {
    return defined shift->{next};
}

sub has_previous {
    return defined shift->{previous};
}

sub next {
    my $self = shift;

    $self->__check_mod();
    croak 'No such element in list.' if not defined $self->{next};

    $self->{position}++;
    $self->{last_returned} = $self->{previous} = $self->{next};
    $self->{next} = $self->{last_returned}->{next};
    return $self->{last_returned}->{data};
}

sub previous {
    my $self = shift;

    $self->__check_mod();
    croak 'No such element in list.' if not defined $self->{previous};

    $self->{position}--;
    $self->{last_returned} = $self->{next} = $self->{previous};
    $self->{previous} = $self->{last_returned}->{previous};
    return $self->{last_returned}->{data};
}

sub remove {
    my $self = shift;

    $self->__check_mod();
    croak 'Illegal state. The subroutine has been invokved at an  inappropriate time.'
        if not defined $self->{last_returned};

    $self->{position}-- if $self->{last_returned} == $self->{previous};
    $self->{next} = $self->{last_returned}->{next};
    $self->{previous} = $self->{last_returned}->{previous};
    $self->{list}->__remove_entry($self->{last_returned});
    $self->{known_mod}++;
    $self->{last_returned} = undef;
}

sub add {
    my ($self, $element) = @_;

    $self->{list}->__check_parameter_count(2, scalar @_);
    $self->__check_mod();

    $self->{list}->{mod_count}++;
    $self->{known_mod}++;
    $self->{list}->{size}++;
    $self->{position}++;

    my $entry = Data::LinkedList::Entry->new(data => $element);
    $entry->{previous} = $self->{previous};
    $entry->{next} = $self->{next};

    (defined $self->{previous})
        ? $self->{previous}->{next} = $entry
        : $self->{first} = $entry;

    (defined $self->{next})
        ? $self->{next}->{previous} = $entry
        : $self->{list}->{last} = $entry;

    $self->{previous} = $entry;
    $self->{last_returned} = undef;
}

sub set {
    my ($self, $element) = @_;

    $self->{list}->__check_parameter_count(2, scalar @_);
    $self->__check_mod();

    if (not defined $self->{last_returned}) {
        croak 'Illegal state. The subroutine has been invokved at an  inappropriate time.'
    } else {
        $self->{last_returned}->{data} = $element;
    }
}

1;

__END__

=head1 NAME

Data::LinkedList::Iterator::ListIterator - A list iterator to walk through a linked list.

=head1 SYNOPSIS

    #!/usr/bin/env perl -w

    use strict;
    use Data::LinkedList;

    my $list = Data::LinkedList->new();
    $list->add_all(1, 2, 3, 4, 5);

    my $iterator = $list->list_iterator(0);
    CORE::say $iterator->next() while $iterator->has_next();

=head1 DESCRIPTION

The list iterator walks through a linked list in sequential order.

=head1 METHODS

=head3 new

Instantiates and returns a new Data::LinkedList::Iterator::ListIterator object. The starting
index for the iterator has to be passed to the object upon construction.

    my $list_iterator = Data::LinkedList::Iterator::ListIterator->new(
        list => Data::LinkedList->new() # Required for construction.
                                        # Won't complain if not passed, but will fail miserably.
    );

=head3 next_index

Returns the position of the next entry.

    $list_iterator->next_index();

=head3 previous_index

Returns the position of the previous entry.

    $list_iterator->previous_index();

=head3 has_next

Returns a boolean value to represent if there is a next entry in the list.

    $list_iterator->has_next();

=head3 has_previous

Returns a boolean value to represent if there is a previous entry in the list.

    $list_iterator->has_previous();

=head3 next

Returns the next entry in the list.

    $list_iterator->next();

=head3 previous

Returns the previous entry in the list.

    $list_iterator->previous();

=head3 remove

Remove the most recently returned element from the list.

    $list_iterator->remove();

=head3 add

Add an entry between the previous and next element and advance to the next element.

    $list_iterator->add($element);

=head3 set

Change the entry data of the most recently returned entry.

    $list_iterator->set($element);

=head1 BUGS

Please report any bugs to lloydg@cpan.org

=head1 AUTHOR

Lloyd Griffiths

=head1 COPYRIGHT

Copyright (c) 2013 Lloyd Griffiths

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
