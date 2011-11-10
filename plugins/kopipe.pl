# kopipe.pl - A kopipe getting plugin for mootykins3 powered by tanasinn.info
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

use MediaWiki::API;
my $mw;

sub urlsafe {
	my $arg = shift();
	$arg =~ s/%/%25/gi;
	$arg =~ s/ /%20/gi;
	$arg =~ s/\?/%3F/gi;
	$arg =~ s/&/%26/gi;
	$arg =~ s/\//%2F/gi;
	return( $arg );
}

# Split into nice handle-able pieces.
sub text_split {
	my $k_text = shift();
	my @lines = split ( /\n/, $k_text );
	$k_text = "";
	foreach my $line ( @lines ) {
		while ( $line =~ /^(.{290,}?)\b(.*)$/gis ) {
			$k_text .= "$1\n";
			$line = $2;
		}

		$k_text .= "$line\n";
	}
	return( $k_text );
}

sub on_load {
	$mw = MediaWiki::API->new();
	$mw->{config}->{api_url} = 'http://tanasinn.info/api.php';
}

sub on_message {
	my ( $self, $message, $speaker, $rspsimple, $sndsimple, $private, $addressed, $irc ) = @_;

	# Get kopipe.
	if( $message =~ /^!kopipe\s?(.*)?$/ ) {
		my $requested = $1;
		tolog( "PLUGIN: Kopipe: Kopipe requested." );

		# Get category list.
		my $cat = $mw->list( {
			action => 'query',
			list => 'categorymembers',
			cmtitle => 'Category:Kopipe',
			cmlimit => 'max',
		} );

		my @cat_list = ();
		foreach( @{$cat} ) {
			$_->{title} =~ /Kopipe:(.*)/;
			if( lc( $1 ) ne 'all kopipe' ) {
				push( @cat_list, $1 );
			}
		}

		# Select category based on user request or randomly.
		# Check for mode inficators.
		my $list = 0;
		my $search = 0;
		my $search_st = "";
		if( !$requested || $requested eq ' ' ) {
			$requested = "Kopipe:" . $cat_list[ rand scalar keys @cat_list ];
		}
		else {
			# Special case: Category list.
			if( lc( $requested ) eq 'categories' ) {
				say( @_, $rspsimple, bold() . "Kopipe categories: " .
					bold() . reset_style() . join( ", ", @cat_list ) . " - http://tanasinn.info/wiki/Kopipe" );
				return;
			}

			# List kopipe.
			if( $requested =~ /list (.*)/ ) {
				$requested = $1;
				$list = 1;
			}

			# search kopipe.
			if( $requested =~ /search (.*)/ ) {
				$requested = $1;
				$search_st = $1;
				$search = 1;
			}
			else {
				# Sanity check
				my $found = 0;
				foreach my $k_cat( @cat_list ) {
					if( lc( $k_cat ) eq lc( $requested ) ) {
						$found = 1;
						$requested = "Kopipe:$k_cat";
					}
				}
				if( !$found ) {
					say( @_, $rspsimple, bold() . "Oops: " . bold() . reset_style() .  "No such category." );
					return;
				}
			}
		}

		# Search mode: Search for kopipe, print out best hit.
		if( $search ) {
			my $results = $mw->list( {
				action => 'query',
				list => 'search',
				srsearch => $requested,
				srwhat => 'text',
				srnamespace => '100',
			} );

			if( scalar @{$results} == 0 ) {
				say( @_, $rspsimple, bold() . "Oops: " . bold() . reset_style() .  "No results." );
				return;
			}
			my @res_array = @{$results};
			$requested = $res_array[ 0 ]->{title};
		}

		# Get kopipe
		my $page = $mw->get_page( { title => $requested } );
		my %kopipe = ();
			while( $page->{'*'} =~ /\n=+=+\s*(.*?)\s*=+=+.*?\n*(.*?)\n+=+=+/gs ) {
			my $title = $1;
			my $text = $2;
			chomp( $text );
			$text =~ s/\n*\[\[image:(?:.*?)\]\]\n*//gi;
			$text =~ s/{{[^}]*?}}//gi;
			$text =~ s/\[\[.*?\|(.*?)\]\]/$1/gi;
			$text =~ s/<[^>]*>//gi;
			if( length( $text ) >= 15 ) {
				$kopipe{ $title } = $text;
			}
		}

		# List mode: Print kopipe list.
		if( $list == 1 ) {
			my( $req_say ) = ($requested =~ /Kopipe:(.*)/);
			my $req_safe = urlsafe( $requested );
			say( @_, $rspsimple, bold() . "Kopipe in $req_say: " .
				bold() . reset_style() . text_split( join( ", ", sort keys( %kopipe ) ) ) .
				" - http://tanasinn.info/wiki/$req_safe" );
			return;
		}

		# Title to use for output.
		my $title;

		# Search mode?
		if( $search ) {
			my $found = 0;
			foreach( keys %kopipe ) {
				print( $search_st . " --- $_\n" );
				if( fuzzy_eq( $search_st, $_ ) > 0.7 ) {
					$title = $_;
					$found = 1;
				}
			}

			if( !$found ) {
				say( @_, $rspsimple, bold() . "Oops: " . bold() . reset_style() .  "No results." );
				return;
			}
		}
		else {
			# Select random kopipe
			my @k_keys = keys( %kopipe );
			my $selected = rand scalar keys %kopipe;
			$title = $k_keys[ rand scalar keys %kopipe ];
		}

		my $k_text = $kopipe{ $title };
		$k_text = text_split( $k_text );

		# Make the info text to send.
		my $title_safe = urlsafe( $title );
		my $req_safe = urlsafe( $requested );
		my $info = say( @_, $rspsimple, "Kopipe: " . bold() . $title . bold() . reset_style() .
			" - http://tanasinn.info/wiki/$req_safe#$title_safe" );
	
		# Send and done.
		say ( @_, $rspsimple, $info );
		say ( @_, $rspsimple, $k_text );
	}
}

sub help {
	return ( "I give kopipe from the oh so famous tanasinn.info kopipe archive. !kopipe for random kopipe, !kopipe somecategory for random kopipe from that category, !kopipe list somecategory to list kopipe in category, !kopipe categories to see categories." );
}
