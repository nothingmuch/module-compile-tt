#!/usr/bin/perl

package tt;
use Module::Compile -base;

use strict;
use warnings;

use Template;

our $VERSION = "0.01";

sub default_tt_config {
	return (
		INTERPOLATE        => 0,
		EVAL_PERL          => 1,
		INCLUDE_PATH       => [ @INC ],
		LOAD_PERL          => 1,
		DEBUG              => "undef",
	);
}

sub default_tt_vars {
	my $class = shift;
	return (
		filter_class => $class,
		'package'    => undef,
		file         => undef,
		from_line    => undef,
		to_line      => undef,
	);
}

sub pmc_compile {
	my ( $class, $source, $extra ) = @_;

	# try to make vars out of the use line
	my %use_opts = do {
		( my $vars = $extra->{use} ) =~ s/^\s*use\s+tt\s*//;
		eval "$vars";
	};

	die "error evaluating vars on use line ($extra->{use}): $@"
		if $@;


	# try to remove keys that look like TT configuration
	my %config = (
		$class->default_tt_config,
		map { $_ => delete $use_opts{$_} } grep /^[A-Z_]+$/, keys %use_opts,
	);

	my %vars = (
		$class->default_tt_vars,
		%use_opts,
	);

	my $t = Template->new(\%config) || die Template->error;

	$t->process( \$source, \%vars, \( my $out ) ) || die $t->error;
	$out || die $t->error;

	return $out;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

tt - Preprocess Perl code with Template Toolkit and Module::Compile.

=head1 SYNOPSIS

	use tt ( subs => [qw/foo bar gorch/] );

	[% FOREACH subname IN subs %]
	sub [% subname %] {
		warn "Hi, i'm [% subname %]";
	}
	[% END %]

	no tt;

=head1 DESCRIPTION

This module uses Module::Compile to help you generate Perl code without using
BEGIN/eval tricks and reducing readability, but without having to repeat
yourself either.

=head1 CONFIGURATION

To configure L<Template> either subclass this module and override
C<default_tt_config>, or pass parameters in the C<use tt> line.

Note that due to the way L<Module::Compile> works you must put all the
variables on one use line.

For example:

	use tt INCLUDE_PATH => "/foo";

The default configuration values are:

		INTERPOLATE        => 0,
		EVAL_PERL          => 1,
		INCLUDE_PATH       => [ @INC ],
		LOAD_PERL          => 1,
		DEBUG              => "undef",

This provides a default that is slightly more suitable for templating code than
normal TT defaults. DEBUG_UNDEF ensures that no undef variables are
interpolated, INTERPOLATE being off ensures that perl variables aren't treated
as TT variables by accident, and the other options allow for a more permissive
use of features.

=head1 VARIABLES

Like configuration parameters, you may pass variables on the C<use tt> line.

Variables and configuration options are destingushed - anything that is all
upper case in the use line is considered configuration.

A probably better way to declare variables is simply in the template itself:

	[% foo = "bar" %]

=head1 CAVEATS

Due to L<Module::Compile>'s semantics the use line is actually fudged and
string-evaled by this module, so it might break and you can't refer to
lexicals.

=head1 TODO

Add all sorts of useful variables about the package that the template is
processing, the file and line numbers, etc.

Currently L<Module::Compile> doesn't provide enough facilities for this.

=head1 SEE ALSO

L<Template>, L<Module::Compile>, L<Filter::Simple>

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

        Copyright (c) 2006 the aforementioned authors. All rights
        reserved. This program is free software; you can redistribute
        it and/or modify it under the same terms as Perl itself.

=cut
