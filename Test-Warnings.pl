use v5.14;
use strict;
use warnings;

our $dist    = 'Test-Warnings';
our $origmod = "Test::Warnings";
our $altdist = sprintf('Alt-%s-ButEUMM', $dist);
our $altver  = '0.001';
our @cruft   = qw(
	Build.PL Changes CONTRIBUTING dist.ini INSTALL Makefile.PL
	MANIFEST META.json META.yml README README.md weaver.ini xt/
);

our $abstract = "alternative distribution of $origmod, using ExtUtils::MakeMaker";
our $description = "This is an alternative distribution of $origmod, "
	. "allowing easier deployment on very old versions of Perl. "
	. "If you have had no problems installing $origmod, "
	. "then you do not need this module!";

do "common.pl" or die($@);
