#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;
BEGIN {
	plan skip_all => '$ENV{AUTHOR_TESTING} is false, skipping tests' unless $ENV{AUTHOR_TESTING};
	plan tests    => 5;
}
use Test::WWW::Mechanize::PSGI;

my $mech = Test::WWW::Mechanize::PSGI->new(app => do 'app.psgi');
$mech->get_ok('/');
$mech->title_is('Gruntmaster 6000');

$mech->get_ok('/pb/');
$mech->title_is('Problems');
$mech->content_contains('Spell');
