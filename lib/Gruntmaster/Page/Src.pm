package Gruntmaster::Page::Src;

use Gruntmaster::Page::Base;

use constant CONTENT_TYPES => +{
	c => 'text/x-csrc',
	cpp => 'text/x-c++src',
	cs => 'text/x-chsarp', # Used by GNOME. Not in mime.types.
	java => 'text/x-java',
	pas => 'text/x-pascal',
	pl => 'text/x-perl',
	py => 'text/x-python',
};

sub generate{
	my ($self, $format, $env, $ct, $job, $ext) = @_;
	debug $env => "Contest is $ct, job is $job and extension is $ext";
	local $Gruntmaster::Data::contest = $ct if $ct;

	[200, ['Content-Type' => CONTENT_TYPES->{$ext}, 'Cache-Control' => 'max-age=604800', 'X-Forever' => 1], [job_inmeta($job)->{files}{prog}{content}] ]
}

1
