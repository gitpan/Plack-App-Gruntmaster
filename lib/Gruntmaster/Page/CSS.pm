package Gruntmaster::Page::CSS;

use Gruntmaster::Page::Base;
use CSS::Minifier::XS qw/minify/;

sub generate{
	my ($self, $format, $env, $theme) = @_;
	debug $env => "theme is $theme";
	return [404, ['Content-Type' => 'text/plain'], [ 'Not found' ]] unless -e "css/themes/$theme.css";
	my $css = read_file "css/themes/$theme.css";
	$css .= read_file $_ for <css/*.css>;
	[200, ['Content-Type' => 'text/css', 'Cache-Control' => 'public, max-age=604800', 'X-Forever' => 1], [minify $css] ]
}

1
