#!/Users/brian/bin/perl
use v5.10;

use Cwd qw(getcwd);
use File::Basename;
use Mojo::UserAgent;

# https://perlmaven.com/yaml-vs-yaml-xs-inconsistencies

my @distros = map { "https://cpan.metacpan.org/authors/id/$_" } qw(
	T/TI/TINITA/YAML-1.30.tar.gz
	T/TI/TINITA/YAML-1.29.tar.gz
	T/TI/TINITA/YAML-1.28.tar.gz
	T/TI/TINITA/YAML-1.27.tar.gz
	T/TI/TINITA/YAML-1.26.tar.gz
	T/TI/TINITA/YAML-1.25.tar.gz
	T/TI/TINITA/YAML-1.24.tar.gz
	I/IN/INGY/YAML-1.23.tar.gz
	I/IN/INGY/YAML-1.22.tar.gz
	I/IN/INGY/YAML-1.21.tar.gz
	I/IN/INGY/YAML-1.20.tar.gz
	TINITA/YAML-1.19.tar.gz
	TINITA/YAML-1.18.tar.gz
	TINITA/YAML-1.17.tar.gz
	TODDR/YAML-Syck-1.34.tar.gz
	TODDR/YAML-Syck-1.32.tar.gz
	SMUELLER/YAML-Syck-1.19.tar.gz
	T/TI/TINITA/YAML-LibYAML-0.83.tar.gz
	T/TI/TINITA/YAML-LibYAML-0.82.tar.gz
	T/TI/TINITA/YAML-LibYAML-0.81.tar.gz
	T/TI/TINITA/YAML-LibYAML-0.80.tar.gz
	INGY/YAML-LibYAML-0.74.tar.gz
	E/ET/ETHER/YAML-Tiny-1.73.tar.gz
	E/ET/ETHER/YAML-Tiny-1.72.tar.gz
	A/AD/ADAMK/YAML-Tiny-1.51.tar.gz
	);

my $starting_dir   = getcwd();
my $test_yaml_file = $ARGV[0];
die "Specify the file to test" unless defined $ARGV[0];


my $ua = Mojo::UserAgent->new;

foreach my $distro ( @distros ) {
	my $tarball = basename($distro);
	my $dist_dir = $tarball =~ s/\.tar\.gz\z//r;
	my $module = $dist_dir =~ s/.*\K-.*//r =~ s/-/::/gr;
	$module = 'YAML::XS' if $module eq 'YAML::LibYAML';

	say "-" x 70;
	say "TARBALL: $tarball DIST_DIR: $dist_dir MODULE: $module";

	unless( -e $dist_dir ) {
		unless( -e $tarball ) {
			say "Downloading $distro";
			$ua->get( $distro )->result->save_to( $tarball );
			}
		system '/usr/bin/tar', '-xzf', $tarball;
		}

	unless( -e $dist_dir ) {
		warn "\tDist dir <$dist_dir> still does not exist";
		$hash{$dist_dir} = '-';
		next;
		}

	chdir $dist_dir or die "\tCould not change to <$dist_dir>: $!";
	say "\tCurrent dir is <$dist_dir>";

	unless( -e 'blib/lib' ) {
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
			$hash{$dist_dir} = '?';
			next;
			}
		}

	my @command = ($^X, qw(-Iblib/lib -Iblib/lib/auto -Iblib/arch), "-M$module=LoadFile", '-e', 'LoadFile(shift)', $test_yaml_file );
	say "\tCOMMAND: @command";

	$hash{$dist_dir} = system {$command[0]} @command;
	$hash{$dist_dir} >> 8;

	if( $hash{$dist_dir} ) {
		say "\tcommand failed <$rc>";
		}

	chdir $starting_dir;
	}

foreach my $module ( sort keys %hash ) {
	printf "%5s %s\n", $hash{$module}, $module;
	}
