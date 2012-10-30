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
 
my $REPO_VER='4.2';
my $SCRIPT_PATH = abs_path();
my $REPO_DIR = "$SCRIPT_PATH/repositories/";
my @REPOSITORIES = ('xwiki-commons', 'xwiki-platform', 'xwiki-rendering');

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

my @bindings = search_pattern_in_file("implements.*ScriptContextInitializer");
for my $file (@bindings) {
	print "$file\n";
}
