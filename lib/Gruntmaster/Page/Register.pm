package Gruntmaster::Page::Register;

use Gruntmaster::Page::Base;
use Apache2::Authen::Passphrase qw/pwcheck pwset USER_REGEX/;

sub generate{
	my ($self, $format, $env) = @_;
	my $r = Plack::Request->new($env);
	my ($username, $password, $confirm_password, $name, $email, $phone, $town, $university, $level) = map { die if length > 200; $_ } map {scalar $r->param($_)} qw/username password confirm_password name email phone town university level/;

	return reply 'Bad username. Allowed characters are letters, digits and underscores, and the username must be between 2 and 20 characters long.' unless $username =~ USER_REGEX;
	return reply 'Username already in use' if -e "$Apache2::Authen::Passphrase::rootdir/$username.yml";
	return reply 'The two passwords do not match' unless $password eq $confirm_password;
	return reply 'All fields are required' if grep { !length } $username, $password, $confirm_password, $name, $email, $phone, $town, $university, $level;
	pwset $username, $password;

	insert_user $username, name => $name, email => $email, phone => $phone, town => $town, university => $university, level => $level;

	purge  "/us/";
	reply 'Registered successfully';
}

1
