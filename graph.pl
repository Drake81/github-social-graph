#!/usr/bin/perl
#
# Gitub Social Graph

use strict;
use warnings;

use Config::Simple;
use File::Basename;

use LWP::Simple;
use JSON;

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


# Build the graph
my($graph) = GraphViz2 -> new(
                 edge   => {color => 'grey'},
                 global => {directed => 1},
                 graph  => {
                    label => 'Social graph',
                    rankdir => 'TB',
                    overlap => 'false',
                    ranksep => '1.5',
                    nodesep => '0.5',
                 },
                 node   => {shape => 'oval'},
);

# Generate nodes
while(my @person=each(%people))
{
    $graph -> add_node(name => $person[0], shape => 'box', color => 'blue');
}

while(my @person=each(%people))
{
    foreach my $follower (@{${$person[1]}{_follower}}) {
        $graph -> add_edge(from => $person[0], to => $follower, arrowsize => 1, color => 'green', dir => 'back');
    } 
    
    foreach my $following (@{${$person[1]}{_following}}) {
        $graph -> add_edge(from => $person[0], to => $following, arrowsize => 1, color => 'blue', dir => 'forward');
    } 
}

$graph->run(format => $output, output_file => "$username.$output");

#$graph -> add_node(name => 'Carnegie', shape => 'circle');
#$graph -> add_node(name => 'Oakleigh',    color => 'blue');
#
#$graph -> add_edge(from => 'Murrumbeena', to    => 'Carnegie', arrowsize => 2);
#$graph -> add_edge(from => 'Murrumbeena', to    => 'Oakleigh', color => 'brown');
#
#$graph -> push_subgraph(
#                        name  => 'cluster_1',
#                        graph => {label => 'Child'},
#                        node  => {color => 'magenta', shape => 'diamond'},
#);
#                                
#$graph -> add_node(name => 'Chadstone', shape => 'hexagon');
#$graph -> add_node(name => 'Waverley', color => 'orange');
#
#$graph -> add_edge(from => 'Chadstone', to => 'Waverley');
#
#$graph -> pop_subgraph;
#
#$graph -> default_node(color => 'cyan');
#
#$graph -> add_node(name => 'Malvern');
#$graph -> add_node(name => 'Prahran', shape => 'trapezium');
#
#$graph -> add_edge(from => 'Malvern', to => 'Prahran');
#$graph -> add_edge(from => 'Malvern', to => 'Murrumbeena');
#
#my($format)      = shift || "svg";
#my($output_file) = shift || "sub.graph.$format";
#





###### Subs

# traverse all persons on github
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

    # make me to the first person
    my $self = new Person( $name, \@followers, \@following);

    return $self;
}

