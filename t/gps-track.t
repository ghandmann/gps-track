use Test::More;
use Test::Exception;

BEGIN { use_ok("GPS::Track"); }

my $track = GPS::Track->new();
is($track->onPoint, undef, "no onPoint callback defined");

throws_ok { $track->parse(); } qr/No file/, "throws without a file";
throws_ok { $track->parse("/a/file/never/to/exist/file.extension"); } qr/does not exist/, "cannot find that file";

subtest(testIdentify => \&testIdentify);


sub testIdentify {
	my $track = GPS::Track->new();

	is($track->identify("noSuffix"), undef);
	is($track->identify("/wrong.suffix/"), undef);
	is($track->identify("file.gpx"), "gpx");
	is($track->identify("/some.path/with.some/file.txt.gif.tcx"), "tcx");
}

sub testParse {
	my $track = GPS::Track->new();

}

done_testing;
