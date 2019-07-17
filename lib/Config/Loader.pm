package Config::Loader;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use Carp qw( croak );
use Storable qw(!retrieve);
use File::Basename;
use Config::Merge;
use Hash::Merge qw( merge );
use Module::Loaded;

our $VERSION = '0.80';

=head1 NAME

Config::Loader - load configuration data from various sources

=head1 SYNOPSIS

OOP USAGE

   use Config::Loader();

   my $config    = Config::Loader->new('/path/to/sources/config');

   $hosts        = $config->{'hosts'};
   @hosts        = $config->get('hosts');
   $cloned_hosts = $config->clone()->{'hosts'};
   -------------------------------------------------------

ADVANCED USAGE

   my $config    = Config::Loader->new(
       file      => '/path/to/sources/config',
       debug     => 1 | 0
   );

=head1 DESCRIPTION

Config::Loader is a configuration module which has a few opinionated goals:

=over

=item * Flexible access

Provide a simple, easy to read, concise way of accessing the configuration
values from various sources by allowing a consumer to provider their own
interface to the configuration data.

=item * Minimal maintenance

Specify the location of the configuration files only once per
application, so that it requires minimal effort to relocate.
See L</"USING Config::Loader">

=item * Easy to alter development environment

Provide a way for overriding configuration values on a development
machine, so that differences between the dev environment and
the live environment do not get copied over accidentally.

=back

=head1 USING C<Config::Loader>

C<Config::Loader> provides a OOP interface the will generate the configuration data when instantiated:

=over

=item OOP STYLE

   use Config::Loader();

   my $config    = Config::Loader->new('/path/to/sources/config');

   $hosts        = $config->{'hosts'};
   @hosts        = $config->get('hosts');
   $cloned_hosts = $config->clone()->{'hosts'};

Also, see L</"ADVANCED USAGE">.

=back

=head1 METHODS

=head3 C<new()>

    $conf = Config::Loader->new($config_file);

new() instantiates a config object, loads the source configuration file and then requires each source's
interface module and attempts to build the configuration object by merging the returned data from each
interface modules ->load() method.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = {};
    bless( $self, $class );

    my $params
        = @_ > 1              ? {@_}
        : ref $_[0] eq 'HASH' ? shift()
        :                       { file => shift() };

    # Emit debug messages
    $self->{debug} = $params->{debug} ? 1 : 0;

    my $file = $params->{file}
        or die( "Source configuration file not specified when creating a new "
        . "'$class' object" );

    if ( $file && -r $file ) {
        $self->{config_file} = $file;
        $self->{_config} = $self->_load_config() || {};

        $self->_normalize_sources();
        $self->_load_from_streams();

        return $self;
    }
    else {
        die( "Configuration file '$file' not readable when creating a new "
            . "'$class' object" );
    }
}

=head2 _load_stream()

Reads the _config from self and parses the streams array for enabled streams. It then sorts the sources by priority
and appends them to $self->{_streams}

=cut

sub _normalize_sources {
    my $self          = shift;
    my $streams       = shift || $self->{_config}->{streams};

    croak "Argument to _normalize_sources must be a ARRAY" unless ref $streams eq 'ARRAY';

    my @enabled = grep { $_->{enabled} == 1 } @{$streams};
    my @sorted = sort { $a->{priority} <=> $b->{priority} } @enabled;

    $self->{_streams} = \@sorted;
}

sub _load_config {
    my $self          = shift;
    my $file          = shift || $self->{config_file};

    # TODO: Make this a config any like https://metacpan.org/source/SYMKAT/Config-Layered-0.000003/lib/Config/Layered/Source/ConfigAny.pm
    my $cfg;
    eval {
        my($filename, $directories, $suffix) = fileparse($file, qr/\.[^.]*/);
        $cfg = Config::Merge->new($directories)->("$filename");
    };

    if ( $@ || not defined $cfg ) {
        croak "Config::Loader ERROR: Unable to load '$file' with 'Config::Merge' $@";
    };

    return keys %$cfg ? $cfg : undef;
}

=head3 C<clone()>

The data is deep cloned, using Storable, so the bigger the data, the more
performance hit.  That said, Storable's dclone is very fast.

=cut

sub clone {
    my $self = shift;
    my $dclone = Storable::dclone($self);
    $dclone->{clone} = 1;

    return $dclone;
}

=head3 C<debug()>

Writes additional contextual data to STDERR when C<debug> is set on instantiation.

=cut

sub debug {
    my $self = shift;
    print STDERR ( join( "\n", @_, '' ) )
        if $self->{debug};
    return 1;
}

=head2 _load_stream()

Loads a stream's interface module into @INC

=cut

sub _init_stream {
    my ( $self, $stream ) = @_;

    my $class = "Config::Loader::$stream";

    return $class if is_loaded($class);

    eval "require $class";
    if ( defined $@ ) {
        eval "require $stream";
        if ( defined $@ ) {
            croak "Config::Loader ERROR: Couldn't find $stream or $class";
        } else {
            $class = $stream;
        }
    }

    return $class;
}

sub _load_from_streams {
    my $self = shift;

    Hash::Merge::set_behavior( 'LEFT_PRECEDENT' );
    Hash::Merge::set_clone_behavior(0);

    my $config;

    for my $source ( @{ $self->{_streams} } ) {

        my $pkg = $self->_init_stream($source->{module})->new();

        $config = $pkg->get();

        if ( keys %$config ) {
            $$self{config} = merge( $$self{config}, $config );
        }

    }

    return 1;
}

1;
