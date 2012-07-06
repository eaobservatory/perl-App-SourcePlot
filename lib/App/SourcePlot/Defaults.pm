package App::SourcePlot::Defaults;
 
=head1 NAME

Defaults - creates a configuration file that stores default
values for telescope, x-axis, y-axis and time for the splot
application.  

=head1 DESCRIPTION

Defaults creates a hidden system configuration file, storing
default values for the splot application.

=cut

use strict;
use IO::File;
use Cwd;
use Class::Struct;

use vars qw/$VERSION/;
$VERSION = '0.10';

=head1 EXTERNAL MODULES

  IO::File
  Class::Struct
  Cwd

=cut

=head1 PUBLIC METHODS

Methods available in this class:

=over 1

=item new

Creates an new Defaults object.
A new Defaults object will be created.  

    $defaults = Defaults->new;

=cut

struct('App::SourcePlot::Defaults', {file =>'$', values => '%'} );

=item r_defaults

Reads an existing .splotcfg configuration file to set default
values or writes to this file with program pre-determined values
if file did not already exist

    $defaults = Defaults->r_defaults();

=cut

sub r_defaults {
	my $self = shift;
	my $curr_dir = cwd();
	my $field = shift;
	my $key;
	my $value;
	chdir(); # go to default home dir
	if(-e $self->file)
	{	
		open(FILE, $self->file) || die "Cannot open file here \n";
		while(<FILE>)
		{
			my ($param,$value) = split(/\=/, $_);
			$self->values($param,$value);
		}
		close(FILE);
		chdir($curr_dir);
	}
	else
	{	#establish default values
		while( ($key,$value) = each (%{$field}))
		{	
			$self->values($key,$value);
		}
		$self->w_defaults();
	}			
	chdir($curr_dir);
			
}

=item w_defaults

Writes to an existing .splotcfg configuration file to set default
values or writes to this file with program pre-determined values
if file did not already exist

    $defaults = Defaults->w_defaults();

=cut

sub w_defaults {
	my $self = shift;
	my $curr_dir = cwd();
	chdir(); # go to default home dir
	my $fl = new IO::File($self->file(), 'w');
	die "Didn't work" unless defined $fl;
	my $key;
	my $value;
	while( ($key,$value) = each (%{$self->values}))
	{	
		print $fl "$key=$value\n";
	}
	chdir($curr_dir);
}

1;

__END__

=back

=head1 AUTHOR

Pam Shimek (University of Victoria)

=head1 COPYRIGHT

Copyright (C) 2012 Science and Technology Facilities Council.
Copyright (C) 1998 Particle Physics and Astronomy Research
Council. All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
