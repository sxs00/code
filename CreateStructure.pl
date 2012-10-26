#!c:/strawberry/perl/bin/perl.exe 
###########################
#  files 1_* 2_* and 3_* all together
# this script creates the basic structure of the webstie from the sitepublish report
# it also adds a generic content.xml file to the root of each directory
# no files are downloaded need to also run parsearticle parsesuperarticle then stylemapping
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
use warnings;

#####  url below is location of stellent structure  need login credentials to get
 ### my $url = "https://wcmscontrib.acs.org/stellent/idcplg?IdcService=SS_GET_SITE_PUBLISH_REPORT&siteId=PublicWebSite";
         use LWP::UserAgent;
         $ua = LWP::UserAgent->new;
         $req = HTTP::Request->new(GET => 'https://wcmscontrib.acs.org/stellent/idcplg?IdcService=SS_GET_SITE_PUBLISH_REPORT&siteId=PublicWebSite');
         $req->authorization_basic('tevolo', '');
         $request = $ua->request($req)->as_string;
			  
					  


############################## variables ##########################################
my @Nodes = ();
my $StartingDir = 'g:\acs\structure';
my $TempDir = 'g:\logs\\';
my $OutputDir = 'g:\output\\';
my $ZipDir = $StartingDir . '\jcr_root\\';
my $BaseDir = $ZipDir . 'content\acsstevesiteconfiguration\acs-steve-home-page\\';
 my $XMLfile = $OutputDir . 'nodesProd.xml';  # also called from super article parser
my $StructureFile =  $TempDir . 'ProdStructure.txt';
my $ZippedFile = $StartingDir . 'prodstruct.zip';
my $region1 = "";
############################## main ###############################################

 if (-e $StructureFile) {
 unlink $StructureFile;
 }
	open FILE, ">$XMLfile" or die $!;
print FILE $request;
close FILE;	 			  			
 open (MYFILE, "$XMLfile") or die;

 while (<MYFILE>) {
 	chomp;
	if (defined $_) {
	my $line = $_;
	if ($line =~ m/nodeId="(\d+)".*url="(.+)?index.htm"\/>?/) {
		$region1 = $2;
		print "first $1 and $2 " . "\n";
		#
		# replaces nonAscii with an n for the espanol
		#  should be looked into more!!!!!!!!!!!!!!!!
		#
		$region1 =~ s/[^!-~\s]/n/g; 
  		$FullDir = $BaseDir . $region1; 
  		# print $FullDir . "\n";
		push(@Nodes, $region1);
   		&mkdir_recursive($FullDir); # called to make directories
	    &Write2File($1,$region1); # makes the structure file
	} else {
	next;
	}
	} # defined
 }
  close (MYFILE); 
 
 ############################### Create XML #######################################
   find( \&createContentxml, $BaseDir );
   
   sub createContentxml {
   	if (-d $File::Find::name) {
   		my $dir = $File::Find::name;
   		#  print $dir . ": \n";
   	 	&subdir($dir) ;
   	}
   }
  
  

################################ EXPERIMENTAL #####################################
sub Archive {
 use Archive::Zip;
 my $METAINF = $StartingDir . 'META-INF';
 my $zip = Archive::Zip->new();
 $zip->addTree( "$ZipDir", 'jcr_root' );
 $zip->addTree( "$METAINF", 'META-INF' );
 $zip->writeToFileNamed("$ZippedFile");
}

################################ SUBS ############################################# 
sub Write2File {
	open (FILE, ">>$StructureFile") or warn( "didnt open structure file");
	 print FILE 'node_id=' . $_[0] . "=" . $_[1]  . "\n";
	close(FILE);
}

sub mkdir_recursive {     # first called passed FullDir which si bae and the region directory
# This sub just builds a folder structure based on the nodes of the project file
	my $path = shift;  
	 $path =~ tr/A-Z/a-z/;
	 print $path;
	mkdir_recursive(dirname($path)) if not -d dirname($path); 
	mkdir $path or warn "Could not make dir $path: $!" if not -d $path; 
	return;
}  

 sub subdir {
   my $dir2 = getcwd;
 #  print $dir2 . "\n";
  my $dir = $_[0];
  chdir($dir) or warn " not able to cd into $dir \n";
 # print "dir: $dir: \n";
  opendir DH, $dir or die "Failed to open $dir: $!";
  	while ($_ = readdir(DH)) {
  	next if $_ eq "." or $_ eq "..";
  	if (-d $_ ) {
  #	print $_ . "\n";
  	  if (-f ".content.xml") {
  	  	open (MYFILE, '>>.content.xml');
  	  	print MYFILE  '<' . $_ . '/>' . "\n";
  	  	close (MYFILE); 
  	  } else {
  	    	 open (MYFILE, '>>.content.xml');
  	    	 print MYFILE '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
			print MYFILE '<jcr:root xmlns:cq="http://www.day.com/jcr/cq/1.0" xmlns:jcr="http://www.jcp.org/jcr/1.0" xmlns:rep="internal"' . "\n";
			print MYFILE '    jcr:mixinTypes="[rep:AccessControllable]"' . "\n";
  	    	 print MYFILE '    jcr:primaryType="cq:Page">' . "\n";
  	    	 print MYFILE '    <jcr:content' . "\n";
			 print MYFILE '         cq:lastModifiedBy="admin"' . "\n";
			 print MYFILE '         cq:designPath="/etc/designs/acs"' . "\n";
			 print MYFILE '		cq:template="/apps/acs/templates/acsPathway"' . "\n";
			 print MYFILE '		jcr:isCheckedOut="{Boolean}true"' . "\n";
			 print MYFILE '		jcr:mixinTypes="[mix:versionable]"' . "\n";
			 print MYFILE '		jcr:primaryType="cq:PageContent">' . "\n";
    		 print MYFILE  '</jcr:content>' . "\n";
	    	 print MYFILE  '<' . $_ . '/>' . "\n";
  	  	close (MYFILE); 
  	  }
  	  	
  	  } else {
  	  next;
  	  }
  	}
  	if (-f ".content.xml") {  	
    		open (MYFILE, '>>.content.xml');
    		print MYFILE  '</jcr:root>' . "\n";
  		close (MYFILE); 
		chdir($dir2);
	} else {
	    open (MYFILE, '>>.content.xml');
	  	print MYFILE '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
	  print MYFILE '<jcr:root xmlns:cq="http://www.day.com/jcr/cq/1.0" xmlns:jcr="http://www.jcp.org/jcr/1.0" xmlns:rep="internal"' . "\n";
	  	print MYFILE '    jcr:primaryType="cq:Page">' . "\n";
	  	print MYFILE '    <jcr:content' . "\n";
		print MYFILE '         cq:lastModifiedBy="admin"' . "\n";
		print MYFILE '		cq:template="/apps/acs/templates/acsPathway"' . "\n";
		print MYFILE '		jcr:isCheckedOut="{Boolean}true"' . "\n";
		print MYFILE '		jcr:mixinTypes="[mix:versionable]"' . "\n";
		print MYFILE '		jcr:primaryType="cq:PageContent">' . "\n";
	    print MYFILE  '</jcr:content>' . "\n";
    	print MYFILE  '</jcr:root>' . "\n";
	  	close (MYFILE); 
	  	chdir($dir2);	
	return 0; # Did not find any subdirectory in this directory
	}
  }
  print time - $^T;