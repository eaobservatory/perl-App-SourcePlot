Package ObsDesk::Source;

=head1 NAME

ObsDesk::Source - creates a observation source

=head1 SYNOPSIS

 use ObsDesk::Source;
 $src = new Obsdesk::Source;

=head1 DESCRIPTION

This class will create Source objects that will hold essential
information for any single source.

=cut

use 5.004;
use Carp;
use strict;
no strict 'subs';
use vars qw/$VERSION/;

use Math::Trig;
use Astro::SLA;
use Date::Manip;
use Astro::Instrument::SCUBA::Array;

$VERSION = '1.00';

my $locateBug = 0;

=head1 EXTERNAL MODULES

  Math::Trig
  Astro::SLA
  Date::Manip
  Astro::Instrument::SCUBA::Array

=cut

=head1 PUBLIC METHODS

These are the methods avaliable in this class:

=over 4

=item new

Create a new Source object.
A new source object will be created.  You can specify nothing, just the 
name, or the RA, DEC and Epoc.

  $obs = new ObsDesk::Source();
  $obs = new ObsDesk::Source($name);
  $obs = new ObsDesk::Source($name, $RA, $DEC, $Epoc);
  $obs = new ObsDesk::Source('', $RA, $DEC, $Epoc);

=cut

sub new {
  print "Creating a new observation Source object\n" if $locateBug;

  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $Source = {};  # Anon hash

  bless($Source, $class);
  print "New observation Source object has been blessed: $Source\n" if $locateBug;

  $Source->name( shift ) if (@_);

  if (@_) {
    print "Passed in paramaters are being entered\n" if $locateBug;
    $Source->ra( shift );
    $Source->dec( shift);
    $Source->epoc( shift );
    print "Preparing to calculate the J2000 coords\n" if $locateBug;
  } else {
    print "No Passed in paramaters.\n" if $locateBug;
    $Source->epoc( 'RJ' );
  }
  $Source->type('normal');
  $Source->active(1);

  print "Object created\n" if $locateBug;

  return $Source;
}

=item destroy

Destroys an object of this type.  Cleans up the variables and
windows within.

  destroy $obs;

=cut

sub DESTROY {
  my $self = shift;
  $self->{MW}->destroy if defined $self->{MW};
}

############################################################
#  Common data manipulation functions
#
=item name

returns and sets the name of the source

  $name = $obs->name();
  $obs->name('Mars');

=cut

sub name {
  my $self = shift;
  $self->{NAME} = shift if @_;
  return $self->{NAME} if defined $self->{NAME};
  return '';
}

=item type

returns and sets the type of source it is.
ie.  planet

  $type = $obs->type();
  $obs->type('planet');

=cut

sub type {
  my $self = shift;
  $self->{TYPE} = shift if @_;
  return $self->{TYPE} if defined $self->{TYPE};
  return '';
}

=item planetnum

returns and sets the planet number if the source is a planet
planet numbers are from 0 to 8 in this order:

Sun, Mercury, Venus, Moon, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto 

  $planetnum = $obs->planetnum();
  $obs->planetnum(5);

=cut

sub planetnum {
  my $self = shift;
  $self->{PLANETNUM} = shift if @_;
  return $self->{PLANETNUM} if defined $self->{PLANETNUM};
  return '';
}

=item active

returns and sets whether the source is active

  $on = $obs->active();
  $obs->active(0);

=cut

sub active {
  my $self = shift;
  $self->{ACTIVE} = shift if @_;
  return $self->{ACTIVE} if defined $self->{ACTIVE};
  return '';
}

=item color

returns and sets the source color

  $col = $obs->color();
  $obs->color('black');

=cut

sub color {
  my $self = shift;
  $self->{COLOR} = shift if @_;
  return $self->{COLOR} if defined $self->{COLOR};
  return '';
}

=item lineWidth

returns and sets the sources thickness

  $LW = $obs->lineWidth();
  $obs->lineWidth(2);

=cut

sub lineWidth {
  my $self = shift;
  $self->{LINEWIDTH} = shift if @_;
  return $self->{LINEWIDTH} if defined $self->{LINEWIDTH};
  return 1;
}

=item index

returns and sets the sources window index

  $index = $obs->index();
  $obs->index(1234);

=cut

sub index {
  my $self = shift;
  $self->{INDEX} = shift if @_;
  return $self->{INDEX} if defined $self->{INDEX};
  return -1;
}

=item ra

returns and sets the ra of the source

  $ra = $obs->ra();
  $obs->ra($ra);

=cut

sub ra {
  my $self = shift;
  if (@_) {
    my $sra = shift;
    $sra =~ s/^\s+//;
    $sra =~ s/\s+$//;
    $sra =~ s/\s+/:/g;
    $self->{RA} = $sra;
    $self->{RA2000} = undef;
    $self->{DEC2000} = undef;
  }
  return $self->{RA} if defined $self->{RA};
  return '';
}

=item dec

returns and sets the dec of the source

  $dec = $obs->dec();
  $obs->dec($dec);

=cut

sub dec {
  my $self = shift;
  if (@_) {
    my $sdec = shift;
    $sdec =~ s/^\s+//;
    $sdec =~ s/\s+$//;
    $sdec =~ s/\+//g;
    $sdec =~ s/\-\s+/\-/;
    $sdec =~ s/\s+/:/g;
    $self->{DEC} = $sdec;
    $self->{RA2000} = undef;
    $self->{DEC2000} = undef;
  }
  return $self->{DEC} if defined $self->{DEC};
  return '';
}

=item ra2000

returns and sets the ra of the source in J2000
Stored in radians

  $ra2000 = $obs->ra2000();
  $obs->ra2000($raIn2000);

=cut

sub ra2000 {
  my $self = shift;
  if (@_) {
    $self->{RA2000} = shift;
  }
  print "Inside ra2000".$self->{RA2000}.".\n" if $locateBug;
  $self->calc2000() unless (defined $self->{RA2000});
  return $self->{RA2000};
}

=item dec2000

returns and sets the dec of the source in J2000
Stored in radians

  $dec2000 = $obs->dec2000();

=cut

sub dec2000 {
  my $self = shift;
  $self->{DEC2000} = shift if @_;
  $self->calc2000() if (!defined $self->{DEC2000});
  return $self->{DEC2000};
}

=item epoc

returns and sets the epoch of the source

  $epoc = $obs->epoc();
  $obs->epoc('RB');

=cut

sub epoc {
  my $self = shift;
  if (@_) {
    $self->{EPOC} = shift;
    $self->{RA2000} = undef;
    $self->{DEC2000} = undef;
  }
  return $self->{EPOC};
}

=item elevation

returns and sets the current elevation of the source at the ut time
Set and returns in degrees

  $ele = $obs->elevation();
  $obs->elevation(30);

=cut

sub elevation {
  my $self = shift;
  $self->{ELEVATION} = shift if @_;
  return $self->{ELEVATION} if defined $self->{ELEVATION};
  return '';
}

=item NameX

returns and sets the current x position of name label

  $x = $obs->NameX();
  $obs->NameX(6.5);

=cut

sub NameX {
  my $self = shift;
  $self->{NAMEX} = shift if @_;
  return $self->{NAMEX} if defined $self->{NAMEX};
  return '';
}

=item NameY

returns and sets the current y position of name label

  $y = $obs->NameY();
  $obs->NameY(6.5);

=cut

sub NameY {
  my $self = shift;
  $self->{NAMEY} = shift if @_;
  return $self->{NAMEY} if defined $self->{NAMEY};
  return '';
}

=item AzElOffsets

returns the amount in the current system to offset to draw the
Elevation and Azimuth axes

  ($elex, $eley, $azx, $azy) = $obs->AzElOffsets();
  $obs->AzElOffsets(.5, 4, .3, 2);

=cut

sub AzElOffsets {
  my $self = shift;
  if (@_) {
    $self->{ELEX} = shift;
    $self->{ELEY} = shift;
    $self->{AZX} = shift;
    $self->{AZY} = shift;
  }
  return ($self->{ELEX}, $self->{ELEY}, $self->{AZX}, $self->{AZY}) if defined $self->{ELEX};
  return (undef, undef, undef, undef);
}

=item timeDotX

returns and sets the current position of the time dot on
the x axis

  $x = $obs->timeDotX();
  $obs->timeDotX('15.122');

=cut

sub timeDotX {
  my $self = shift;
  $self->{TIMEDOTX} = shift if @_;
  return $self->{TIMEDOTX} if defined $self->{TIMEDOTX};
  return '';
}

=item timeDotY

returns and sets the current position of the time dot on
the y axis

  $y = $obs->timeDotY();
  $obs->timeDotY('15.122');

=cut

sub timeDotY {
  my $self = shift;
  $self->{TIMEDOTY} = shift if @_;
  return $self->{TIMEDOTY} if defined $self->{TIMEDOTY};
  return '';
}

=item time_ele_points

These functions return an array of comparative points for different 
characteristics of this source.  The avaliable comparisons are:

  time_ele_points       - time vs elevation
  time_az_points       - time vs azimuth
  time_pa_points       - time vs parallactic angle
  ele_time_points       - elevation vs time
  ele_az_points       - elevation vs azimuth
  ele_pa_points       - elevation vs parallactic angle
  az_time_points       - azimuth vs time
  az_ele_points       - azimuth vs azimuth
  az_pa_points       - azimuth vs parallactic angle
  pa_time_points       - parallactic angle vs time
  pa_ele_points       - parallactic angle vs elevation
  pa_az_points       - parallactic angle vs azimuth
  
  Example syntax:

  @time_ele_points = $obs->time_ele_points();

=cut

sub time_ele_points {
  my $self = shift;
  return @{$self->{TIME_ELE_POINTS}} if defined $self->{TIME_ELE_POINTS};
  return ();
}

sub time_az_points {
  my $self = shift;
  return @{$self->{TIME_AZ_POINTS}} if defined $self->{TIME_AZ_POINTS};
  return ();
}

sub time_pa_points {
  my $self = shift;
  return @{$self->{TIME_PA_POINTS}} if defined $self->{TIME_PA_POINTS};
  return ();
}

sub ele_time_points {
  my $self = shift;
  return @{$self->{ELE_TIME_POINTS}} if defined $self->{ELE_TIME_POINTS};
  return ();
}

sub ele_az_points {
  my $self = shift;
  return @{$self->{ELE_AZ_POINTS}} if defined $self->{ELE_AZ_POINTS};
  return ();
}

sub ele_pa_points {
  my $self = shift;
  return @{$self->{ELE_PA_POINTS}} if defined $self->{ELE_PA_POINTS};
  return ();
}

sub az_time_points {
  my $self = shift;
  return @{$self->{AZ_TIME_POINTS}} if defined $self->{AZ_TIME_POINTS};
  return ();
}

sub az_ele_points {
  my $self = shift;
  return @{$self->{AZ_ELE_POINTS}} if defined $self->{AZ_ELE_POINTS};
  return ();
}

sub az_pa_points {
  my $self = shift;
  return @{$self->{AZ_PA_POINTS}} if defined $self->{AZ_PA_POINTS};
  return ();
}

sub pa_time_points {
  my $self = shift;
  return @{$self->{PA_TIME_POINTS}} if defined $self->{PA_TIME_POINTS};
  return ();
}

sub pa_ele_points {
  my $self = shift;
  return @{$self->{PA_ELE_POINTS}} if defined $self->{PA_ELE_POINTS};
  return ();
}

sub pa_az_points {
  my $self = shift;
  return @{$self->{PA_AZ_POINTS}} if defined $self->{PA_AZ_POINTS};
  return ();
}

############################################################
#  Some needed methods - not calculations but info gluers
#
=item dispLine

returns the line to display - presentation use

  $line = $obs->dispLine();

=cut

sub dispLine {
  my $self = shift;
  my $line;
  if ($self->type() eq 'normal') {
    $line = sprintf " %-4d  %-16s  %-12s  %-13s  %-4s", ($self->index()+1), $self->name(), $self->ra(), $self->dec(), $self->epoc();
  } elsif ($self->type() eq 'planet'){
    $line = sprintf " %-4d  %-16s  %-12s  %-13s  %-4s", ($self->index()+1), $self->name(), 'Planet';
  } 
  return $line;
}

=item copy

returns a copy of this object

  $cp = $obs->copy();

=cut

sub copy {
  my $self = shift;
  my $source = $self->new($self->name, $self->ra, $self->dec, $self->epoc);
  return $source;
}




############################################################
#  This methods make calculations on the data
#
=item calc2000

Sets the RA2000 and DEC2000 fields...ie. in J2000 epoc
Returns 1 for success and 0 for a failure.

  $obs->calc2000();

=cut

sub calc2000 {
  print "Entering into calc2000\n" if $locateBug;

  my $self = shift;
  my ($h, $m, $s) = split(/:/, $self->ra());
  my $ra = ($h + $m/60 + $s/3600)*pi/12.0;
  my ($d, $mi, $se) = split(/:/, $self->dec());
  my $dec = ($d + $mi/60 + $se/3600)*pi/180.0;
  my ($ra_2000, $dec_2000);
  my ($debug) = 0;
  my ($mjd);

  if ($self->epoc() =~ /^RB|RJ|GA|EQ$/i) {
    if ($self->epoc() =~ /^RB/i) {
      print "Coord-type: RB\n" if ($debug);
      slaFk45z($ra, $dec, 1950.0, $ra_2000, $dec_2000);
    } elsif ($self->epoc() =~ /^RJ/i) {
      $ra_2000 = $ra;
      $dec_2000 = $dec;
      print "Coord-type: RJ\n" if ($debug);
    } elsif ($self->epoc() =~ /^GA/i) {
      print "Coord-type: GA\n" if ($debug);
      slaGaleq($ra, $dec, $ra_2000, $dec_2000);
    } elsif ($self->epoc() =~ /^EQ/i) {
      print "Coord-type: EQ\n" if ($debug);
      slaEcleq($ra, $dec, $mjd, $ra_2000, $dec_2000);
    }
    $self->ra2000($ra_2000);
    $self->dec2000($dec_2000);
    return 1;
  }
  return 0;
}

=item calcApp

returns the apparent Ra and Dec at the passed in LST in radians

  ($ra, $dec) = $obs->calcApp(2.3333);

=cut

sub calcApp {
  my $self = shift;
  my $mjd = shift;
  my ($ra_app, $dec_app);
  slaMap ($self->ra2000(), $self->dec2000(), 0.0, 0.0, 0.0, 0.0,
	  2000.0, $mjd, $ra_app, $dec_app);
  return ($ra_app, $dec_app);
}

=item calcPoints

Calculations the Elevation, Azimeth, etc. points
$MW is the main window widget.  Required for 
progress bar

  $obs->calcPoints($date, $Time, $NumPoints, $MW, $tel);

=cut

sub calcPoints {
  my $self = shift;
  my $DATE = shift;
  my $TIME = shift;
  my $numPoints = shift;
  my $MW = shift;
  my $tel = shift;
  my $timeBug = 0;

  my $array = new Astro::Instrument::SCUBA::Array;
  $array->tel($tel);
  my ($y, $mo, $d) = split (/\//, $DATE, 3);

  my $tlen = @{$self->{TIME_ELE_POINTS}} if defined $self->{TIME_ELE_POINTS};
  if (defined $tlen && $tlen > 0) {
    return;
  }

  my $offset = -2;
  my $date;
  if ($offset < 0) {
    $date = DateCalc(ParseDate("$mo\/$d\/$y $TIME"), "$offset hours");
  } else {
    $date = DateCalc(ParseDate("$mo\/$d\/$y $TIME"), "+ $offset hours");
  }
  my ($yy2, $mn2, $dd2) = split (/ /, UnixDate($date, '%Y %m %d'));
  my ($hh2, $mm2, $ss2) = split (/ /, UnixDate($date, '%H %M %S'));
  $mn2 = '0'.$mn2 if length($mn2) < 2;
  $dd2 = '0'.$dd2 if length($dd2) < 2;
  $mm2 = '0'.$mm2 if length($mm2) < 2;
  $ss2 = '0'.$ss2 if length($ss2) < 2;
  my ($lst, $mjd) = ut2lst($yy2,$mn2,$dd2,$hh2,$mm2,$ss2,$array->tel()->long_by_rad());
  $offset ++;
  if ($offset < 0) {
    $date = DateCalc(ParseDate("$mo\/$d\/$y $TIME"), "$offset hours");
  } else {
    $date = DateCalc(ParseDate("$mo\/$d\/$y $TIME"), "+ $offset hours");
  }
  ($yy2, $mn2, $dd2) = split (/ /, UnixDate($date, '%Y %m %d'));
  ($hh2, $mm2, $ss2) = split (/ /, UnixDate($date, '%H %M %S'));
  $mn2 = '0'.$mn2 if length($mn2) < 2;
  $dd2 = '0'.$dd2 if length($dd2) < 2;
  $mm2 = '0'.$mm2 if length($mm2) < 2;
  $ss2 = '0'.$ss2 if length($ss2) < 2;
  my ($lst2, $mjd2) = ut2lst($yy2,$mn2,$dd2,$hh2,$mm2,$ss2,$array->tel()->long_by_rad());
  if ($lst2 < $lst) {
    $lst2 += 2*pi;
  }
  my $lstdiff = $lst2 - $lst;
  for (my $h = 0; $h < $numPoints; $h++) {
    my ($ra, $dec);
    $MW->update;
    if ($self->type() =~ /planet/i) {
      my $dia;
      my $long =  $array->tel()->long_by_rad();
      my $lat =  $array->tel()->lat_by_rad();
      my $num = $self->planetnum();
      &slaRdplan( $mjd, $num, $long, $lat, $ra, $dec, $dia);
    } else {
      ($ra, $dec) = $self->calcApp( $mjd );
    }
    $array->lst($lst);
    $array->ra_centre_by_rad($ra);
    $array->dec_centre_by_rad($dec);

    my $ele = $array->elevation_by_deg();
    my $az = $array->azimuth_by_deg();
    my $pa = $array->par_angle_by_deg();

    push (@{$self->{TIME_ELE_POINTS}}, $lst);
    push (@{$self->{TIME_ELE_POINTS}}, $ele);

    push (@{$self->{TIME_AZ_POINTS}}, $lst);
    push (@{$self->{TIME_AZ_POINTS}}, $az);

    push (@{$self->{TIME_PA_POINTS}}, $lst);
    push (@{$self->{TIME_PA_POINTS}}, $pa);

    push (@{$self->{ELE_TIME_POINTS}}, $ele);
    push (@{$self->{ELE_TIME_POINTS}}, $lst);
    
    push (@{$self->{ELE_AZ_POINTS}}, $ele);
    push (@{$self->{ELE_AZ_POINTS}}, $az);

    push (@{$self->{ELE_PA_POINTS}}, $ele);
    push (@{$self->{ELE_PA_POINTS}}, $pa);

    push (@{$self->{AZ_TIME_POINTS}}, $az);
    push (@{$self->{AZ_TIME_POINTS}}, $lst);

    push (@{$self->{AZ_ELE_POINTS}}, $az);
    push (@{$self->{AZ_ELE_POINTS}}, $ele);

    push (@{$self->{AZ_PA_POINTS}}, $az);
    push (@{$self->{AZ_PA_POINTS}}, $pa);

    push (@{$self->{PA_TIME_POINTS}}, $pa);
    push (@{$self->{PA_TIME_POINTS}}, $lst);

    push (@{$self->{PA_ELE_POINTS}}, $pa);
    push (@{$self->{PA_ELE_POINTS}}, $ele);

    push (@{$self->{PA_AZ_POINTS}}, $pa);
    push (@{$self->{PA_AZ_POINTS}}, $az);

    $lst += $lstdiff * (24 / ($numPoints - 1));
  }  
}

=item calcPoint

Returns the time in decimal, elevation, azimuth, and parallactic angle
for a given source at a particular time and date.

  ($ele, $az, $pa) = $obs->calcPoint("1998/07/14", "13:05:44", $tel);

=cut

sub calcPoint {
  my $self = shift;
  my $DATE = shift;
  my $TIME = shift;
  my $tel = shift;
  my ($ra, $dec);
  my $array = new Astro::Instrument::SCUBA::Array;
  $array->tel($tel);
  my ($y, $mo, $d) = split (/\//, $DATE, 3);
  my $offset = 10;
  my $date;
  my $timeBug = 0;

  print "date = $DATE and time = $TIME before manips\n" if $timeBug;
  $date = DateCalc(ParseDate("$mo\/$d\/$y $TIME"), "+ $offset hours");
  my ($yy2, $mn2, $dd2) = split (/ /, UnixDate($date, '%Y %m %d'));
  my ($hh2, $mm2, $ss2) = split (/ /, UnixDate($date, '%H %M %S'));
  $mn2 = '0'.$mn2 if length($mn2) < 2;
  $dd2 = '0'.$dd2 if length($dd2) < 2;
  $ss2 = '0'.$ss2 if length($ss2) < 2;
  $mm2 = '0'.$mm2 if length($mm2) < 2;
  print "date = $yy2\/$mn2\/$dd2 and time = $hh2:$mm2:$ss2\n" if $timeBug;
  my ($lst, $mjd) = ut2lst($yy2,$mn2,$dd2,$hh2,$mm2,$ss2,$array->tel()->long_by_rad());

  if ($self->type() =~ /planet/i) {
    my $dia;
    my $long =  $array->tel()->long_by_rad();
    my $lat =  $array->tel()->lat_by_rad();
    my $num = $self->planetnum();
    &slaRdplan( $mjd, $num, $long, $lat, $ra, $dec, $dia);
  } else {
    ($ra, $dec) = $self->calcApp( $mjd );
  }

  $array->lst($lst);
  $array->ra_centre_by_rad($ra);
  $array->dec_centre_by_rad($dec);

  my ($elex, $eley) = $array->AzToRa(0, 30);
  my ($azx, $azy) = $array->AzToRa(30, 0);

  return ($lst, $array->elevation_by_deg(),$array->azimuth_by_deg(), $array->par_angle_by_deg(), $elex, $eley, $azx, $azy);
}

=item erasePoints

Erases all of the plotting points.  Needed when new coords put in.

  $obs->erasePoints();

=cut

sub erasePoints {
  my $self = shift;
  $self->{TIME_ELE_POINTS} = ();
  $self->{TIME_AZ_POINTS} = ();
  $self->{TIME_PA_POINTS} = ();
  $self->{ELE_TIME_POINTS} = ();
  $self->{ELE_AZ_POINTS} = ();
  $self->{ELE_PA_POINTS} = ();
  $self->{AZ_TIME_POINTS} = ();
  $self->{AZ_ELE_POINTS} = ();
  $self->{AZ_PA_POINTS} = ();
  $self->{PA_TIME_POINTS} = ();
  $self->{PA_ELE_POINTS} = ();
  $self->{PA_AZ_POINTS} = ();
  $self->{TIMEDOTX} = undef;
  $self->{TIMEDOTY} = undef;
}

=item eraseTimeDot

Erases the time dot coordinates

  $obs->eraseTimeDot();

=cut

sub eraseTimeDot {
  my $self = shift;
  $self->{TIMEDOTX} = undef;
  $self->{TIMEDOTY} = undef;
}

=back

=head1 AUTHOR

Casey Best

=cut

1;
