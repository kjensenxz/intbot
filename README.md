# intbot
IRC bot with sandboxed interpreters for Bash (4.2.24(3)) and Perl (5.24.0) with GNU coreutils. This is a fork of evalbot (http://www.vidarholen.net/contents/evalbot/).

### Invocation
    ./evalbot.pl & disown
    # bash:
    <irc_user> # ls /
    <intbot> irc_user: README  bin  dev  etc  lib  proc  root  tmp
    # perl:
    <irc_user> pl 'print "Hello world"'
    <intbot> irc_user: Hello world
    <irc_user> # perl -e 'print "Hello world"'
    <intbot> irc_user: Hello world
    
