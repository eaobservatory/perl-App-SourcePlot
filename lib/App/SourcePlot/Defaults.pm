package App::SourcePlot::Defaults;
 
=head1 NAME

Defaults - creates a configuration file that stores default
values for telescope, x-axis, y-axis and time for the splot
application.  
By Pam Shimek (University of Victoria)

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

