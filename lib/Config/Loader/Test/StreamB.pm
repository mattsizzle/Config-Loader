package Config::Loader::Test::StreamB;

use warnings;
use strict;
use Config::Merge;

use base 'Config::Loader::Stream';

sub get_config {
    my ( $self ) = @_;

    return Config::Merge->new('b');
}

sub get_path {
    my ($vol,$path) = File::Spec->splitpath(
        File::Spec->rel2abs($0)
    );
    $path = File::Spec->catdir(
        File::Spec->splitdir($path),
        'data/streams',@_
    );
    return File::Spec->catpath($vol,$path,'');
}

1;
