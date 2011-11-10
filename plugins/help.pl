# help.pl - Plugin help plugin for mootykins3
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
	# Nothing happens.
}

sub on_message {
	my ( $self, $message, $speaker, $rspsimple, $sndsimple, $private, $addressed, $irc ) = @_;
	my %plugins = %{ $irc -> {'MTK_PLUGIN_HASH'} };
	
	if ( $message =~ /^!help(\s(.*))*$/i ) {
		# Specific plugin's help requested?
		if ( $1 ) {
			my $help_about= $2;
			chomp ( $help_about );
			tolog ( "PLUGIN: help: Help about $help_about requested." );
			foreach my $plugin ( keys ( %plugins ) ) {
				if ( 
					lc ( $help_about ) eq 
					lc ( $plugins{$plugin}->{'MTK_PLUGIN_NAME'} ) ) 
				{
					my $help = $plugins { $plugin }->help (
						$private, $rspsimple, $irc
					);
					$help = 
						colour ( 7 ) . bold ( ) . "(mootyhelp) " .
						bold ( ) . "$plugin: " . reset_style ( ) .
						$help;

					notice ( @_, $sndsimple, $help );
				}
			}
		} else {
			my @plugin_names = ( );
			tolog ( "PLUGIN: help: Help requested." );
			if ( $private ) {
				foreach my $plugin ( @{ $irc -> {'MTK_PLUGINS'} } ) {
					push (
						@plugin_names,
						$plugins{$plugin}->{'MTK_PLUGIN_NAME'} 
					);
				}
			} else {
				foreach my $plugin ( @{$irc->{'MTK_' . lc ( $rspsimple ) . '_PLUGINS'}} ) {
					push (
						@plugin_names,
						$plugins{$plugin}->{'MTK_PLUGIN_NAME'} 
					);
				}
			}
			my $help = 
				colour ( 7 ) . bold ( ) . "(mootyhelp) " .
				bold ( ) . "plugins: " . reset_style ( ) .
				join ( ", ", @plugin_names ) . "\n" .
				"For single plugin usage information, type !help pluginname.\n" .
				"i wish to be the little girl";

			notice ( @_, $sndsimple, $help );
		}
	}
}

sub help {
	my ( $self, $private, $channel, $irc ) = @_;
	return ( "!help to recieve general help, !help pluginname for help about specific plugins." );
}
