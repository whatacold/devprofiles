#!/usr/bin/env perl

# This script takes advantage of ctags's tags file, and add one debug statement
# upon the entry of every functions, so that we can view the program's
# execution flow more conveniently.

use strict;
use warnings;

sub add_log_to_function
{
    my $filename = shift;
    my $funcname = shift;
    my $funcpattern = shift;

    #print "original pattern: $funcpattern\n";
    # XXX take assumption that all pattern are '/^abc$/;"'
    # and strip off all except abc.
    $funcpattern =~ s@^/\^(.*)\$/;"$@$1@s; # 's' for . match newline

    # metacharacters
    # http://www.cs.tut.fi/~jkorpela/perl/regexp.html
    $funcpattern = quotemeta $funcpattern; # NOTE reaaaaally helpful
    #print "tuned pattern: $funcpattern\n";

    my $saved = $/;
    undef $/;
    open(FHTOPROC, "+<$filename") || die("Failed to open $filename");
    while(defined(my $wholefile = <FHTOPROC>)) {
        #print "file content---\n$wholefile";
        # multiline regex
        # http://docstore.mik.ua/orelly/perl/cookbook/ch06_07.htm
        #
        # various regex options
        # http://stein.cshl.org/genome_informatics/regex/regex4.html
        #
        # TODO make debug statement configurable, like via arg.
        $wholefile =~ s/(^$funcpattern\n\s*{)/$1\n    DEBUG("$funcname");\n/m;
        seek(FHTOPROC, 0, 0); #rewind
        #print "\n\n>>after file content---\n$wholefile";
        print FHTOPROC "$wholefile";
    }
    close FHTOPROC;
    $/ = $saved;
}

#add_log_to_function("select_fdsize.bak.c", "get_set_fd",
#"/^char *get_set_fd(int maxfd, const fd_set *fds)\$/;\"");
#exit;

unless(-f "tags") {
    print STDERR "tags file doesn't exist, use 'ctags -R' to generate.\n";
    exit 1;
}

open(FHTAGS, "tags") || die("Failed to open file 'tags'");
while(<FHTAGS>) {
    my $tagname;
    my $tagpattern;
    my $filename;
    my $extension; 
    my $tunedpattern;
    chomp;
    ($tagname, $filename, $tagpattern, $extension) = split(/\t/);

    unless(defined $extension && $extension eq "f") {
        next;
    }

    if(!defined $tagpattern) {
        next;
    }

    # FIXME use only one regex pattern to get it
    unless($filename =~ m/\.c$/) { # NOTE: must have curely brackets.
        unless($filename =~ m/\.cpp$/) { # NOTE: must have curely brackets.
            next; # perl's 'continue'
        }
    }
    #print "$tagname, $filename, $tagpattern, $extension\n";
    add_log_to_function($filename, $tagname, $tagpattern);
}
close FHTAGS;
