#!/Users/brian/bin/perl
use v5.18;
use strict;
use experimental qw(signatures);

use Cwd qw(getcwd);
use File::Basename;
use File::Spec::Functions;

=head1 NAME

yaml-test.pl - see what Perl YAML modules work for the input

=head1 SYNOPSIS

	% yaml-test.pl some-file.yml

=head1 DESCRIPTION

The collection of Perl modules that deal with YAML act differently or
implement different parts of the YAML spec. There are annoying differences
even among different versions of the same module.

I've been bit by this on more than a few projects. In an ideal world I'd
get to change the input to suit the tool, but I don't always get to do
that. I made this little program to figure out which module/version works
for the input. Once I know that, I can specify the right prerequisites.

=head2 How it works

This program downloads, but does not install, several modules. It builds
them then uses the modules directly from their distribution directories.

=head1 TO DO

* Make a list of differences in the modules

=head1 SEE ALSO

=over 4

=item * https://perlmaven.com/yaml-vs-yaml-xs-inconsistencies

=back

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/yaml-module-test

=head1 AUTHOR

brian d foy, C<< bdfoy@cpan.org >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2021-2022, brian d foy, All Rights Reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

my @distros = glob( 'modules/*.gz' );

my $starting_dir   = getcwd();
my $test_yaml_file = catfile( $starting_dir, $ARGV[0] );

die "Specify the file to test" unless defined $ARGV[0];

my %hash;
foreach my $distro ( @distros ) {
	chdir $starting_dir;

	my $dist_dir = basename($distro) =~ s/\.tar\.gz\z//r;
	my $module = basename($dist_dir) =~ s/.*\K-.*//r =~ s/-/::/gr;
	$module = 'YAML::XS' if $module eq 'YAML::LibYAML';

	unless( -e $dist_dir ) {
		system '/usr/bin/tar', '-xzf', $distro;
		}

	$hash{$dist_dir}{exit_code} = '-';

	if( -e $dist_dir ) {
		chdir $dist_dir or die "\tCould not change to <$dist_dir>: $!";
		unless( make_dist() ) {
			next;
			}

		my @command = ($^X, qw(-Iblib/lib -Iblib/lib/auto -Iblib/arch), "-M$module=LoadFile", '-e', 'LoadFile(shift)', $test_yaml_file );
		my( $output, $error, $exit_code ) = run_command( \@command );

		$hash{$dist_dir}{exit_code} = $exit_code;
		$hash{$dist_dir}{error} = $error // '';
		}
	else {
		warn "\tDist dir <$dist_dir> still does not exist";
		}


	printf "%3d %-20s %s\n", $hash{$dist_dir}{exit_code}, $dist_dir, $hash{$dist_dir}{error};
	}

sub make_dist () {
	unless( -e 'blib/lib' ) {
		local $ENV{PERL5LIB} = ".:$ENV{PERL5LIB}" if -e "inc";
		if( -e 'Makefile.PL' ) {
			system $^X, 'Makefile.PL' and die "\tCould not run Makefile.PL: $!";
			system 'make';
			}
		elsif( -e 'Build.PL' ) {
			system $^X, 'Build.PL';
			system './Build';
			}
		else {
			warn "\tdid not find a build file";
			return;
			}
		}

	return 1;
	}

sub run_command ( $command ) {
	state $rc  = require IPC::Open3;
	state $rc2 = require Symbol;

	my( $in, $out );
	my $err = Symbol::gensym();

	my $pid = IPC::Open3::open3( $in, $out, $err, $command->@* );
	close($in);
	my $output = do { local $/; <$out> };
	my $error  = do { local $/; <$err> };
	$error =~ s/\s+\z//g;
	$error =~ s/ at -e line 1\.//g;
	$error =~ s/\s*\QBEGIN failed--compilation aborted.//g;
	$error =~ s/\v+/ || /g;
	waitpid($pid, 0);
	my $exit_code = $? >> 8;
	( $output, $error, $exit_code );
	}
