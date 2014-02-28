#!/usr/bin/perl -w
use v5.14;

use Apache2::Authen::Passphrase qw/pwcheck/;
use Apache2::AuthzCaps qw/hascaps/;
use Gruntmaster::Data;
use Plack::App::Gruntmaster;
use Plack::Builder;
use Plack::Request;
use Digest::SHA qw/sha256/;
use Log::Log4perl;

use constant ACCESSLOG_FORMAT => '%{X-Forwarded-For}i|%h %u "%r" %>s %b "%{Referer}i" "%{User-agent}i"';
use constant CONTENT_SECURITY_POLICY => q,default-src 'none'; script-src 'self' www.google-analytics.com; style-src 'self'; img-src 'self'; connect-src 'self',;

$Apache2::AuthzCaps::rootdir = $Apache2::Authen::Passphrase::rootdir;
my $word = qr,(\w+),a;

sub debug {
	local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
	$_[0]->{'psgix.logger'}->({qw/level debug message/ => $_[1]})
}

sub some_auth_required {
	my $r = Plack::Request->new($_[0]);
	return 1 if $_[0]->{'gruntmaster.reqadmin'} || $r->path eq '/action/passwd' || $r->path =~ m,/pb/$word/submit$,;
	return 1 if $r->path =~ m,^/ct/$word/pb/$word, && time < contest_end $1;
	0
}

sub admin_required {
	local $_ = $_[0];
	return problem_owner $1 if m,^/pb/$word, && problem_private $1;
	return job_user $1  if m,^/log/(?:job|src)/$word, && job_private $1;
	return contest_owner $1 if m,^/ct/$word/(?:pb|log), && time < contest_start $1;
	if (m,^/ct/$word/log/(?:job|src)/$word, && time < contest_end $1){
		local $Gruntmaster::Data::contest = $1;
		return job_user $2;
	}
	0
}

sub require_admin {
	my $app = $_[0];
	sub {
		local *__ANON__ = "require_admin_middleware";
		my $env = $_[0];
		my $r = Plack::Request->new($env);
		$env->{'gruntmaster.reqadmin'} = admin_required $r->path;
		$app->($env)
	}
}

my %authen_cache;

sub authenticate {
	my ($user, $pass, $env) = @_;
	my $cache_key = sha256 "$user:$pass";
	my $time = $authen_cache{$cache_key} // 0;
	if ($time >= time - 300) {
		return 1;
	} else {
		delete $authen_cache{$cache_key};
	}

	return unless eval {
		pwcheck $user, $pass;
		1
	};
	$authen_cache{$cache_key} = time;

	return if $env->{'gruntmaster.reqadmin'} && $env->{'gruntmaster.reqadmin'} ne $user && !hascaps $user, 'gmadm';
	1
}

Log::Log4perl->init('log.conf');
my $access_logger = Log::Log4perl->get_logger('access');

builder {
	enable_if { $_[0]->{PATH_INFO} eq '/ok' } sub { sub{ [200, [], []] }};
	enable 'AccessLog', format => ACCESSLOG_FORMAT, logger => sub { $access_logger->info(@_) };
	enable 'ContentLength';
	enable Header => set => ['Content-Security-Policy', CONTENT_SECURITY_POLICY];
	enable_if { $_[0]->{PATH_INFO} =~ qr,^/static/,} Header => set => ['Cache-Control', 'public, max-age=604800'];
	enable 'Static', path => qr,^/static/,;
	enable 'Log4perl', category => 'plack';
	enable \&require_admin;
	enable_if \&some_auth_required, 'Auth::Basic', authenticator => \&authenticate, realm => 'Gruntmaster 6000';
	Plack::App::Gruntmaster->to_app
}
