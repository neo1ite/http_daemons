#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use LWP 5.23;
use HTTP::Daemon;
use Sys::Hostname;

use constant DEBUG          => 0;

use constant SERVER_ADDR    => 'localhost';
use constant SERVER_PORT    => 80;
use constant SERVER_TIMEOUT => 60;

use constant DOCUMENT_ROOT  => './www';

use constant CRLF           => "\015\012";

print "Starting server...\n" if DEBUG;
my $server = HTTP::Daemon->new(
   LocalAddr => SERVER_ADDR,
   LocalPort => SERVER_PORT,
   Timout    => SERVER_TIMEOUT
) or die "Can't create server: $!";

print "Server started successfully. Wating for connection...\n" if DEBUG;
while (my $client = $server->accept) {
   while (my $request = $client->get_request) {
      if ($request->method eq 'GET') {
         my $path = $request->url->path;
         my $server_name = $request->header('Host') || lc Sys::Hostname::hostname() || inet_ntoa($client->sockaddr);

         if (-d DOCUMENT_ROOT . $path && $path !~ /\/$/)
         {
            my $url = 'http://' . $server_name . $path . '/';
            print "Redirecting to $url\n" if DEBUG;
            $client->send_redirect($url);
         }

         $path = (-d DOCUMENT_ROOT . $path && -f DOCUMENT_ROOT . $path . 'index.html')
            ? DOCUMENT_ROOT . $path . 'index.html'
            : DOCUMENT_ROOT . $path;

         if (-d $path) {
            $client->send_error(403);
         } elsif (-f $path) {
            print "Sending file $path\n" if DEBUG;
            $client->send_file_response($path);
         } else {
            $client->send_error(404);
         }
      }
   }
   $client->close;
   undef($client);
}

exit(0);
