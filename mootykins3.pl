#!/usr/bin/perl
# mootykins3, a Perl IRC bot, now with magical POE powers.
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

# Defaulty
use warnings;
use strict;
use diagnostics;
use Socket;

# External includes
use Data::Dumper;

my $handle;

# POE!
use POE qw( 
	Component::IRC
	Component::IRC::Plugin::Connector
	Component::IRC::Plugin::CTCP
	Component::IRC::Plugin::NickReclaim
);

# Internal
use mootyconf;
use mootyplug;
use mootyplug::plugin;

# Do the daemon thing
exit if fork;

# Version string
my $mooty_version = "0.93 beta";

# Admin password
my $admin_password;

# Connection hash - holds all the connection items, linked to their names
my %connections = ( );

# Ignore list.
my @ignore = ();

# Read the config
tolog ( "STARTUP: Loading config." );
mootyconf::read ( "mootykins.config" );
my $ignore = mootyconf::getvalues ( "mootykins::ignore" );
@ignore = defined( $ignore ) ? @{ $ignore } : ();

# Ignore (Just kill off) child threads.
$SIG {CHLD} = "IGNORE";

# Load all possible plugins
my %plugins = ( );
tolog ( "STARTUP: Loading plugins." );
load_all_plugins();
tolog ( "STARTUP: All plugins loaded." );

tolog ( "STARTUP: Beginning connection initialization." );
# bc all those my - vars are not supposed to be file-scoped.
init ( );

# This will never be reached.
exit;

sub init {
	# Read the one global thing - admin pass - from the config
	$admin_password = mootyconf::getvalue ( "mootykins::admin_password" );

	# IRC is GO!
	tolog ( "STARTUP: IRC starting." );
	
	POE::Session->create(
		package_states => [
			'main' => [ qw( 
					_start
					irc_001
					irc_public
					irc_msg
					irc_340
					irc_nick
					irc_whois
				) ],
		],
		inline_states => {
			poe_die => sub {
				tolog( "SHUTDOWN: Exiting." );
				$poe_kernel->stop();
				exit();
			}
		}
	);

	# POE is GO!
	$poe_kernel->run();
}

######### EVENT HANDLERS BELOW THIS LINE

# Called on session start.
sub _start {
	my ( $kernel, $heap, $session ) = @_[KERNEL,HEAP,SESSION];

	# Server setup
	my @servers = @{ mootyconf::getvalues ( "mootykins::servers" ) };
	foreach ( @servers ) {
		connect_server( $_, $session );
	}

	return ( undef );
}

# Happens on connect
sub irc_001 {
	my ($kernel,$sender) = @_[KERNEL,SENDER];
	my $irc = $sender -> get_heap ( );

	tolog ( "STARTUP: Connected to " . $irc -> {MTK_SERVER_NAME} . " (" . $irc -> server_name ( ) . ")" );
		
	$irc->{MTK_NICK} = $irc->nick_name();

	if ( $irc -> {MTK_LOCALADDR} eq "auto" ) {
		# Get local ip
		tolog ( "STARTUP: Getting IP from sever." );
		# Get address from irc server
		$kernel -> post( $sender => quote => "USERIP " . $irc -> {MTK_NICK} );
	}
	
	# Join some channels.
	foreach ( @{ $irc -> {MTK_CHANNELS} } ) {
		tolog ( "STARTUP: Joining: $_" );
		$kernel -> post( $sender => join => $_ );
	}
}

sub irc_whois {
	my ($kernel,$sender,$nickinfo) = @_[KERNEL,SENDER,ARG0];
	my %nick = %{$nickinfo};
	print( "IS ON: " . $nick{nick} . "!" . $nick{user} . "@" . $nick{host} . ":" . $nick{real} . "#" . localtime(time()) . "\n"); 
}

# Nick change
sub irc_nick {
	my ($kernel,$sender,$changer,$newnick) = @_[KERNEL,SENDER,ARG0,ARG1];
	
	# Just make sure our own nick stays up-to-date in the internal data structure.
	my $irc = $sender->get_heap();
	$irc->{MTK_NICK} = $irc->nick_name();
}

# Recieved public message
sub irc_public {
	my ( $kernel, $heap, $sender, $speaker, $rspto, $message ) 
		= @_[KERNEL,HEAP,SENDER,ARG0,ARG1,ARG2];
	irc_any_message ( $kernel, $heap, $sender, $speaker, $rspto, $message, 0 );
}

# /msg recieved, fiddles a little with rspto
sub irc_msg {
	my ( $kernel, $heap, $sender, $rspto, $ignore_me, $message ) 
		= @_[KERNEL,HEAP,SENDER,ARG0,ARG1,ARG2];
	my $rspto_arr = [ ( split /!/, $rspto ) [ 0 ] ];
	irc_any_message ( $kernel, $heap, $sender, $rspto, $rspto_arr, $message, 1 );
}

# Recieved ANY message
sub irc_any_message {
	my ( $kernel, $heap, $sender, $speaker, $rspto, $message, $private ) = @_;
	my $irc = $sender->get_heap();
	
	my $rspsimple = @{ $rspto } [ 0 ];
	my $sndsimple = ( split /!/, $speaker ) [ 0 ];

	# Ignore list check.
	foreach( @ignore ) {
		if( lc( $sndsimple ) eq lc( $_ ) ) {
# 			notice( undef,
# 				$message,
# 				$speaker,
# 				$rspsimple,
# 				$sndsimple,
# 				$private,
# 				0,
# 				$irc,
# 				$sndsimple,
# 				"How about no."
# 			);
			return;
		}
	}

	# First thing's first: Was this an admin command?
	# If so, handle it.
	if( $message =~ /^!admin $admin_password rehash$/i ) {
		rehash();
	}

	if( $message =~ /^!admin $admin_password raw (.*)$/i ) {
		$irc->yield( quote => $1 );
	}
	
	if( $message =~ /^!admin $admin_password shutdown$/i ) {
		tolog( "SHUTDOWN: Unloading plugins." );
		foreach( keys %plugins ) {
			$plugins{ $_ }->on_unload();
		}
		
		tolog( "SHUTDOWN: Disconnecting servers." );
		foreach( keys %connections ) {
			disconnect_server( $_ );
		}
		
		$poe_kernel->delay( "poe_die" => 5 );
	}

	# Addressed?
	my $addressed = 0;
	my $mynick = $irc->{MTK_NICK};
	if ( $message =~ /^(\@$mynick|\@$mynick:|$mynick:)(\s*)(.*)/i ) {
		$message = $3;
		$addressed = 1;
	}

	# Private messages are sorta "adressed"
	if ( $private ) {
		$addressed = 1;
	}
		
	
	# Call the appropriate plugins.
	if ( $private ) {
		foreach my $plugin ( @{ $irc -> {'MTK_PLUGINS'} } ) {
			$plugins { $plugin } -> on_message (
				$message,
				$speaker,
				$rspsimple,
				$sndsimple,
				$private,
				$addressed,
				$irc
			);
		}
	} else {
		# Channel plugins.
		foreach my $plugin ( @{ $irc -> {'MTK_' . lc ( $rspsimple ) . '_PLUGINS'} } ) {
			$plugins { $plugin } -> on_message (
				$message,
				$speaker,
				$rspsimple,
				$sndsimple,
				$private,
				$addressed,
				$irc
			);
		}
	}
}

sub irc_340 {
	my ( $kernel, $heap, $sender,$arg1 ) = @_[KERNEL,HEAP,SENDER,ARG1];
	my $irc = $sender->get_heap();
	$irc->{MTK_ACTUALADDR} = ( ( $arg1 =~ /@(.*)/ ) [ 0 ] );
	tolog( "GENERAL: New local IP recieved ( $arg1 ) => " . $irc -> {MTK_ACTUALADDR} );
}

########## HELPER FUNCTIONS below this line.

# Connect to a single server.
sub connect_server {
	my $current_server = shift();
	my $session = shift();
	
	my $irc_server = 
		 mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::address" ) 
		|| "localhost";
	my $irc_port = 
		 mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::port" ) 
		||  mootyconf::getvalue ( "mootykins::port" ) 
		|| "6667";
	my $irc_nick = 
		 mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::nick" ) 
		||  mootyconf::getvalue ( "mootykins::nick" ) 
		|| "mootykins";
	my $irc_name = 
		 mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::ircname" )
		||  mootyconf::getvalue ( "mootykins::ircname" )
		|| "mootykins3 v$mooty_version";
	my $irc_username = mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::username" )
		||  mootyconf::getvalue ( "mootykins::username" )
		|| "mootykins3";
	my $irc_password = mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::password" )
		||  mootyconf::getvalue ( "mootykins::password" )
		|| "";
	my $irc_channels =
		 mootyconf::getvalues ( "mootykins::servers::" . $current_server . "::channels" )
		||  mootyconf::getvalues ( "mootykins::channels" )
		|| [ "#mootykins" ];
	my $local_addr = 
		 mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::local_addr" )
		||  mootyconf::getvalue ( "mootykins::local_addr" )
		|| "auto";	
	my $serv_plugins =  mootyconf::getvalues ( "mootykins::servers::" . $current_server . "::plugins" )
		||  mootyconf::getvalues ( "mootykins::plugins" )
		|| [ ];
	
	# Define a connection.
	my $conn = POE::Component::IRC -> spawn (
		server => $irc_server,
		port => $irc_port,
		nick => $irc_nick,
		ircname => $irc_name,
		NATAddr => $local_addr,
		Username => $irc_username,
		Password => $irc_password
	) or die "ERROR: This shouldn't have happend: $!\n";
	
	# IRC Plugins:
	# CTCP autoresponder
	$conn->plugin_add ( 'CTCP' => POE::Component::IRC::Plugin::CTCP -> new (
		version => $irc_name,
		userinfo => $irc_name
	) );
	
	# Nick reclaimer
	$conn->plugin_add ( 'NickReclaim' => POE::Component::IRC::Plugin::NickReclaim -> new( 
		poll => 30 ) 
	);
	
	# Connection keeper
	$conn-> plugin_add ( 'Connector' => POE::Component::IRC::Plugin::Connector -> new ( ) );
	
	# Copy parms to conn for later reference
	$conn->{MTK_SERVER_NAME} = $current_server;
	$conn->{MTK_SERVER} = $irc_server;
	$conn->{MTK_PORT} = $irc_port;
	$conn->{MTK_DESIRED_NICK} = $irc_nick;
	$conn->{MTK_NAME} = $irc_name;
	$conn->{MTK_USERNAME} = $irc_username;
	$conn->{MTK_PASSWORD} = $irc_password;
	$conn->{MTK_CHANNELS} = $irc_channels;
	$conn->{MTK_LOCALADDR} = $local_addr;
	$conn->{MTK_PLUGINS} = $serv_plugins;
	$conn->{MTK_SELF} = $conn;
	$conn->{MTK_PLUGIN_HASH} = \%plugins;
	$conn->{MTK_CONN_HASH} = \%connections;

	# Plugin settings for each channel.
	foreach ( @{ $conn -> {MTK_CHANNELS} } ) {
		my $plugs = mootyconf::getvalues ( "mootykins::channels::" . $current_server. "::" . $_ . "::plugins" );
		$conn -> {'MTK_' . lc ( $_ ) . '_PLUGINS'} = $plugs || $serv_plugins;
	}
	
	# Save for later use.
	$connections { $current_server } = $conn;
	
	# FYI
	tolog ( "CONNECT: Registering PoCo IRCs with session..." );
	$poe_kernel->signal( $poe_kernel, 'POCOIRC_REGISTER', $session->ID(), 'all' );
	tolog ( "CONNECT: Connecting to " .  $conn->{MTK_SERVER} . "..." );
	$poe_kernel->post( $conn->session_id() => connect => { } );
}



# Reload config vars for a single server.
sub reconfigure_server {
	my $current_server = shift();
	my $conn = $connections{ $current_server };
	
	my $irc_server = 
		 mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::address" ) 
		|| "localhost";
	my $irc_port = 
		 mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::port" ) 
		||  mootyconf::getvalue ( "mootykins::port" ) 
		|| "6667";
	my $irc_nick = 
		 mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::nick" ) 
		||  mootyconf::getvalue ( "mootykins::nick" ) 
		|| "mootykins";
	my $irc_name = 
		 mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::ircname" )
		||  mootyconf::getvalue ( "mootykins::ircname" )
		|| "mootykins3 v$mooty_version";
	my $irc_username = mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::username" )
		||  mootyconf::getvalue ( "mootykins::username" )
		|| "mootykins3";
	my $irc_password = mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::password" )
		||  mootyconf::getvalue ( "mootykins::password" )
		|| "";
	my $irc_channels =
		 mootyconf::getvalues ( "mootykins::servers::" . $current_server . "::channels" )
		||  mootyconf::getvalues ( "mootykins::channels" )
		|| [ "#mootykins" ];
	my $local_addr = 
		 mootyconf::getvalue ( "mootykins::servers::" . $current_server . "::local_addr" )
		||  mootyconf::getvalue ( "mootykins::local_addr" )
		|| "auto";	
	my $serv_plugins =  mootyconf::getvalues ( "mootykins::servers::" . $current_server . "::plugins" )
		||  mootyconf::getvalues ( "mootykins::plugins" )
		|| [ ];
	
	# Did the server address, port, username, password or ircname change? If so, reconnect.
	if( ($conn->{MTK_SERVER} ne $irc_server)
		|| ($conn->{MTK_PORT} ne $irc_port)
		|| ($conn->{MTK_NAME} ne $irc_name)
		|| ($conn->{MTK_NAME} ne $irc_name)
		|| ($conn->{MTK_USERNAME} ne $irc_username)
		|| ($conn->{MTK_PASSWORD} ne $irc_password)
	) {
		tolog( "REHASH: Found change in config that requires reconnect of $current_server." );
		disconnect_server( $current_server );
		connect_server( $current_server );
		
		# At this point, this server is pretty much done.
		return();
	}
	
	# Is the local address value "auto" now?
	# If so, USERIP time.
	if ( $local_addr eq "auto" ) {
		tolog ( "REHASH: Re-getting IP from sever." );
			$conn->yield( quote => "USERIP " . $conn->{MTK_NICK} );
	}
	
	# Did the nickname change -> rename.
	if( $conn->{MTK_NICK} ne $irc_nick ) {
		$conn->yield( nick => $irc_nick );
	}
	
	# Join new channels and load plugin settings for the channels.
	my %new_channels = ();
	foreach ( @{ $irc_channels } ) {
		$new_channels{ lc( $_ ) } = 1;
		
		if( !$conn->{'MTK_' . lc ( $_ ) . '_PLUGINS'} ) {
			$conn->yield( join => $_ );
		}
		
		my $plugs = mootyconf::getvalues ( "mootykins::channels::" . $current_server. "::" . $_ . "::plugins" );
		$conn->{'MTK_' . lc ( $_ ) . '_PLUGINS'} = $plugs || $serv_plugins;
	}
	
	# Part old channels.
	foreach( @{ $conn->{MTK_CHANNELS} } ) {
		if( !$new_channels{ lc( $_ ) } ) {
			$conn->yield( part => $_ => "Mootykins3: Mootyleaving." );
			undef( $conn->{'MTK_' . lc ( $_ ) . '_PLUGINS'} );
			$conn->{'MTK_' . lc ( $_ ) . '_PLUGINS'} = undef;
		}
	}
	
	# Copy parms to conn for later reference
	$conn->{MTK_DESIRED_NICK} = $irc_nick;
	$conn->{MTK_CHANNELS} = $irc_channels;
	$conn->{MTK_LOCALADDR} = $local_addr;
	$conn->{MTK_PLUGINS} = $serv_plugins;	
}

# Disconnect a single server.
sub disconnect_server {
	my $server = shift();
	# Do it in sync. This is supposed to happen NOW!
	tolog( "DISCONNECT: Disconnecting $server." );
	$connections{ $server }->plugin_del( "Connector" );
	$connections{ $server }->call( "shutdown" => "Mootykins3: Mootyquiting." );
	undef( $connections{ $server } );
	$connections{ $server } = undef;
	delete( $connections{ $server } );
}

# Unload and load all plugins in plugins/
sub load_all_plugins {
	my %new_plugins = ();
	while( <plugins/*.pl> ) {
		$_ =~ /plugins\/([^.]*)\.pl/;
		my $plugin = load_plugin( $1 );
		
		# If this is a plugin reload, unload the plugin first.
		if( $plugins{ $1 } ) {
			# A word of warning: it is assumed that plugins
			# properly clean up if asked to. If they don't do
			# that, bad things _might_ happen.
			tolog( "PLUGINS: Unloading plugin $1." );
			$plugins{ $1 }->on_unload();
		}
		
		$new_plugins{ $1 } = 1;
		
		$plugins{ $1 } = $plugin;
		$plugin->on_load();
		tolog( "PLUGINS: Loaded plugin $1." );
	}
	
	# Kick removed plugins out of the plugin hash.
	foreach( keys( %plugins ) ) {
		if( !$new_plugins{ $_ } ) {
			undef( $plugins{ $_ } );
			$plugins{ $_ } = undef;
			delete( $plugins{ $_ } );
		}
	}
}

# Load a single plugin.
# Returns an object of said plugin.
sub load_plugin {
	# Yes, we're redefining subroutines. Meh.
	no warnings 'redefine';
		
	my $plugin = shift ( );
	
	my $sub;
	open PLUGIN, "plugins/$plugin.pl" or die "ERROR: Loading $plugin failed: $!";
	{
		local $/ = undef;
		$sub = <PLUGIN>;
	}
	close PLUGIN;
	
	# Fumble in optional functions. 
	# Hacky, but should do the job, mostly.
	if( $sub !~ /on_load/ ) {
		$sub .= "\n sub on_load(){} \n"
	}
	
	if( $sub !~ /on_unload/ ) {
		$sub .= "\n sub on_unload(){} \n"
	}
	
	my $eval = (
		"\n" .
		"package mootyplug::$plugin;" .
		'use mootyplug;' .
		'use vars qw(@ISA);' .
		'use strict;' .
		'@ISA = qw(mootyplug::plugin);' .
		$sub .
		"# End of plugin.\n"
	);
	eval $eval;
	die "ERROR: $plugin - eval $@" if $@;

	my $pclass = "mootyplug::$plugin";
	my $plug_obj = $pclass->new();
	$plug_obj->{MTK_PLUGIN_NAME} = $plugin;
	return ( $plug_obj );
}

# Rehash of the entire bot.
sub rehash {
	tolog( "REHASH: Rehash initiated." );
	
	sleep( 1 );
	
	tolog( "REHASH: Reloading configuration from disk." );
	mootyconf::read ( "mootykins.config" );

	@ignore = @{ mootyconf::getvalues ( "mootykins::ignore" ) };

	tolog ( "REHASH: Reloading plugins." );
	load_all_plugins();
	
	my @servers = @{ mootyconf::getvalues ( "mootykins::servers" ) };
	my %new_servers = ();
	foreach( @servers ) {
		$new_servers{ $_ } = 1;
	}
	
	tolog ( "REHASH: Setting parameters on untouched servers." );
	foreach( @servers ) {
		if( $connections{ $_ } ) {
			reconfigure_server( $_ );
		}
	}
	
	tolog ( "REHASH: Connecting new servers." );	
	foreach( @servers ) {
		if( !$connections{ $_ } ) {
			connect_server( $_ );
		}
	}
	
	tolog ( "REHASH: Disconnecting old servers." );
	foreach( keys( %connections ) ) {
		if( !$new_servers{ $_ } ) {
			disconnect_server( $_ );
		}
	}
	
	tolog ( "REHASH: Rehash over." );
}
