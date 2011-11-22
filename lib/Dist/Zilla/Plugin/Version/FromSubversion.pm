use strict;
use warnings;
package Dist::Zilla::Plugin::Version::FromSubversion;
{
  $Dist::Zilla::Plugin::Version::FromSubversion::VERSION = '1.000002';
}
{
  $Dist::Zilla::Plugin::Version::FromSubversion::VERSION = '1.000001';
}
{
  $Dist::Zilla::Plugin::Version::FromSubversion::VERSION = '1.000001';
}

use Moose;
with (
    'Dist::Zilla::Role::VersionProvider',
    'Dist::Zilla::Role::TextTemplate',
);

has major => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    default  => 1,
);

has format => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => q<{{     $major + int($revision / 1_000_000) }}>
              . q<.{{ sprintf '%06u', $revision % 1_000_000 }}>
              . q<{{$ENV{DEV} ? (sprintf '_%03u', $ENV{DEV}) : ''}}>
);


sub provide_version
{
    my $self = shift;

    require SVN::Client;
    my $svn = SVN::Client->new or die "can't initialize SVN::Client";

    my $rev;
    $svn->info("", undef, undef, sub { $rev = $_[1]->rev }, 0);

    my $version = $self->fill_in_string(
	$self->format,
	{
	    major => \( $self->major ),
	    revision => $rev,
	},
    );

    $self->log_debug([ 'providing version %s', $version ]);

    return $version;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Dist::Zilla::Plugin::Version::FromSubversion - Use the revision of the working directory

=head1 VERSION

version 1.000002

=head1 SYNOPSIS

In dist.ini:

    [Version::FromSubversion]
    ; optional, default is 1
    major = 0
    ; optional, default is something like sprintf('%u.%06u', $major, $revision)
    format = {{ $major }}.{{ sprintf('%06u', $revision) }}

To do a release:

    $ svn update .
    $ dzil release

=head1 DESCRIPTION

B<Using revision numbers of the versioning system is a *really bad* idea: that
will not scale>. For example, it will not work if you start to use branches and
want to make releases from them because revision numbers are global, and not
per branch. So keep this only for small projects and be prepared to change you
version scheme if that goes wrong!

This plugin build a version number for a release from the Subversion revision
number of the current directory.

Notes:

=over 4

=item *

It is the user responsability to keep the directory up to date (with
"C<svn update .>"). The plugin currently does not even warn if the release
is made from a directory which is not clean (everything committed).

=item *

This plugin works only from a working copy of your repository. This means that
the F<.svn> directory must exists.

So this will not work from content extracted from the repository using
C<svn export>. If you want to make release from that context, use this instead:

    $ svn propset svn:keywords Revision dist.ini

In dist.ini:

    [AutoVersion]
    major = 1
    format = {{ $major }}.{{ sprintf '%06u', ("$Revision: $" =~ /(\d+)/) }}


=back

=head1 SEE ALSO

Some suggestions of plugins to use in combination with this one:

=over 4

=item *

L<Dist::Zilla::Plugin::NextRelease>

=item *

L<Dist::Zilla::Plugin::PkgVersion>

=back

=head1 AUTHOR

Olivier MenguE<eacute>, L<mailto:dolmen@cpan.org>.

Some code from L<Dist::Zilla::Plugin::AutoVersion> by Ricardo Signes has been
reused here.

=head1 COPYRIGHT AND LICENSE

Copyright E<copy> 2011 Olivier MenguE<eacute>.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl 5 itself.

=cut
