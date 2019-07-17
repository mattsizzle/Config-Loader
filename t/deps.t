use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    my $skip_all = 0;
    my @missing_list;

    eval { require Carp; };
    if ( $@ ) {
        $skip_all++;
        push @missing_list, 'Carp';
    }

    eval { require Storable; };
    if ( $@ ) {
        $skip_all++;
        push @missing_list, 'Storable';
    }

    eval { require Hash::Merge; };
    if ( $@ ) {
        $skip_all++;
        push @missing_list, 'Hash::Merge';
    }

    eval { require File::Spec; };
    if ( $@ ) {
        $skip_all++;
        push @missing_list, 'File::Spec';
    }

    eval { require File::Basename; };
    if ( $@ ) {
        $skip_all++;
        push @missing_list, 'File::Basename';
    }

    eval { require Config::Merge; };
    if ( $@ ) {
        $skip_all++;
        push @missing_list, 'Config::Merge';
    }

    SKIP: {
        skip "ConfigLoader requires @missing_list", 1
            if $skip_all;

        use_ok( 'Config::Loader' );
    }
}
