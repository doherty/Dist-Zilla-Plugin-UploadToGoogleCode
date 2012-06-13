package Dist::Zilla::Plugin::UploadToGoogleCode;
use strict;
use warnings;
# ABSTRACT: upload your dist to Google Code
# VERSION
use Moose;
with qw(Dist::Zilla::Role::BeforeRelease Dist::Zilla::Role::Releaser);

use Google::Code::Upload qw(upload);
use Moose::Util::TypeConstraints;
use Scalar::Util qw(weaken);
use Try::Tiny;
use namespace::autoclean;


has credentials_stash => (
    is  => 'ro',
    isa => 'Str',
    default => '%GoogleCode'
);

has _credentials_stash_obj => (
    is   => 'ro',
    isa  => maybe_type( class_type('Dist::Zilla::Stash::GoogleCode') ),
    lazy => 1,
    init_arg => undef,
    default  => sub { $_[0]->zilla->stash_named( $_[0]->credentials_stash ) },
);

sub _credential {
    my ($self, $name) = @_;

    return unless my $stash = $self->_credentials_stash_obj;
    return $stash->$name;
}

sub mvp_aliases {
    return { user => 'username' };
}


has username => (
    is   => 'ro',
    isa  => 'Str',
    lazy => 1,
    required => 1,
    default  => sub {
        my ($self) = @_;
        return $self->_credential('username')
            || $self->googlecode_cfg->{username}
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
        return $self->_credential('password')
            || $self->googlecode_cfg->{password}
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
    default => sub {
        my ($self) = @_;
        return $self->name;
    },
);

has labels => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    required => 1,
    default => sub { [qw( Type-Archive )] },
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

sub before_release {
    my $self = shift;
    die $self->project;

    $self->$_ || $self->log_fatal("You need to supply a $_")
        for qw(username password project);
}

sub release {
    my ($self, $archive) = @_;

    my ($status, $reason, $url) = upload(
        "$archive",
        $self->project,
        $self->username,
        $self->password,
        'test',
        $self->labels
    );

    if ($url) {
        $self->log("Uploaded to $url");
    }
    else {
        $self->log('An error occurred, and your file was not uploaded.');
        $self->log("The Google Code server said: $reason ($status)");
    }
}

__PACKAGE__->meta->make_immutable;

1;

=head1 SYNOPSIS

If loaded, this plugin will allow the F<release> command to upload to Google Code.

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
