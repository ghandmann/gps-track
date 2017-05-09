package GPS::Track::Point;

use Mojo::Base -base;
use Scalar::Util qw/blessed/;
use Geo::Distance;

has ["lon", "lat", "ele", "time", "spd", "bpm", "cad" ] => undef;
has geoDistance => sub { return Geo::Distance->new(); };

sub handleTime {
	my $self = shift;
	my $timestamp = shift;

	if(defined $timestamp) {
		warn "parsing timestamp=$timestamp";
		my $dt = DateTime::Format::ISO8601->parse_datetime($timestamp);
		$self->{time} = $dt;
		return $self;
	}
	else {
		return $self->{time};
	}
}

sub distanceTo {
	my $self = shift;
	my $other = shift;

	my $otherLon = undef;
	my $otherLat = undef;

	if(blessed($other)) {
		unless($other->isa("GPS::Track::Point")) {
			die "\$other is not a GPS::Track::Point!";
		}

		$otherLon = $other->lon;
		$otherLat = $other->lat;
	}
	else {
		unless(ref($other) eq "HASH") {
			die "\$other is not a HASH reference!";
		}

		$otherLon = $other->{lon};
		$otherLat = $other->{lat};
	}

	die "\$other is missing a 'lon' value!" unless(defined $otherLon);
	die "\$other is missing a 'lat' value!" unless(defined $otherLat);

	die "\$self is missing a 'lon' value!" unless(defined $self->lon);
	die "\$self is missing a 'lat' value!" unless(defined $self->lat);

	return $self->geoDistance->distance("meter", $self->lon, $self->lat, $otherLon, $otherLat);
}

sub equals {
	my $self = shift;
	my $other = shift;

	unless(blessed($other) && $other->isa("GPS::Track::Point")) {
		die "First argument not a GPS::Track::Point!";
	}

	my $equal =	$self->lon == $other->lon &&
					$self->lat == $other->lat &&
					$self->time == $other->time &&
					$self->ele == $other->ele &&
					$self->spd == $other->spd &&
					$self->cad == $other->cad &&
					$self->bpm == $other->bpm;

	return $equal ? 1 : 0;
}

1;

__END__

=head1 NAME

GPS::Track::Point - Represent a Point of a GPS::Track

=head1 SYNOPSIS

    # Construct an empty point
    my $point = GPS::Track::Point->new();
    
    # Construct a simple point
    my $point = GPS::Track::Point->new(lon => 12, lat => 13, ele => 8848);
    my $point = GPS::Track::Point->new( { lon => 12, lat => 13 } ); # Hashref Construction supported too
    
    my $pointsEqual = $pointA == $pointB;
    my $distance = $pointA->distanceTo($pointB);
    my $distance = $pointaA->distanceTo( { lon => 12, lat => 13 } );

=head1 DESCRIPTION

C<GPS::Track::Point> is a thin module representing a Point as parsed by L<GPS::Track>.

=head1 ATTRIBUTES

=head2 lon

   my $lon = $point->lon;
   $point = $point->lon(48);

=head2 lat

   my $lat = $point->lat;
   $point = $point->lat(9);

=head2 time

This is currently a really dump getter/setter which just returns, what was passed in.

Future version will accepts various datetime-formats and return a L<DateTime> object.

   my $time = $point->time;
   my $point = $point->time("2015-01-20T13:26:57.000Z");

=head2 ele

   my $ele = $point->ele;
   $point = $point->ele(8848);

=head2 spd

The speed at this point, measured in meter per second.

   my $spd = $point->spd;
   my $point = $point->spd(10);

=head2 cad

   my $cad = $point->cad;
   $point = $point->cad(75);

=head2 bpm

   my $bpm = $point->bpm;
   $point = $point->bpm(180);

=head1 METHODS

=head2 distanceTo($otherPoint)

Return the 2D distance to the other point in meters.

Dies if one of the points is missing lon/lat.

   my $distance = $pointA->distanceTo($pointB);

=head2 distanceTo( { lon => X, lat => Y } )

Shorthand method to get the 2D distance to a nown lon-lat-pair.

   my $distance = $pointA->distanceTo( { lon => 12, lat => 6 } );

=head2 equals($otherPoint)

Compares to point object attribute by attribute.

Return 1 for equal points, otherwise 0.

    my $equal = $pointA->equals($pointB);

=head1 OPERATORS

=head2 ==

Shorthand operator to call C<equals> on $pointA with $pointB as argument.

   my $areEqual = $pointA == $pointB;
   # Equivalent to $pointA->equals($pointB);

=cut
