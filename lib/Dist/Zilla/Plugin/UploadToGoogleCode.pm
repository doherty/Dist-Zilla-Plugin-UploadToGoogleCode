package Dist::Zilla::Plugin::UploadToGoogleCode;
use strict;
use warnings;
# ABSTRACT: upload your dist to Google Code (experimental)
# VERSION
use Moose;
with qw(Dist::Zilla::Role::BeforeRelease Dist::Zilla::Role::Releaser);

use Moose::Util::TypeConstraints;
use Try::Tiny;
use namespace::autoclean;

=for Pod::Coverage mvp_multivalue_args

=cut

sub mvp_multivalue_args { qw(labels) }

has username => (
    is   => 'ro',
    isa  => 'Str',
    lazy => 1,
    required => 1,
    default  => sub {
        my ($self) = @_;
        return $self->googlecode_cfg->{username}
            || $self->zilla->chrome->prompt_str('Google code username: ');
    },
);

has password => (
    is   => 'ro',
    isa  => 'Str',
    lazy => 1,
    required => 1,
    default  => sub {
        my ($self) = @_;
        return $self->googlecode_cfg->{password}
            || $self->zilla->chrome->prompt_str(
                'Google Code password (from https://code.google.com/hosting/settings): ',
                { noecho => 1 }
            );
    },
);

has project => (
    is  => 'ro',
    isa => 'Str',
    lazy => 1,
    required => 1,
    default => sub { $_[0]->payload->{project} || lc $_[0]->zilla->name },
);

has labels => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    required => 1,
    default => sub { [qw( Featured Type-Archive OpSys-All )] },
);

has googlecode_cfg => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    lazy    => 1,
    default => sub {
        require Config::Identity;
        my %cfg = Config::Identity->load_best('googlecode');
        $cfg{username} = delete $cfg{user} unless $cfg{username};
        return \%cfg;
    },
);

has uploader => (
    is      => 'ro',
    isa     => 'Google::Code::Upload',
    handles => [qw/upload/],
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        require Google::Code::Upload;
        return Google::Code::Upload->new(
            project  => $self->project,
            username => $self->username,
            password => $self->password,
        );
    },
);

has summary => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
    lazy => 1,
    default => sub {
        my ($self) = @_;
        $self->zilla->name . '-' . $self->zilla->version . ': ' . $self->zilla->abstract
    },
);

has changelog => (
    is  => 'ro',
    isa => 'Str',
    default => 'Changes',
    predicate => 'has_changelog',
);

has description => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        return unless $self->has_changelog;

        my $last_release = try {
            $self->zilla->ensure_built_in;

            require File::pushd;
            my $wd = File::pushd::pushd( $self->zilla->built_in );

            require Dist::Zilla::File::OnDisk;
            my $changelog_content = Dist::Zilla::File::OnDisk->new({ name => $self->changelog })->content;

            require CPAN::Changes;
            my $changelog = CPAN::Changes->load_string( $changelog_content );
            my @releases  = $changelog->releases;
            pop @releases;
        }
        catch {
            warn $_;
            return;
        };

        return $last_release->serialize;
    },
);

=head1 METHODS

=head2 before_release

Checks that we have the data we need to release.

=cut

sub before_release {
    my $self = shift;

    $self->$_ || $self->log_fatal("You need to supply a $_")
        for qw(username password project);
}

=head2 release

Performs the release using L<Google::Code::Upload>.

=cut

sub release {
    my ($self, $archive) = @_;

    try {
        my $url = $self->upload(
            file        => "$archive",
            summary     => $self->summary,
            labels      => $self->labels,
            ( $self->description ? (description => $self->description) : ()),
        );
        $self->log("Uploaded to $url");
    }
    catch {
        $self->log("The file wasn't uploaded: $_");
    };
}

__PACKAGE__->meta->make_immutable;

1;

=head1 SYNOPSIS

If loaded, this plugin will allow the F<release> command to upload to Google Code.

=for test_synopsis
1;
__END__

=head1 DESCRIPTION

This plugin looks for the Google Code project name in F<dist.ini>, and gets your
Google Code credentials from F<~/.googlecode-identity> (which can be
GnuPG-encrypted; see L<Config::Identity>).

If any configuration is missing, it will prompt you to enter your
username and password during the BeforeRelease phase.  Entering a
blank username or password will abort the release.

=head1 ATTRIBUTES

=head2 username

This option supplies the user's Google Code username. If not supplied, it will
be looked for in the user's GoogleCode configuration.

=head2 password

This option supplies the user's Google Code password (ie, from
L<https://code.google.com/hosting/settings>). If not supplied, it will be
looked for in the user's GoogleCode configuration.

=head2 googlecode_cfg

This is a hashref of defaults loaded from F<~/.googlecode-identity>.
