use strict;
use warnings;

use File::Spec;
use Test::More 'tests' => 4;
use FindBin qw($Bin);
use lib "$Bin/../lib";

BEGIN { use_ok('Config::Loader'); }
BEGIN { use_ok('Config::Loader::Stream'); }

my $config;

# WOOT! I'm not adding Test::Exception to see if it fails to construct properly

use Data::Dumper;
print STDERR "$Bin/../lib";

ok($config = Config::Loader->new( { file => get_path('test.yml'), debug => => 1 } ),
    'OO - Load perl source configuration file' );

my $clone = $config->clone();

ok(delete $clone->{clone} == 1, 'Has cloned attribute');
is_deeply($clone, $config);

print STDERR Dumper($config);

sub get_path {
    my ($vol,$path) = File::Spec->splitpath(
        File::Spec->rel2abs($0)
    );
    $path = File::Spec->catdir(
        File::Spec->splitdir($path),
        'data',@_
    );
    return File::Spec->catpath($vol,$path,'');
}
