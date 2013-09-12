package HTTP::Headers::ActionPack;
use v5.16;
use warnings;
use mop;

use Scalar::Util qw[ blessed ];

use HTTP::Headers::ActionPack::MediaType;

class MediaTypeList extends HTTP::Headers::ActionPack::PriorityList {

    method new (@items) {
        # FIXME: this is wrong
        $self = $class->next::method;
        foreach my $item ( @items ) {
            $self->add( ref $item eq 'ARRAY' ? @$item : $item )
        }
        $self
    }

    method add {
        my ($q, $mt) = scalar @_ == 1 ? ((exists $_[0]->params->{'q'} ?$_[0]->params->{'q'} : 1.0), $_[0]) : @_;
        $self->next::method( $q, $mt );
    }

    method add_header_value {
        my $mt   = HTTP::Headers::ActionPack::MediaType->new( @{ $_[0] } );
        my $q    = $mt->params->{'q'} || 1.0;
        $self->add( $q, $mt );
    }

    method as_string is overload('""') {
        join ', ' => map { $_->[1]->as_string } $self->iterable;
    }

    method iterable {
        # From RFC-2616 sec14
        # Media ranges can be overridden by more specific
        # media ranges or specific media types. If more
        # than one media range applies to a given type,
        # the most specific reference has precedence.
        sort {
            if ( $a->[0] == $b->[0] ) {
                $a->[1]->matches_all
                    ? 1
                    : ($b->[1]->matches_all
                        ? -1
                        : ($a->[1]->minor eq '*'
                            ? 1
                            : ($b->[1]->minor eq '*'
                                ? -1
                                : ($a->[1]->params_are_empty
                                    ? 1
                                    : ($b->[1]->params_are_empty
                                        ? -1
                                        : 0)))))
            }
            else {
                $b->[0] <=> $a->[0]
            }
        } map {
            my $q = $_;
            map { [ $q+0, $_ ] } reverse @{ $self->items->{ $q } }
        } keys %{ $self->items };
    }

    method canonicalize_choice ($choice) {
        return blessed $choice
            ? $choice
            : HTTP::Headers::ActionPack::MediaType->new( $choice );
    }

}

1;

__END__

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::MediaTypeList;

  # normal constructor
  my $list = HTTP::Headers::ActionPack::MediaTypeList->new(
      HTTP::Headers::ActionPack::MediaType->new('audio/*', q => 0.2 ),
      HTTP::Headers::ActionPack::MediaType->new('audio/basic', q => 1.0 )
  );

  # you can also specify the 'q'
  # rating independent of the
  # media type definition
  my $list = HTTP::Headers::ActionPack::MediaTypeList->new(
      [ 0.2 => HTTP::Headers::ActionPack::MediaType->new('audio/*', q => 0.2 )     ],
      [ 1.0 => HTTP::Headers::ActionPack::MediaType->new('audio/basic' ) ]
  );

  # or from a string
  my $list = HTTP::Headers::ActionPack::MediaTypeList->new_from_string(
      'audio/*; q=0.2, audio/basic'
  );

=head1 DESCRIPTION

This is a subclass of the L<HTTP::Headers::ActionPack::PriorityList>
class with some specific media-type features. It is the default object
used to parse most of the C<Accept> header since they will often contain
more then one media type.

=head1 METHODS

=over 4

=item C<iterable>

This returns the same data type as the parent (two element
ARRAY ref with quality and choice), but the choice element
will be a L<HTTP::Headers::ActionPack::MediaType> object. This is
also sorted in a very specific manner in order to align with
RFC-2616 Sec14.

  Media ranges can be overridden by more specific
  media ranges or specific media types. If more
  than one media range applies to a given type,
  the most specific reference has precedence.

=item C<canonicalize_choice>

If this is passed a string, it returns a new
L<HTTP::Headers::ActionPack::MediaType> object from that string. If it
receives an object it simply returns that object as is.

=back

=cut
