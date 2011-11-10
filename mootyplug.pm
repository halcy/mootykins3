#!/usr/bin/perl
# mootplug.pm - the mootykins3 plugin api, basically.
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

package mootyplug;

use mootyconf;

use strict;
use warnings;

use Algorithm::HowSimilar qw( compare );

use Exporter 'import';

our @EXPORT = qw(tolog get_conf_value get_conf_values say notice action colour reset_style bold underline invert get_channel_conf_value get_channel_conf_values get_server_conf_value get_server_conf_values fuzzy_eq get_hash_approx get_array_approx);

# Log function. Just prints stuff to stdout. 
sub tolog {
	print shift ( ) . "\n";
}

# Wrappers for mootyconf.
sub get_conf_value {
	return ( mootyconf::getvalue ( shift ( ) ) );
}

sub get_conf_values {
	return ( mootyconf::getvalues ( shift ( ) ) );
}

sub get_channel_conf_value {
	my $server = shift ( );
	$server = $server->{'MTK_SERVER_NAME'};
	my $channel = shift ( );
	my $key = shift ( );
	return ( mootyconf::getvalue ( 
		"mootykins::channels::" . $server . "::" . $channel . "::plugin::" . $key
	) );
}

sub get_channel_conf_values {
	my $server = shift ( );
	$server = $server->{'MTK_SERVER_NAME'};
	my $channel = shift ( );
	my $key = shift ( );
	return ( mootyconf::getvalues ( 
		"mootykins::channels::" . $server . "::" . $channel . "::plugin::" . $key
	) );
}

sub get_server_conf_value {
	my $server = shift ( );
	$server = $server->{'MTK_SERVER_NAME'};
	my $key = shift ( );
	return ( mootyconf::getvalue ( "mootykins::servers::" . $server . "::plugin::" . $key ) );
}

sub get_server_conf_values {
	my $server = shift ( );
	$server = $server->{'MTK_SERVER_NAME'};
	my $key = shift ( );
	return ( mootyconf::getvalues ( "mootykins::servers::" . $server . "::plugin::" . $key ) );
}

# Say things.
sub say {
	my ( $a, $said, $b , $rspsimple, $sndsimple, $c , $d , $irc, $target, $message ) = @_;

	my @messages = split ( /\n/, $message );
	foreach my $do ( @messages ) {
		$do = replace_vars ( $said, $rspsimple, $sndsimple, $target, $irc, $do );
		$irc->yield( 'privmsg' => $target => $do );
	}
}

# Send notices.
sub notice {
	my ( $a, $said, $b , $rspsimple, $sndsimple, $c , $d , $irc, $target, $message ) = @_;

	my @messages = split ( /\n/, $message );
	foreach my $do ( @messages ) {
		$do = replace_vars ( $said, $rspsimple, $sndsimple, $target, $irc, $do );
		$irc->yield( 'notice' => $target => $do );
	}
}

# /me style.
sub action {
	my ( $a, $said, $b , $rspsimple, $sndsimple, $c , $d , $irc, $target, $message ) = @_;

	my @messages = split ( /\n/, $message );
	foreach my $do ( @messages ) {
		$do = replace_vars ( $said, $rspsimple, $sndsimple, $target, $irc, $do );
		$irc->yield( 'ctcp' => $target => "ACTION $do" );
	}
}

# Replace common vars: %sender, %channel, %server, %myname, %said, %to
sub replace_vars {
	my ( $said, $channel, $sender, $to, $irc, $message ) = @_;
	my $server = $irc->{MTK_SERVER_NAME};
	my $nick = $irc->{MTK_NICK};
	$message =~ s/%sender/$sender/gi;
	$message =~ s/%channel/$channel/gi;
	$message =~ s/%server/$server/gi;
	$message =~ s/%myname/$nick/gi;
	$message =~ s/%said/$said/gi;
	$message =~ s/%to/$to/gi;
	$message =~ s/%C([0-9][0-9]),([0-9][0-9])/colour($1,$2)/ge;
	$message =~ s/%C([0-9][0-9])/colour($1)/ge;
	$message =~ s/%C/colour()/ge;
	$message =~ s/%B/bold()/ge;
	$message =~ s/%O/reset_style()/ge;
	$message =~ s/%U/underline()/ge;
	return ( $message );
}

# Colourize text
sub colour {
	my ( $fg, $bg ) = @_;
	if ( !$bg ) {
		if ( !$fg ) {
			return ( chr ( 3 ) );
		} else {
			return ( chr ( 3 ) . $fg );
		}
	} else {
		return ( chr ( 3 ) . $bg );
	}
}

# Colour reference, borrowed from the irssi docs.
#                foreground (fg)     background (bg)
#    -------------------------------------------------------
#     0          white               light gray   + blinking fg
#     1          black               black
#     2          blue                blue
#     3          green               green
#     4          light red           red          + blinking fg
#     5          red                 red
#     6          magenta (purple)    magenta
#     7          orange              orange
#     8          yellow              orange       + blinking fg
#     9          light green         green        + blinking fg
#     10         cyan                cyan
#     11         light cyan          cyan         + blinking fg
#     12         light blue          blue         + blinking fg
#     13         light magenta       magenta      + blinking fg
#     14         gray                black        + blinking fg
#     15         light gray          light gray


# Reset all styling (^O)
sub reset_style {
	return ( chr ( 15 ) );
}

# Boldifies text (^B)
sub bold {
	return ( chr ( 2 ) );
}

# Underlines text (^U)
sub underline {
	return ( chr ( 31 ) );
}

# Inverts colours (^R)
sub invert {
	return ( chr ( 22 ) );
}

# Does a fuzzy compare of two values. Returns a similarity between 1 and 0.
sub fuzzy_eq {
	my ( $one, $two ) = @_;

	if( !defined( $one ) || !defined( $two ) || $one eq '' || $two eq '' )
		{ return( 0 ) };

	my @res = compare( lc ( $one ), lc ( $two ) );
	return ( $res [ 0 ] );
}

# Get an approximateley matching value from a hash.
# Returns in the form of [ similarity, matched key]
# Might sometimes return [ 1, perfect match ]
# Might sometimes return [ 0, totally not matching value ]
# CASE INSENSITIVE.
sub get_hash_approx {
	my $key = shift ( );
	my %hash = @_;
	
	# Return the best match.
	return get_array_approx ( $key, keys ( %hash ) );
}

# Same as above, for arrays.
sub get_array_approx {
	my $element = shift ( );
	my @array = @_;
	my $element_compare = lc ( $element );

	if( !defined( $element_compare ) || $element_compare eq '' ) 
		{ return( [ 0, undef ] ) };

	# Build the similarity array and compare.
	my @similiar = ( );
	foreach my $arr_element ( @array ) {
		if ( $element_compare eq lc ( $arr_element ) ) {
			# Perfect
			return ( [ 1, $arr_element ] );
		} else {
			my @res = compare ( $element_compare, lc ( $arr_element ) );
			push ( @similiar, [ $res [ 0 ], $arr_element ] );
		}
	}

	# No perfect match has been found => sort the imperfect matches.
	my @sorted =  sort { $b->[0] <=> $a->[0] } @similiar;
	
	if( $sorted [ 0 ] ) {
		# Return the best match.
		return $sorted [ 0 ];
	} else {
		# SO YOU GET NOTHING! YOU LOOSE, GOOD DAY SIR!
		[ 0, '' ]
	}
}
