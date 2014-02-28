package Gruntmaster::Page::St;

use Gruntmaster::Page::Base st => 'Standings';

use constant LEVEL_VALUES => {
	beginner => 100,
	easy => 250,
	medium => 500,
	hard => 1000,
};

sub calc_score{
	my ($user, $problem, $date, $tries, $totaltime) = @_;
	my $mxscore = LEVEL_VALUES->{problem_level($problem)};
	my $score = $mxscore;
	my $timetaken = $date - get_open($problem, $user);
	$timetaken = 0 if $timetaken < 0;
	$timetaken = 300 if $timetaken > $totaltime;
	$score = ($totaltime - $timetaken) / $totaltime * $score;
	$score -= $tries / 10 * $mxscore;
	$score = $mxscore * 3 / 10 if $score < $mxscore * 3 / 10;
	int $score + 0.5
}

sub _generate{
	my ($self, $htc, $lang, $env, $ct) = @_;
	debug $env => "language is '$lang' and contest is '$ct'";
	my ($totaltime, $start);

	local $Gruntmaster::Data::contest;
	if ($ct) {
		$start = contest_start ($ct);
		$totaltime = contest_end ($ct) - $start;
		$Gruntmaster::Data::contest = $ct;
	}

	my @problems = problems;
	@problems = sort @problems;
	my (%scores, %tries);
	for (1 .. jobcard) {
		next unless defined job_user && defined job_problem && defined job_result;
		next if $Gruntmaster::Data::contest && job_date() < $start;

		if ($Gruntmaster::Data::contest) {
			$scores{job_user()}{job_problem()} = job_result() ? 0 : calc_score (job_user(), job_problem(), job_date(), $tries{job_user()}{job_problem()}, $totaltime);
			$tries{job_user()}{job_problem()}++;
		} else {
			no warnings 'numeric';
			$scores{job_user()}{job_problem()} = 0 + job_result_text() || (job_result() ? 0 : 100)
		}
	}

	my @st = sort { $b->{score} <=> $a->{score} or $a->{user} cmp $b->{user}} map {
		my $user = $_;
		+{
			user => $user,
			name => do {local $Gruntmaster::Data::contest; user_name $user},
			score => sum (values $scores{$user}),
			scores => [map { $scores{$user}{$_} // '-'} @problems],
			problems => $Gruntmaster::Data::contest,
		}
	} keys %scores;

	$st[0]->{rank} = 1;
	$st[$_]->{rank} = $st[$_ - 1]->{rank} + ($st[$_]->{score} < $st[$_ - 1]->{score}) for 1 .. $#st;
	$htc->param(problems => [map { problem_name } @problems ]) if $Gruntmaster::Data::contest;
	$htc->param(st => \@st);
}

1
