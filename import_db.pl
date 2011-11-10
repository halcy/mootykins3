#!/usr/bin/perl
# Small tool for importing into the new mooty fact DB.

use strict;

use DB_File;

my $file = shift();
my $filein = shift();

my %db = ();

tie( %db, "DB_File", $file, O_RDWR|O_CREAT, 0640, $DB_HASH )
	or die "ERROR: Plugin: infobot: Could not open DB $file.";

open( my $IN, '<', $filein );
while( <$IN> ) {
	my $thing = <$IN>;
	chomp( $_ );
	chomp( $thing );
	$db{$_} = $thing;
	print "Setting $_ = $thing\n";
}
close( $IN );

untie( %db );
 