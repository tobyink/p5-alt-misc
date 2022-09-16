use v5.14;
use strict;
use warnings;
use File::chdir;

our $dist    = 'Lexical-Var';
our $origmod = "Lexical::Var";
our $altdist = sprintf('Alt-%s-ButSupportModernPerl', $dist);
our $altver  = '0.001';
our $origver = '0.009';
our @cruft   = qw(
	.gitignore Build.PL Changes Makefile.PL MANIFEST
	META.json META.yml README SIGNATURE
);

our @no_index = qw( Lexical::Var Lexical::Sub );

our $abstract = "alternative distribution of $origmod, with support for more modern versions of Perl";
our $description = "This is an alternative distribution of $origmod, "
	. "allowing use on Perl 5.21.7 and above. "
	. "If you have had no problems installing $origmod, "
	. "then you do not need this module!\n\n"
	. "Hopefully an official release of $origmod with support for modern Perl will happen, "
	. "and I'll be able to remove this abomination from the CPAN. :-)";

our $tweak_meta = sub {
	my $meta = shift;
	$meta->{prereqs}{runtime}{requires}{perl} = '5.008001';
};

our $tweak_dir = sub {
	my $dir = shift;
	
	system(
		chmod => ( '-R', 'u+rwX', $dir ),
	);
	
	$dir->child( 'meta/DYNAMIC_CONFIG.PL' )->spew( sprintf <<'CONFIG', $dist, $origver );
$meta->{name}           = '%s';
$meta->{version}        = '%s';
$dynamic_config{LIBS}   = [''];
$dynamic_config{DEFINE} = '';
$dynamic_config{INC}    = '-I.';
CONFIG
	
	system(
		patch => (
			'-d'   => $dir,
			'-i'   => $dir->parent->child( 'patches/lexvar.patch' )->absolute,
			'-p1',
		)
	);
	
	system(
		mv => ( "$dir/lib/Lexical/Var.xs", "$dir/Var.xs" ),
	);
};

do "./common.pl" or die($@);
