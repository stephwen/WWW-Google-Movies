use warnings;
use strict;
use lib 'lib';
use WWW::Google::Movies;

my $showtimes = WWW::Google::Movies->new("city" => "Paris");
print "\nref showtimes: ";
print ref $showtimes;

my $theaters = $showtimes->theaters;
print "\nref theaters: ";
print ref $theaters;

my $theater = pop(@{$theaters});
print "\nref theater: ";
print ref $theater;

my $movies = $theater->movies;
print "\nref movies: ";
print ref $movies;

my $movie = pop(@{$movies});
print "\nref movie: ";
print ref $movie;

print "\nref movie->name: ";
print ref $movie->name;
print "\n".$movie->name;
print "\nref movie->info: ";
print ref $movie->info;
print "\n".$movie->info;
print "\nref movie->times: ";
print ref $movie->times;
