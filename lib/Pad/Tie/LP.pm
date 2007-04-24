use strict;
use warnings;

package Pad::Tie::LP;

use base 'Lexical::Persistence';

sub parse_variable {
  my ($self, $var) = @_;

  my ($sigil, $context, $member) = $self->SUPER::parse_variable($var);

  if ($context eq '_' and not exists $self->{context}{_}{$member}) {
    return; # don't auto-vivify _
  }

  return ($sigil, $context, $member);
}

1;
