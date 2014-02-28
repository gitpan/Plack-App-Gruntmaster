package Plack::App::Gruntmaster;

use 5.014000;
use strict;
use warnings;
use parent qw/Plack::Component/;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
our $VERSION = '5999.000_001';

use File::Slurp qw/read_file/;
use HTTP::Negotiate qw/choose/;
use Plack::Request;
use Gruntmaster::Page::Log;
use Gruntmaster::Page::Pb::Entry;
use Gruntmaster::Page::Generic;

my %handlers;

sub call {
	my $env = $_[1];
	my $r = Plack::Request->new($env);
	my @handlers = @{ $handlers{$r->method} // [] };
	for my $handler (@handlers) {
		my ($re, $obj) = @$handler;
		my @args;
		next unless @args = $r->path =~ m/^$re$/a;
		my $format = choose $obj->variants, $r->headers;
		return $obj->generate($format, $env, map { $_ // '' } @args);
	}

	if ($r->method eq 'GET' || $r->method eq 'HEAD') {
		my $article = $r->path eq '/' ? '/index' : $r->path;
		$article = substr $article, 1;
		$article =~ tr,/,_,;
		my @variants = grep { !/\.title$/ } <a/$article.*>;
		if (@variants) {
			my $lang = choose [ map { [$_, 1, 'text/html', undef, undef, $_, undef] } map { /\.(.+)$/ } @variants ], $r->headers;
			my $content = read_file "a/$article.$lang";
			my $title = read_file "a/$article.$lang.title";
			my $html = Gruntmaster::Page::Base::header($lang, $title) . $content . Gruntmaster::Page::Base::footer($lang);
			return [200, ['Content-Type' => 'text/html', 'Content-Language' => $lang, 'Vary' => 'Accept-Language', 'X-Forever' => 1, 'Cache-Control' => 'max-age=300'], [$html] ]
		}
	}

	[404, ['Content-Type' => 'text/plain'], ['Not found']]
}

sub get  {
	my ($re, $obj) = @_;
	eval "require Gruntmaster::Page::$obj" or die $@;
	push @{$handlers{GET }}, [ $re, "Gruntmaster::Page::$obj" ]
}

sub post {
	my ($re, $obj) = @_;
	eval "require Gruntmaster::Page::$obj" or die $@;
	push @{$handlers{POST}}, [ $re, "Gruntmaster::Page::$obj" ]
}

BEGIN{
	my $word = qr,(\w+),a;
	my $ct = qr,(?:\/ct/$word)?,a;

	sub generic {
		my ($thing, $ct, $fs) = @_;
		$ct //= '', $fs //= '';
		my $pkg = ucfirst $thing;
		get  qr,$ct/$thing/,             => $pkg;
		get  qr,$ct/$thing/read,         => "${pkg}::Read";
		get  qr,$ct/$thing/$word$fs,     => "${pkg}::Entry";
#		post qr,$ct/$thing/$word/create, => "${pkg}::Entry::Create";
		get  qr,$ct/$thing/$word/read,   => "${pkg}::Entry::Read";
#		post qr,$ct/$thing/$word/update, => "${pkg}::Entry::Update";
#		post qr,$ct/$thing/$word/delete, => "${pkg}::Entry::Delete";
	}

	get qr,/css/$word\.css, => 'CSS';
	get qr,/js\.js, => 'JS';

	generic 'us';
	generic ct => '', '/';
	generic pb => $ct;
	#generic log => $ct;

	get qr,$ct/log/(\d+)?, => 'Log';
	get qr,$ct/log/st, => 'St';
	get qr,$ct/log/job/$word, => 'Log::Entry';
	get qr,$ct/log/job/$word/read, => 'Log::Entry::Read';
	get qr,$ct/log/src/$word\.$word, => 'Src';
	post qr,$ct/pb/$word/submit, => 'Submit';

	post qr,/action/register, => 'Register';
	post qr,/action/passwd, => 'Passwd';
}

1;
__END__
