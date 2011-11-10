# A Goa'Uld speaking plugin for mootykins3
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
		
	# Match against greetings.
	if ( fuzzy_eq ( $message, "Tek'ma'tae" ) > 0.82 ) {
		say ( @_, $rspsimple, "Ba'ja'kakma'te, $sndsimple!" );
		say ( @_, $rspsimple, random_goauld_sentence ( ) );
		return;
	}
	
	# Won't do that
	if ( fuzzy_eq ( $message, "Tal'chak'amel" ) > 0.82 ) {
		say ( @_, $rspsimple, "$sndsimple! Tal'bet Tau'ri!" );
		return;
	}
		
	# Surrender
	if ( fuzzy_eq ( $message, "Tal'bet" ) > 0.82 ) {
		say ( @_, $rspsimple, "Tal'chak'amel! Jaffa, ha'tak!" );
		return;
	}
		
	# Gods have come.
	if ( fuzzy_eq ( $message, "Di'bro, das weiafei, doo'wa!" ) > 0.82 ) {
		say ( @_, $rspsimple, "Kel sha, Goa'uld." );
		return;
	}
	
	# Attack
	if ( fuzzy_eq ( $message, "Jaffa, ha'tak!" ) > 0.82 ) {
		say ( @_, $rspsimple, "Bradio!" );
		return;
	}
	
	if ( fuzzy_eq ( $message, "Na'noweia si'taia!" ) > 0.82 ) {
		say ( @_, $rspsimple, "Lek tol, Tau'ri!" );
		return;
	}
	
	if ( fuzzy_eq ( $message, "Quell'shak" ) > 0.82 ) {
		say ( @_, $rspsimple, "Shal'kek..." );
		return;
	}
	
	if ( 
		( fuzzy_eq ( $message, "Rin'tel'noc" ) > 0.82 ) ||
		( fuzzy_eq ( $message, "Shal'kek" ) > 0.82 )
	) {
		say ( @_, $rspsimple, "Tal'chak'amel..." );
		return;
	}
}

sub random_goauld_sentence {
	my @sentences = (
		"Hakor Heelk'sha, Bradio!",
		"Di'bro, das weiafei, doo'wa!",
		"Jaffa, ha'tak!",
		"Ju'iu! Tau'ri!",
		"Ki'banja'swei!",
		"Kel sha.",
		"Na'noweia si'taia!",
		"Or'onac shol'va!",
		"Pa'kree?",
		"Quell'shak!",
		"Rin'tel'noc!",
		"Tal mal'tiak mal we'ia!"
	);
	return ( $sentences [ rand ( @sentences ) ] );
}

sub help {
	return "I speak Goa'uld! Behold the glowy eyes! (Hit up wikipedia for some Goa'uld sentences to try :).";
}