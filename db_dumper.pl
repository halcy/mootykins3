#!/usr/bin/perl
# Small tool for dumping a fact db (or any perl DBM file)
# to STDOUT

use strict;

my %db;
my $file = shift();

dbmopen ( %db, $file, 0664 ) or die(" FFFFFF" );

foreach ( keys %db ) {
	print "$_\n" . $db{$_} . ".\n";
}

dbmclose( %db );