use Test::More;
use Test::Exception;
use DateTime::Format::ISO8601;

BEGIN { use_ok("GPS::Track::Parser"); }

subtest(testConstructor => \&testConstructor);
subtest(testOnPoint => \&testOnPoint);
subtest(testIdentify => \&testIdentify);
subtest(testConvert => \&testConvert);
subtest(testParseTCX => \&testParseTCX);

sub testConstructor {
	my $track = GPS::Track::Parser->new();
	ok($track->isa("GPS::Track::Parser"), "default constructor is good");
}

sub testOnPoint {
	my $ref = sub { };

	my $parser = GPS::Track::Parser->new();
	is($parser->onPoint(), undef, "no onPoint callback");

	$parser->onPoint($ref);
	is($parser->onPoint(), $ref, "callback is set");

	$parser->onPoint(undef);
	is($parser->onPoint(), undef, "callback removed");

	throws_ok { $parser->onPoint(1); } qr/not a code/i;
	throws_ok { $parser->onPoint("test"); } qr/not a code/i;
	throws_ok { $parser->onPoint($parser); } qr/not a code/i;
	throws_ok { $parser->onPoint( { key => 1 } ); } qr/not a code/i;
}

sub testIdentify {
	my $parser = GPS::Track::Parser->new();

	is($parser->identify("file.gpx"), "gpx");
	is($parser->identify("file.fit"), "fit");
	is($parser->identify("/some.path/with.some/file.txt.gif.tcx"), "tcx");
	is($parser->identify(".gpx"), "gpx");
	is($parser->identify("some.GPX"), "gpx");

	throws_ok { $parser->identify("invalid.file_extension"); } qr/unknown dataformat/i, "invalid.file_extension";
	throws_ok { $parser->identify("noSuffix"); } qr/unknown dataformat/i, "no suffix";
	throws_ok { $parser->identify("file.gpx."); } qr/unknown dataformat/i, "file.gpx.";
}

sub testConvert {
	my $parser = GPS::Track::Parser->new();
	my $xml = $parser->convert("./t/files/simple.gpx");
	ok($xml =~ /TrainingCenterDatabase/, "from gpx, looks like a TCX file now");

	$xml = undef;
	$xml = $parser->convert("./t/files/simple.tcx");
	ok($xml =~ /TrainingCenterDatabase/, "from tcx, looks like a TCX file now");

	$xml = undef;
	$xml = $parser->convert("./t/files/sample_file.fit");
	ok($xml =~ /TrainingCenterDatabase/, "from fit, looks like a TCX file now");
}

sub testParseTCX {

	my $refPoint = GPS::Track::Point->new(
		lat => 48.2256215,
		lon => 9.0323674,
		ele => 799.8,
		time => DateTime::Format::ISO8601->parse_datetime("2017-05-10T16:06:58Z"),
		cad => 95,
		bpm => 91,
		spd => 3.382
	);

	my $onPointCallbackFired = 0;

	my $parser = GPS::Track::Parser->new(onPoint => sub {
			my $callbackPoint = shift;
			ok($callbackPoint == $refPoint, "callbackpoint equals refpoint");
			$onPointCallbackFired = 1;
	});

	my @points = $parser->parseTCX(getMinimalTCX());
	is(scalar(@points), 1, "parser returned one point");

	ok($refPoint == $points[0], "parsed point matches expectation");
	is($onPointCallbackFired, 1, "the onPoint callback got triggered");
}

sub getMinimalTCX {
	return slurp("./t/files/minimal.tcx");
}

sub slurp {
	my $file = shift;
	local $/;
	return <"$file">;
}


done_testing;
