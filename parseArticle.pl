#!c:/strawberry/perl/bin/perl.exe 
###########################
# parses joson file for article as stellent contentIDs 
# downlaods content id for articles and pdf's
# should be run after superarticle
###########################
require LWP::UserAgent;
use HTTP::Headers;
use List::Util;
use LWP::Simple; 
use XML::Simple;
use Data::Dumper; 
use Net::SMTP;
use Tie::File;
use warnings;
use Cwd;
use FileHandle; 
use File::Find qw(find);
use File::Basename;
use File::Copy;
  my @array = "";
my $StartingDir = 'g:\input\\';
my $OutputDir = 'g:\output\\';
my $LogDir = 'g:\logs\\';
my $ZipDir = $StartingDir . 'SA3/';
my $BaseDir = $ZipDir . 'content/acs/';
my $NodesProd = $OutputDir . 'nodesProd.xml';
my $Articles = $LogDir . 'Articles.txt';
my $Extensions = $LogDir . 'ArtExtensions.txt';
 if (-e $Articles) {
 unlink $Articles or warn " could not unlink articles";
 }
 if (-e $Extensions) {
 unlink $Extensions or warn " could not unlink extensions";
 }

 open (MYFILE, ">$Articles") or warn " didnt open log file ";	
open (EXTFILE, ">$Extensions") or warn " didnt open ext file ";

# my $url2 = "https://wcmsconsumpdev.acs.org/stellent/idcplg?IdcService=SS_GET_SITE_PUBLISH_REPORT&siteId=PublicWebSite";
# my $xml_file = getstore($url, "C:\\apache\\apache2.2\\scripts\\project.xml");
 open (MYJSON, 'C:\temp\articleJason.txt');   ##### need to automate this
 while (<MYJSON>) {
 	chomp;

	if ($_ =~ m/\"([A-Za-z]+_[0-9]+)\"/) {
	print  " line  $1 \n ";
	$ContentID = $1;
	}
	if ($_ =~ m/\"Web Extension\": \"(.*)\"/) {
			#if ($1 =~ m/(doc|pdf|docx)/) {
			$extension = $1 ;
			# print "$extension  extension \n";
			&count_unique($extension);
			#} 
	}
	if ($_ =~ m/WebSiteSection/) {
		if ($_ =~ m/PublicWebSite:(.*)\"/) {
		$node = $1 ;
		# $node = 'node_id="' . $node . '"';
		 print MYFILE "ContentID:" . $ContentID . " Extension:" . $extension . " Node: " . $node . "\n";
		 &FindFolder($node,$ContentID,$extension);
		}
	}
 }
 close (MYJSON); 
 close (MYFILE);
  close (EXTFILE);
 sub FindFolder {
  $node2match = $_[0];
  $contentid = $_[1];
  $ext = $_[2];
    $root = $BaseDir;
  open (MYNODE, "$NodesProd");
	while (<MYNODE>) {
 	chomp;
		if ( $_ =~ m/\"$node2match\"/ ) {
		$_ =~ m/url=\"(.*\/)index.htm/;
		$tempstub = $1;
		# print " we have a match $node2match at $tempstub\n";
		$newpath = $root . $tempstub;
		chdir($newpath);
			if ( $ext eq "doc" or $ext eq "docx") {
			print MYFILE "ContentID: $_[1] -> $tempstub \n";
			my $wgetURL = 'https://wcmscontrib.acs.org/dc/' . $_[1]; 
			system("wget -q --no-check-certificate -t 3 -T 90 -O $contentid $wgetURL") ;
			
			} elsif ($ext eq "pdf") 
			{
			print MYFILE "ContentID: $_[1] -> $tempstub \n";
			my $WgetURLpdf = 'https://wcmscontrib.acs.org/PublicWebSite/' . $tempstub . $_[1];
			 system("wget -q --no-check-certificate -t 3 -T 90 -O $contentid $WgetURLpdf") ;
			$i++;
			} else 
			{
			print MYFILE "not pdf or doc \n";			
			print MYFILE "ContentID: $_[1] -> $tempstub \n";
			print " something else \n";
			}
		} else {
		# print MYFILE "ContentiD: $_ -> miss \n";
		}
	
	}
	close (MYNODE); 
 }
 sub count_unique {
    push(@array,@_);
    my %count;
    map { $count{$_}++ } @array;

      #print them out:

   map {print "$_ = ${count{$_}}\n"} sort keys(%count);

      #or just return the hash:

}
print time - $^T;
 