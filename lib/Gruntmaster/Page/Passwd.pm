package Gruntmaster::Page::Passwd;

use Gruntmaster::Page::Base;
use Apache2::Authen::Passphrase qw/pwcheck pwset/;

sub generate{
	my ($self, $format, $env) = @_;
	my $r = Plack::Request->new($env);
	my ($oldpass, $newpass, $confirm) = map {scalar $r->param($_)} 'password', 'new_password', 'confirm_new_password';

	return reply 'Incorrect password' unless eval { pwcheck $r->user, $oldpass; 1 };
	return reply 'The two passwords do not match' unless $newpass eq $confirm;

	pwset $r->user, $newpass;
	reply 'Password changed successfully';
}

1
