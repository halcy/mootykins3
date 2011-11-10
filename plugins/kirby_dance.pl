# kirby_dance.pl - A sophisticated kirby-dance plugin for mootykins3
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

my @kirbys_normal = ( );
my @kirbys_wavy = ( );
my @kirbys_xtra = ( );
my @eyes = ( );
	
my @standard_texts = ( );

my $use_normal = 0;
my $use_wavy = 0;
my $use_xtra = 0;

my $color = 0;

sub on_load {
	my $load_tmp;

	$load_tmp = get_conf_values ( "plugin::kirby_dance::kirbys_normal" );
	if ( $load_tmp ) {
		@kirbys_normal =  @{ $load_tmp };
	} else {
		@kirbys_normal =  ( "<(^_^<)","(>^_^)>", "(>^_^<)", "<(^_^)>" );
	}

	$load_tmp = get_conf_values ( "plugin::kirby_dance::kirbys_wavy" );
	if ( $load_tmp ) {
		@kirbys_wavy =  @{ $load_tmp };
	} else {
		@kirbys_wavy = ( "~(^_^~)", "~(^_^)~", "(~^_^)~" );
	}

	$load_tmp = get_conf_values ( "plugin::kirby_dance::kirbys_xtra" );
	if ( $load_tmp ) {
		@kirbys_xtra =  @{ $load_tmp };
	} else {
		@kirbys_xtra = ( "[- . -]", "(v^_^)>", "<(^_^v)", "\(^_^)", "(^_^)/", "\(^_^)/" );
	}

	$load_tmp = get_conf_values ( "plugin::kirby_dance::eyes" );
	if ( $load_tmp ) {
		@eyes =  @{ $load_tmp };
	} else {
		@eyes = ( '^', '\'', '-', '*', 'o' );
	}
	
	$load_tmp = get_conf_values ( "plugin::kirby_dance::texts" );
	if ( $load_tmp ) {
		@standard_texts =  @{ $load_tmp };
	} else {
		@standard_texts = (
			"HEART!",
			"SUPER HAPPY FUN!",
			"OH YEAH!",
			"PINK FLUFFY BALLS OF LOVE!",
			"KIRBY DANCE!",
			"WOOOOOOOOOO!",
			"SUNSHINE!",
			"HEART!",
			"IT IS THE POWER OF LOVE!"
		);
	}

	$load_tmp = get_conf_value ( "plugin::kirby_dance::use_normal" ) || '1';
	if ( $load_tmp || $load_tmp == 0 ) {
		$use_normal = $load_tmp;
	} else {
		$use_normal = 1;
	}

	$load_tmp = get_conf_value ( "plugin::kirby_dance::use_wavy" ) || '1';
	if ( $load_tmp || $load_tmp == 0 ) {
		$use_wavy = $load_tmp;
	} else {
		$use_wavy = 1;
	}

	$load_tmp = get_conf_value ( "plugin::kirby_dance::use_xtra" ) || '1';
	if ( $load_tmp || $load_tmp == 0 ) {
		$use_xtra = $load_tmp;
	} else {
		$use_xtra = 1;
	}

	$load_tmp = get_conf_value ( "plugin::kirby_dance::colour" ) || $color;
	if ( $load_tmp || $load_tmp == 0 ) {
		$color = $load_tmp;
	} else {
		$color = 1;
	}

	tolog ( "PLUGIN: Kirby dance loaded." );
}

sub on_message {
	my ( $self, $message, $speaker, $rspsimple, $sndsimple, $private, $addressed, $irc ) = @_;

	if ( $message =~ /kirby dance/i ) {
		tolog ( "PLUGIN: kirby_dance: Doing default dance." );
		say ( @_, $rspsimple, kirby_dance ( ) );
	}

	if ( $message =~ /^!kirby(.*)/i ) {
		tolog ( "PLUGIN: kirby_dance: Doing configured dance." );
		say ( @_, $rspsimple, kirby_dance ( $1 ) );
	} else {
		if ( $message =~ /^!kirby/i ) {
			tolog ( "PLUGIN: kirby_dance: Doing default dance." );
			say ( @_, $rspsimple, kirby_dance ( ) );
		}
	}
}

# The uber-awesome kirby dance funcion
sub kirby_dance {
	my $cmdline = shift ( );
	my @ARGV_pre = ( );
	if ( $cmdline ) {
		@ARGV_pre = split ( /\s(?=--)/, $cmdline );
	}

	my @ARGV = ( );
	foreach ( @ARGV_pre ) {
		if ( $_ && $_ ne '' ) {
			$_ =~ /^(--[^ ]*)(\s+(.*))?$/;
			if ( $3 ) {
				push ( @ARGV , $1 );
				push ( @ARGV , $3 );
			} else {
				push ( @ARGV , $1 );
			}
		}
	}
	
	my $kirbyanz = rand ( 9 ) + 3;
	my $say = int ( rand ( ) );
	my $text = $standard_texts [ rand ( @standard_texts ) ];

	for ( my $i = 0; $i < @ARGV; $i++ ) {
		if ( $ARGV [ $i ] =~ /--no-normal/ ) {
			$use_normal = 0;
			next;
		}
		
		if ( $ARGV [ $i ] =~ /--no-wavy/ ) {
			$use_wavy = 0;
			next;
		}
		
		if ( $ARGV [ $i ] =~ /--no-extra/ ) {
			$use_xtra = 0;
			next;
		}
		
		if ( $ARGV [ $i ] =~ /--num/ ) {
			$kirbyanz = $ARGV [ $i + 1 ];
			if ( $kirbyanz > 50 ) {
				return ( "Use a sane amount, ffs!" );
			}
			$i++;
			next;
		}
		
		if ( $ARGV [ $i ] =~ /--text/ ) {
			$text = $ARGV [ $i + 1 ];
			$i++;
			next;
		}
		
		if ( $ARGV [ $i ] =~ /--say-left/ ) {
			$say = 1;
			next;
		}
		
		if ( $ARGV [ $i ] =~ /--say-right/ ) {
			$say = 0;
			next;
		}
		
		if ( $ARGV [ $i ] =~ /--say-nothing/ ) {
			$say = 2;
			next;
		}
		
		if ( $ARGV [ $i ] =~ /--say-nothing/ ) {
			$say = 2;
			next;
		}
		
		if ( $ARGV [ $i ] =~ /--no-eyes-happy/ ) {
			$eyes [ 0 ] = 'z';
			next;
		}
		
		if ( $ARGV [ $i ] =~ /--no-eyes-serious/ ) {
			$eyes [ 1 ] = 'z';
			shift ( @kirbys_xtra );
			next;
		}
	
		if ( $ARGV [ $i ] =~ /--no-eyes-cool/ ) {
			$eyes [ 2 ] = 'z';
			next;
		}

		if ( $ARGV [ $i ] =~ /--no-eyes-starry/ ) {
			$eyes [ 3 ] = 'z';
			next;
		}
		
		if ( $ARGV [ $i ] =~ /--no-eyes-confused/ ) {
			$eyes [ 4 ] = 'z';
			next;
		}

		if ( $ARGV [ $i ] =~ /--colour-all/ ) {
			$color = 1;
			next;
		}

		if ( $ARGV [ $i ] =~ /--colour-some/ ) {
			$color = 2;
			next;
		}

		if ( $ARGV [ $i ] =~ /--colour-none/ ) {
			$color = 0;
			next;
		}

		if ( $ARGV [ $i ] =~ /--help/ ) {
			return ( 
				"Usage: " .
				"kirby.pl --num <number> --say-(right|left|nothing) --text " .
				"<text> --no-[wavy|normal|extra] " . 
				"--no-eyes-[happy|serious|cool|starry|confused] " . 
				"--colour-(all|some|none)"
			);
		}

		return ( "ATTN: Invalid kirby option - '" . $ARGV [ $i ] . "'!" );
	}

	my @eyes_proc = ( );
	foreach ( @eyes ) {
		if ( $_ && $_ ne 'z' ) {
			push ( @eyes_proc, $_ );
		}
	}

	my $kirbys = "";
	
	while ( $kirbyanz > 0 ) {
		my $curarr = int ( rand ( 3 ) - 0.00001 );
		if ( $curarr == 0 ) {
			if ( $use_normal ) {
				my $new_kirby = $kirbys_normal [ rand ( @kirbys_normal ) ] . " ";

				if ( $color == 1 ) {
					$new_kirby = colour ( 13 ) . $new_kirby . reset_style ( );
				}

				if ( $color == 2 ) {
					if ( rand ( ) >= 0.5 ) {
						$new_kirby = colour (13) . $new_kirby . reset_style();
					}
				}

				my $random_eye = $eyes_proc [ rand ( @eyes_proc ) ];
				$new_kirby =~ s/\^/$random_eye/g;
				$kirbys .= $new_kirby;
				$kirbyanz--;
			}
		}
		
		if ( $curarr == 1 ) {
			if ( $use_wavy ) {
				my $new_kirby = $kirbys_wavy [ rand ( @kirbys_wavy ) ] . " ";

				if ( $color == 1 ) {
					$new_kirby = chr(3) . "13$new_kirby" . chr(3) . "0";
				}

				if ( $color == 2 ) {
					if ( rand ( ) >= 0.5 ) {
						$new_kirby = chr(3) . "13$new_kirby" . chr(3) . "0";
					}
				}

				my $random_eye = $eyes_proc [ rand ( @eyes_proc ) ];
				$new_kirby =~ s/\^/$random_eye/g;
				$kirbys .= $new_kirby;
				$kirbyanz--;
			}
		}
		
		if ( $curarr == 2 ) {
			if ( $use_xtra ) {
				my $new_kirby = $kirbys_xtra [ rand ( @kirbys_xtra ) ] . " ";

				if ( $color == 1 ) {
					$new_kirby = chr(3) . "13$new_kirby" . chr(3) . "0";
				}

				if ( $color == 2 ) {
					if ( rand ( ) >= 0.5 ) {
						$new_kirby = chr(3) . "13$new_kirby" . chr(3) . "0";
					}
				}

				my $random_eye = $eyes_proc [ rand ( @eyes_proc ) ];
				$new_kirby =~ s/\^/$random_eye/g;
				$kirbys .= $new_kirby;
				$kirbyanz--;
			}
		}
	}
	
	if ( $say == 0 ) {
		$kirbys .= reset_style ( ) . "< $text";
	}
	
	if ( $say == 1 ) {
		$kirbys = "$text > $kirbys";
	}
	
	return ( $kirbys );
}

sub help {
	my ( $self, $private, $channel, $irc ) = @_;
	return ( 
		"I make cool kirby dances. Just type 'kirby dance' or use like this: " .
		"!kirby --num <number> --say-(right|left|nothing) --text " .
		"<text> --no-[wavy|normal|extra] " . 
		"--no-eyes-[happy|serious|cool|starry|confused] " . 
		"--colour-(all|some|none)"
	);
}