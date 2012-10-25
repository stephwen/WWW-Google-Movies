﻿#!/usr/bin/perl
use strict;
use warnings;

package Movie;
use Moose;

has 'name' => (is	=> 'rw', isa	=> 'Str');
has 'info' => (is	=> 'rw', isa	=> 'Str');
has 'times' => (
	is	=> 'rw',
	isa	=> 'ArrayRef[Str]',
	default => sub { [] },
    handles => {
            addTime => 'push',
            removeTime => 'pop'
    },
    traits  => ['Array'],
);

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
            addMovie => 'push',
            removeMovie => 'pop'
    },
    traits  => ['Array'],
);

no Moose;
1;

package WWW::Google::Movies;
use Moose;
use Moose::Util::TypeConstraints;
use Date::Simple ('date', 'today');
use URI::Escape;
use LWP::Simple;
use pQuery;

subtype 'DateSimple'
	=> as Object
	=> where { $_->isa('Date::Simple') };

coerce 'DateSimple' => from 'Str' => via { Date::Simple->new($_) };

has 'city'			=> (is => 'ro', isa => 'Str', required => 1);
has 'date'			=> (
	is 		=> 'ro',
	isa		=> 'DateSimple',
	default	=> sub { today() },
	writer 	=> "_set_date",
	reader 	=> "get_date",
	coerce	=> 1
);

has 'nbDays' 		=> (is => 'rw', isa => 'Int', writer => "_set_nbDays");	# 0 = today, 1 = tomorrow, etc.
has 'lang'			=> (is => 'rw', isa => 'Str', default => "en");
has 'url' 			=> (is => 'rw', isa => 'Str', writer => "_set_url");
has 'theaters' 		=> (
	is		=> 'rw',
	isa		=> 'ArrayRef[Theater]',
	default => sub { [] },
    handles => {
            addTheater => 'push',
            removeTheater => 'pop'
    },
    traits  => ['Array'],
);

# The magic happens here
sub BUILD {
	my $self = shift;
	my $diff = $self->get_date - today();
	$self->_set_nbDays($diff);
	#$self->_set_url("http://www.google.com/movies?near=".uri_escape($self->city)."&date=".$self->nbDays."&hl=".$self->lang);
	$self->_set_url("http://www.google.com/movies?near=".$self->city."&date=".$self->nbDays."&hl=".$self->lang);
	# which one is correct?
	#	On Win7 	=> without uri_escape
	#	On Ubuntu	=> TODO
	
	my $content = get($self->url) or die("Unable to fetch ".$self->url."\n");
	my $pq = pQuery($content) or die("Error parsing fetched url\n");
	
	# first check to see if they are movies at the specified place and date
	if ($pq->find(".movie_results")->length()) {
		print "movies found\n";
		# change this TODO
	} else {
		print "movies not found\n";
		# will have to return an error TODO
	}
	
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
						my $timesText = $pQ->text; 
						# warning: there can be some non-timely parts (like "dubbed in french")
						$timesText =~ s/[^\d:\s]+//g;	# keep only digits and colons characters
						$timesText =~ s/\s+/ /g;		# multi white space becomes space
						$timesText =~ s/^\s//g;			# remove first white space
						my @times = split(/ /, $timesText);
						$movie->times(\@times);
					});
					$theater->addMovie($movie);
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
						my $timesText = $pQ->text; 
						# warning: there can be some non-timely parts (like "dubbed in french")
						$timesText =~ s/[^\d:\s]+//g;	# keep only digits and colons characters
						$timesText =~ s/\s+/ /g;		# multi white space becomes space
						$timesText =~ s/^\s//g;			# remove first white space
						my @times = split(/ /, $timesText);
						$movie->times(\@times);
					});
					$theater->addMovie($movie);
				});
			});
		});
		
		$self->addTheater($theater);
		
	});
	
}

no Moose;
1;








package main;

use LWP::Simple;
use pQuery;
use utf8;
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

$foo->getMovies

possible options for getMovies:
	* start time	=> exact time, or range
	* genre
	* language
	* dubbed lang
	* duration
