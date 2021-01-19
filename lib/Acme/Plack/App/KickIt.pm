package Acme::Plack::App::KickIt;
use strict;
use warnings;
use Carp qw/croak/;
use parent qw/Plack::Component/;
use Plack::Request;
use Plack::Util::Accessor qw/
    repos_dir
    secret
/;
use JSON qw/decode_json/;

our $VERSION = '0.01';

sub prepare_app {
    my $self = shift;

    if (!defined $self->repos_dir) {
        croak 'required `repos_dir`.';
    }

    $self->repos_dir($self->_normalize_repos_dir($self->repos_dir));

    $self->secret(defined $self->secret ? $self->secret : '');

    return $self;
}

sub _normalize_repos_dir {
    my ($self, $repos_dir) = @_;

    $repos_dir =~ s/^~/$ENV{HOME}/;

    if (!-e $repos_dir) {
        croak sprintf('repos_dir:%s does not exists.', $repos_dir);
    }

    return $repos_dir;
}

sub call {
    my ($self, $env) = @_;

    my $req  = Plack::Request->new($env);

    if ($req->method eq 'POST') {
        return $self->_kick_it($req);
    }

    return $self->_call_content($req);
}

sub _call_content {
    my ($self, $req) = @_;

    if (($req->parameters->{secret} || '') ne $self->secret) {
        croak 'Forbidden.';
    }

    my $secret = $req->parameters->{secret} || '';

    my $content = <<_HTML_;
<html>
<head></head>
<body>
<div id="result"></div>
<script>
let data = new Object();
data.path = document.location.pathname;
data.line = document.location.hash.match(/^#L(\\d+)/);
data.line = data.line[1];
data.secret = '$secret';
let request = new XMLHttpRequest();
request.open('POST', '/');
request.onload = function() {
  window.close();
};
request.send(JSON.stringify(data));
</script>
</body>
</html>
_HTML_

    return [200, ['Content-Type' => 'text/html'], [$content]];
}

sub _kick_it {
    my ($self, $req) = @_;

    my $params = decode_json($req->content);

    if (($params->{secret} || '') ne $self->secret) {
        croak 'Forbidden.';
    }

    my $command = $self->_build_command($params);

    system $command;
    warn "$command\n";

    return [200, [], ["Kicked '$command'"]];
}

sub _build_command {
    my ($self, $params) = @_;

    my $repos_dir = $params->{repos_dir} ? $self->_normalize_repos_dir($params->{repos_dir}) : $self->repos_dir;

    my $local_lib_path = $repos_dir . '/' . $self->_get_local_lib_path($params->{path});

    if (!-f $local_lib_path) {
        croak sprintf('File:%s Not Found', $local_lib_path);
    }

    my $line = $params->{line} || 1;

    my $command = 'code -g ' . $local_lib_path . ':' . $line;

    return $command;
}

sub _get_local_lib_path {
    my ($self, $path) = @_;

    my (undef, $account_name, $repos_name, $blob, $branch, @paths) = split '/', $path;

    return join '/', ($repos_name, @paths);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Acme::Plack::App::KickIt - Kick your ed


=head1 SYNOPSIS

    plackup -MAcme::Plack::App::KickIt -e 'Acme::Plack::App::KickIt->new(repos_dir=>"~/repos_dir")->to_app'


=head1 DESCRIPTION

Acme::Plack::App::KickIt is


=head1 REPOSITORY

=begin html

<a href="https://github.com/bayashi/Acme-Plack-App-KickIt/blob/master/README.pod"><img src="https://img.shields.io/badge/Version-0.01-green?style=flat"></a> <a href="https://github.com/bayashi/Acme-Plack-App-KickIt/blob/master/LICENSE"><img src="https://img.shields.io/badge/LICENSE-Artistic%202.0-GREEN.png"></a> <a href="https://github.com/bayashi/Acme-Plack-App-KickIt/actions"><img src="https://github.com/bayashi/Acme-Plack-App-KickIt/workflows/master/badge.svg"/></a> <a href="https://coveralls.io/r/bayashi/Acme-Plack-App-KickIt"><img src="https://coveralls.io/repos/bayashi/Acme-Plack-App-KickIt/badge.png?branch=master"/></a>

=end html

Acme::Plack::App::KickIt is hosted on github: L<http://github.com/bayashi/Acme-Plack-App-KickIt>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Other::Module>


=head1 LICENSE

C<Acme::Plack::App::KickIt> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
