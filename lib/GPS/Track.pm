package GPS::Track;

use 5.018000;
use strict;
use warnings;
use Moo;
use GPS::Track::Point;
use XML::Simple;
use Try::Tiny;
use Scalar::Util qw/blessed/;

our $VERSION = '0.01';

has ["distance", "duration", "power", "kcal"] => (
	is => "rw",
	default => undef,
);

has ["start", "stop"] => (
	is => "rw",
	isa => sub {
		GPS::Track::_validateDateTime(shift);
	},
	default => undef,
);

sub BUILD {
	my $self = shift;
	my $args = shift;

	foreach(qw/start stop/) {
		if(exists $args->{$_}) {
			GPS::Track::_validateDateTime($args->{$_});
		}
	}

	return $args;
}

sub _validateDateTime {
	my $candidate = shift;
	if(defined($candidate)) {
		unless(blessed($candidate) && $candidate->isa("DateTime")) {
			die "not a DateTime object!";
		}
	}
}

sub addPoint {

}

sub finalize {

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
