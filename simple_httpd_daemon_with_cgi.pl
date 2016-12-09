#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use LWP 5.23;
use HTTP::Daemon;
use File::Basename;
use Sys::Hostname;

use constant DEBUG          => 0;

use constant SERVER_ADDR    => 'localhost';
use constant SERVER_PORT    => 80;
use constant SERVER_TIMEOUT => 60;

use constant DOCUMENT_ROOT  => './www';
use constant SCRIPT_PATH    => './www/cgi-bin';

use constant USE_ERROR_LOG  => 1;
use constant ERROR_LOG_FILE => (fileparse($0, qr/\.[^.]*/))[0] . '.error.log';

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
            if ($path =~ /\.pl$/)
            {
               my $pipe_line = $^X . ' ' . $path . ' 2>' . (USE_ERROR_LOG ? ERROR_LOG_FILE : ($^O =~ /MSWin32/ ? 'NUL' : '/dev/null')) . '|';
               print "Opening pipe $pipe_line\n" if DEBUG;

               my $pipe;
               open($pipe, $pipe_line);
               my $header = <$pipe>;
               my $lines;
               {
                  local $/ = '';
                  $lines = <$pipe>;
               }
               close($pipe);

               $client->send_error(500) unless (length($header) <= 30);
               $client->send_basic_header();

               print $client $header;
               print $client 'Content-Length: ' . length($lines) . CRLF;
               print $client CRLF;
               print $client $lines;
            }
            else
            {
               print "Sending file $path\n" if DEBUG;
               $client->send_file_response($path);
            }
         } else {
            $client->send_error(404);
         }
      }
   }
   $client->close;
   undef($client);
}

exit(0);
