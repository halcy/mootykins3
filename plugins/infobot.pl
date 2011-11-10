# infobot.pl - Plugin help plugin for mootykins3
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

my $default_db;

use DB_File;

sub on_load {
	# Look up the default db.
	$default_db = get_conf_value ( "plugin::infobot::db" ) || "info_db";
}

sub on_message {
	my ( $self, $message, $speaker, $rspsimple, $sndsimple, $private, $addressed, $irc ) = @_;

	# Useful tidbits for making a regex later.
	my $rx_things = "([^?]+?)";
	my $rx_questions = "(who|what|wer|was|wtf)";
	my $rx_pronouns = "(the|der|die|das|teh|a|one)";
	my $rx_is = "(is|ist|isch)";

	# Special questions
	if( $addressed ) {
		if ( $message =~ /who are you/i ) {
			$message = "Who is " . $irc->{MTK_NICK} . "?";
		}
	}

	if ( $message =~ /^who am i\??$/i ) {
		$message = "Who is $sndsimple?";
	}

	# It's a question => Give fact.
	if ( $message =~ /^$rx_questions\s$rx_is(\s$rx_pronouns)?\s$rx_things\??$/i ) {
		# Find which DB to use.
		my $use_db = $default_db;
		if ( $private ) {
			$use_db = get_server_conf_value ( $irc, "infobot::db" ) || $default_db;
		} else {
			$use_db = 
				get_channel_conf_values ( $irc, $rspsimple, "infobot::db" ) ||
				get_server_conf_values ( $irc, "infobot::db" ) || 
				$default_db;
		}
	
		# Open the info DB
		my %info_db = ( );
		tie( %info_db, "DB_File", $use_db, O_RDWR|O_CREAT, 0640, $DB_HASH )
			or die "ERROR: Plugin: infobot: Could not open DB $use_db.";

		my $prefix = $4;
		if ( $prefix ) {
			$prefix .= " ";
		} else {
			$prefix = "";
		}

		my $thing = $5;

		# Fetch fact from the DB
		my @res = @{ get_hash_approx ( $thing, %info_db ) };

		my $response = "";

		# Perfect match.
		if ( $res [ 0 ] == 1 ) {
			$response = 
				$prefix . $res [ 1 ] . " is " . 
				$info_db { $res [ 1 ] } . ".";
		}

		# No match.
		if ( $res [ 0 ] < 0.82 ) {
			if ( $addressed ) {
				$response = "Sorry, I know nothing.";
			} else {
				$response = "";
			}
		}

		# Fuzzy match.
		if ( $res [ 0 ] > 0.82 && $res [ 0 ] != 1 ) {
			$response = 
				"If by '$thing' you mean '" . $res [ 1 ] .
				"', then let me tell you, " .
				 $prefix . $res [ 1 ] . " is " .
				$info_db { $res [ 1 ] } . ".";
		}
		
		tolog ( "PLUGIN: infobot: Fact about '$thing' requested from $use_db." );
		say ( @_ , $rspsimple, ucfirst ( $response ) );
		
		untie( %info_db );

		return;
	}
	
	# It's a fact => Store.
	if ( $message =~ /^($rx_pronouns\s)?$rx_things\s$rx_is\s$rx_things[.!1]?$/i ) {
		# Find which DB to use.
		my $use_db = $default_db;
		if ( $private ) {
			$use_db = get_server_conf_value ( $irc, "infobot::db" ) || $default_db;
		} else {
			$use_db = 
				get_channel_conf_values ( $irc, $rspsimple, "infobot::db" ) ||
				get_server_conf_values ( $irc, "infobot::db" ) || 
				$default_db;
		}
	
		# Open the info DB
		my %info_db = ( );
		tie( %info_db, "DB_File", $use_db, O_RDWR|O_CREAT, 0640, $DB_HASH )
			or die "ERROR: Plugin: infobot: Could not open DB $use_db.";

		# Store fact.
		$info_db { lc( $3 ) } = $5;
		tolog ( "PLUGIN: infobot: Learned new fact $3 = $5 to $use_db." );

		untie ( %info_db );

		return;
	}
}

sub help {
	my ( $self, $private, $channel, $irc ) = @_;
	return ( "Ask me questions, or tell me loads of interesting things! I learn while people talk." );
}