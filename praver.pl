use strict;
use warnings;
use utf8;
use WWW::Crawler::Mojo; # curl -L cpanmin.us | perl - -n WWW::Crawler::Mojo
use Data::Dumper;
use 5.10.0;
use Encode qw /from_to decode_utf8 encode/;
use DBI;
use autodie qw(:all); # apt-get install libipc-system-simple-perl
use Mojo::DOM;
binmode(STDOUT, ":utf8");

my $dbh = DBI->connect("dbi:SQLite:jus.db","","", {sqlite_unicode => 1,  AutoCommit => 0, RaiseError => 1}) or die "Could not connect";
my $sql  = "INSERT INTO raw (url_type, url, url_id, body, fetched, title)  VALUES (?, ?, ?, ?, ?, ?)";
my $sth = $dbh->prepare($sql);

my $url_type = 1; # http://www.pravo.by/main.aspx?guid=3961&p0=P31000001
my $template = 'http://www.pravo.by/main.aspx?guid=3961&p0=P';
# my $template = 'http://web.dev/';
my $start_id = 31000001;

# Статистика
# http://pravo.by/main.aspx?guid=4091
# first new routing doc
# http://pravo.by/main.aspx?guid=3961&p0=P31000001
# desc of struct
# http://pravo.by/main.aspx?guid=1641
# 2003
# http://pravo.by/main.aspx?guid=4061&p0=2003&p1=1
	
my $bot = WWW::Crawler::Mojo->new;
$bot->ua_name('Mozilla/5.0 (Windows; U; Windows NT 5.1; rv:1.7.3) Gecko/20041001 Firefox/0.10.1');
$bot->max_conn(5);
$bot->max_conn_per_host(5);

$bot->on(start => sub {
    shift->say_start;
});


# <div class="reestrmap">
# <b>Название акта</b>
# <div>О подписании международного договора и его временном применении</div>
# <b>Вид акта, орган принятия, дата и номер принятия (издания)</b>
# <div>Указ Президента Республики Беларусь от 11 января 2010 г. № 12 </div>
# <b>Регистрационный номер Национального реестра</b><div>1/11293</div>
# <b>Дата включения в Национальный реестр</b>
# <div>12.01.2010</div><b>Дата вступления в силу</b>
# <div>11.01.2010</div>
# <b>Источник(и) официального опубликования</b>
# <div>Национальный реестр правовых актов Республики Беларусь, <a href="main.aspx?guid=4061&amp;p0=2010&amp;p1=14"> от 19.01.2010 г., № 14</a>, 1/11293</div>



$bot->on(res => sub {
    my ($bot, $scrape, $job, $res) = @_;
    say sprintf('fetching %s resulted status %s', $job->url, $res->code);
	
	# say $res->headers->date;
	# say $res->body;
	
	my $cur_external_id = $job->{url}->{var};
	my $cur_incr = $job->{url}->{incr};
	
	my $body = decode_utf8($res->body); 
	my $dom = Mojo::DOM->new($body);
	
	# div class="reestrmap"><b>Название акта</b><div>Об утверждении плана подготовки законопроектов на 2010 год</div><b>
	my $upnode = $dom->at('div.reestrmap');
	my $node = $upnode->children('div');
	
	if ($node){
		if ($node->first){
			my $title = $node->first->text;
			# say $title;
			my $reestrmap = $upnode->to_string();
			$reestrmap  =~ s/\s+/ /g;
			# say $reestrmap;
			
			$sth->execute ($url_type, $job->url, $cur_external_id, $reestrmap, $res->headers->date, $title)  or die "Couldn't execute statement: " . $sth->errstr;
			$sth->finish();
		}
	}
	
	say $cur_external_id;
	
	++$cur_incr;
	++$cur_external_id;
	
	say $cur_incr;
	
	# $dbh->commit();
	
	unless ($cur_incr%100) {
		# say "commit";
		$dbh->commit();
	}
	
	if ($cur_incr == 1000){
		exit;
	}
	
	my $new_new_url = Mojo::URL->new($template.$cur_external_id);
	$new_new_url->{var} = $cur_external_id;
	$new_new_url->{incr} = $cur_incr;
	$bot->enqueue($new_new_url);
});

$bot->on(error => sub {
    my ($msg, $job) = @_;
    say $msg;
    say "Re-scheduled";
    $bot->requeue($job);
});

# my $new_job  = Mojo::URL->new('http://web.dev/');
my $new_job  = Mojo::URL->new($template.$start_id);
$new_job->{var} = $start_id;
$new_job->{incr} = 0;
$bot->enqueue($new_job);
$bot->crawl;

$dbh->commit();
$dbh->disconnect();
