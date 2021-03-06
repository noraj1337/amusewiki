package AmuseWikiFarm::Controller::Custom;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Custom - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

use AmuseWikiFarm::Log::Contextual;
use File::Spec;

sub root :Chained('/site') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub custom :Chained('root') :PathPart('custom') :Args(1) {
    my ($self, $c, $file) = @_;
    log_debug { "Requested $file" };

    if (my $site = $c->stash->{site}) {
        my $site_id = $site->id;
        if (my $serve = $c->model('DB::JobFile')->find($file)) {
            log_debug { "Found $file in the db" };
            my $job = $serve->job;
            if ($job->site_id eq $site_id) {
                if (my $jobuser = $job->username) {
                    # this is a private job
                    if ($c->user_exists) {
                        my $username = $c->user->get('username');
                        if ($username eq $jobuser or
                            $c->check_any_user_role(qw/admin root/)) {
                            log_info { "$username is accessing its own job (or is admin) for $file" };
                            $c->stash(serve_static_file => $serve->path);
                            $c->detach($c->view('StaticFile'));
                            return;
                        }
                    }
                }
                else {
                    log_debug { "$file ok, belongs to $site_id and to no user in particular" };
                    $c->stash(serve_static_file => $serve->path);
                    $c->detach($c->view('StaticFile'));
                    return;
                }
            }
        }
    }
    $c->detach('/not_found');
}


=encoding utf8

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
