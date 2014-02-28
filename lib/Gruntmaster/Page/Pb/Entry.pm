package Gruntmaster::Page::Pb::Entry;

use Gruntmaster::Page::Base pb_entry => '<tmpl_var name>';

use constant FORMATS => [qw/C CPP JAVA PERL PYTHON/];

sub _generate{
	my ($self, $htc, $lang, $env, $contest, $id) = @_;
	debug $env => "language is '$lang', contest is '$contest', id is '$id'";
	my $user = $env->{REMOTE_USER};
	if ($contest && $user && time >= contest_start $contest) {
		local $Gruntmaster::Data::contest = $contest;
		mark_open $id, $user;
		debug $env => "Marking problem $id of contest $contest open by $user";
	}

	$htc->param(cansubmit => 1);
	if ($contest) {
		$htc->param(cansubmit => time <= contest_end $contest);
		$htc->param(contest => $contest);
	}
	$htc->param(formats => FORMATS);
	$htc->param(id => $id);
	local $Gruntmaster::Data::contest = $contest if $contest;
	$htc->param(name => problem_name $id);
	$htc->param(author => problem_author $id);
	$htc->param(owner => problem_owner $id);
	$htc->param(owner_name => do{ local $Gruntmaster::Data::contest; user_name $htc->param('owner')} );
	$htc->param(statement => problem_statement $id);
}

sub vary { 'Authorization' }
sub max_age { 600 }

1
