#!/usr/bin/perl

use strict;
use warnings;
use Git::Repository;
use Cwd qw(abs_path);
use Git::Repository::Command;
use Cwd 'chdir';
use File::Find::Rule;
use File::Slurp;
use File::Grep qw( fgrep fmap fdo );
use LWP::Simple;
 
my $REPO_VER='4.3';
my $SCRIPT_PATH = abs_path();
my $REPO_DIR = "$SCRIPT_PATH/repositories/";
my @REPOSITORIES = ('xwiki-commons', 'xwiki-platform', 'xwiki-rendering', 'xwiki-enterprise', 'xwiki-manager');

# Creates a directory with the parameter name
sub create_dir {
    my $directory = shift;
    unless(mkdir $directory) {
		die "Unable to create $directory\n";
    }
}

# If $REPO_DIR (which holds the git repositories for the XWiki projects) is not created, create it
unless(-e $REPO_DIR) { 
    create_dir($REPO_DIR);
}

# Clones a git repo
sub clone_repo {
	my $repo_name = shift;
	Git::Repository->run( clone => "git://github.com/xwiki/$repo_name.git", "$REPO_DIR/$repo_name");
	chdir "$REPO_DIR/$repo_name";
	Git::Repository->run( checkout => "$repo_name-$REPO_VER", { quiet => 1 } );
}

# Clone all defined repositories
foreach my $repo (@REPOSITORIES) {
	unless (-d "$REPO_DIR/$repo") {
		clone_repo($repo);
	} else {
		# Change dir and do a checkout with that tag (assume the sources are there)
		# TODO: make sure you update first the repo
		chdir "$REPO_DIR/$repo";
		Git::Repository->run( checkout => "$repo-$REPO_VER", { quiet => 1 } );	
	}
}

# Returns all files with a *.java extension
sub get_all_java_files {
	my @files = File::Find::Rule->file()
                              ->name( '*.java' )
                              ->in( $REPO_DIR );	
        return @files;
}

# Allows you to enter a pattern and searches all java files for that pattern. Return an array containing the found files
sub search_pattern_in_file {
	my $pattern = shift;
	my @found_files;
	for my $file (get_all_java_files()) {
		if (fgrep {/$pattern/} $file) 
		{
			push (@found_files, $file);
		}
	}
	return @found_files;
}

# lists the available bindings
sub  list_bindings {
	my @bindings_found_files = search_pattern_in_file("implements.*ScriptContextInitializer");
	for my $file (@bindings_found_files) {
		open(R_FILE,"<$file") or die $!;
		while (my $line = <R_FILE>) {
			if ($line =~ /setAttribute/) {
				if ($line =~ /"(.+?)"/) {				
					print '$' . "$1 $file\n";
				}
			}
		}
		close R_FILE;
	}		 
}

# lists all the available velocity tools
sub list_velocity_tools {
	 my @velocity_tools_found_files = search_pattern_in_file("implements.*VelocityConfiguration");
	 for my $file (@velocity_tools_found_files) {
		open(R_FILE,"<$file") or die $!;
		while (my $line = <R_FILE>) {
			if ($line =~ /defaultTools.setProperty/) {
				if ($line =~ /"(.+?)"/) {				
					print '$' . "$1 $file\n";
				}
			}
		}
		close R_FILE;
	 }
}

# lists all available plugins
sub list_plugins {
	 my @plugins_found_files = search_pattern_in_file("implements.*VelocityContextInitializer");
	 	for my $file (@plugins_found_files) {
		open(R_FILE,"<$file") or die $!;
		while (my $line = <R_FILE>) {
			if ($line =~ /public static final String VELOCITY_CONTEXT_KEY/) {
				if ($line =~ /"(.+?)"/) {				
					print '$' . "$1 $file\n";
				}
			}
		}
		close R_FILE;
	 }
}

# lists all available services
sub list_services {
	 my @plugins_found_files = search_pattern_in_file("implements.*ScriptService");
	 	for my $file (@plugins_found_files) {
		open(R_FILE,"<$file") or die $!;
		while (my $line = <R_FILE>) {
			if ($line =~ /\@Named/) {
				if ($line =~ /"(.+?)"/) {				
					print '$' . "$1 $file\n";
				}
			}
		}
		close R_FILE;
	 }
}

list_bindings();
list_velocity_tools();
list_plugins();
list_services();