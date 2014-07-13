use v5.14;
use strict;
use warnings;

use HTTP::Tiny;
use JSON::PP;
use Path::Tiny;
use Archive::Tar;
use File::chdir;

our ($dist, $origmod, $altdist, $altver, @cruft);

# Fetch data about original distribution
my $ua   = "HTTP::Tiny"->new;
my $json = "JSON::PP"->new;
my $meta = $json->decode(
	$ua->get('http://api.metacpan.org/v0/release/'.$dist)->{content}
);

# Download and extract original distribution
{
	my $tar = "Archive::Tar"->new;
	$ua->mirror($meta->{download_url}, $meta->{archive});
	$tar->read($meta->{archive});
	$tar->extract;
	unlink($meta->{archive});
}

# Rename the directory
my $newname;
{
	my $dirname = ($meta->{archive} =~ s/\.(tar.gz|tgz|tar.bz2|tbz2|zip)$//r);
	$newname = path sprintf('%s.%s', $altdist, 'tmp');
	rename($dirname, $newname);
}

# Read META.json
my $METAjson = do {
	$json->decode( $newname->child('META.json')->slurp_raw );
};

our $tweak_meta;
if ($tweak_meta) {
	$tweak_meta->($METAjson);
}

# Prune cruft
for (@cruft) {
	my $cruft = $newname->child($_);
	m{/$} ? $cruft->remove_tree : $cruft->remove;
}

# Create cpanfile
{
	my $cpanfile = $newname->child('cpanfile')->openw_utf8;
	my $output_deps = sub {
		my ($set, $indent) = @_;
		$indent //= "";
		
		for my $level (qw/ requires recommends suggests conflicts /) {
			for my $dep (sort keys %{$set->{$level}}) {
				my $ver = $set->{$level}{$dep};
				my $fmt = $ver
					? "%s%s '%s', '%s';\n"
					: "%s%s '%s';\n";
				printf {$cpanfile} $fmt, $indent, $level, $dep, $ver;
			}
		}
	};
	$output_deps->($METAjson->{prereqs}{runtime});
	if ($METAjson->{prereqs}{test}) {
		print {$cpanfile} "\n";
		print {$cpanfile} "on 'test' => sub {\n";
		$output_deps->($METAjson->{prereqs}{test}, "\t");
		print {$cpanfile} "};\n";
	}
}

# Create dist.ini
{
	our ($abstract);
	require B;
	my $authors = sprintf(
		'[%s]',
		join(",", map B::perlstring($_), @{$METAjson->{author}}),
	);
	my $docs = B::perlstring(path(__FILE__)->parent->child('docs')->absolute);
	$newname->child('dist.ini')->spew_utf8(
		";;class='Dist::Inkt::Profile::Simple'\n",
		";;name='$altdist'\n",
		";;abstract=".B::perlstring($abstract)."\n",
		";;author=$authors\n",
		";;license=['$METAjson->{license}[0]']\n",
		";;standard_documents_dir=$docs\n",
	);
}

# Create lead module
{
	my $module = ($altdist =~ s/-/::/gr);
	
	our ($abstract, $description);
	
	my $file = $newname->child("lib/" . ($module =~ s{::}{/}gr) . ".pm");
	$file->parent->mkpath;
	
	$file->spew_utf8(
		"use strict;\n",
		"use warnings;\n\n",
		"package $module;\n\n",
		"our \$AUTHORITY = 'cpan:TOBYINK';\n",
		"our \$VERSION   = '$altver';\n\n",
		"1;\n\n",
		"=pod\n\n",
		"=encoding utf8\n\n",
		"=head1 NAME\n\n",
		"$module - $abstract\n\n",
		"=head1 SYNOPSIS\n\n",
		"   use $origmod;\n\n",
		"=head1 DESCRIPTION\n\n",
		"$description\n\n",
		"Version $altver of $module includes version $meta->{version} of $origmod.\n\n",
		"=head1 SEE ALSO\n\n",
		"L<Alt>, L<$origmod>.\n\n",
		"=head1 COPYRIGHT, LICENCE, AND DISCLAIMER OF WARRANTIES\n\n",
		"This file is distributed under the same conditions as L<$origmod>.\n\n",
		"=cut\n\n",
	);
}

# Hook META.json creation
{
	my $metapl = $newname->child("meta/META.PL");
	$metapl->parent->mkpath;
	$metapl->spew_utf8(
		map {
			my $pkg = $_;
			"print STDERR qq/Do not index package '$pkg'\\n/;\n",
			"push \@{ \$_->{no_index}{package} ||= [] }, '$pkg';\n\n";
		} ($origmod, our @no_index)
	);
}

our $tweak_dir;
if ($tweak_dir) {
	$tweak_dir->($newname);
}

# Build dist
{
	local ($CWD) = $newname;
	system("distinkt-dist");
}
my $tarball = $newname->child(sprintf('%s-%s.tar.gz', $altdist, $altver));
$tarball->exists or die("could not find tarball!");
rename $tarball, path(__FILE__)->parent->child($tarball->basename);
$newname->remove_tree;
exit(0);
