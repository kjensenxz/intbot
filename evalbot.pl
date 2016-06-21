#!/usr/bin/perl
use utf8;
use warnings;

use Net::IRC;

my $usage;
$usage="
Run evalbot: ./evalbot.pl configfile

Where configfile is an evalbot config file (see config.sample)
";

if(!$ARGV[0]) { die "$usage"; }
do "$ARGV[0]" or die "Error when doing config file";


if(!$nick)	{ die "nick unspecified"; }
if(!$password)	{ die "password unspecified"; }
if(!$server)	{ die "irc server unspecified"; }
if(!$owner)	{ die "owner unspecified"; }
if($#channels == -1) { print "No channels specified. Continuing anyways\n"; }

$SIG{'INT'} = 'my_sigint_catcher';
$SIG{'TERM'} = 'my_sigint_catcher';
$SIG{'QUIT'} = 'my_sigint_catcher';
$SIG{'ALRM'} = 'my_alarm';
sub my_sigint_catcher {
	exit(1); 
}


# Set up the connection to the IRC server.
my $irc = new Net::IRC;
my $conn = $irc->newconn( Server => "$server",
	Nick => "$nick",
	Ircname => "intbot, owned by $owner" );


my $joined=0;

sub my_alarm {
	if($joined==0) {
		if($nickserv) {
			$conn->sl("nickserv identify $nickserv");
		}
		foreach (@channels) {   
			$conn->join( "$_" );
		}
		$joined=1;
	}

	$conn->privmsg("$nick", "ping");
	alarm(60);
}

alarm(10);



# Connect the handlers to the events.
$conn->add_handler( 376, \&join_channel );
$conn->add_handler( 422, \&join_channel );
$conn->add_handler( 'public', \&message );
$conn->add_handler( 'msg', \&private );


# Start the Net::IRC event loop.
$irc->start;

sub join_channel
{
	my( $conn, $event ) = @_;
	print( "Connected!\n" );
}

sub message
{
	my( $conn, $event ) = @_;
	my( $msg ) = $event->args;

	if( $msg =~/^(sh[>]{0,}|#) (.*)/ ) {
		open(FOO, "-|", "./evalcmd", "$2");
		while(<FOO>) { 
			$conn->privmsg($event->to, $event->nick . ": $_");
		}
		close(FOO);
	}
	elsif( $msg =~ /^pl[>]{0,} (.*)/ ) {
		$x = $1;
		$x =~ s/\"/\\\"/g;
		open(FOO, "-|", "./evalcmd", qq{perl -e "$x"});
		while(<FOO>) {
			$conn->privmsg($event->to, $event->nick . ": $_");
		}
	}
	elsif ( $msg =~ /^[!\.]bots\s*/ ){
		$conn->privmsg($event->to, "[perl/bash] intbot: Bash (4.2.24) and Perl (5.24.0) interpreter");
		$conn->privmsg($event->to, "https://github.com/kjensenxz/intbot");
	}
	elsif ( $msg =~ /^[!\.]source\s*/ ){
		$conn->privmsg($event->to, "https://github.com/kjensenxz/intbot");
	}
	elsif ( $msg =~ /^[!\.]help\s*/ ){
		$conn->privmsg($event->to, "Type a command starting with sh> for bash, pl> for perl");
	}
}

sub private 
{
	my( $conn, $event ) = @_;
	my( $msg ) = $event->args;  

	if($event->nick =~ /^$nick$/) { return; } #don't let the bot talk to itself
	if($event->nick ne $owner) {
		$conn->privmsg( "$owner", "< " . $event->nick . "> $msg" );
	}
	if( $msg =~ /^[!\.]*help\s*/ ) {
		$conn->privmsg( $event->nick, "Usage: sh> cmd OR pl> perlexpression" );
	} 
	elsif ( $msg =~ /^[!\.]*source\s*/ ){
		$conn->privmsg($event->nick, "https://github.com/kjensenxz/intbot");
	}
	elsif($msg =~ /^!raw $password (.*)/) {
		$conn->sl($1);
	} 
	elsif( $msg =~/^(sh[>]{0,}|#) (.*)/ ) {
		open(FOO, "-|", "./evalcmd", "$2");
		while(<FOO>) { 
			$conn->privmsg($event->nick, "$_");
		}
		close(FOO);
	}
	elsif( $msg =~ /^pl[>]{0,} (.*)/ ) {
		$x = $1;
		$x =~ s/\"/\\\"/g;
		open(FOO, "-|", "./evalcmd", qq{perl -e "$x"});
		while(<FOO>) {
			$conn->privmsg($event->nick, "$_");
		}
	}
}
