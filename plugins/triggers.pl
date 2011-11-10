# triggers.pl - A trigger plugin for mootykins3
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
	$load_tmp = get_conf_values ( "plugin::triggers" );
	if ( $load_tmp ) {
		@triggers = @{ $load_tmp };
	}
}

sub on_message {
	my ( $self, $message, $speaker, $rspsimple, $sndsimple, $private, $addressed, $irc ) = @_;

	my $ch_tmp;
	if ( $private ) {
		$ch_tmp = get_server_conf_values ( $irc, "triggers::active" ) || ( );
	} else {
		$ch_tmp = 
			get_channel_conf_values ( $irc, $rspsimple, "triggers::active" ) ||
			get_server_conf_values ( $irc, "triggers::active" ) || 
			( );
	}

	my @ch_triggers = $ch_tmp ? @{ $ch_tmp } : ( );

	foreach my $trigger ( @ch_triggers ) {
		if ( lc ( $trigger ) ne lc ( $message ) ) {
			next;
		}

		tolog ( "PLUGIN: triggers: $trigger activated." );

		my @do = @{ get_conf_values ( "plugin::triggers::" . $trigger . "::message" ) };
		my $type = get_conf_value ( "plugin::triggers::" . $trigger . "::type" ) || "say";
		my $to = get_conf_value ( "plugin::triggers::" . $trigger . "::to" );
		$to = ( $to && $to eq "channel" ) ? $rspsimple : $sndsimple;

		my $do_joined = join ( "\n", @do );

		if ( lc ( $type ) eq "say" ) {
			say ( @_, $to, $do_joined );
		}

		if ( lc ( $type ) eq "notice" ) {
			notice ( @_, $to, $do_joined );
		}

		if ( lc ( $type ) eq "action" ) {
			action ( @_, $to, $do_joined );
		}
	}
}

sub help {
	my ( $self, $private, $channel, $irc ) = @_;

	my $ch_tmp;
	if ( $private ) {
		$ch_tmp = get_server_conf_values ( $irc, "triggers::active" ) || ( );
	} else {
		$ch_tmp = 
			get_channel_conf_values ( $irc, $channel, "triggers::active" ) ||
			get_server_conf_values ( $irc, "triggers::active" ) || 
			( );
	}

	my @ch_triggers = $ch_tmp ? @{ $ch_tmp } : ( );

	return ( "I react to different simple triggers. (" . join ( ", ", @ch_triggers ) . ")" );
}