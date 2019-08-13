#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use IO::Uncompress::Brotli;
use Data::Dumper;
my @list;
my $ua;#dummy user
my $url;
my $url2;
my $url3;
my %headers;#dummy header
my %params=();
my @germ;
my @desc;

createUA();
#$url="https://www.maizegdb.org/data_center/locus-reports";
#$url="https://www.maizegdb.org/search/shadowbox/shadowbox_search.php";
#$url="https://www.maizegdb.org/search/gene_locus_data.php";
$url="https://ajax0.maizegdb.org/record_data/gene_locus_data.php";
$url2="https://ajax2.maizegdb.org/record_data/gene_data.php";
$url3="https://ajax1.maizegdb.org/record_data/gene_locus_data.php";

open FILE, "<$ARGV[0]" or die "$!\n";
while(<FILE>){	
	chop;
	chop;
	my ($id,$geneShort,$geneLong)=split(/\t/,$_);
	my ($syno,$pheno,$model,$rLoci)=id2info($url,$id);
	my ($anno)=id2anno($url,$id);
	my ($n,$type,$title,$refInfo)=id2ref($url3,$id);
	#gene
	print "\@maizeGDB_id:$id\t$geneShort\t$geneLong\n";
	#syno
	print "\tsynonyms:\n\t\t$$syno[0]\n";
	#pheno
	print "\tphenotype:\n";
	foreach(@{$pheno}){print "\t\t$_\n";}
	#gene model
	print "\tgene model:\n";
	foreach my $gene(@{$model}){
		print "\t\t$gene\n";
		my ($n,$term,$desc)=terms($url2,$gene);
		for(my $i=0;$i<=$n;$i++){
			print "\t\t\t$$term[$i]\t$$desc[$i]\n";
		}
	}
	#rLoci
	print "\tRelated loci:\n";
	if(defined $$rLoci[0]){
		foreach(@{$rLoci}){print "\t\t$_\n";}
	}
	else{
		print "\t\tNone\n";
	}
	#anno
	print "\tComments:\n";
	foreach(@{$anno}){print "\t\t$_\n";}
	#ref
	print "\tRelated papers:\n";
	if(defined $$type[0]){
		for(my $i=0;$i<=$n;$i++){
			print "\t\t$$type[$i]:\t$$title[$i]\t$$refInfo[$i]\n";
		}
	}
	else{
		print "\t\tNone\n";
	}
}
close FILE;


sub terms{
	my ($url,$id)=@_;
	my @term;
	my @desc;
	my $q=$url."?id=$id&type=annotations";
	my $response = $ua->post($q, \%params, %headers);
	if($response->is_success){
		my $httpPage = unbro $response->content, 10_000_000;
		my @hp=split(/\n/,$httpPage);
		for(my $i=0;$i<scalar(@hp);$i++){
			if($hp[$i] =~ /purl.obolibrary.org/){
				$hp[$i]=~s/.*">//;
				$hp[$i]=~s/<.*//;
				chop($hp[$i]);
				push @term,$hp[$i];
			}
			elsif($#term >$#desc && $hp[$i] =~ /<td>/){
				$hp[$i]=~s/.*<td>//;
				$hp[$i]=~s/<\/td>//;
				chop($hp[$i]);
				push @desc,$hp[$i];
			}
		}
	}
	return ($#term,\@term,\@desc);
}

sub id2info{
	my ($url,$id)=@_;
	my @syno;
	my @pheno;
	my @model;
	my @rLoci;
	my %rLociNextLine;
	my $q=$url."?id=$id&type=overview_gene";
	my $response = $ua->post($q, \%params, %headers);
	if($response->is_success){
		my $httpPage = unbro $response->content, 10_000_000;
		my @hp=split(/\n/,$httpPage);
		for(my $i=0;$i<scalar(@hp);$i++){
			#if($hp[$i] =~ /\[Classical/){
			#	$hp[$i]=~s/.*">//;
			#	$hp[$i]=~s/<.*//;
			#	return "$hp[$i]";
			#	}
			
			if($hp[$i] =~ /Synonyms/){
				$hp[$i]=~s/<.*?>//g;
				$hp[$i]=~s/^\s+//;
				chop $hp[$i];
				push @syno,$hp[$i];
			}
			elsif($hp[$i] =~ /phenotype/){
				$hp[$i]=~s/.*">//;
				$hp[$i]=~s/<.*//;
				push @pheno,$hp[$i];
				
			}
			elsif($hp[$i] =~ /MaizeGDB\ curated/){
				$hp[$i]=~s/.*">//;
				$hp[$i]=~s/<.*//;
				push @model,$hp[$i];
			}
			elsif($hp[$i] =~ /locus\?/){
				$hp[$i]=~s/<.*?>//g;
				$hp[$i]=~s/^\s+//;
				chop $hp[$i];
				push @rLoci,$hp[$i];
				$rLociNextLine{$i+1}="";
			}
			elsif(defined $rLociNextLine{$i}){
				$hp[$i]=~s/^\s+//;
				chop $hp[$i];
				$rLoci[$#rLoci]=$rLoci[$#rLoci]." $hp[$i]";
			}
		}
	}
	return(\@syno,\@pheno,\@model,\@rLoci);
}



sub createUA{
	#robot header, I am saying this is a window OS with firefox...
	 %headers = (
	  'User-Agent' => 'Mozilla/5.0 (Windows; U; Windows NT 6.1; pl; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13',
	  'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
	  'Accept-Language'=>'en-US,en;q=0.5',
      'Accept-Encoding'=>'gzip, deflate,br',
      'Connection'=> 'keep-alive',
	  'Content-Type' => 'text/html;charset=UTF-8',
	);
	$ua = LWP::UserAgent->new();	
}


sub id2anno{
	my ($url,$id)=@_;
	my @anno;
	my $q=$url."?id=$id&type=annotations_gene";
	my $response = $ua->post($q, \%params, %headers);
	if($response->is_success){
		my $httpPage = unbro $response->content, 10_000_000;
		my @hp=split(/\n/,$httpPage);
		my $ind=0;
		for(my $i=0;$i<scalar(@hp);$i++){
			if($hp[$i] =~ /Comments\ are\ additional\ notes/){
				$ind=1;
			}
			elsif($ind == 1 && $hp[$i] =~/<b>/){
				$hp[$i]=~s/<.*?>//g;
				$hp[$i]=~s/^\s+//;
				push @anno,$hp[$i];
			}
			elsif($ind == 1 && $hp[$i] =~/<\/p>/){
				last;
			}
		}
	}
	return(\@anno);
}


sub id2ref{
	my ($url,$id)=@_;
	my @type;
	my @title;
	my @refInfo;
	my $q=$url."?id=$id&type=references_gene";
	my $response = $ua->post($q, \%params, %headers);
	if($response->is_success){
		my $httpPage = unbro $response->content, 10_000_000;
		my @hp=split(/\n/,$httpPage);
		my $ind=0;
		for(my $i=0;$i<scalar(@hp);$i++){
			if($hp[$i] =~ /Related\ Papers/){
				$ind=1;
			}
			elsif($ind == 1 && $hp[$i] =~/<i>/){
				$hp[$i]=~s/.*?>//;
				$hp[$i]=~s/<.*//;
				push @type,$hp[$i];
			}
			elsif($ind == 1 && $hp[$i] =~/.*reference.*title="(.*?)">(.*)<\/a>/){
				push @title,$1;
				push @refInfo,$2;
			}
		}
	}
	return($#type,\@type,\@title,\@refInfo);
}


