#!/usr/bin/perl
# mootyconf.pm - the mootykins3 config handling module.
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

package mootyconf;
use strict;
use warnings;
use Data::Dumper;

# This hash holds the config.
my %config;
my %lc_config;

# Read in a config file
sub read {
	my ( $filename ) = @_;
	my $section = "mootykins";
	open FH, "<$filename";
	
	# Clean up before reloading.
	undef( %config );
	undef( %lc_config );
	
	while ( <FH> ) {
		# Whithespace sux
		chomp $_;
		
		# Comments
		next if ( $_ =~ /^#/ );
		
		# Empty lines
		next if ( $_ =~ /^(\s*)$/ );

		# Check if this is a section or value
		if ( $_ =~ /^(\s*)\[(.*)\]$/ ) {
			# Section
			my @secparts = split ( "::", $2 );
			$section = "";
			for ( my $i = 0; $i < @secparts - 1; $i++ ) {
				$_ = $secparts [ $i ];

				# Watch out for empty section id
				if ( $section eq "" ) {
					$section .= "$_";
				} else {
					$section .= "::$_";
				}
				
				$section = $section;
				
				# Create new hash value if needed.
				if ( !defined ( $config {$section} ) ) {
					$config {$section} = [ ];
				}
				# Puh the next element into this hashvalue.
				push ( @{ $config {$section} }, $secparts [ $i + 1 ] );
			}
		
			# Empty section strikes again:
			if ( $section eq "" ) {
				$section .= $secparts [ @secparts - 1 ];
			} else {
				$section .= "::" . $secparts [ @secparts - 1 ];
			}
		} else {
			# Value... or not?
			if ( $_ =~ /^(\s*)(.*?)(\s*)=(\s*)(.*)(\s*)$/ ) {
				# Value indeed.
				
				my $hashname = $2;
				# Create new hash value if needed.
				if ( !defined ( $config {$section . "::" . $hashname} ) ) {
					$config {$section . "::" . $hashname} = [ ];
				}

				# Values can be seperated by commata, commata can
				# be escaped as double-commata.
				my $to_split = $5;
				$to_split =~ s/,,/\n/g;
				my @nextval = split ( ",", $to_split );

				# Whitespace removal
				for ( my $i = 0; $i < @nextval; $i++ ) {
					$nextval [ $i ] =~ s/^(\s*)(.*)(\s*)$/$2/;
					$nextval [ $i ] =~ s/\n/,/g;
				}
				# Puh the next elements into this hashvalue.
				push ( @{ $config {$section . "::" . $hashname} }, @nextval );
			} else {
				#  Wrong syntax means death.
				die ( "MOOTYCONF: Error while reading config! ($_)" );
			}
		}
	}

	%lc_config = ( );
	foreach ( keys ( %config ) ) {
		$lc_config{ lc( $_ ) } = $_;
	}

	# Config has been read. Close the file.
	close FH;
}

# Fetch a single value from the config - returns all values of this 
# config item's value array joined by ", " ( w/o quotes)
sub getvalue {
	my ( $item ) = @_;
	$item = lc ( $item );
	if ( !$lc_config {$item} ) {
		 return "";
	}
	return ( join ( ", ",  @{ $config{ $lc_config {$item} } } ) );
}

# Fetch a lot of values from the config - returns this config items value array
sub getvalues {
	my ( $item ) = @_;
	$item = lc ( $item );

	if ( !$lc_config {$item} ) {
		return ( ( ) );
	}
	return $config{ $lc_config {$item} };
}

1;
