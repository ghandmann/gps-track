use Test::More;
use strict;
use warnings;
use Version::Compare;

my $gpsbabel = `gpsbabel --version`;
is($?, 0, "gpsbabel is installed") or BAIL_OUT "GPSBabel is required for GPS::Track! Refer to Documentation!";


my ($version) = ($gpsbabel =~ /GPSBabel Version (\d+\.\d+\.\d+)/i);

ok(Version::Compare::version_compare($version, "1.4.3") >= 0, "GPSBabel Version $version is greater or equal 1.4.3") or BAIL_OUT "GPSBabel version requirement >= 1.4.3 not met!";;

done_testing();
