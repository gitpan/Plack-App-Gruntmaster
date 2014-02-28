use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Plack::App::Gruntmaster',
	VERSION_FROM      => 'lib/Plack/App/Gruntmaster.pm',
	ABSTRACT_FROM     => 'lib/Plack/App/Gruntmaster.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'AGPL_3',
	SIGN              => 1,
	BUILD_REQUIRES    => {
		qw/Test::More                 0
		   Test::WWW::Mechanize::PSGI 0/,
	},
	PREREQ_PM         => {
		qw/Carp        0
		   Digest::SHA 0
		   List::Util  0
		   POSIX       0
		   constant    0
		   feature     0
		   parent      0
		   strict      0
		   warnings    0

		   Apache2::Authen::Passphrase 0
		   Apache2::AuthzCaps          0
		   CSS::Minifier::XS           0
		   File::Slurp                 0
		   Gruntmaster::Data           0
		   HTML::Template::Compiled    0
		   HTTP::Negotiate             0
		   JavaScript::Minifier::XS    0
		   JSON                        0
		   Log::Log4perl               0
		   LWP::UserAgent              0
		   Plack::Builder              0
		   Plack::Request              0/,
	},
	META_MERGE        => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=plack-app-gruntmaster.git',
		}
	}
)
