
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "upload your dist to Google Code (experimental)",
  "dist_author" => [
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "Dist-Zilla-Plugin-UploadToGoogleCode",
  "dist_version" => "0.003",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Plugin::UploadToGoogleCode",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "CPAN::Changes" => 0,
    "Config::Identity" => 0,
    "Dist::Zilla::File::OnDisk" => 0,
    "Dist::Zilla::Role::BeforeRelease" => 0,
    "Dist::Zilla::Role::Releaser" => 0,
    "File::pushd" => 0,
    "Google::Code::Upload" => "0.006",
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
