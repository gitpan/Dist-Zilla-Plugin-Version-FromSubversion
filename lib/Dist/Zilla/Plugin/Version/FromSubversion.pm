use strict;
use warnings;
package Dist::Zilla::Plugin::Version::FromSubversion;
{
  $Dist::Zilla::Plugin::Version::FromSubversion::VERSION = '1.000012';
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

has fallback_revision => (
    is       => 'ro',
    isa      => 'Str',
);


sub provide_version
{
    my $self = shift;

    my $rev;
    my $root = $self->zilla->root;

    # Are we in a working copy?
    if (-d $root->subdir('.svn')) {
	require SVN::Client;
	my $svn = SVN::Client->new or die "can't initialize SVN::Client";

	$svn->info("", undef, undef, sub { $rev = $_[1]->rev }, 0);

	my $dist_ini = $root->file('dist.ini')->absolute->stringify;
	if (-f $dist_ini && $self->fallback_revision) {
	    my $kwd = $svn->propget('svn:keywords', $dist_ini, undef, 0);
	    unless (exists $kwd->{$dist_ini}
		&& grep /^Rev(?:ision)$/, split ' ', $kwd->{$dist_ini}) {
		$self->log_fatal("enable svn:keywords expansion on dist.ini to activate fallback_revision:\n  svn propset svn:keywords \"Revision\" dist.ini");
	    }
	}
    } else {
	my $fb = $self->fallback_revision;
	unless ($fb) {
	    $self->log_fatal("not in a Subversion working copy. Use the fallback_revision option in dist.ini or switch to [AutoVersion]");
	}
	unless ($fb =~ /\$(?:Rev(?:ision)?|LastChangedRevision): ([0-9]+)\S*\s*\$/) {
	    $self->log_fatal('invalid fallback_revision value: use $Revision: $');
	}
	$rev = $1;
    }


    my $version = $self->fill_in_string(
	$self->format,
	{
	    major => \( $self->major ),
	    revision => $rev,
	},
    );

    $self->log([ 'providing version %s', $version ]);

    return $version;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Dist::Zilla::Plugin::Version::FromSubversion - Use the revision of the working directory

=head1 VERSION

version 1.000012

=head1 SYNOPSIS

In dist.ini:

    [Version::FromSubversion]
    ; optional, default is 1
    major = 0
    ; optional, default is something like sprintf('%u.%06u', $major, $revision)
    format = {{ $major }}.{{ sprintf('%06u', $revision) }}
    ; optional. The svn:keywords property must be set to 'Revision' on dist.ini
    fallback_revision = $Revision: $

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

The C<fallback_revision> option can be used for the cases where the distribution
is not built from a working copy but from an export (svn export). For example,
integration tools such as Jenkins. For this case we are using the
C<svn:keywords> property on F<dist.ini> to be able to retrieve the revision
number from a known place.

Notes:

=over 4

=item *

It is the user responsability to keep the directory up to date (with
"C<svn update .>"). The plugin currently does not even warn if the release
is made from a directory which is not clean (everything committed).

=back

=head1 EXAMPLE

This distribution is built with itself. You can checkout its Subversion
repository from Google Code:

  svn checkout http://dist-zilla-plugin-version-fromsubversion.googlecode.com/svn/trunk/ DZ-P-Version-FromSubversion

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
