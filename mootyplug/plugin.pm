#!/usr/bin/perl
# plugin.pm - The mootykins3 plugin base class.
#
# (c) 2007 Lorenz Diener, lorenzd@gmail.com
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License or any later
# version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

use strict;

package mootyplug::plugin;

# A simple constructor.
sub new {
	my $type = shift;
	my $self = { };
	return bless $self, $type;
}

sub on_load {
	# die ( "ERROR: mootyplug default onload handler called." );
}

sub on_message {
	# die ( "ERROR: mootyplug default msg handler called." );
}

sub help {
	return ( "No help available." );
}
1;