#!/usr/bin/perl
use lib 'lib';
use Test::Simple tests => 1;
use WWW::Google::Movies;

my $showtimes = WWW::Google::Movies->new("city" => "Paris");
ok( defined($showtimes) && ref $showtimes eq 'WWW::Google::Movies', 'new() works' );