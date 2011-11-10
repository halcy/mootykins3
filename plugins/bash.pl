# bash.pl - A quote getting plugin for mootykins3
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

use LWP::UserAgent;
my $ua;

sub on_load {
	$ua = LWP::UserAgent->new;
	$ua->agent( "mootykins3" );
}

sub on_message {
	my ( $self, $message, $speaker, $rspsimple, $sndsimple, $private, $addressed, $irc ) = @_;

	my $quote;
	my $perma;
	my $score;
	
	# Do bash.org
	if( $message =~ /^!bash(\s[0-9]*)?$/ ) {
		my $html;
		my $id = $1;
		if ( $id && !( $id eq ' ' ) ) {
			$id =~ /\s([0-9]*)/;
			$id = $1;
			$html = get_website ( "http://bash.org/?$id" );
		} else {
			$html = get_website ( "http://bash.org/?random" );
		}

		$html =~ s/<br \/>/\n/gi;
		$html =~ /<p class="qt">([^<]*)/;		
		$quote = $1;

		$html =~ /title="Permanent link to this quote."><b>#([0-9]*)<\/b><\/a>/;
		$perma = "http://bash.org/?$1";

		$html =~ /class="qa">\+<\/a>\(([\-0-9]*)\)<a href=".\/\?le=/;
		$score = $1;
	}

	# Do qdb.us
	if( $message =~ /^!qdb(\s[0-9]*)?$/ ) {
		my $html;
		my $id = $1;

		if ( $id && !( $id eq ' ' ) ) {
			$id =~ /\s([0-9]*)/;
			$id = $1;
			$html = get_website ( "http://qdb.us/$id" );
		} else {
			$html = get_website ( "http://qdb.us/random" );
		}

		$html =~ s/<br \/>/\n/gi;
		$html =~ /<td bgcolor="#ffffff"><p>([^<]*)/;
		$quote = $1;

		$html =~ /<td bgcolor="#ffffff"><a href="\/([0-9]*)">#/;
		$perma = "http://qdb.us/$1";

		$html =~ /"><b>([\-0-9]*)<\/b><\/font>\//;
		$score = $1;
	}

	# Do german-bash.org
	if( $message =~ /^!gbo(\s[0-9]*)?$/ ) {
		my $html;
		my $id = $1;
		if ( $id && !( $id eq ' ' ) ) {
			$id =~ /\s([0-9]*)/;
			$id = $1;
			$html = get_website ( "http://german-bash.org/$id" );
		} else {
			$html = get_website ( "http://german-bash.org/action/random" );
		}
		
		$html =~ s/<span class="quote_zeile">//gi;
		$html =~ s/<\/span>/\n/gi;
		$html =~ /<div class="zitat">([^<]*)/;
		$quote = $1;

		$html =~ /Bewerte Zitat #([0-9]*) positiv/;
		$perma = "http://german-bash.org/$1";
	
		$html =~ /abgegebene Stimmen.">([\-0-9]*)<\/a>/;
		$score = $1;
	}

	# Do notalwaysright.com
	if( $message =~ /^!nar(\s[0-9]*)?$/ ) {
		my $html;
		my $id = $1;
		if ( $id && !( $id eq ' ' ) ) {
			$id =~ /\s([0-9]*)/;
			$id = $1;
			$html = get_website ( "http://notalwaysright.com/a/$id" );
		} else {
			$html = get_website ( "http://notalwaysright.com/?random" );
		}

		$html =~ /<h3 class="storytitle"><a href="([^"]*)/i;
		$perma = $1;
	
		$html =~ s/<a href="([^"]*)">//gi;
		$html =~ s/<\/a>//gi;
		$html =~ s/<p>//gi;
		$html =~ s/<\/p>/\n/gi;
		$html =~ s/^(<em>|<strong>)?Related:.*$//gim;
		$html =~ s/<br \/>/\n/gi;
		$html =~ /<div class="storycontent">(.*?)<\/div>/s;

		$quote = $1;
		$quote =~ s/(<strong>|<em>|<\/strong>|<\/em>)/bold();/gei;
	}

	# Do grouphug.us
	if( $message =~ /^!gh(\s[0-9]*)?$/ ) {
		my $html;
		my $id = $1;
		if ( $id && !( $id eq ' ' ) ) {
			$id =~ /\s([0-9]*)/;
			$id = $1;
			$html = get_website ( "http://beta.grouphug.us/confessions/$id" );
			$perma = "http://beta.grouphug.us/confessions/$id";
		} else {
			$html = get_website ( "http://beta.grouphug.us/random?p=" . rand( 99999999 ) );
			$html =~ /<a href="\/confessions\/([0-9]+)">/i;
			$perma = "http://beta.grouphug.us/confessions/$1";
		}

		$html =~ s/<br \/>/\n/gi;
		$html =~ s/<a href="([^"]*)">//gi;
		$html =~ s/<\/a>//gi;
		$html =~ s/<p>//gi;
		$html =~ s/<\/p>/\n/gi;
		$html =~ /<div class="content">([^<]*?)<\/div>/s;

		$quote = $1;
	}

	if ( $quote ) {
		# Clean stuff up a bit.
		$quote =~ s{(&\#([0-9]+);|&#x([0-9a-f]+);)}{chr($2 or hex $3)}gei;
		$quote =~ s/&nbsp;/ /gi;
		$quote =~ s/&quot;/"/gi;
		$quote =~ s/&lt;/</gi;
		$quote =~ s/&gt;/>/gi;
		$quote =~ s/&amp;/&/gi;
		
		# Remove unneccesary whitespace.
		$quote =~ s/^(\s*)([^\n]*)/\n$2/gi;
		$quote =~ s/\n(\s*)([^\n]*)/\n$2/gi;
		$quote =~ s/([^\n]*)(\s*)\n/$1\n/gi;
		
		# Beautify with bold.
		$quote =~ s/^<(.[^>]*?)>/(bold() . "<$1>" . bold() . reset_style())/geim;
		$quote =~ s/^([^: ]*?): /(bold() . "$1: " . bold() . reset_style())/geim;
		
		# Split into nice handle-able pieces.
		my @lines = split ( /\n/, $quote );
		$quote = "";
		foreach my $line ( @lines ) {
			while ( $line =~ /^(.{290,}?)\b(.*)$/gis ) {
				$quote .= "$1\n";
				$line = $2;
			}

			$quote .= "$line\n";
		}

		# Make the info text to send.
		my $info =	
			"Permalink to quote: " . bold() . $perma . bold() .
			( ( defined ( $score ) ) ? " | Score: " . bold() . $score . bold() . reset_style() : "" );
	
		# Send and done.
		say ( @_, $rspsimple, $info );
		say ( @_, $rspsimple, $quote );
	}
}

sub help {
	return ( "I give quotes from bash.org, qdb.us, german-bash.org, notalwaysright.com and GroupHug.us (!bash, !qdb, !gbo, !nar, !gh; Give a number to get a specific quote)." );
}

# Some helpers.
sub get_website {
	my $url = shift();
	tolog ( "PLUGIN: bash: Doing request to $url." );
	my $req = HTTP::Request->new( GET => $url );
	my $res = $ua->request($req);

	if ( $res->is_success ) {
		my $html = $res->content;
		$html =~ s/[\n\r]//gi;
		return $html;
	} else {
		tolog ( "ERROR: PLUGIN: bash: Could not fetch $url." );
		return "";
	}
}