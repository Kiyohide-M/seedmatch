#!/usr/bin/perl

# 2009-06-18.y-naito

use warnings ;
use strict ;
use Socket ;

my %query = get_query_parameters() ;  # CGIが受け取ったデータの処理
my $seedseq = flatsequence($query{'seedseq'}) or redirect_to_top() ;
print_result_html(seedmatch($seedseq)) ;

exit ;

# ====================
sub get_query_parameters {  # CGIが受け取ったデータの処理
my $buffer = '' ;
if (defined $ENV{'REQUEST_METHOD'} and $ENV{'REQUEST_METHOD'} eq 'POST' and defined $ENV{'CONTENT_LENGTH'}){
	read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'}) ;
} elsif (defined $ENV{'QUERY_STRING'}){
	$buffer = $ENV{'QUERY_STRING'} ;
}
my %query ;
my @query = split /&/, $buffer ;
foreach (@query){
	my ($name,$value) = split /=/ ;
	if (defined $name and defined $value){
		$value =~ tr/+/ / ;
		$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/eg ;
		$name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/eg ;
		$query{$name} = $value ;
	}
}
return %query ;
} ;
# ====================
sub flatsequence {  # 塩基配列の整形
if (defined $_[0]){
	my $seq = $_[0] ;
	$seq =~ s/[^ATGCUNRYMKSWHBVD-]//gi ;
	return $seq ;
} else {
	return '' ;
}
} ;
# ====================
sub seedmatch {
my $seedseq = $_[0] ;
my $seedmatch_result ;
my $host = 'localhost' ;
my $port = 5959 ;

# ホスト名を、IPアドレスの構造体に変換
my $iaddr = inet_aton($host)
	|| return ;

# port と IP アドレスをまとめて構造体に変換
my $sock_addr = pack_sockaddr_in($port, $iaddr);

# ソケット生成
socket(SOCKET, PF_INET, SOCK_STREAM, 0)
	|| return ;

connect(SOCKET, $sock_addr)
	|| return ;

# ファイルハンドルSOCKETをバッファリングしない
select(SOCKET) ; $|=1 ; select(STDOUT) ;

# サーバにqueryを送る
print SOCKET "$seedseq\n";

while (<SOCKET>){
	$seedmatch_result .= $_ ;
}

chomp $seedmatch_result ;
return $seedmatch_result ;
} ;
# ====================
sub print_result_html {
my $text = $_[0] || '' ;
print 'Content-type: text/html; charset=utf-8

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html lang=ja>

<head>
<meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
<meta http-equiv="Content-Style-Type" content="text/css">
<meta name="author" content="Yuki Naito">
<title>seedmatch</title>
<style type="text/css">
<!--
/* font */
	p,table,div,h1,h2,h3 {
		font-family:verdana,arial,helvetica,sans-serif;
	}
	p,table,div {
		font-size:9pt;
	}
/* hyperlink */
	a:link,a:visited {
		text-decoration:none;
		color:#004080;
	}
	a:hover {
		text-decoration:none;
		color:red;
	}
-->
</style>
</head>

<body>

<div style="border-top:15px solid black; padding-top:10px"><font size=5>seedmatch </font>result</div>

<hr><!-- __________________________________________________ -->

<p>結果をExcelに直接コピペできます。<br>
<textarea rows=15 cols=80>
' . $text . '
</textarea></p>

<p><a href="./">［もどる］</a></p>

</body>
</html>
' ;
exit ;
} ;
# ====================
sub redirect_to_top {
print "Location: .\n\n" ;
exit ;
} ;
# ====================
