sub on_load {
	tolog ( "DEBUG: Debug plugin ready go." );
}

sub on_message {
	my ( $self, $message, $speaker, $rspsimple, $sndsimple, $private, $addressed, $irc ) = @_;
	tolog ( "DEBUG: $speaker said '$message' ($rspsimple/$sndsimple - $private/$addressed)" );
}

sub help {
	my ( $self, $private, $channel, $irc ) = @_;
	return ( "Debug plugin, plz2ignore." );
}