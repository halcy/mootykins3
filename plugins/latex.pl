# help.pl - Plugin help plugin for mootykins3
#
# (c) 2008 Lorenz Diener, lorenzd@gmail.com
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

my $latex_path;
my $latex_url;
my $textogif_path;

sub on_load {
	$latex_path = get_conf_value ( "plugin::latex::path" ) || "";
	$latex_url = get_conf_value ( "plugin::latex::url" ) || "";
	$textogif_path = get_conf_value ( "plugin::latex::textogif" ) || "";
}

sub on_message {
	my ( $self, $message, $speaker, $rspsimple, $sndsimple, $private, $addressed, $irc ) = @_;
	my %plugins = %{ $irc -> {'MTK_PLUGIN_HASH'} };
	
	my $who = $sndsimple;
	$who =~ s/[^a-zA-Z0-9]//gi;

	if ( $message =~ /^!latex (.*)$/i ) {
		tolog( "PLUGIN: latex: Rendering some LaTeX." );
		
		my $filename = time();
		open( my $TEXFILE, '>', $latex_path . $filename . '.tex' );
		
		print $TEXFILE '\documentclass[amstex]{article}' . "\n";
		print $TEXFILE '\pagestyle{empty}' . "\n";
		print $TEXFILE '\begin{document}' . "\n";
		
		print $TEXFILE "Posted by $who at " . localtime( $filename ) . ":\n";
		
		print $TEXFILE '\begin{displaymath}' . "\n";
		print $TEXFILE "$1\n";
		print $TEXFILE '\end{displaymath}' . "\n";
		
		print $TEXFILE '\end{document}' . "\n";
		
		close $TEXFILE;
		
		open( my $PIPE, "$textogif_path $latex_path$filename.tex 2>&1 |" );
		my $success = 0;
		while( <$PIPE> ) {
			if( $_ =~ /<img src/ ) {
				$success = 1;
			}
		}
		close( $PIPE );
		
		if( $success == 1 ) {
			say( @_ , $rspsimple, "LaTeX: $latex_url$filename.png" );
		}
		else {
			say( @_ , $rspsimple, "LaTeX: Something went wrong while trying to render." );
		}
	}

# Deactivated due to pointless.
#if ( $message =~ /^!latexraw (.*)$/i ) {
#	my $filename = time();
#	open( my $TEXFILE, '>', $latex_path . $filename . '.tex' );
#	print $TEXFILE "$1\n";
#	close $TEXFILE;
#	
#	system( $textogif_path, $latex_path . $filename . '.tex' );
#
#	say( @_ , $rspsimple, "LaTeX (raw): $latex_url$filename.png" );
#}
}

sub help {
	my ( $self, $private, $channel, $irc ) = @_;
	return ( "!latex some_latex_expression: Renders whatever needs to be rendered as latex." );
}
