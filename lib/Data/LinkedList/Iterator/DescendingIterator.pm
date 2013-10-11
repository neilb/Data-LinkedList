package Data::LinkedList::Iterator::DescendingIterator;

use strict;
use warnings;
use Carp;
use Data::LinkedList;
use Data::LinkedList::Entry;

our $VERSION = '0.1';

sub new {
    my ($class, %params) = @_;
    my $self = {
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

    $self->{known_mod} = $self->{list}->{mod_count};
    $self->{next} = $self->{list}->{last};
    $self->{position} = ($self->{list}->{size} - 1);
    return bless $self, $class;
}

sub __check_mod {
    my $self = shift;

    if ($self->{known_mod} != $self->{list}->{mod_count}) {
        croak(qq(
            Concurrent modification. Object modified whilst not in a permissible state.
        ));
    }
}

sub has_next {
    return defined shift->{next};
}

sub next {
    my $self = shift;
    $self->__check_mod();

    if (not defined $self->{next}) {
        croak 'No such element in list.';
    }

    --$self->{position};
    $self->{last_returned} = $self->{next};
    $self->{next} = $self->{last_returned}->{previous};
    return $self->{last_returned}->{data};
}

sub remove {
    my $self = shift;
    $self->__check_mod();

    if (not defined $self->{last_returned}) {
        croak(
            'Illegal state. Subroutine invokved at an inappropriate time.'
        );
    }

    $self->{list}->__remove_entry($self->{last_returned});
    $self->{last_returned} = undef;
    ++$self->{known_mod};
}

1;

__END__

=head1 NAME

Data::LinkedList::Iterator::ListIterator - A list iterator to iterate over the 
linked list in reverse order.

=head1 DESCRIPTION

This object keeps track of its position in the linked list as well as the next and previous
entry for the current entry.

=head1 METHODS

=head3 new

Instantiates and returns a new Data::LinkedList::Iterator::ListIterator object. The starting
index for the iterator is that of the last element in the list.

=head3 has_next

Returns a boolean value to represent if there is a next entry in the list.

=head3 next

Returns the next entry in the list.

=head3 remove

Remove the most recently returned element from the list.

=head1 COPYRIGHT

Copyright (c) 2013 Lloyd Griffiths

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
