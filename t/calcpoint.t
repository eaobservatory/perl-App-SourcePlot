#!perl

use strict;

use Test::More tests => 4;

use App::SourcePlot::Source;
use Astro::Telescope;

my $jcmt = new Astro::Telescope('JCMT');

my $s = new App::SourcePlot::Source('test', '21:00:00', '+45:00:00', 'RJ');

my ($lst, $el, $az, $pa) = $s->calcPoint('2012/06/28', '09:36:00', $jcmt);

is_nearly($lst, 0.974294569996843, 'LST');
is_nearly($el,  6.6940742301743, 'EL');
is_nearly($az, 315.65503926889, 'AZ');
is_nearly($pa, 68.5484222279766, 'PA');

sub is_nearly {
  my ($a, $b, $name) = @_;
  ok(abs($a - $b) < 0.000001, $name . ' (got ' . $a . ' expected ' . $b . ')');
}
