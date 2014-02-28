package Gruntmaster::Page::Log;

use Gruntmaster::Page::Base log => 'Job log';

use constant PAGE_SIZE => 10;

sub _generate{
	my ($self, $htc, $lang, $env, $ct, $page) = @_;
	debug $env => "language is '$lang', contest is '$ct' and page is '$page'";
	local $Gruntmaster::Data::contest = $ct if $ct;

	my $pages = POSIX::floor (jobcard / PAGE_SIZE);
	$pages ||= 1;
	$page ||= $pages;

	my @log = sort { $b->{id} <=> $a->{id} } map +{
		id => $_,
		(job_private() ? (private => job_private) : ()),
		date => (job_date() ? strftime ('%c' => localtime job_date) : '?'),
		extension => job_extension,
		name => problem_name job_problem,
		problem => job_problem,
		result => job_result,
		result_text => job_result_text,
		size => sprintf ("%.2f KiB", job_filesize() / 1024),
		user => job_user}, ($page - 1) * PAGE_SIZE + 1 .. ($page == $pages ? jobcard : $page * PAGE_SIZE);
	$_->{user_name} = do { local $Gruntmaster::Data::contest; user_name $_->{user} } for @log;
	$htc->param(log => \@log);
	$htc->param(next => $page + 1) unless $page == $pages;
	$htc->param(prev => $page - 1) unless $page == 1;
}

sub max_age { 5 }

1
