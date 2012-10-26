#!c:/strawberry/perl/bin/perl.exe 
###########################
# parses cms project to get 
# landing pages that are super articles and also writes a list of sueprarticles to SuperArticles.txt
# this will also downlaod the stellent contentID file as html and gets the images from it while rewriting the urls
# to do:::  do not save it as index.htm save it as the stellent contentID look in style mapping for code for that
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
use Win32::Process;
use Win32;
my @SSfiles = ();
my $int = 0;
my $StartingDir = 'g:\input\\';
my $OutputDir = 'g:\output\\';
my $LogDir = 'g:\logs\\';
my $ZipDir = $StartingDir . 'SA3\\';
my $BaseDir = $ZipDir . 'content/acs\\';
my $PROJECTfile = $OutputDir . 'SSproject.xml'; 
my $SuperArticles = $LogDir . 'SuperArticles.txt';
my $XMLfile = $OutputDir . 'nodesProd.xml'; 
         use LWP::UserAgent;
         $ua = LWP::UserAgent->new;
         $req = HTTP::Request->new(GET => 'https://wcmscontrib.acs.org/stellent/groups/code/documents/webassets/ss_project_publicwebsite.xml');
         $req->authorization_basic('tevolo', '');
         $request = $ua->request($req)->as_string;

 if (-e $SuperArticles) {
 unlink $SuperArticles or warn " could not unlink superarticles";
 }
		 
 open (MYFILE, ">$SuperArticles") or die;		 
open FILE, ">$PROJECTfile" or die $!;
print FILE $request;
close FILE;	 



 open (MYFILE, $PROJECTfile);
 while (<MYFILE>) {
 	chomp;
 	# print "$_\n";
	#sleep(2);
	if ($_ =~ m/primaryUrl=\"PP_SUPERARTICLE/) {
	if ($_ =~ m/(nodeId="\d+")/) {
	$line = $_;
	$nodeID = $1;
	$nodeID =~ s/"//g;
	$nodeID =~ s/nodeId/node_id/g;
	# need to match node to url here then make the directory
	&ParseXml($nodeID);
		if ($line =~ m/region1=([A-Za-z0-9]+_\d+)/) {
			$region1 = $1;  # this is the stellent content ID
		}
		if ($line =~ m/urlDirName="([A-Za-z]+)\"/) {
			$region2 = $1; # this is the actual directory structure 
			# print " region1  $region1  reegion2 $region2 \n";
			&Write2FileSA($nodeID,$region1,$region2); 
			my $dir = getcwd;
			&mkdir_SA($dir,$region1);
		}
	} else {
	next;
	}
	} else {
		if ($_ =~ m/(nodeId="\d+")/) {
	$line = $_;
	$nodeID = $1;
	$nodeID =~ s/"//g;
	$nodeID =~ s/nodeId/node_id/g;
	# need to match node to url here then make the directory
	&ParseXml($nodeID);
	print " \n \n This is i $int \n \n ";
		if ($line =~ m/urlDirName="([A-Za-z]+)\"/) {
			$region2 = $1;
			$region1 = "placeholder";
			my $dir = getcwd;
			&mkdir_SA($dir,$region1);
		}
		} else {
		next;
		}
	}
 }
 close (MYFILE); 
 sub Write2File {
tie @lines, 'Tie::File', $SuperArticles or die;
        for (@lines) {
          if (/$_[0]\s/) {
            $_ .= "\r\n  $_[1] ";
            last;
          }
        }
		 untie @lines;
}

sub Write2FileSA { # takes nodeID the stellent contentID and the directory path
	open (FILE, ">>$SuperArticles") or warn( "didnt open");
	print FILE $_[0] . " " . $_[1] . " " . $_[2] . "\n";
	close(FILE);
}

sub ImageLocal {   # called from mkdir_SA  should probably merge into content.xml for images 
 $file = $_[0];
 open (IMFILE, "$file");
  # open (OUT, '>>index.htm') or warn( "didnt open");  # no need to make index.htm
	while (<IMFILE>) {
		chomp;
		$_ =~ s/PublicWebSite/acs\/SA\/content\/acs/g;
		if ($_ =~ m/<img src=\"\/.*\/([A-Za-z0-9]+-\d+.jpg|gif)?\"/) {
			$savedimage = $1;
			$image = '"' . $savedimage;
			$line = $_;
			$line =~ m/img src=\"(.*jpg|gif)/ ; 
			$imagePath = $1;
			$imageURL = 'https://wcmscontrib.acs.org' . "$imagePath";
			# print "$image url is $imageURL \n";
				if ($int > 10) {
				&CheckWget;
				$int = 0;
				}
			system("wget  -b -q  -nv -a c:\\temp\\wgetlog.txt --no-check-certificate -t3 -T30 -O $savedimage $imageURL") ;
			# print " \n This is line before replace \n $_ \n \n ";
	#		$_ =~ s/\"\/.*jpg|gif?/$image/g;
			# print "\n \n this should be a whole line \n \n $_ \n \n ";
		}
		# print OUT $_ . "\n";
		
	}
	close(IMFILE);
#	close(OUT);
#	copy("index.htm","$file");
}

sub mkdir_SA {     # this gets passed the current directory and the stellent content ID
	my $path = $_[0];  
	# print $path;
	mkdir $path or die "Could not make dir $path: $!" if not -d $path; 
	chdir($path) or warn " not able to cd into $path \n";
	my $fileName = $_[1] ;
	my $wgetURL = 'https://wcmscontrib.acs.org/dc/' . $_[1];  # get the dynamic converted stellent content ID as html
	if ($fileName ne "placeholder") {   # dont bother connecting if it is a dummy placeholder
	$int = $int +1;
	print "integer is $int \n";
	if ($int > 2) {
	$int = 0;
	system("wget  -q -nv --no-check-certificate -a c:\\temp\\wgetlog.txt -t 3 -T 90 -O $fileName $wgetURL") ;
	# &CheckWget;
	} else {
	system("wget   -q -nv --no-check-certificate -a c:\\temp\\wgetlog.txt -t 3 -T 90 -O $fileName $wgetURL") ;
	}
	
	my $pwd = cwd();
	# print "$pwd\\$fileName \n";
	push(@SSfiles, "$pwd\\$fileName");
 	# &ImageLocal($fileName);  # content ID
	}
	return;
}  

sub ParseXml {
 my $NodeMatch = $_[0];  
 open (MYNODES, $XMLfile);
 while (<MYNODES>) {
 	chomp;
		$node = " ";
		if ($_ =~ m/(nodeId="\d+")/) {
		$node = $1;
		$node =~ s/"//g;
		$node =~ s/nodeId/node_id/g;
		}
		if ($NodeMatch eq $node) {
				if ($_ =~ m/url="(.+)index.htm"/) {
				$stub = $1;
				$stub =~ s/[^!-~\s]/n/g; 
				$FullDir = $BaseDir . $stub; 
				# print $FullDir . "\n";
				&mkdir_recursive($FullDir);
				 chdir($FullDir) or warn " not able to chdir \n";

				}
			return ;
		}
 }
 close (MYNODES); 
}
####  does this need to be here any more??????
sub mkdir_recursive {     
	$path = shift;  
	#  print $path;
	mkdir_recursive(dirname($path)) if not -d dirname($path); 
	mkdir $path or die "Could not make dir $path: $!" if not -d $path; 
	return;
}  

sub CheckWget {
use Win32::Process::Info;
$WgetCount = 1;
while ($WgetCount >= 1) {
    my $pi = Win32::Process::Info->new();
    my @info = $pi->GetProcInfo();
    $WgetCount = 0;
        foreach my $pid (@info){
        my $proc = $pid->{"Name"} ;
            if  ($proc eq "wget.exe") {
			$WgetCount = $WgetCount +1;
			print " still have some wgets $WgetCount \n";
				
             } # end if
        } # end for
} # end while
} # end sub
&CheckWget;
foreach $line (@SSfiles) {
print $line . "\n";
&ImageLocal($line);
&CheckWget;
}
print time - $^T;