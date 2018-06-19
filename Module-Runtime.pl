use v5.14;
use strict;
use warnings;

our $dist    = 'Module-Runtime';
our $origmod = "Module::Runtime";
our $altdist = sprintf('Alt-%s-ButEUMM', $dist);
our $altver  = '0.002';
our @cruft   = qw(
	.gitignore Build.PL Changes Makefile.PL MANIFEST
	META.json META.yml README SIGNATURE
);

our $abstract = "alternative distribution of $origmod, using ExtUtils::MakeMaker";
our $description = "This is an alternative distribution of $origmod, "
	. "allowing easier deployment on very old versions of Perl. "
	. "If you have had no problems installing $origmod, "
	. "then you do not need this module!";

our $tweak_meta = sub {
	my $meta = shift;
	$meta->{prereqs}{test}{requires}{"Test::More"} = '0.47';
};

do "./common.pl" or die($@);
