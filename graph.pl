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
my $deep     = $cfg->param('deep');
my $output   = $cfg->param('output');

my $json = JSON->new->allow_nonref;

# All related persons to account
my %people;


# Made user the first person
my $self = makePerson($username);
$people{$username} = $self; 

# aggregate others
followlinks($self,$deep);

# Output
while(my @array=each(%people))
{
 print "Wert: $array[0]    ";
 print "Schluessel: $array[1]\n";
}



#my($graph) = GraphViz2 -> new(
#                       edge   => {color => 'grey'},
#                       global => {directed => 1},
#                       graph  => {label => 'Adult', rankdir => 'TB'},
#                       logger => $logger,
#                       node   => {shape => 'oval'},
#);
#
#$graph -> add_node(name => 'Carnegie', shape => 'circle');
#$graph -> add_node(name => 'Murrumbeena', shape => 'box', color => 'green');
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
#$graph -> run(format => $format, output_file => $output_file);





###### Subs

# traverse all persons on github
sub followlinks {
    my $actperson = shift;
    my $actdeep = shift;
    
    if($actdeep == 0){
        return;
    }
    $actdeep--;
    
    foreach my $person (@{$actperson->getFollower()}) {
    
        if(!(exists $people{$person})){
            print "Create a new entry for \"$person\"\n";
            
            my $self = makePerson($person);
            $people{$person} = $self;
            followlinks($self,$actdeep);
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

