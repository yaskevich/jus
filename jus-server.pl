#!/usr/bin/env perl
use strict;
use utf8;
use 5.010;
# use AnyEvent; # libanyevent-perl
use EV; # libev-perl
use Mojolicious::Lite;
use Mojo::Log;
# binmode STDOUT, ':encoding(UTF-8)';
use DBI;
use Data::Dumper;
# use Encode;
use Mojolicious::Plugin::Authentication;
use Mojolicious::Plugin::RemoteAddr;

use HTTP::BrowserDetect; # libtest-most-perl libhttp-browserdetect-perl 
 app->sessions->default_expiration(60*60);
use Time::HiRes qw/gettimeofday/;
use BSON qw/encode decode/;
 use Data::MessagePack;
  use MIME::Base64;

# Disable IPv6, epoll and kqueue
# BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }
plugin('RemoteAddr');
# app->config(hypnotoad => {
	# listen => ['http://*:'.$cfg->{port}],
	# proxy => 1,
	# workers => 1
	# });
app->secrets(['7b840960b54f7dd5b0c263f44ce273d36b1cd55cbf1b4375961123131f012e5055039']);

app->defaults(gzip => 0);


push @{app->static->paths}, '/d/parsers/rab';

# my $log = Mojo::Log->new(path => $cfg->{log});


app->attr(dbh => sub { # dbh attribute
	my $c = shift;
	my $dbh = DBI->connect("dbi:SQLite:jus.db","","", {sqlite_unicode => 1,  AutoCommit => 1, RaiseError => 1, sqlite_use_immediate_transaction => 1,});
	return $dbh;
});


helper db => sub { app->dbh };

hook before_dispatch => sub {
   my $c = shift;
   # notice: url must be fully-qualified or absolute, ending in '/' matters.
   # $c->req->url->base(Mojo::URL->new($cfg->{site}));
};  


any '/' => sub {                
    my $c = shift;
	# $c->req->param('u'), $c->req->param('p')
	$c->reply->static('index.html');
};


any '/data.json' => sub {
	
	my $c = shift;
	my $p = $c->req->params->to_hash;
	my $r = $p->{q};
	 # say Dumper ($r);
	my $dbh = $c->app->dbh;
	# my $ref;
	# if ($q =~ /\d/) {
		# # ($ref) = $dbh->selectrow_array("select graph_json from t21 where id = ".$q);
		# ($ref) = $dbh->selectrow_array('select * from t21 where place_name_be glob "Якубавіч*"');
	# }
	

	my $ref = $dbh->selectall_arrayref('select * from raw ORDER BY rowid', { Slice => {} });
	
	
	
    
	$c->render(json => $ref );
};

post '/test' => sub {
	
	my $c = shift;
	my $p = $c->req->params->to_hash;
    
	$c->render(json => $p );
};

app->start;