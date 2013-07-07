package Data::LinkedList::Iterator::DescendingIterator;

use strict;
use warnings;
use Carp;
use Data::LinkedList;
use Data::LinkedList::Entry;

sub new {
    my ($class, %params) = @_;
    my ($self) = {
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
    my ($self) = shift;
    
    if ($self->{known_mod} != $self->{list}->{mod_count}) {
        croak (
            'Concurrent modification. Object modified whilst not in a permissible state.'
        );
    }
}

sub has_next {
    return defined shift->{next};
}

sub next {
    my ($self) = shift;
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
    my ($self) = shift;
    $self->__check_mod();
    
    if (not defined $self->{last_returned}) {
        croak (
            'Illegal state. Subroutine invokved at an inappropriate time.'
        );
    }
    
    $self->{list}->__remove_entry($self->{last_returned});
    $self->{last_returned} = undef;
    ++$self->{known_mod};
}

1;