#!/usr/bin/env perl

#   Reddit Imgur Scraper
#   Copyright (c) J-F B, 2013
#   This program is heavily based on Reddit Image Scrapper by Joshua Copyright (C) 2011 published under the same license.
#   
#   This program is free software: you can redistribute it and/or modify 
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use JSON;
use WWW::Mechanize;
use YAML::Tiny;

#Load the configuration file.
my $config = YAML::Tiny->read('config.yml');
#Set the path where to save the images.
my $savePath = $config ->[0]->{savePath};
#Verify is we can use the specified directory from the configuration path.
if (!-d $savePath && !-w $savePath){
		die "Cannot use specified directory" . $savePath . ".\n Either doesn't exist or unwritable.'\n";
}
print "Saving to :  $savePath\n";
# #Loop over the subreddits array and save the images.
foreach my $sub (@{$config->[0]->{subreddits}}) {
	# Create the subreddit directory only if necessary.
    mkdir $savePath."/".$sub unless -d $savePath."/".$sub;
    my $url = "http://www.reddit.com/r/$sub/.json?limit=200";
    print "Downloading from http://www.reddit.com/r/$sub\n";
    my $mech = WWW::Mechanize->new;
    $mech->get($url);
    my $json_string = $mech->text();
    my $json = JSON->new;
    my $json_text = $json->allow_nonref->utf8->relaxed->decode($json_string);
    my $posts = $json_text->{data}->{children}; 
    foreach my $post (@{$posts}) {
        my $domain = $post->{data}->{domain};
        my $url = $post->{data}->{url};
		my $title = $post->{data}->{title};
		my $score = $post->{data}->{score};
		#Verify if the post has a high enough score to be worth saving.
		if ($config->[0]->{score} < $score) {
		    print "saving : $title \n";
		    if ( $domain =~ m/i.imgur.com/){
		        $url =~ /(gif|png|jpeg.|jpg)$/i;
		        my $file_ext = '.'.$1;
				my $realfile_name = substr $title, 0, 200;
				print $url.'\n';
				$realfile_name =~ s/[^a-zA-Z0-9]/-/g;
				if (!-f "$sub/$realfile_name$file_ext"){
						$mech->get($url,':content_file' => "$savePath/$sub/$realfile_name"."$file_ext");
				}
			}
		}
    }
 }
