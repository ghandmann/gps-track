use Test::More;
use Test::Exception;
use DateTime::Format::ISO8601;

BEGIN { use_ok("GPS::Track"); }

subtest(testConstructor => \&testConstructor);
subtest(testInterface => \&testInterface);
subtest(testDateTimeValidation => \&testDateTimeValidation);

sub testConstructor {
	my $track = GPS::Track->new();
	ok($track->isa("GPS::Track"), "default constructor is good");

	$track = GPS::Track->new(distance => 1234);
	is($track->distance, 1234, "distance works");
}

sub testInterface {
	my $track = GPS::Track->new();

	ok($track->can("distance"));
	ok($track->can("duration"));
	ok($track->can("start"));
	ok($track->can("stop"));
	ok($track->can("power"));
	ok($track->can("kcal"));
}

sub testDateTimeValidation {
	my $validator = \&GPS::Track::_validateDateTime;
	my $dt = DateTime->now();

	lives_ok { $validator->(undef); } "undef is valid too";
	lives_ok { $validator->($dt); } "isa dt, no exception";
	throws_ok { $validator->("nono"); } qr/not a datetime/i, "not a datetime object";
	throws_ok { $validator->(GPS::Track->new()); } qr/not a datetime/i, "not a datetime object";
	throws_ok { $validator->({}); } qr/not a datetime/i, "not a datetime object";
	throws_ok { $validator->(sub {}); } qr/not a datetime/i, "not a datetime object";
}


done_testing;
