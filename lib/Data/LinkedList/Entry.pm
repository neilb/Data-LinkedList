package Data::LinkedList::Entry;

use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my ($class, %params) = @_;
    my $self = {
        data     => undef,
        next     => undef,
        previous => undef
    };

    while (my ($key, $value) = each %params) {
        $self->{$key} = $value if exists $self->{$key};
    }

    return bless $self, $class;
}

1;

__END__

=head1 NAME

Data::LinkedList::Entry - Object to represent an entry in the list.

=head1 DESCRIPTION

Each C< Entry > object has three properties:

=over

=item C< data > The entry data. This can be anything from an integer to an array.

=item C< next > The next entry in the list.

=item C< previous > The previous entry in the list.

=back

=head1 METHODS

=head3 new

Instantiates and returns a new Data::LinkedList::Entry object. Doesn't require
any parameters - the properties of the object can be set after instantiation.

=head1 AUTHOR

Lloyd Griffiths

=head1 COPYRIGHT

Copyright (c) 2013 Lloyd Griffiths

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
