#!perl

use strict;
use warnings;

use Test::More 'no_plan';
use Pad::Tie;

package PT;
use Test::More;

sub scalar_foo {
  $_[0]->{foo} = $_[1] if @_ > 1;
  $_[0]->{foo};
}

sub bar {
  return $_[0]->{bar} ||= [];
}

sub bar_list {
  my $self = shift;
  push @{ $self->bar }, @_ if @_;
  return @{ $self->bar };
}

sub hash {
  $_[0]->{hash} ||= {};
}

{
  my ($self, $foo, @bar, @list, %hash, $color);

  sub test_self {
    isa_ok $self, 'PT';
    $self->scalar_foo("pony");
    push @{ $self->bar }, 1, 5, 17;
    $self->hash->{one} = 1;
    $self->hash->{two} = 2;
    $self->{color} = 'red';
  }

  sub test_scalar {
    is $foo, 'pony', "scalar content";
    is $self->scalar_foo, 'pony', 'self->content';
    $foo = 13;
    is $self->scalar_foo, 13, 'self->content after write';
  }

  sub test_scalar_attr {
    is $color, 'red', 'scalar attr content';
    is $self->{color}, 'red', 'self->content';
    $color = 'blue';
    is $self->{color}, 'blue', 'self->content after write';
  }
  
  sub test_array_ref {
    is_deeply \@bar, [ 1, 5, 17 ], "array_ref content";
    unshift @bar, 23;
    is_deeply $self->bar, [ 23, 1, 5, 17 ], "self->content after write";
    is \@bar, $self->bar, "array_ref and method share ref";
    @bar = qw(cheez doodle);
    is_deeply $self->bar, [ qw(cheez doodle) ], "self->content after write";
    shift @{ $self->bar };
    is_deeply \@bar, [ qw(doodle) ], "array_ref content after write";
  }

  sub test_list {
    @{$self->bar} = qw(your face);
    is_deeply [ @list ], [ qw(your face) ], "content from list";
    is_deeply [ $self->bar_list ], [ qw(your face) ], "self->content";
    # XXX test unsupported behavior: push, shift, etc.
    is @list, 2, "list size unchanged by read";
    eval { $list[1] = 17 };
    like $@, qr/do not assign/, "error on single STORE";
    @list = qw(my face);
    is $list[2], 'my', "list content after write" ;
    is_deeply [ $self->bar_list ], [qw(your face my face)],
      "self->content after write";
  }

  sub test_hash_ref {
    is_deeply \%hash, { one => 1, two => 2 };
    is \%hash, $self->hash;
    $self->hash->{three} = 3;
    is $hash{three}, 3;
    delete $hash{one};
    ok ! exists $self->{hash}->{one};
  }
}

package main;

my $obj = bless {} => 'PT';
my $pad_tie = Pad::Tie->new(
  $obj,
  [
    scalar => [
      scalar_foo => { -as => 'foo' }
    ],
    scalar_attr => [
      'color',
    ],
    array_ref => [ 'bar' ],
    hash_ref  => [ 'hash' ],
    list      => [ bar_list => { -as => 'list' } ],
    'self',
  ],
);

isa_ok $pad_tie, 'Pad::Tie';

$pad_tie->call(\&PT::test_self);

$pad_tie->call(\&PT::test_scalar);

$pad_tie->call(\&PT::test_scalar_attr);

$pad_tie->call(\&PT::test_array_ref);

$pad_tie->call(\&PT::test_list);
  
$pad_tie->call(\&PT::test_hash_ref);

