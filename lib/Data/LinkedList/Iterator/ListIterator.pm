package Data::LinkedList::Iterator::ListIterator;

use strict;
use warnings;
use Carp;
use Data::LinkedList;
use Data::LinkedList::Entry;

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

    if ($self->{known_mod} != $self->{list}->{mod_count}) {
        croak (
            'Concurrent modification. Object modified whilst not in a permissible state.'
        );
    }
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

    if (not defined $self->{next}) {
        croak 'No such element in list.';
    }

    $self->{position}++;
    $self->{last_returned} = $self->{previous} = $self->{next};
    $self->{next} = $self->{last_returned}->{next};
    return $self->{last_returned}->{data};
}

sub previous {
    my $self = shift;
    $self->__check_mod();

    if (not defined $self->{previous}) {
        croak 'No such element in list.';
    }

    $self->{position}--;
    $self->{last_returned} = $self->{next} = $self->{previous};
    $self->{previous} = $self->{last_returned}->{previous};
    return $self->{last_returned}->{data};
}

sub remove {
    my $self = shift;
    $self->__check_mod();

    if (not defined $self->{last_returned}) {
        croak(
            'Illegal state. The subroutine has been invokved at an  inappropriate time.'
        );
    }

    if ($self->{last_returned} == $self->{previous}) {
        $self->{position}--;
    }

    $self->{next} = $self->{last_returned}->{next};
    $self->{previous} = $self->{last_returned}->{previous};
    $self->{list}->__remove_entry($self->{last_returned});
    $self->{known_mod}++;
    $self->{last_returned} = undef;
}

sub add {
    if (scalar @_ < 2) {
        croak 'Expected two parameters, only got ' . scalar @_;
    }

    my ($self, $element) = @_;
    $self->__check_mod();
    $self->{list}->{mod_count}++;
    $self->{known_mod}++;
    $self->{list}->{size}++;
    $self->{position}++;

    my $entry = Data::LinkedList::Entry->new(data => $element);
    $entry->{previous} = $self->{previous};
    $entry->{next} = $self->{next};

    if (defined $self->{previous}) {
        $self->{previous}->{next} = $entry;
    } else {
        $self->{first} = $entry;
    }

    if (defined $self->{next}) {
        $self->{next}->{previous} = $entry;
    } else {
        $self->{list}->{last} = $entry;
    }

    $self->{previous} = $entry;
    $self->{last_returned} = undef;
}

sub set {
    if (scalar @_ < 2) {
        croak 'Expected two parameters, only got ' . scalar @_;
    }

    my ($self, $element) = @_;
    $self->__check_mod();

    if (not defined $self->{last_returned}) {
        croak (
            'Illegal state. The subroutine has been invokved at an  inappropriate time.'
        );
    } else {
        $self->{last_returned}->{data} = $element;
    }
}

1;

__END__
