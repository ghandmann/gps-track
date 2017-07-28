package GPS::Track::Parser;

use 5.018000;
use strict;
use warnings;
use Moo;
use GPS::Track::Point;
use GPS::Track;
use XML::Simple;
use Try::Tiny;

has "onPoint" => (
	is => "rw",
	isa => sub {
		GPS::Track::Parser::_validateOnPoint(shift);
	}
);

sub BUILD {
	my $self = shift;
	my $args = shift;

	if(exists $args->{onPoint}) {
		GPS::Track::Parser::_validateOnPoint($args->{onPoint});
	}

	return $args;
}



sub parse {
	my $self = shift;
	my $file = shift;

	my $tcx = $self->convert($file);
	return $self->parseTCX($tcx);
}

sub convert { 
	my $self = shift;

	my $file = shift or die "No file supplied to parse!";
	die "The file '$file' does not exist!" unless(-e $file);

	# identify dies on unknown formats!
	my $format = $self->identify($file);

	my $xml = undef;
	if($format eq "gpx") {
		$xml = $self->_convertGPX($file);
	}
	elsif($format eq "fit") {
		$xml = $self->_convertFIT($file);
	}
	elsif($format eq "tcx") {
		$xml = $self->_convertTCX($file);
	}

	return $xml;
}

sub parseTCX {
	my $self = shift;
	my $xml = shift;

	# use a faster parser
	$XML::Simple::PREFERRED_PARSER = "XML::SAX::ExpatXS";

	my @options = ( ForceArray => ['Course', 'Trackpoint'] );
	my $data = XMLin($xml, @options);

	my @courses = @{$data->{Courses}->{Course}};

	my $track = GPS::Track->new();

	foreach my $course (@courses) {
		my @trackpoints = @{$course->{Track}->{Trackpoint}};
		foreach my $p (@trackpoints) {
			# Parse the ISO8601 DateTime
			my $time = undef;
			try {
				$time = DateTime::Format::ISO8601->parse_datetime($p->{Time});
			};

			my $gpsTrackPoint = GPS::Track::Point->new(
				lat => $p->{Position}->{LatitudeDegrees},
				lon => $p->{Position}->{LongitudeDegrees},
				time => $time,
				ele => $p->{AltitudeMeters} || undef,
				spd => $p->{Extensions}->{TPX}->{Speed} || undef,
				bpm => $p->{HeartRateBpm}->{Value} || undef,
				cad => $p->{Cadence} || undef,
			);

			# fire onPoint Callback
			$self->onPoint()->($gpsTrackPoint) if(defined($self->onPoint));

			$track->addPoint($gpsTrackPoint);
		}
	}

	$track->finalize();
	return $track;
}

sub identify {
	my $self = shift;
	my $filename = shift;

	my $suffix = "";
	if($filename =~ /\.(\w+)$/) {
	  $suffix = lc($1);
	}

	my %validSuffixes = (
		gpx => 1,
		fit => 1,
		tcx => 1,
	);

	die "File '$filename' has an unknown dataformat!" unless(exists $validSuffixes{$suffix});

	return $suffix;
}

sub _convertFIT {
	my $self = shift;
	my $file = shift;
	$self->gpsbabel_convert("garmin_fit", $file);
}

sub _convertGPX {
	my $self = shift;
	my $file = shift;
	return $self->gpsbabel_convert("gpx", $file);
}

sub _convertTCX {
	my $self = shift;
	my $file = shift;

	$self->gpsbabel_convert("gtrnctr", $file);
}

sub gpsbabel_convert {
	my $self = shift;
	my $sourceFormat = quotemeta(shift);
	my $file = quotemeta(shift);

	my $tcx = `gpsbabel -i $sourceFormat -f $file -o gtrnctr -F -`;
	return $tcx;
}

sub _validateOnPoint { 
	my $candidate = shift;

	if(defined($candidate) && ref($candidate) ne "CODE") {
		die "Not a CODE-Ref to onPoint!"
	}
}
1;
