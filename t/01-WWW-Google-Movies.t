use warnings;
use strict;
use lib 'lib';
use Test::More;
use WWW::Google::Movies;

my $showtimes = WWW::Google::Movies->new("city" => "Paris", "date" => "2024-10-10");

ok( defined($showtimes) && ref $showtimes eq 'WWW::Google::Movies', 'new() works' );

my $theaters = $showtimes->theaters;
my @theatersArray = @{$theaters};
ok( defined($theaters) && ref $theaters eq 'ARRAY', 'theaters() works (1/2)' );

if (!@theatersArray) { done_testing(2); exit; }

ok(ref $theatersArray[0] eq 'Theater', 'theaters() works (2/2)' );

my $movies = $theatersArray[0]->movies;
my @moviesArray = @{$movies};
ok(defined($movies) && ref $movies eq 'ARRAY', 'movies() works (1/2)' );

if (!@moviesArray) { done_testing(4); exit; }

ok(ref $moviesArray[0] eq 'Movie', 'movies() works (2/2)' );

done_testing(5);