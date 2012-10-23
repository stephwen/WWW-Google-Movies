#!/usr/bin/perl
use strict;
use warnings;

package Movie;
use Moose;

has 'name' => (is	=> 'rw', isa	=> 'Str');
has 'info' => (is	=> 'rw', isa	=> 'Str');
has 'times' => (is	=> 'rw', isa	=> 'Str');

no Moose;
1;

package Theater;
use Moose;

has 'name' => (
	is	=> 'rw',
	isa	=> 'Str'
);

has 'movies' => (
	is	=> 'rw',
	isa	=> 'ArrayRef[Movie]',
	default => sub { [] },
    handles => {
            add => 'push',
            remove => 'pop'
    },
    traits  => ['Array'],
);

no Moose;
1;

package main;

use LWP::Simple;
use pQuery;
use Data::Dumper;
use utf8;
binmode STDOUT, ":encoding(UTF-8)";

my @theaters;

my $url = "http://www.google.com/movies?near=Li%C3%A8ge&date=0";		# pagination with &start=10
my $content = get($url) or die("Unable to fetch $url\n");
my $pq = pQuery($content) or die("Error parsing fetched url\n");

my $theaters = $pq->find(".theater");
$theaters->each(sub {
	my $theater_ = shift;			# pquery stuff
	my $theater = Theater->new;		# Moose object
	my $pQ = pQuery( $_ );
	$pQ->find(".desc")->each(sub {
		my $desc = shift;
		my $pQ = pQuery( $_ );
		$pQ->find(".name")->each(sub {
			my $titre = shift;
			my $pQ = pQuery( $_ );
			$theater->name($pQ->text);
		});		
	});
	$pQ->find(".showtimes")->each(sub {
		my $showtimes = shift;
		my $pQ = pQuery($_ );
		$pQ->find(".show_left")->each(sub {
			my $showleft = shift;
			my $pQ = pQuery($_ );
			$pQ->find(".movie")->each( sub {
				my $movie_ = shift;			# pquery stuff
				my $movie = Movie->new;		# Moose object
				my $pQ = pQuery($_ );
				$pQ->find(".name")->each( sub {
					my $name = shift;
					my $pQ = pQuery( $_ );
					$movie->name($pQ->text);
				});
				$pQ->find(".info")->each( sub {
					my $info = shift;
					my $pQ = pQuery( $_ );
					$movie->info($pQ->text);
				});
				$pQ->find(".times")->each( sub {
					my $times = shift;
					my $pQ = pQuery( $_ );
					# warning: there can be some non-timely parts (like "dubbed in french")
					$movie->times($pQ->text);
				});
				$theater->add($movie);
			});
		});
		$pQ->find(".show_right")->each(sub {
			my $showleft = shift;
			my $pQ = pQuery($_ );
			$pQ->find(".movie")->each( sub {
				my $movie_ = shift;			# pquery stuff
				my $movie = Movie->new;		# Moose object
				my $pQ = pQuery($_ );
				$pQ->find(".name")->each( sub {
					my $name = shift;
					my $pQ = pQuery( $_ );
					$movie->name($pQ->text);
				});
				$pQ->find(".info")->each( sub {
					my $info = shift;
					my $pQ = pQuery( $_ );
					$movie->info($pQ->text);
				});
				$pQ->find(".times")->each( sub {
					my $times = shift;
					my $pQ = pQuery( $_ );
					# warning: there can be some non-timely parts (like "dubbed in french")
					$movie->times($pQ->text);
				});
				$theater->add($movie);
			});
		});
	});
	
	
	push(@theaters, $theater);
	
});


foreach my $theater (@theaters) {
	print $theater->name."\n";
	foreach my $movie (@{$theater->movies}) {
		print "\t".$movie->name."\n";
		print "\t".$movie->info."\n";
		print "\t".$movie->times."\n";
	}
}



__DATA__

just so I don't forget the HTML tree of the webpage I'm parsing

id: results
	id: movie_results
		class: movie_results
			class: theater
				class: desc
					class: name		# theater name
					class: info		# theater adress
				class: showtimes
					class: show_left
						class: movie
							class: name		# movie name
							class: info
							class: times
					class: show_right
						class: movie
							class: name		# movie name
							class: info		# should be 4/5 fields, separated by " - ". Length, child rating, genre, language, subtitles language. Unfortunately, not always the case!
							class: times


you should have a look at this if you want to build a fully fledged app: http://search.cpan.org/~stepanov/IMDB-Film-0.52/lib/IMDB/Film.pm


possible internal data structure:

theaters
	movies
		name	Str
		info	Str
		times	Datetimes

		
How should this module behave ?

Something like 

my $foo = WWW::Google::Movies->new("cityName"); 
or 
my $foo = WWW::Google::Movies->new("cityName", $date);  perhaps ?

my $theaters = $foo->getTheaters();	# arrayRef

foreach my $theater (@$theaters) {
	my $movies = $theater->getMovies();
}

possible options for getMovies:
	* start time
	* genre
	* language
	* dubbed lang