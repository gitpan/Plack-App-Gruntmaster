package Gruntmaster::Page::Submit;

use Gruntmaster::Page::Base;

use constant FORMAT_EXTENSION => {
	C => 'c',
	CPP => 'cpp',
	MONO => 'cs',
	JAVA => 'java',
	PASCAL => 'pas',
	PERL => 'pl',
	PYTHON => 'py',
};

sub generate{
	my ($self, $frm, $env) = @_;
	my $r = Plack::Request->new($env);
	my ($problem, $format, $contest, $private, $prog) = map {scalar $r->param($_)} 'problem', 'prog_format', 'contest', 'private', 'source_code';
	my $upload = $r->upload('prog');
	if (defined $upload) {
		my $temp = read_file $upload->path;
		$prog = $temp if $temp
	}
	die if defined $contest && $contest !~ /^\w+$/ ;
	die if defined $contest && (time > contest_end $contest);
	return reply 'A required parameter was not supplied' if grep { !defined } $problem, $format, $prog;
	return reply 'Maximum source size is 10KB' if length $prog > 25 * 1024;
	return reply 'You must wait 30 seconds between jobs' unless time > user_lastjob ($r->user) + 30;
	set_user_lastjob $r->user, time;

	local $Gruntmaster::Data::contest = $contest if $contest;

	my $job = push_job (
		date => time,
		problem => $problem,
		user => $r->user,
		defined $private ? (private => $private) : (),
		defined $contest ? (contest => $contest, private => 1) : (),
		filesize => length $prog,
		extension => FORMAT_EXTENSION->{$format},
	);

	set_job_inmeta $job, {
		files => {
			prog => {
				format => $format,
				name => 'prog.' . FORMAT_EXTENSION->{$format},
				content => $prog,
			}
		}
	};

	$contest //= '';
	PUBLISH 'jobs', "$contest.$job";
	[303, [Location => $r->path =~ s,/pb/\w+/submit$,/log/,r], ['']]
}

1
