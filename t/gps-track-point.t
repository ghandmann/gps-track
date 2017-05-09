use Test::More;
use Test::Exception;
use strict;
use warnings;
use Geo::Distance;

BEGIN { use_ok("GPS::Track::Point"); }


subtest(simplePoint => \&simplePoint);
subtest(pointConstructor => \&pointConstructor);
subtest(pointSettersGetters => \&pointSettersGetters);
subtest(pointsEqual => \&pointsEqual);
subtest(pointDistances => \&pointDistances);

sub simplePoint {
	my $point = GPS::Track::Point->new();

	# Attributes
	ok($point->can("lon"), "point can lon");
	ok($point->can("lat"), "point can lat");
	ok($point->can("ele"), "point can ele");
	ok($point->can("bpm"), "point can bpm");
	ok($point->can("cad"), "point can cad");
	ok($point->can("spd"), "point can spd");
	# Methods
	ok($point->can("equals"), "point can equals");

	is($point->lon, undef, "lon is undef");
	is($point->lat, undef, "lat is undef");
	is($point->ele, undef, "ele is undef");
	is($point->bpm, undef, "bpm is undef");
	is($point->cad, undef, "cad is undef");
	is($point->spd, undef, "spd is undef");
}

sub pointConstructor {
	my @arrayInit = (lon => 12, lat => 17, ele => 8848, bpm => 60, cad => 90, spd => 10);
	my $hashRefInit = {@arrayInit};

	my $pointIsGood = sub {
		my $point = shift;
		is($point->lon, 12);
		is($point->lat, 17);
		is($point->ele, 8848);
		is($point->bpm, 60);
		is($point->cad, 90);
		is($point->spd, 10);
	};
	
	note("point constructor with hashref");
	my $point = GPS::Track::Point->new($hashRefInit);
	$pointIsGood->($point);

	note("point constructor with array");
	$point = GPS::Track::Point->new(@arrayInit);
	$pointIsGood->($point);
}

sub pointSettersGetters {
	my $point = GPS::Track::Point->new();

	# Setters use the "fluent interface" design
	# therefore returning self
	$point = $point->lon(10);
	is($point->lon, 10);

	$point = $point->lat(20);
	is($point->lat(), 20);

	$point = $point->ele(8848);
	is($point->ele, 8848);

	$point = $point->bpm(120);
	is($point->bpm, 120);

	$point = $point->cad(75);
	is($point->cad, 75);
}

sub pointsEqual {
	my $initA = { lon => 12, lat => 13, ele => 8848, cad => 0, bpm => 0, spd => 10 };
	my $initB = { lon => -12, lat => 9, ele => 0, cad => 70, bpm => 120 };
	my $pointA = GPS::Track::Point->new($initA);
	my $pointB = GPS::Track::Point->new($initB);

	is($pointA->equals($pointB), 0, "points aren't equal");
	is($pointB->equals($pointA), 0, "points aren't equal");

	$pointB = GPS::Track::Point->new($initA);
	is($pointA->equals($pointB), 1, "points are equal");
	is($pointB->equals($pointA), 1, "points are equal");

	$pointB->lon(0);
	is($pointA->equals($pointB), 0, "points aren't equal");
	is($pointB->equals($pointA), 0, "points aren't equal");

	# always equal
	is($pointA->equals($pointA), 1, "points equal");

	throws_ok { $pointA->equals("something"); } qr/not a GPS::Track::Point/;
}

sub pointDistances {
	my $expected = Geo::Distance->new->distance("meter", 9, 48, 8, 47);

	my $pointA = GPS::Track::Point->new( lon => 9, lat => 48 );
	my $pointB = GPS::Track::Point->new( lon => 8, lat => 47 );

	is($pointA->distanceTo($pointB), $expected);
	is($pointA->distanceTo( { lat => $pointB->lat, lon => $pointB->lon } ), $expected);

	my $badPoint = GPS::Track::Point->new();
	throws_ok { $badPoint->distanceTo($pointA); } qr/self.*missing.*lon/;

	$badPoint->lon(12);
	throws_ok { $badPoint->distanceTo($pointA); } qr/self.*missing.*lat/;

	$badPoint->lon(undef);

	throws_ok { $pointA->distanceTo($badPoint); } qr/other.*missing.*lon/;
	$badPoint->lon(12);
	throws_ok { $pointA->distanceTo($badPoint); } qr/other.*missing.*lat/;

	throws_ok { $pointA->distanceTo({ }); } qr/other.*missing.*lon/;
	throws_ok { $pointA->distanceTo({ lon => 12 }); } qr/other.*missing.*lat/;
}

done_testing;
