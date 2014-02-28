package Gruntmaster::Page::Base;

use 5.014000;
use strict;
use warnings;
our $VERSION = '5999.000_001';

use File::Slurp qw/read_file/;
use HTML::Template::Compiled;

##################################################

sub read_templates {
	my $root = 'tmpl';
	my $name = shift;

	map { m/\.(.+)$/; $1 => scalar read_file $_ } <tmpl/$name.*>;
}

my %header_templates = read_templates 'header';
my %footer_templates = read_templates 'footer';

sub header{
  my ($language, $title) = @_;
  $header_templates{$language} =~ s/TITLE_GOES_HERE/$title/ger;
}

sub footer{
  $footer_templates{$_[0]};
}

##################################################

use POSIX ();
use Gruntmaster::Data ();
use List::Util ();
use LWP::UserAgent;
use Plack::Request ();
use feature ();

my $ua = LWP::UserAgent->new;
my %templates;

use Carp qw/cluck/;

sub import_to {
	my ($self, $caller, $name, $title) = @_;

	strict->import;
	feature->import(':5.14');
	warnings->import;
	File::Slurp->export_to_level(1, $caller, qw/read_file/);
	Gruntmaster::Data->export_to_level(1, $caller);
	List::Util->export_to_level(1, $caller, qw/sum/);

	no strict 'refs';
	*{"${caller}::ISA"} = [__PACKAGE__];
	*{"${caller}::VERSION"} = $VERSION;
	*{"${caller}::strftime"} = \&POSIX::strftime;
	*{"${caller}::debug"} = sub {
		local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
		$_[0]->{'psgix.logger'}->({qw/level debug message/ => $_[1]})
	};
	*{"${caller}::reply"} = sub { [200, ['Content-Type' => 'text/plain', 'Cache-Control' => 'no-cache'], [ @_ ] ] };
	*{"${caller}::purge"} = sub {
		return unless $ENV{PURGE_HOST};
		my $req = HTTP::Request->new(PURGE => "http://$ENV{PURGE_HOST}$_[0]");
		$ua->request($req)
	};

	if ($name) {
		$templates{$caller} = { read_templates $name };
		$templates{$caller}{$_}  = header ($_, $title) . $templates{$caller}{$_} for keys $templates{$caller};
		$templates{$caller}{$_} .= footer  $_  for keys $templates{$caller};
	}
}

sub import {
	return unless $_[0] eq __PACKAGE__;
	splice @_, 1, 0, scalar caller;
	goto &import_to
}

##################################################

sub generate{
	my ($self, $lang, @args) = @_;

	my $htc = HTML::Template::Compiled->new(scalarref => \$templates{$self}{$lang}, default_escape => 'HTML', use_perl => 1);
	$self->_generate($htc, $lang, @args);
	my $out = $htc->output;
	utf8::downgrade($out);
	my $vary = 'Accept-Language, ' . $self->vary;
	[200, ['Content-Type' => 'text/html', 'Content-Language' => $_[1], 'Vary' => $vary, 'X-Forever' => 1, 'Cache-Control' => 'max-age=' . $self->max_age], [ $out ] ]
}

sub _generate {}

sub vary { '' }

sub max_age { 60 }

sub variants {
	return [] unless exists $templates{$_[0]};
	[ map { [ $_, 1, 'text/html', undef, undef, $_, undef ]} keys $templates{$_[0]} ]
}

1
