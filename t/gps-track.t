use Test::More;
use Test::Exception;
use Mojo::File;
use DateTime::Format::ISO8601;

BEGIN { use_ok("GPS::Track"); }

my $track = GPS::Track->new();
is($track->onPoint, undef, "no onPoint callback defined");

throws_ok { $track->parse(); } qr/No file/, "throws without a file";
throws_ok { $track->parse("/a/file/never/to/exist/file.extension"); } qr/does not exist/, "cannot find that file";

subtest(testIdentify => \&testIdentify);
subtest(testConvert => \&testConvert);
subtest(testParseTCX => \&testParseTCX);


sub testIdentify {
	my $track = GPS::Track->new();

	is($track->identify("noSuffix"), undef);
	is($track->identify("/wrong.suffix/"), undef);
	is($track->identify("file.gpx"), "gpx");
	is($track->identify("/some.path/with.some/file.txt.gif.tcx"), "tcx");
	is($track->identify("file.gpx."), undef);
	is($track->identify(".gpx"), "gpx");
	is($track->identify("some.GPX"), "gpx");
}

sub testConvert {
	my $track = GPS::Track->new();
	my $xml = $track->convert("./t/files/simple.gpx");
	ok($xml =~ /TrainingCenterDatabase/, "from gpx, looks like a TCX file now");

	$xml = undef;
	$xml = $track->convert("./t/files/simple.tcx");
	ok($xml =~ /TrainingCenterDatabase/, "from tcx, looks like a TCX file now");

	$xml = undef;
	$xml = $track->convert("./t/files/sample_file.fit");
	ok($xml =~ /TrainingCenterDatabase/, "from fit, looks like a TCX file now");
}

sub testParseTCX {
	my $track = GPS::Track->new();
	my @points = $track->parseTCX(getMinimalTCX());
	is(scalar(@points), 1, "parser returned one point");

	my $refPoint = GPS::Track::Point->new(
		lat => 48.2256215,
		lon => 9.0323674,
		ele => 799.8,
		time => DateTime::Format::ISO8601->parse_datetime("2017-05-10T16:06:58Z"),
		cad => 95,
		bpm => 91,
		spd => 3.382
	);

	ok($refPoint == $points[0], "parsed point matches expectation");
}

sub getMinimalTCX {
	return Mojo::File->new("./t/files/minimal.tcx")->slurp();
}


done_testing;
