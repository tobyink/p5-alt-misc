use v5.14;
use strict;
use warnings;

our $dist    = 'Class-Tiny';
our $origmod = "Class::Tiny";
our $altdist = sprintf('Alt-%s-ButPerl56', $dist);
our $altver  = '0.001';
our @cruft   = qw(
	Changes CONTRIBUTING cpanfile dist.ini LICENSE Makefile.PL MANIFEST
	META.json META.yml perlcritic.rc README tidyall.ini xt/
);

our @no_index = qw( Class::Tiny::Object );

our $abstract = "alternative distribution of $origmod, with Perl 5.6 support";
our $description = "This is an alternative distribution of $origmod, "
	. "allowing use on Perl 5.6.x. "
	. "If you have had no problems installing $origmod, "
	. "then you do not need this module!\n\n"
	. "Hopefully an official release of $origmod with support for Perl 5.6 will happen, "
	. "and I'll be able to remove this abomination from the CPAN. :-)";

our $tweak_meta = sub {
	my $meta = shift;
	$meta->{prereqs}{runtime}{requires}{perl} = '5.006';
};

our $tweak_dir = sub {
	my $dir = shift;
	
	# Adjust 'use 5.008001' lines
	system find => (
		$dir,
		-type => "f",
		-exec => ("sed", "-i", "s/use 5\.008001/use 5.006/", "{}", ";"),
	);
	
	# Requires MRO::Compat and Devel::GlobalDestruction on old Perls.
	$dir->child('meta/DYNAMIC_CONFIG.PL')->spew_utf8(
		"eval { require mro; } or \n",
		"\t\$meta->{prereqs}{runtime}{requires}{'MRO::Compat'} = 0;\n\n",
		"\$] >= 5.014 or \n",
		"\t\$meta->{prereqs}{runtime}{requires}{'Devel::GlobalDestruction'} = 0;\n\n",
	);
};

do "common.pl" or die($@);
