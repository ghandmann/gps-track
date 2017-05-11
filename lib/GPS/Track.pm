package GPS::Track;

use 5.018000;
use strict;
use warnings;
use GPS::Track::Point;
use Mojo::Base -base;
use Mojo::File;
use XML::Simple;
use Try::Tiny;

has "onPoint" => undef;

our $VERSION = '0.01';

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
	else {
		die "File '$file' has an unkown dataformat!";
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

	my @retval;

	foreach my $course (@courses) {
		my @trackpoints = @{$course->{Track}->{Trackpoint}};
		foreach my $p (@trackpoints) {
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

			if(defined($self->onPoint)) {
				$self->onPoint()->($gpsTrackPoint);
			}
			push(@retval, $gpsTrackPoint);
		}
	}

	return @retval;
}

sub identify {
	my $self = shift;
	my $filename = shift;

	my $suffix = undef;
	if($filename =~ /\.(\w+)$/) {
	  $suffix = lc($1);
	}

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

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

GPS::Track - Perl extension for parsing GPS Tracks

=head1 SYNOPSIS

  use GPS::Track;
  my $track = GPS::Track->new;
  my @trackPoints = $track->parse($filename);
  
  # Parse-Callback
  my $track = GPS::Track->new(onPoint => sub { my $trackPoint = shift; });
  my @trackPoints = $track->parse($filename);

=head1 DESCRIPTION

GPS::Track tries to parse common GPS Tracks recorded by diffrent GPS/Sports trackers.

Under the hood the conversion is done by calling gpsbabel on your system.

=head1 ATTRIBUTES

=head2 onPoint

Callback which gets called for every parsed L<GPS::Track::Point>. Gets the parsed L<GPX::Track::Point> passed as argument.

   $track->onPoint(sub { my $trackPoint = shift; $trackPoint->lon; });

=head1 METHODS

=head2 parse($filename)

Tries to parse the given filename and returning all the parsed L<GPX::Track::Point>s as an array.

Additionally if the 'onPoint' attribute is defined, it will be called for every parsed point.

=head2 convert($filename)

Converts the file from the identified format to the internaly used XML format.

   my $xml = $track->convert($filename);

=head2 identify($filename)

Tries to identify the type of file by looking at the suffix.

TODO: Interpret file magic bytes.

   my $format = $track->identify($filename);

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Sven Eppler, E<lt>cpan@sveneppler.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Sven Eppler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
