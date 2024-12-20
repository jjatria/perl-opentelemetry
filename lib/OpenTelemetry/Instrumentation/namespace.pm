package
    OpenTelemetry::Instrumentation::namespace;
# ABSTRACT: OpenTelemetry instrumentation for a namespace

our $VERSION = '0.028';

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

use parent 'OpenTelemetry::Instrumentation';

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
