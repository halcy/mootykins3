#!/usr/bin/perl
# pseudopoe.pm - It's like a POE session, but doesn't yield shit.
# Instead, it stores events in a queue for the main thread to handle.
# It also holds config value stuff for the plugins to work with.
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

use warnings;
use strict;

package pseudopoe;

# Threading
use threads;
use threads::shared;
use Thread::Queue;

sub new {
	my( $class, $conn, $queue ) = @_;
	my $self = bless {}, $class;
 	$self->{MTK_SERVER_NAME} = $conn->{MTK_SERVER_NAME};
	$self->{MTK_SERVER} = $conn->{MTK_SERVER};
	$self->{MTK_PORT} = $conn->{MTK_PORT};
	$self->{MTK_NICK} = $conn->{MTK_NICK};
	$self->{MTK_NAME} = $conn->{MTK_NAME};
	$self->{MTK_USERNAME} = $conn->{MTK_USERNAME};
	$self->{MTK_CHANNELS} =$conn->{MTK_CHANNELS};
	$self->{MTK_LOCALADDR} = $conn->{MTK_LOCALADDR};
	$self->{MTK_PLUGINS} = $conn->{MTK_PLUGINS};
	$self->{MTK_PLUGIN_HASH} = $conn->{MTK_PLUGIN_HASH};
	
	foreach ( @{ $self->{MTK_CHANNELS} } ) {
		my $plugs = mootyconf::getvalues (
			"mootykins::channels::" . $conn->{MTK_SERVER_NAME} . "::" . $_ . "::plugins"
		);
		$self->{'MTK_' . lc ( $_ ) . '_PLUGINS'} = $plugs || $self->{MTK_PLUGINS};
	}
	
	# Self-pointers are not copied, this would kind
	# of make all this pointless.
	# Set to undef to make things fail horribly
	# instead of quietly going wrong.
	# I should find a better solution for this at some point.
	# Maybe with names.
	$self->{MTK_SELF} = undef;
	$self->{MTK_CONN_HASH} = undef;
	
	$self->{_event_queue} = $queue;
	return( $self );
}

sub yield {
	my $self = shift();
	my $coll_queue = $self->{_event_queue };
	my @event_line :shared;
	@event_line = ( $self->{MTK_SERVER_NAME}, @_ );
	$coll_queue->enqueue( \@event_line );
}

1;