#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use WWW::Google::Movies;
binmode STDOUT, ":encoding(UTF-8)";

my $foo = WWW::Google::Movies->new("city" => "Liège");
#$foo = WWW::Google::Movies->new("city" => "Liège", "date" => "2012-10-27");

print $foo->get_date."\n";
print $foo->city."\n";
print $foo->nbDays."\n";
print $foo->url."\n";

foreach my $theater (@{$foo->theaters}) {
	print $theater->name."\n";
	foreach my $movie (@{$theater->movies}) {
		print "\t".$movie->name."\n";
		print "\t".$movie->info."\n";
		foreach my $time (@{$movie->times}) {
			print "\t".$time;
		}
		print "\n";
	}
}