package AmuseWikiFarm::Controller::Listing;
use Moose;
with qw/AmuseWikiFarm::Role::Controller::Listing/;

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Listing - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub root :Chained('/site') :PathPart('') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
    # compare with Controller::Category::single_category
}

sub select_texts :Chained('root') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $text_rs = $c->stash->{site}->titles->texts_only;
    $c->stash(texts => $text_rs);
}

sub listing :Chained('filter_texts') :PathPart('listing') :Args(0) {
    my ($self, $c) = @_;
    $self->_stash_pager($c, '/listing/listing');
    $c->stash(
              page_title => $c->loc('Full list of texts'),
              nav => 'titles',
             );
}


=encoding utf8

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
