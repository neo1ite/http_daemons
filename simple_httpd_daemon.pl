#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use LWP 5.23;
use HTTP::Daemon;
use Sys::Hostname;

use constant DOCUMENT_ROOT => './www';
use constant SCRIPT_PATH   => './www/cgi-bin';
use constant CRLF          => "\015\012";

print "Starting server...\n";
my $server = HTTP::Daemon->new(LocalAddr => 'localhost', Timout => 60, LocalPort => 80);

print "Server started successfully. Wating for connection...\n";
while (my $client = $server->accept) {
   while (my $request = $client->get_request) {
      if ($request->method eq 'GET') {
         my $path = $request->url->path;
         my $server_name = $request->header('Host') || lc Sys::Hostname::hostname() || inet_ntoa($client->sockaddr);

         if (-d DOCUMENT_ROOT . $path && $path !~ /\/$/)
         {
            my $url = 'http://' . $server_name . $path . '/';
            #print "Redirecting to $url\n";
            $client->send_redirect($url)
         }

         $path = (-d DOCUMENT_ROOT . $path && -f DOCUMENT_ROOT . $path . 'index.html')
            ? DOCUMENT_ROOT . $path . 'index.html'
            : DOCUMENT_ROOT . $path;

         if (-d $path) { $client->send_error(403); }
         if (-f $path) {
            #print "Sending file $path\n";
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
