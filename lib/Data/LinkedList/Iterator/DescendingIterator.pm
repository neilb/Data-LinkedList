package Data::LinkedList::Iterator::DescendingIterator;

use strict;
use warnings;
use Carp;
use Data::LinkedList;
use Data::LinkedList::Entry;

our $VERSION = '0.01';

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

    croak(qq(
        Concurrent modification. Object modified whilst not in a permissible state.
    )) if $self->{known_mod} != $self->{list}->{mod_count};
}

sub has_next {
    return defined shift->{next};
}

sub next {
    my $self = shift;

    $self->__check_mod();
    croak 'No such element in list.' if (not defined $self->{next});

    --$self->{position};
    $self->{last_returned} = $self->{next};
    $self->{next} = $self->{last_returned}->{previous};
    return $self->{last_returned}->{data};
}

sub remove {
    my $self = shift;

    $self->__check_mod();
    croak 'Illegal state. Subroutine invokved at an inappropriate time.'
        if not defined $self->{last_returned};

    $self->{list}->__remove_entry($self->{last_returned});
    $self->{last_returned} = undef;
    ++$self->{known_mod};
}

1;

__END__

=head1 NAME

Data::LinkedList::Iterator::ListIterator - A list iterator to walk through a
linked list in reverse order.

=head1 SYNOPSIS

    #!/usr/bin/env perl -w

    use strict;
    use Data::LinkedList;
    
    my $list = Data::LinkedList->new();
    $list->add_all(1, 2, 3, 4, 5);
    
    my $iterator = $list->descending_iterator();
    CORE::say $iterator->next() while $iterator->has_next();

=head1 DESCRIPTION

The descending list iterator walks through the linked list in reverse sequential order.

=head1 METHODS

=head3 new

Instantiates and returns a new Data::LinkedList::Iterator::ListIterator object. The starting
index for the iterator is that of the last element in the list.

    my $descending_iterator = Data::LinkedList::Iterator::DescendingIterator->new(
        list => Data::LinkedList->new() # Required for construction.
                                        # Won't complain if not passed, but will fail miserably.
    );
        

=head3 has_next

Returns a boolean value to represent if there is a next entry in the list.

    $descending_iterator->has_next();

=head3 next

Returns the next entry in the list.

    $descending_iterator->next();

=head3 remove

Remove the most recently returned element from the list.

    $descending_iterator->remove();

=head1 BUGS

Please report any bugs to lloydg@cpan.org

=head1 AUTHOR

Lloyd Griffiths

=head1 COPYRIGHT

Copyright (c) 2013 Lloyd Griffiths

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
