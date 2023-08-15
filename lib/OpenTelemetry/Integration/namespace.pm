package OpenTelemetry::Integration::namespace;
# ABSTRACT: OpenTelemetry integration for a namespace

our $VERSION = '0.001';

use strict;
use warnings;
use experimental 'signatures';

use Carp 'croak';
use Class::Inspector;
use Class::Method::Modifiers 'install_modifier';
use Feature::Compat::Defer;
use List::Util 'any';
use OpenTelemetry::Constants qw( SPAN_KIND_CLIENT SPAN_STATUS_ERROR SPAN_STATUS_OK );
use OpenTelemetry;
use Ref::Util 'is_arrayref';
use Module::Load;
use Devel::Peek;

use parent 'OpenTelemetry::Integration';

use constant {
    IS_TRACE => 0,
    IS_DEBUG => 0,
};

my ( %INSTALLED, $loaded );
sub uninstall ( $class ) {
    return unless $loaded;
    no strict 'refs';
    no warnings 'redefine';
    for my $package ( keys %INSTALLED ) {
        for my $sub ( keys %{ $INSTALLED{ $package } // {} } ) {
            delete $Class::Method::Modifiers::MODIFIER_CACHE{$package}{$sub};
            *{ $package . '::' . $sub } = delete $INSTALLED{$package}{$sub};
        }
    }
    undef $loaded;
    return;
}

my $parse_rules = sub ( $config ) {
    my ( $paths, $subroutines, $subpackages );

    if ( my @list = @{ $config->{paths} // [] } ) {
        $paths = '^(:?' . join( '|', map quotemeta, @list ) . ')';
        $paths = qr/$paths/;

        if ( IS_DEBUG ) {
            warn "Paths:\n";
            warn "- $_\n" for @list;
        }
    }

    if ( my %map = %{ $config->{subroutines} // {} } ) {
        while ( my ( $k, $v ) = each %map ) {
            @{ $subroutines->{$k} }{ @$v } = 1;
        }

        if ( IS_DEBUG ) {
            warn "Subroutines:\n";
            for my $k ( sort keys %{ $subroutines } ) {
                warn "- ${k}::$_\n" for sort keys %{ $subroutines->{$k} };
            }
        }
    }

    if ( my %map = %{ $config->{subpackages} // {} } ) {
        while ( my ( $k, $v ) = each %map ) {
            @{ $subpackages->{$k} }{ @$v } = 1;
        }

        if ( IS_DEBUG ) {
            warn "Subpackages:\n";
            for my $k ( sort keys %{ $subpackages } ) {
                warn "- ${k}:\n";
                warn "  - $_\n" for sort keys %{ $subpackages->{$k} };
            }
        }
    }

    ( paths => $paths, subroutines => $subroutines, subpackages => $subpackages )
};

sub install ( $class, %config ) {
    return if $loaded;

    my $package = $config{package};
    #     or croak 'Cannot automatically instrument OpenTelemetry without a package name';

    my %include = $parse_rules->( $config{include} );
    my %exclude = $parse_rules->( $config{exclude} );

    my $install_wrappers = sub ($package) {
        my $subs = namespace::clean->get_functions($package);

        while ( my ( $subname, $coderef ) = each %$subs ) {
            my $fullname = "${package}::$subname";

            # Skip functions we've already wrapped
            next if $INSTALLED{$package}{$subname};

            # If we are explicitly including this subroutine
            # none of the other checks matter
            if ( $include{subroutines}{$package}{$subname} ) {
                warn "Including $fullname explicitly" if IS_TRACE;
            }
            else {
                # Otherwise, perform all other additional checks
                next
                    # Skip packages we only included for some subs
                    if %{ $include{subroutines}{$package} // {} }
                    # Skip import and unimport
                    || $subname =~ /^(?:un)?import$/
                    # Skip uppercase functions
                    || uc($subname) eq $subname
                    # Skip "private" functions
                    || $subname =~ /^_/
                    # Skip subroutines we are explicitly excluding
                    || $exclude{subroutines}{$package}{$subname};

                # Skip imported functions.
                # See https://stackoverflow.com/a/3685262/807650
                if ( my $gv = Devel::Peek::CvGV($coderef) ) {
                    if ( *$gv{PACKAGE} ne $package ) {
                        warn "$package has dirty namespace ($subname)\n" if IS_TRACE;
                        next;
                    }
                }

                if ( defined prototype $coderef ) {
                    warn "Not wrapping $fullname because it has a prototype\n" if IS_TRACE;
                    next;
                }
            }

            $INSTALLED{$package}{$subname} = 1;

            install_modifier $package => around => $subname => sub {
                my ( $orig, $self, @rest ) = @_;
                OpenTelemetry->tracer_provider->tracer(
                    name    => __PACKAGE__,
                    version => $VERSION,
                )->in_span(
                    "${package}::$subname" => (
                        attributes => {
                            'code.function'  => $subname,
                            'code.namespace' => $package,
                        },
                    ),
                    sub { $self->$orig(@rest) },
                );
            };

            warn "Wrapped ${package}::$subname\n" if IS_TRACE;
        }
    };

    my $wrap = sub ($module) {
        return if
            lc $module eq $module   # pragma
            || $module =~ /^[0-9]/; # version

        my $filename = $INC{$module} or return;

        my $package = $module =~ s/\//::/gr;
        $package =~ s/\.p[ml]$//;

        return if exists $INSTALLED{$package};
        $INSTALLED{$package} = {};

        if ( my $data = $include{subpackages}{$package} ) {
            # If this package has any subpackages that we are interested
            # in wrapping, wrap those as well
            $install_wrappers->($_) for keys %$data;
        }

        # If we are specifically including any subroutine in this
        # package, then we cannot skip it wholesale
        unless ( $include{subroutines}{$package} ) {
            $package =~ /^::/ and do {
                warn "Skipping $package because it is not a package\n" if IS_TRACE;
                return;
            };

            $package =~ /^OpenTelemetry/ and do {
                warn "Skipping $package because it is ourselves\n" if IS_TRACE;
                return;
            };

            # TODO
            $package =~ /^(?:B|Exporter|Test2|Plack|XSLoader)(?:::|$)/ and do {
                warn "Skipping $package because it is not currently supported\n" if IS_TRACE;
                return;
            };

            $include{paths} && $filename !~ $include{paths} and do {
                warn "Skipping $package because it is not in include paths\n" if IS_TRACE;
                return;
            };

            $exclude{paths} && $filename =~ $exclude{paths} and do {
                warn "Skipping $package because it is in exclude paths\n" if IS_TRACE;
                return;
            };
        }

        $install_wrappers->($package);
    };

    $wrap->($_) for keys %INC;

    my $old_hook = ${^HOOK}{require__before};
    ${^HOOK}{require__before} = sub {
        my ($name) = @_;

        my $return;
        $return = $old_hook->($name) if $old_hook;

        return sub {
            $return->() if ref $return && reftype $return eq 'CODE';
            $wrap->($name);
        };
    };

    return $loaded = 1;
}

1;

__END__

=encoding utf8

=head1 NAME

OpenTelemetry::Integration::namespace - OpenTelemetry integration for a namespace

=head1 SYNOPSIS

    # This integration is EXPERIMENTAL

    use OpenTelemetry::Integration 'namespace' => {
        include => {
            paths => [(
                lib/Local
            )],
        },
        exclude => {
            paths => [qw(
                lib/Local/Secret
            )],
            subroutines => {
                'Some::Package' => [qw(
                    low_level
                )],
            },
        },
    };

=head1 DESCRIPTION

See L<OpenTelemetry::Integration> for more details.

Since this is a core module, it's included in the L<OpenTelemetry> core
distribution as well.

=head1 CONFIGURATION

=head2 include / exclude

The C<include> and C<exclude> sections control the package and subroutines
that are considered to be relevant by the monitoring code. Fields in the
C<exclude> section take precedence.

=head3 paths

This field should be set to list of literal paths or path segments. Any code
that is loaded from those paths will be included or excluded depending on what
section this was under.

For example:

    include => {
        paths => [qw(
            lib/Local
            lib/Test
        )],
    },
    exclude => {
        paths => [qw(
            lib/Local/Secret
        )],
    },

would make all the code that is loaded from C<lib/Local> and C<lib/Test>,
except the code loaded from C<lib/Local/Secret>, relevant for monitoring.

=head3 subpackages

Perl allows multiple packages to be defined inside the same file, so that
importing one file makes all of those packages available, without the
subpackages ever being explicitly loaded. Under normal circumstances, this
makes these packages invisible to the approach in this integration.

This key makes it possible to specify packages that should be wrapped for
monitoring whenever we detect another packages being loaded.

This field should be set to a hash where the keys are package names and
the values are lists of packages to be wrapped whenever the parent is.

For example:

    include => {
        subpackages => {
            'Local::Foo' => [qw(
                Local::Foo::Bar
            )],
        },
    },

This mapping has no meaning under C<exclude>, and is ignored in that case.

=head3 subroutines

In some cases, some specific subroutines are of interest even though they
are defined in packages that would otherwise not be eligible for reporting.

This field makes it possible to mark those subroutines as explicitly
relevant or irrelevant depending on the section this is under. If under
C<include>, these subroutines will always be wrapped; while under C<exclude>
they will I<never> be.

This field should be set to a hash where the keys are package names and
the values are lists of subroutine names.

For example:

    include => {
        subroutines => {
            'Local::Splines' => [qw(
                reticulate
            )],
        },
    },
    exclude => {
        subroutines => {
            'Local::Splines' => [qw(
                frobligate
            )],
        },
    },

This would make C<Local::Splines::reticulate> I<always> be wrapped, even
if C<Local::Splines> was loaded from a path that was not otherwise
specified as relevant. Likewise, C<Local::Splines::frobligate> would never
be wrapped, even if C<Local::Splines> was marked as relevant through some
other method.

=head1 COPYRIGHT

...
