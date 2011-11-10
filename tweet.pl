# tweet.pl - A twitter plugin for mootykins. Possibly outdated.
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

use Net::Twitter::Lite;
my $nt;

sub on_load {
	$nt = Net::Twitter::Lite->new(
		clientname => "VIPTWEET",
		clientver => "9001",
		clienturl => "http://secretareaofvipquality.net/",
		useragent => "VIPTWEET",
		source => "viptweet",
		consumer_key => "YOUR KEY HERE",
		consumer_secret => "YOUR SECRET HERE",
		username => "YOUR USERNAME HERE",
		password => "YOUR PASSWORD HERE",
	);
}

sub on_message {
	my ( $self, $message, $speaker, $rspsimple, $sndsimple, $private, $addressed, $irc ) = @_;

	# Get kopipe.
	if( $message =~ /^!tweet\s?(.*)?$/ ) {
		my $requested = $1;
		
		tolog( "PLUGIN: Tweet: Tweet requested." );

		if( $requested && !$requested =~ /^\s*$/ ) {
			# tweets4vip
			if( !( $requested =~ /tweets4vip/i ) ) {
				if( rand(3) < 1 ) {
					$requested =~ s/\s+$//;
					$requested .= " #tweets4vip";
					say( @_, $rspsimple, "That was VIP QUALITY." );
				}
			}

			eval { $nt->update( $requested ) };
			say( @_, $rspsimple, "It tweets. http://twitter.com/saovq" );
		}
	}
}

sub help {
	return ( "I tweet. http://twitter.com/saovq ." );
}
