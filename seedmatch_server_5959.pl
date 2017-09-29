#!/usr/bin/perl

use warnings ;
use strict ;
use Socket ;

my $port   = 5959 ;
my $refseq = '/genome/RefSeq_Release60/Hs.refseq60.gbff' ;

# ソケット生成
socket(CLIENT_WAITING, PF_INET, SOCK_STREAM, 0)
	or die "ソケットを生成できません。$!" ;

# ソケットオプション設定
setsockopt(CLIENT_WAITING, SOL_SOCKET, SO_REUSEADDR, 1)
	or die "setsockopt に失敗しました。$!" ;

# ソケットにアドレス（＝名前）を割り付ける
bind(CLIENT_WAITING, pack_sockaddr_in($port, INADDR_ANY))
	or die "bind に失敗しました。$!" ;

# ポートを見張る
listen(CLIENT_WAITING, SOMAXCONN)
	or die "listen: $!" ;

print "[" . timestamp() . "] [SeedcheckServer] Starting SeedcheckServer on port $port\n" ;

my @db = read_gbff($refseq) ;

print "[" . timestamp() . "] [SeedcheckServer] SeedcheckServer ready.\n" ;

# while(1)することで、1つの接続が終っても次の接続に備える
while (1){
	my $paddr = accept(CLIENT, CLIENT_WAITING) ;

	# ホスト名、IPアドレス、クライアントのポート番号を取得
	my ($client_port, $client_iaddr) = unpack_sockaddr_in($paddr) ;
	my $client_hostname = gethostbyaddr($client_iaddr, AF_INET) ;
	my $client_ip = inet_ntoa($client_iaddr) ;

	print "[" . timestamp() . "] [SeedcheckServer] Connect: $client_ip ($client_hostname) port $client_port\n" ;

	# クライアントに対してバッファリングしない
	select(CLIENT) ; $|=1 ; select(STDOUT) ;

	my $input = <CLIENT> ;  # 1行読み込む
	chomp $input ;

	print "[" . timestamp() . "] [SeedcheckServer] Input: $input\n" ;

	my $result = seedmatch($input) ;
	print CLIENT "$result\n" ;
	close CLIENT ;

	print "[" . timestamp() . "] [SeedcheckServer] Connection closed: $client_ip ($client_hostname) port $client_port\n" ;
}

exit ;

# ====================
sub timestamp {  # タイムスタンプを 2000-01-01 00:00:00 の形式で出力
my ($sec, $min, $hour, $mday, $mon, $year) = localtime ;
return sprintf("%04d-%02d-%02d %02d:%02d:%02d",
	$year+1900, $mon+1, $mday, $hour, $min, $sec) ;
} ;
# ====================
sub read_gbff {
my $gbff = $_[0] or return () ;

if ($gbff =~ /\.gz$/i){
	open FILE, "/usr/bin/gzip -dc $gbff |" ;
} else {
	open FILE, $gbff ;
}

$/ = "\n//\n" ;
my @db ;
while (<FILE>){
	my $version = (/^VERSION\s+(\S+)/m) ? $1 : '' ;
	my $cds = (/^     CDS\s+(.*)$/m) ? $1 : '' ;
	my ($cds_start, $cds_end) = ($cds and $cds =~ /^(\d+)\.\.(\d+)$/)           ? ($1, $2) :
	                            ($cds and $cds =~ /^join\((\d+)\..*\.(\d+)\)$/) ? ($1, $2) :
	                                                                              ('', '') ;
	my $seq = (/^ORIGIN(.*)/sm) ? flatsequence($1) : '' ;
	my $seqlength = length $seq ;
	my ($cdsseq, $utr5seq, $utr3seq) = ($cds_start and $cds_end) ?
		(subseq($cds_start, $cds_end, $seq), subseq(1, $cds_start - 1, $seq), subseq($cds_end + 1, $seqlength, $seq)) :
		('', '', '') ;
	push @db, "<$version>$utr3seq" ;
}
$/ = "\n" ;

close FILE ;

return @db ;
} ;
# ====================
sub flatsequence {  # 塩基構成文字以外を除去
my $seq = $_[0] or return '' ;
$seq =~ s/[^ATGCUNRYMKSWHBVD-]//gi ;
return $seq ;
} ;
# ====================
sub subseq {  # 塩基配列の部分配列取得。subseq(13, 567, $seq) → $seq内の13..567を返す
my $seq   = flatsequence($_[2]) ;
my $start = $_[0] and $_[0] =~ /^\d+$/ or return $seq ;
my $end   = $_[1] and $_[1] =~ /^\d+$/ or return $seq ;
return substr($seq, $start - 1, $end - $start + 1) || $seq ;
} ;
# ====================
sub seedmatch {
my $seed = uc(flatsequence($_[0])) ;
my %count ;
my $out = "[searchseq]	[$seed]\n" ;
foreach (@db){
	my $accession = (/<(.*)>/) ? $1 : '' ;
	$count{$accession} = 0 ;
	while (/$seed/ig){
		$count{$accession} ++ ;
	}
	if ($count{$accession}){
		(my $withoutversion = $accession) =~ s/\.\d+$// ;
		$out .= "$withoutversion	$count{$accession}\n" ;
	}
}
chomp $out ;
return $out ;
} ;
# ====================
