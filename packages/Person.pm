#!/usr/bin/perl 

package Person;

sub new
{
    my $class = shift;
    my $self = {
        _name => shift,
        _follower => shift,
        _following => shift,
    };
    bless $self, $class;
    return $self;
}

sub setFollower {
    my ( $self, $followers ) = @_;
    $self->{_follower} = $followers if defined($followers);
}

sub setFollowing {
    my ( $self, @following ) = @_;
    $self->{_following} = $following if defined($following);
}

sub getName {
    my( $self ) = @_;
    return $self->{_name};
}

sub getFollower {
    my( $self ) = @_;
    return $self->{_follower};
}

sub getFollowing {
    my( $self ) = @_;
    return $self->{_following};
}
1;
