use Test::More;
use Test::Exception;
use Mojo::File;
use DateTime::Format::ISO8601;

BEGIN { use_ok("GPS::Track"); }

my $track = GPS::Track->new();
is($track->onPoint, undef, "no onPoint callback defined");

throws_ok { $track->parse(); } qr/No file/, "throws without a file";
throws_ok { $track->parse("/a/file/never/to/exist/file.extension"); } qr/does not exist/, "cannot find that file";

subtest(testConstructor => \&testConstructor);
subtest(testOnPoint => \&testOnPoint);
subtest(testIdentify => \&testIdentify);
subtest(testConvert => \&testConvert);
subtest(testParseTCX => \&testParseTCX);

sub testConstructor {
	my $track = GPS::Track->new();
	ok($track->isa("GPS::Track"), "default constructor is good");

	$track = GPS::Track->new(onPoint => sub { });
	ok($track->isa("GPS::Track"), "constructor with valid onPoint callback is good");

	throws_ok { GPS::Track->new(onPoint => "test"); } qr/not a code/i;
}

sub testOnPoint {
	my $ref = sub { };

	my $track = GPS::Track->new();
	is($track->onPoint(), undef, "no onPoint callback");

	$track->onPoint($ref);
	is($track->onPoint(), $ref, "callback is set");

	$track->onPoint(undef);
	is($track->onPoint(), undef, "callback removed");

	throws_ok { $track->onPoint(1); } qr/not a code/i;
	throws_ok { $track->onPoint("test"); } qr/not a code/i;
	throws_ok { $track->onPoint($track); } qr/not a code/i;
	throws_ok { $track->onPoint( { key => 1 } ); } qr/not a code/i;
}

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

	my $track = GPS::Track->new(onPoint => sub {
			my $callbackPoint = shift;
			ok($callbackPoint == $refPoint, "callbackpoint equals refpoint");
			$onPointCallbackFired = 1;
	});

	my @points = $track->parseTCX(getMinimalTCX());
	is(scalar(@points), 1, "parser returned one point");

	ok($refPoint == $points[0], "parsed point matches expectation");
	is($onPointCallbackFired, 1, "the onPoint callback got triggered");
}

sub getMinimalTCX {
	return Mojo::File->new("./t/files/minimal.tcx")->slurp();
}


done_testing;
