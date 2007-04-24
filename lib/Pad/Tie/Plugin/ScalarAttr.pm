use strict;
use warnings;

package Pad::Tie::Plugin::ScalarAttr;

use Devel::LexAlias ();
use base 'Pad::Tie::Plugin';

sub provides { 'scalar_attr' }

sub scalar_attr {
  my ($plugin, $ctx, $self, $args) = @_;

  $args = $plugin->canon_args($args);

  my $rv = { pre_call => [] };
  for my $method (keys %$args) {
    my $name = $args->{$method};
    push @{ $rv->{pre_call} }, sub {
      my ($self, $code, $args) = @_;
      Devel::LexAlias::lexalias(
        $code,
        '$' . $name,
        \$self->{invocant}->{$method},
      );
    };
  }

  return $rv;
}

1;
