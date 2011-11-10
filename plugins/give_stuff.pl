# give_stuff.pl - A stuff-giver plugin for mootykins3
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

use Tie::File;

my @stuff = ( );

sub on_load {
	my $load_tmp;
	$load_tmp = get_conf_values ( "plugin::give_stuff" );
	if ( $load_tmp ) {
		@stuff = @{ $load_tmp };
	}
}

sub on_message {
	my ( $self, $message, $speaker, $rspsimple, $sndsimple, $private, $addressed, $irc ) = @_;

	my $ch_tmp;
	if ( $private ) {
		$ch_tmp = get_server_conf_values ( $irc, "give_stuff::active" ) || ( );
	} else {
		$ch_tmp = 
			get_channel_conf_values ( $irc, $rspsimple, "give_stuff::active" ) ||
			get_server_conf_values ( $irc, "give_stuff::active" ) || 
			( );
	}

	my @ch_stuff = $ch_tmp ? @{ $ch_tmp } : ( );

	foreach my $giveable ( @ch_stuff ) {
		my $type;
		my $to_whom;

		# Find out if we're going to give out this thing, and to whom
		# and what type of thing specifically.
		my $giveableto = $giveable . "to";
		if ( !( $message =~ /^!$giveable( -(.*))?$/ ) ) {
			if ( !( $message =~ /^!$giveableto (\S+)( -(.*))?$/ ) ) {
				next;
			} else {
				$to_whom = $1;
				$type = $3;
			}
		} else {
			$to_whom = $sndsimple;
			$type = $1;
		}

		tolog ( "PLUGIN: give_stuff: Giving $giveable to $to_whom." );

		# Get config values.
		my $type_file = get_conf_value ( "plugin::give_stuff::" . $giveable . "::type_file" );
		my $prefix = get_conf_values (  "plugin::give_stuff::" . $giveable . "::prefix" );
		my $howto = get_conf_value (  "plugin::give_stuff::" . $giveable . "::how" ) || "hands";

		if ( $prefix ) {
			my @prefixes = @{ $prefix };
			$prefix = ' ' . $prefixes [ rand ( @prefixes ) ] . ' '; 
		} else {
			$prefix = ' ';
		}

		# Get a value from the type file.
		my @types;
		if ( ! -e ( $type_file ) ) {
			die "ERROR: PLUGIN: give_stuff: Could not open type file $type_file.";
		}
		open TYPES, '<', $type_file or die "ERROR: PLUGIN: give_stuff: Could not open type file $type_file.";
		@types = <TYPES>;
		close TYPES;

		if ( $type ) {
			my @res = @{ get_array_approx ( $type, @types ) };
			if ( $res [ 0 ] <= 0.4 ) {
				$type = "nosuch$giveable";
			} else {
				$type = $res [ 1 ];
			}
		} else {
			$type = $types [ rand ( @types ) ];
		}
		chomp( $type );

		action ( @_, $rspsimple, $howto . ' ' . $to_whom . $prefix . $type . '.' );

		untie @types;
	}
}

sub help {
	my ( $self, $private, $channel, $irc ) = @_;

	my $ch_tmp;
	if ( $private ) {
		$ch_tmp = get_server_conf_values ( $irc, "give_stuff::active" ) || ( );
	} else {
		$ch_tmp = 
			get_channel_conf_values ( $irc, $channel, "give_stuff::active" ) ||
			get_server_conf_values ( $irc, "give_stuff::active" ) || 
			( );
	}

	my @ch_stuff = $ch_tmp ? @{ $ch_tmp } : ( );

	return ( 'I give people stuff. Use like this: !(thing)[to (person) [-type] / Example: !beerto %myname -skol . I give these fine things: ' . join ( ', ', @ch_stuff ) . '.' );
}