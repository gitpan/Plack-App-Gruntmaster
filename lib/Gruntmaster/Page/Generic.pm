package Gruntmaster::Page::Generic;

use 5.014000;
use strict;
use warnings;
our $VERSION = '5999.000_001';

use Gruntmaster::Data;
use Gruntmaster::Page::Base;
use JSON qw/encode_json decode_json/;

sub hgetall {
	my $hash = shift;
	my $cp = $Gruntmaster::Data::contest ? "contest.$Gruntmaster::Data::contest." : '';
	map { { id => $_, HGETALL "$cp$hash.$_" } } SMEMBERS "$cp$hash"
}

sub putsym {
	my ($key, $value) = @_;
	no strict 'refs';
	*{"$key"} = $value;
}

sub makepkg {
	my ($pkg, $id, $title) = @_;
	my $fn = $pkg =~ s,::,/,gr;
	return if $INC{"$fn.pm"};
	$INC{"$fn.pm"} = 1;
	Gruntmaster::Page::Base->import_to($pkg, $id, $title);
	1
}

sub list {
	my ($thing, $lang, $env, $ct) = @_;
	my %thing = %$thing;
	undef $ct unless $thing{contest};
	debug $env => "Contest is $ct";
	local $Gruntmaster::Data::contest = $ct if $ct;
	my @thing = hgetall $thing{hash};
	@thing = map  { $thing{mangle}->(); $_ } @thing if exists $thing{mangle};
	@thing = grep { $thing{choose}->() } @thing if exists $thing{choose};
	@thing = sort { $thing{sortby}->() } @thing if exists $thing{sortby};
	my %params;
	$thing{group} //= sub { $thing{id} };
	for (@thing) {
		my $group = $thing{group}->();
		$params{$group} //= [];
		push $params{$group}, $_
	}
	wantarray ? %params : \%params
}

sub entry {
	my ($thing, $lang, $env, $id, $ct) = @_;
	my %thing = %$thing;
	($id, $ct) = ($ct, $id) if $thing{contest};
	local $Gruntmaster::Data::contest = $ct if $ct;
	debug $env => "Hash is $thing{hash} and id is $id";
	my %params = HGETALL "$thing{hash}.$id";
	$thing{mangle}->(local $_ = \%params) if exists $thing{mangle};
	wantarray ? %params : \%params
}

sub headers ($) { ['Content-Type' => 'application/json', 'Cache-Control' => 'max-age=' . $_[0]->max_age] }

sub create_thing {
	my %thing = @_;
	my $ucid = ucfirst $thing{id};
	my $pkg = "Gruntmaster::Page::$ucid";

	putsym "${pkg}::_generate", sub { $_[1]->param(list \%thing, @_[2..$#_]) } if makepkg $pkg, @thing{qw/id title/};
	putsym "${pkg}::Entry::_generate",  sub { $_[1]->param(entry \%thing, @_[2..$#_]) } if makepkg "${pkg}::Entry", "$thing{id}_entry", '<tmpl_var name>';
	putsym "${pkg}::Read::generate", sub { [200, headers shift, [encode_json list \%thing, @_]] } if makepkg "${pkg}::Read";
	putsym "${pkg}::Entry::Read::generate", sub { [200, headers shift, [encode_json entry \%thing, @_]] } if makepkg "${pkg}::Entry::Read";
}

sub params;
sub contest;
sub choose (&);
sub sortby (&);
sub group  (&);
sub mangle (&);

sub thing (&){
	my %thing;
	no strict 'refs';
	local *{"params"} = sub { @thing{qw/id hash title/} = @_ };
	local *{"choose"} = sub { $thing{choose} = shift };
	local *{"sortby"} = sub { $thing{sortby} = shift };
	local *{"mangle"} = sub { $thing{mangle} = shift };
	local *{"group"} = sub { $thing{group} = shift };
	local *{"contest"} = sub { $thing{contest} = 1 };
	use strict 'refs';

	shift->();
	create_thing %thing
}

##################################################

thing {
	params qw/us user Users/;
	choose { $_->{name} =~ /\w/ };
	sortby { lc $a->{name} cmp lc $b->{name} };
};

thing {
	params qw/pb problem Problems/;
	contest;
	sortby { $a->{name} cmp $b->{name} };
	group { $_->{level} };
	mangle { $_->{owner_name} = do { local $Gruntmaster::Data::contest; user_name $_->{owner} } }
};

thing {
	params qw/ct contest Contests/;
	sortby { $b->{start} <=> $a->{start} };
	group { time < $_->{start} ? 'pending' : time > $_->{end} ? 'finished' : 'running' };
	mangle { $_->{started} = time >= $_->{start}; $_->{owner_name} = do { local $Gruntmaster::Data::contest; user_name $_->{owner} } };
};

thing {
	params qw/log job/, 'Job log';
	contest;
	mangle { $_->{results} &&= decode_json $_->{results}; $_->{user_name} = do { local $Gruntmaster::Data::contest; user_name $_->{user} } }
};

1
