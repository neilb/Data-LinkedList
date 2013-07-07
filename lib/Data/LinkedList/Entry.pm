package Data::LinkedList::Entry;

use strict;
use warnings;

sub new {
	my ($class, %params) = @_;
	my ($self) = {
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