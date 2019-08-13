#!/usr/bin/perl

use strict;
use warnings;

open FILE, "<$ARGV[0]" or die "$!\n";
while(<FILE>){
	chomp;
	if($_ =~ /href/){
		$_=~s/.*id=//;
		$_=~s/">/\t/;
		$_=~s/ <i>/\t/;
		$_=~s/<\/i><\/a>//;
		my ($id,$gene,$desc)=split(/\t/,$_);
		$desc=~tr/ /_/;
		print "$id\t$gene\t$desc\n";
	}
}
close FILE;
