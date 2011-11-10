# relay.pl - A relay plugin for mootykins3
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

sub on_load {
	
}

sub on_message {
	my ( $self, $message, $speaker, $rspsimple, $sndsimple, $private, $addressed, $irc ) = @_;

	my $ch_tmp;
	if ( $private ) {
		# No point in relaying privmsgs.
		return;
	} else {
		$ch_tmp = 
			get_channel_conf_values ( $irc, $rspsimple, "relay::to" ) ||
			( );
	}
	my @ch_relays = $ch_tmp ? @{ $ch_tmp } : ( );

	foreach my $relay ( @ch_relays ) {
		my ( $channel, $server ) = ( $relay =~ /^([^ ]*)\s(.*)$/ );
		my $say_what = "<$sndsimple> $message";
		$irc -> {MTK_CONN_HASH} -> {$server} -> yield( 'privmsg' => $channel => $say_what );
	}
}

sub help {
	my ( $self, $private, $channel, $irc ) = @_;

	my $ch_tmp;
	if ( $private ) {
		return "I relay messages to other channels.";
	} else {
		$ch_tmp = 
			get_channel_conf_values ( $irc, $channel, "relay::to" ) ||
			( );
	}

	my @ch_relays = $ch_tmp ? @{ $ch_tmp } : ( );

	return ( 'I relay messages to other channels. From this channel, I relay to: ' . join ( ', ', @ch_relays ) . '.' );
}