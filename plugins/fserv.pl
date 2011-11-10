# fserv.pl - A file server plugins for mootykins3.
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

my @triggers = ( );

sub on_load {
	my $load_tmp;
	$load_tmp = get_conf_values ( "plugin::fserv::triggers" );
	if ( $load_tmp ) {
		@triggers = @{ $load_tmp };
	}
}

sub on_message {
	my ( $self, $message, $speaker, $rspsimple, $sndsimple, $private, $addressed, $irc ) = @_;

	my $ch_tmp;
	if ( $private ) {
		$ch_tmp = get_server_conf_values ( $irc, "fserv::triggers" ) || ( );
	} else {
		$ch_tmp = 
			get_channel_conf_values ( $irc, $rspsimple, "fserv::triggers" ) ||
			get_server_conf_values ( $irc, "fserv::triggers" ) || 
			( );
	}

	my @ch_triggers = $ch_tmp ? @{ $ch_tmp } : ( );

	foreach my $trigger ( @ch_triggers ) {
		if ( lc ( $trigger ) ne lc ( $message ) ) {
			next;
		}

		tolog ( "PLUGIN: fserv: $trigger activated." );

		my $path = get_conf_value( "plugin::fserv::" . $trigger . "::path" );
		my $note = get_conf_value( "plugin::triggers::" . $trigger . "::note" );
		my $message = get_conf_value( "plugin::triggers::" . $trigger . "::message" );

		
	}
}

sub help {
	my ( $self, $private, $channel, $irc ) = @_;

	my $ch_tmp;
	if ( $private ) {
		$ch_tmp = get_server_conf_values ( $irc, "fserv::triggers" ) || ( );
	} else {
		$ch_tmp = 
			get_channel_conf_values ( $irc, $channel, "fserv::triggers" ) ||
			get_server_conf_values ( $irc, "fserv::triggers" ) || 
			( );
	}

	my @ch_triggers = $ch_tmp ? @{ $ch_tmp } : ( );

	return ( "I serve files. Call up an fserv window by doing /msg %OWN_NICK% sometrigger. Triggers active: " . join ( ", ", @ch_triggers ) . "" );
}