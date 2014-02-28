package Gruntmaster::Page::JS;

use Gruntmaster::Page::Base;
use JavaScript::Minifier::XS qw/minify/;

sub generate{
	my ($self, $format, $env) = @_;
	debug $env => "";
	my $js;
	$js .= read_file $_ for <js/*.js>;
	[200, ['Content-Type' => 'application/javascript', 'Cache-Control' => 'public, max-age=604800', 'X-Forever' => 1], [minify $js] ]
}

1
