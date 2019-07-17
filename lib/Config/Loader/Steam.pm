package Config::Loader::Stream;

use strict;
use warnings FATAL => 'all';
use Carp qw( croak );

# Parent Class

sub new {
    my ( $class, $args ) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub get_config {
    my $self = shift;

    croak "Config::Loader ERROR: '$self' does not implement 'get_config'";
}

sub get {
    my $self = shift;
    return $self->get_config();
}

1;
