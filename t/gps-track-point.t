use Test::More;
BEGIN { use_ok("GPS::Track::Point"); }


subtest(simplePoint => \&simplePoint);

sub simplePoint {
	my $point = GPS::Track::Point->new();

	is($point->lon, undef, "lon is undef");
}

done_testing;
