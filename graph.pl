#!/usr/bin/perl
#
# Gitub Social Graph

use strict;
use warnings;

use Config::Simple;
use File::Basename;

use LWP::Simple;
use JSON;
use Log::Handler;
use GraphViz2;

use lib "packages";
use Person;

# make a new config config object
my $currentpath = dirname(__FILE__);
my $cfg         = new Config::Simple("$currentpath/graph.config");

# some global variables
my $username = $cfg->param('username');
my $password = $cfg->param('password');
my $depth     = $cfg->param('depth');
my $output   = $cfg->param('output');

my $json = JSON->new->allow_nonref;

# All related persons to a account
my %people;

# Made user the first person
my $self = makePerson($username);
$people{$username} = $self; 

# aggregate others
followlinks($self,$depth);

my($logger) = Log::Handler -> new;

$logger -> add(
         screen =>
         {
                 maxlevel       => 'debug',
                 message_layout => '%m',
                 minlevel       => 'error',
         }
);


#logger => $logger,
# Build the graph
my($graph) = GraphViz2 -> new(
                 edge   => {color => 'grey'},
                 global => {directed => 1},
                 graph  => {
                    label => 'Social graph',
                    layout => 'circo',
                    splines => 'compound',
                    overlap => 'false',
                 },
                 node   => {shape => 'oval'},
);

print "Generate Graph\n";

# Generate nodes
while(my @person=each(%people))
{
    $graph -> add_node(name => $person[0], color => 'blue',shape => 'house');

    foreach my $repo (@{${$person[1]}{_repos}}) {
        $graph -> add_node(name => $repo, color => 'violet',shape => 'box');
    }

    foreach my $star (@{${$person[1]}{_starred}}) {
        $graph -> add_node(name => $star, color => 'red',shape => 'diamond');
    } 

}

while(my @person=each(%people))
{
    foreach my $follower (@{${$person[1]}{_follower}}) {
        $graph -> add_edge(from => $person[0], to => $follower, arrowsize => 1, color => 'green', dir => 'back');
    } 
    
    foreach my $following (@{${$person[1]}{_following}}) {
        $graph -> add_edge(from => $person[0], to => $following, arrowsize => 1, color => 'blue', dir => 'forward');
    } 
    
    foreach my $star (@{${$person[1]}{_starred}}) {
        $graph -> add_edge(from => $person[0], to => $star, arrowsize => 1, color => 'red', dir => 'forward');
    } 
    
    foreach my $repo (@{${$person[1]}{_repos}}) {
        $graph -> add_edge(from => $person[0], to => $repo, arrowsize => 1, color => 'violet', dir => 'forward');
    } 
}

print "Graph ready -> Output\n";

$graph->run(driver => 'sfdp', format => $output, output_file => "$username.$output");

print "Finish\n";

###### Subs

# traverse all persons on github related to the user
sub followlinks {
    my $actperson = shift;
    my $actdepth = shift;
    
    if($actdepth == 0){
        return;
    }
    $actdepth--;
    
    foreach my $person (@{$actperson->getFollower()}) {
    
        if(!(exists $people{$person})){
            print "Create a new entry for \"$person\"\n";
            
            my $self = makePerson($person);
            $people{$person} = $self;
            followlinks($self,$actdepth);
        }
    }

    foreach my $person (@{$actperson->getFollowing()}) {
    
        if(!(exists $people{$person})){
            print "Create a new entry for \"$person\"\n";
            
            my $self = makePerson($person);
            $people{$person} = $self;
            followlinks($self,$actdepth);
        }
    }

}

#init a new person
sub makePerson {
    my $name = shift;
   
    my @followers;
    my $rawdata = get("https://$username:$password\@api.github.com/users/$name/followers");
    my $json_followers = $json->decode($rawdata);

    # write Followers to array
    foreach my $follower (@$json_followers) {
        push (@followers, $follower->{"login"});
    }

    # Get Following
    $rawdata = get("https://$username:$password\@api.github.com/users/$name/following");
    my $json_following = $json->decode($rawdata);

    # write Followings to array
    my @following;
    foreach my $ifollow (@$json_following) {
        push (@following, $ifollow->{"login"});
    }

    # Get Starred
    $rawdata = get("https://$username:$password\@api.github.com/users/$name/starred");
    my $json_starred = $json->decode($rawdata);

    # write stars to array
    my @starred;
    foreach my $star (@$json_starred) {
        push (@starred, $star->{"full_name"});
    }

    # Get Repos
    $rawdata = get("https://$username:$password\@api.github.com/users/$name/repos");
    my $json_repos = $json->decode($rawdata);

    # write Repos to array
    my @repos;
    foreach my $repo (@$json_repos) {
        push (@repos, $repo->{"full_name"});
    }

    # make me to the first person
    my $self = new Person( $name, \@followers, \@following, \@starred, \@repos);

    return $self;
}

