#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use utf8;

print "Content-type: text/plain\n\n";

$Data::Dumper::Sortkeys = 1;

print Data::Dumper::Dumper \%ENV;

exit(0);
