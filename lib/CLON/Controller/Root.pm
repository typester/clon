package CLON::Controller::Root;
use strict;
use warnings;
use base 'Catalyst::Controller';
__PACKAGE__->config->{namespace} = '';

sub default :Private {
    my ($self, $c) = @_;
    $c->res->status(404);
    $c->stash->{template} = 'errors/404.tt';
}

sub index :Private {
    my ($self, $c) = @_;
}

sub end :ActionClass('RenderView') {
    my ($self, $c) = @_;
    $c->res->header( 'Cache-Control' => 'private' );
}

1;
