#!c:/strawberry/perl/bin/perl.exe 
  use HTML::TokeParser;
  use HTML::Element;
  use HTML::TreeBuilder;
  use warnings;
  use File::Copy;
  use File::Basename;
  use File::Find;
  use File::Path qw(mkpath);
  use Cwd;
  use LWP::Simple; # for downloading urls 
  use LWP 5.64;
#####################################################
# R17 change image right left center to not be seperate sections
# R17 added regex to strip all nonstandard characters from directories being created 
# R17 fixing image span classes
# R18 adding columns and embed
# R19 fixed double counting of javascript embed
# R19 fixed problem with mapping into cq5 dir
# R19 fixed problem with tables
$STARTDIR = 'g:\input';
$LOGDIR = 'g:\logs';
$OUTDIR = 'g:\output'; 
$ERRORFILE =  $LOGDIR . '\errors.txt';
$FILES =  $LOGDIR . '\ContentMapping.txt';
$DLwrapper = $LOGDIR . '\DLwrapper.txt';
$LOGFILE =  $LOGDIR . '\logfile.txt';
$PDFIMAGE = $LOGDIR . '\pdficon.txt';
$PDFMAPPING = $LOGDIR . '\PDFmapping.txt';
$BegImageFile = $OUTDIR . '\.content.xml';
# my $dir = 'C:\temp\SA\content\acs\pressroom/presspacs';  ## change per env ##
my $PATH = '\SA3\content\acs';
# my $dir =  $STARTDIR . $PATH . '//';  ## change per env ##
# my $dir =  $STARTDIR . $PATH . '\about';
#my $dir =  $STARTDIR . $PATH . '\acsstore'
#my $dir =  $STARTDIR . $PATH . '\announcements';
#my $dir =  $STARTDIR . $PATH . '\articleindex'
#my $dir =  $STARTDIR . $PATH . '\browse'
#my $dir =  $STARTDIR . $PATH . '\calendar'
# my $dir =  $STARTDIR . $PATH . '\careers';
#my $dir =  $STARTDIR . $PATH . '\climatescience';
#my $dir =  $STARTDIR . $PATH . '\contact'
my $dir =  $STARTDIR . $PATH . '\coolscience';
#my $dir =  $STARTDIR . $PATH . '\copyright'
#my $dir =  $STARTDIR . $PATH . '\education'
#my $dir =  $STARTDIR . $PATH . '\errorpage'
#my $dir =  $STARTDIR . $PATH . '\everydaychemistry'
#my $dir =  $STARTDIR . $PATH . '\feature'
#my $dir =  $STARTDIR . $PATH . '\funding'
#my $dir =  $STARTDIR . $PATH . '\global'
#my $dir =  $STARTDIR . $PATH . '\greenchemistry'
#my $dir =  $STARTDIR . $PATH . '\help'
#my $dir =  $STARTDIR . $PATH . '\meetings'
#my $dir =  $STARTDIR . $PATH . '\membernetwork'
#my $dir =  $STARTDIR . $PATH . '\membership'
#my $dir =  $STARTDIR . $PATH . '\molecule'
#my $dir =  $STARTDIR . $PATH . '\noteworthy'
#my $dir =  $STARTDIR . $PATH . '\patent'
#my $dir =  $STARTDIR . $PATH . '\policy'
#my $dir =  $STARTDIR . $PATH . '\pressroom'
#my $dir =  $STARTDIR . $PATH . '\privacy'
#my $dir =  $STARTDIR . $PATH . '\promo'
#my $dir =  $STARTDIR . $PATH . '\publications'
#my $dir =  $STARTDIR . $PATH . '\search'
#my $dir =  $STARTDIR . $PATH . '\security'
#my $dir =  $STARTDIR . $PATH . '\sitemanager'
#my $dir =  $STARTDIR . $PATH . '\sitemap'
#my $dir =  $STARTDIR . $PATH . '\sustainability'
#my $dir =  $STARTDIR . $PATH . '\techadmin'
#my $dir =  $STARTDIR . $PATH . '\terms'
#my $dir =  $STARTDIR . $PATH . '\tp'
#my $dir =  $STARTDIR . $PATH . '\volunteer'
my $cq5Dir = 'g:\acs\structure\jcr_root\content\acsstevesiteconfiguration\acs-steve-home-page'; # directory to place files prior to being zipped
$beginningDir =  $STARTDIR . $PATH;  ### where the real exported content is to be converted
$doccounter = 0;
$pdfcounter = 0;
$othercounter = 0;
$relatedcontent = 0;
$final_counter =0;
$haveimage = "true"; # R20 need to set to false and then set to true with image
open ERROR, ">$ERRORFILE" || warn " could not open log file for errors ";
open FILES, ">>$FILES" || warn " could not open log file for files ";
open DLwrapper, ">$DLwrapper" || warn " could not open log file for files ";
open LOGFILE, ">$LOGFILE" || warn " could not open log file for files ";
open PDFIMAGE, ">$PDFIMAGE" || warn " could not open pdf image ";
find(\&isArticle, $dir);
find(\&isXML, $cq5Dir);
find(\&delXML, $cq5Dir);

sub isArticle
{
$imagerighthit = "false" ;
$imagelefthit = "false";
$imagecenterhit = "false";
 my %PDFhash = ();
 
	 #   if ($_ =~ m/.*_\d*$/ || $_ eq "index.htm") {
    if ($_ =~ m/.*_\d*$/ ) {
	$final_counter++;
    $articlefile = $_;  # article file gets set to a content id and path but possibly not an article
    $outputfilename = basename($articlefile); # content ID
    $articleList = 'C:\acs\articleMetaShort.txt';## change per env ##   #####   need to automate !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ($ArtTitle,$URL,$Ext,$cwd) = FindMeta($articleList,$outputfilename);
	if ($ArtTitle eq "miss") {
	# next ;
	} else {
    $outputfile = $cwd . '/' . $URL;
		if ($Ext eq "doc" or $Ext eq "docx") {
		$doccounter++;
		&Stripping($articlefile);
		&Stellent2CQ($articlefile,$outputfile,$ArtTitle);
		# print " we have a doc \n"
		} elsif ($Ext eq "pdf") {
		# extract pdf and do some pdf work ###################################################################
		&StellentPDF2CQ($articlefile,$outputfile,$ArtTitle,$URL); # create pdf file 
		$pdfcounter++
		# print " we hae a pdf \n";
		} else {
		print LOGFILE " title: $ArtTitle  and extension $Ext \n";
		$othercounter++;
		}
    }
	}
}
##########			Begin StellentPDF2CQ #########
sub StellentPDF2CQ {
$filenameStellent = $_[0]; # stellent filename
$outfilePDF = $_[1]; # this is the formed url directory
$outfilePDF =~ s/[^0-9a-zA-Z_-]+//g; # strip out all none standard characters
	$outfilePDF =~ s/\//\\/g;
	my $FromDir = $beginningDir;
	$FromDir =~ s /\\/\\\\/g;
	my $ToDir = $cq5Dir;
	$ToDir  =~ s /\\/\\\\/g;
	$outfilePDF =~ s/$FromDir/$ToDir/g;  #### just added 8/16
	$outfilePDF=~ s/\\\\/\\/g;	

$outfilePDF =~ s/$beginningDir/$cq5Dir/;
$articletitlePDF = $_[2]; # title from metadata
$filenamePDF = $_[3]; # filename of new pdf
$filenamePDF =~ tr/A-Z/a-z/;
$filenamePDF =~ s/_{1,5}/-/g;
$filenamePDF =~ s/-{2,5}/-/g;
if (! -d $outfilePDF) {
my $dirs = eval {mkpath($outfilePDF) };
print ERROR  " failed to make $outfilePDF \n" unless $dirs;
}
$finalPDF = $outfilePDF . '/' . $filenamePDF . '.pdf';
copy("$filenameStellent","$finalPDF") or print ERROR "Copy failed: $!";

$PDFhash{ $filenameStellent } = $finalPDF;
}
##########			Begin Stellent2CQ	##########

sub Stellent2CQ {
##### arrays #####
@MainPar = ();
@RightPar = ();
@LeftPar = ();
@CenterPar = ();
# @Final = ();
@Add2End = ();
##################
$filename = $_[0]; # stellent filename
$outfile = $_[1]; # this is the formed url
$articletitle = $_[2];  # title from metadata
	my $name_cq5 = basename($outfile);
 print FILES "contentID=$filename cq5id=$name_cq5 url=$outfile \n";
 print LOGFILE " file being processed $filename \n";
  print  "contentID=$filename cq5id=$name_cq5 url=$outfile \n";
$spanhit = "false";
$twocolumn = "false";
$ArtTitle = "";
 $a = 0; #master counter
 $i = 0; #h tags
 $j = 0; # par tag
 $k = 0; # unordered list
 $l = 0; # blockquote
 $m = 0; # image right
 $n = 0; # image left 
 $o = 0; # image center
 $p = 0; # table
 $q = 0; # ordered list
 $r = 0; # related content
 $s = 0; # embed
 $t = 0; # column
#######################################
#         my $root = HTML::TreeBuilder->new;
#          $root->parse_file($filename);
#			my @sc = $root->look_down('_tag', 'span', 'class', 'image-right');
#	if (@sc) {
#print "there was an image right in $filename \n";
#$twocolumn = "true";
#}
#			my @sc = $root->look_down('_tag', 'span', 'class', 'related-content');
#	if (@sc) {
#print "there was related content in $filename \n";
#$twocolumn = "true";
#}
#$root->delete();	
####################################
  open (MYARTICLE, "$filename");
  open (MYOUTFILE, ">>$outfile");
 while (<MYARTICLE>) {
 ##########			 begin cleanup 	##########
 	if($_=~/^\s*$/){
 	next;
 	}
##########			 end cleanup 	##########

#####  dont double or tripple count spans #####
#####  keep track of paragraphs here  #
if ($_ =~ m/<div class="dl-wrapper"><dl>/ig) {
 print DLwrapper "contentID=$filename has a dl-wrapper \n";
}
if ($spanhit eq "true") {
	if ($_ =~ m/<\/span>/) {
	$spanhit = "false" ;
	next;
	} else {
	if ($_ =~ m/<p>/)
	{ $j++;
	} elsif ($_ =~ m/<ul>/) {
	$k++;
	}
	elsif ($_ =~ m/<ol>/) {
	$q++;
	}
	next;
	}
}

 ###   print "$_ \n";
 ###################################

 
 
##########			check for header
#### from below <\/h[1-6]>
if ($_ =~ m/<(h[1-6])>(.*)/) {
$HeadingNum = $1;
	$output = & get_h($filename);	
	$a++;
	$output =~ s/</&lt;/g;
	$output =~  s/>/&gt;/g;
	$output =~    s/'/&pos;/g;
	$output =~ s/"/&quot;/g;
	$output =~ s/&lt;h[1-6]&gt;//g;
	$output =~ s/&lt;\/h[1-6]&gt;//g;
if ($HeadingNum eq "h1") {
	$ArtTitle = $output;
	} else
	{
	$output = &convert($output);
	$textcounter = 'headingtext_' . "$a";
	push(@MainPar,  '<' . $textcounter );
	push(@MainPar,    'jcr:primaryType="nt:unstructured"' );
	push(@MainPar,    'sling:resourceType="acs/components/general/headingtext"' );
        push(@MainPar,    'border="Normal"');
        push(@MainPar,    'round="Normal"' );
        push(@MainPar,    'style="Normal"' ); 
	push(@MainPar,'text="' . $output . '"');
	push(@MainPar,'textIsRich="true"' ); 
	push(@MainPar,'xheadingstyle="' . $HeadingNum . '">' ); 
	push(@MainPar,  '</' . $textcounter  . '>' );
	}
	$i++; ##### iterate if we have found a head tag
	next;
}
##########			end header check

##########			check for paragraph
if ($_ =~ m/<p>/) {	
	$a++;
	# print "\n $j   $_  \n";
	$output = & get_par($filename);
	if ($output =~ m/pdf-icon/gi) {
	$output =~ s/<span class="pdf-icon">//gi;
	print PDFIMAGE "$filename has a pdf image \n";
	}
			$output =~ s/</&lt;/g;
			$output =~  s/>/&gt;/g;
			$output =~    s/'/&pos;/g;
			$output =~ s/"/&quot;/g;	
			$output = &convert($output);
	$textcounter = 'text_' . "$a";
	push(@MainPar,  '<' . $textcounter );
	push(@MainPar,    'jcr:primaryType="nt:unstructured"' );
	push(@MainPar,    'sling:resourceType="acs/components/general/text"' );
        push(@MainPar,    'border="Normal"');
        push(@MainPar,    'round="Normal"' );
        push(@MainPar,    'style="Normal"' ); 
	push(@MainPar,'text="' . $output . '&lt;/p&gt;"');
	push(@MainPar,'textIsRich="true">' ); 
	push(@MainPar,  '</' . $textcounter  . '>' );
	$j++; ##### iterate if we have found a para tag
	next;
}
##########			end pragraph check
#########  embed ####################
 # if ($_ =~ m/<script type="text\/javascript" src="(http:.*?FileRetrieve.*?)"><\/script>/ig) {  # only use when can access servers through vpn

 #########  embed #################
##########			check for lists  
if ($_ =~ m/<ul>/) {
	$a++;
	#print "\n $_ \n";
	$output = & get_list($filename,"unordered");
			$output =~ s/</&lt;/g;
			$output =~  s/>/&gt;/g;
			$output =~    s/'/&pos;/g;
			$output =~ s/"/&quot;/g;
			$output = &convert($output);
	$listcounter = 'list_' . "$a";
	push(@MainPar,  '<' . $listcounter );
	push(@MainPar,    'jcr:primaryType="nt:unstructured"' );
	push(@MainPar,    'sling:resourceType="acs/components/general/text"' );
    push(@MainPar,    'border="Normal"');
    push(@MainPar,    'round="Normal"' );
    push(@MainPar,    'style="Normal"' ); 
	#print "\n" . 'text="' . $output  . '"' .  "\n";
	push(@MainPar,'text="' . $output . '"');
	push(@MainPar,'textIsRich="true">' ); 
	push(@MainPar,  '</' . $listcounter  . '>' );
	$k++; ##### iterate if we have found a list tag

	next;
}

if ($_ =~ m/<ol>/) {
	$a++;
	#print "\n $_ \n";
	$output = & get_list($filename,"ordered");
			$output =~ s/</&lt;/g;
			$output =~  s/>/&gt;/g;
			$output =~    s/'/&pos;/g;
			$output =~ s/"/&quot;/g;
			$output = &convert($output);
	$listcounter = 'list_' . "$a";
	push(@MainPar,  '<' . $listcounter );
	push(@MainPar,    'jcr:primaryType="nt:unstructured"' );
	push(@MainPar,    'sling:resourceType="acs/components/general/text"' );
    push(@MainPar,    'border="Normal"');
    push(@MainPar,    'round="Normal"' );
    push(@MainPar,    'style="Normal"' ); 
	#print "\n" . 'text="' . $output  . '"' .  "\n";
	push(@MainPar,'text="' . $output . '"');
	push(@MainPar,'textIsRich="true">' ); 
	push(@MainPar,  '</' . $listcounter  . '>' );
	$q++; ##### iterate if we have found a list tag

	next;
}
##########			end list check

##########			check for block quote

if ($_ =~ m/<blockquote>/) {
	
	$a++;
	#print "\n $_ \n";
	$output = & get_blockquote($filename);
			$output =~ s/</&lt;/g;
			$output =~  s/>/&gt;/g;
			$output =~    s/'/&pos;/g;
			$output =~ s/"/&quot;/g;
			$output = &convert($output);
	push(@MainPar,'<pullquotes' . "$a");
	push(@MainPar,'jcr:lastModifiedBy="admin"');
	push(@MainPar,'jcr:primaryType="nt:unstructured"');
	push(@MainPar,'sling:resourceType="acs/components/general/pullquotes"');
	push(@MainPar,'text="' . $output . '"');
	push(@MainPar,'textIsRich="true"/>' . "\n");
	$l++; ##### iterate if we have found a blockquote tag
	next;
}

##########			end block quote

if ($_ =~ m/<span class="image-right">/) {
	($imageURL, $caption, $credit, $border, $height, $width) = &get_spanclassR($filename,$m);
	$spanhit = "true";
	 print LOGFILE "span right  Image url body is $imageURL \n";
	&GenericImage($imageURL,$caption,$credit,$border,$height,$width,"right");
	$m++; ##### iterate if we have found a span image right
}	# end of beginning if 
##########			end span right

if ($_ =~ m/<span class="image-left">/) {
	($imageURL, $caption, $credit, $border, $height, $width) = &get_spanclassL($filename,$n);
	$spanhit = "true";
		print LOGFILE "span left  Image url body is $imageURL \n";
		&GenericImage($imageURL,$caption,$credit,$border,$height,$width,"left");
	$n++; ##### iterate if we have found a span image left
}	# end of beginning if 
##########			end span right

if ($_ =~ m/<span class="image-center">/) {
($imageURL, $caption, $credit, $border, $height, $width) = &get_spanclassC($filename,$n);
	$spanhit = "true";
			print LOGFILE "span center  Image url body is $imageURL \n";
			&GenericImage($imageURL,$caption,$credit,$border,$height,$width,"center");
	$o++; ##### iterate if we have found a span image center
}

##########			end span center

if ($_ =~ m/<table>/) {
	#print "\n $_ \n";
	$output = & get_table($filename);
	$p++; ##### iterate if we have found a table
	$a++;
	#print "\n" . 'table="' . $output . '"' . "\n";
	# push(@MainPar,'image="' . $output . '"');
	next;
}

if ($_ =~ m/<div class="related-content">/) {
$relatedcontent = 1;
print LOGFILE "related content container $filename \n";
$a++;
	$containercounter = 'acscontainer_' . "$a";
	push(@MainPar,  '<' . $containercounter );
	push(@MainPar,    'jcr:primaryType="nt:unstructured"' );
	push(@MainPar,    'sling:resourceType="acs/components/general/acscontainer"' );
    push(@MainPar,    'border="bordered"');
	push(@MainPar,    'color="box-blue"' );
    push(@MainPar,    'round="rounded"' );
    push(@MainPar,    'style="rbc">' ); 
	#print "\n" . 'text="' . $output  . '"' .  "\n";
	$r++;
	$countainercounterPar = 'containerPar';
	push(@MainPar,  	'<' . $countainercounterPar );
	push(@MainPar,    'jcr:primaryType="nt:unstructured"' );
	push(@MainPar,    'sling:resourceType="foundation/components/parsys">' );
	
    

} # end of related content

if ($_ =~ m/^\s*<\/div>.*$/ && $relatedcontent == 1) {	
	push(@MainPar,  	'</' . $countainercounterPar  . '>'  );
	push(@MainPar,  '</' . $containercounter  . '>' );	  
	$relatedcontent = 0;
}

  if ($_ =~ m/<script type="text\/javascript" src="http:.*?FileRetrieve\?ContentID=(\w+_\w+)"><\/script>/ig) {
 # print " start $_ \n";
 		 my $embedder = LWP::UserAgent->new;
		my $JSGET = 'https://wcmscontrib.acs.org/dc/' . $1;
		 my $response = $embedder->get( $JSGET );
		#  print "javascript is $JSGET \n";
		 print LOGFILE  "javascript is $JSGET \n";
	if ($response->is_success) {
	my $contentJS = get($JSGET) or die 'Unable to get page';
	# print " content before is $contentJS \n";
	$contentJS =~ s/(<p>)?document.write(ln)?\(("|'|&quot;|&#39;)?//gi;
	$contentJS =~ s/("|'|&#39;|&quot;)\);(<\/p>)?//gi;
	$contentJS =~ s/\\//gi;
	$contentJS =~ s/</&lt;/gi;
	$contentJS =~ s/"/&quot;/gi;
	chomp($contentJS);
		chomp($contentJS);
	# print " content is $contentJS \n";
	push(@MainPar,  '<embed_' . $s );
	push(@MainPar,    'jcr:primaryType="nt:unstructured"' );
	push(@MainPar,    'sling:resourceType="acs/components/general/embed"' );
	push(@MainPar,    'align="Left"' ); 
    push(@MainPar,    'border="Normal"');
    push(@MainPar,    'round="Normal"' );
    push(@MainPar,    'style="Normal"' ); 
	push(@MainPar,'snippet="' . $contentJS . '">');
	push(@MainPar,  '</embed_' . $s  . '>' );	
	
	}
	$s++
 }                   

# print " I did not match anything $_ \n ";

 } ######### 			end main while loop	##########
 
 
##########			loop thorugh arrays 	##########    

&BuildIt();
&CloseTags();
close(MYOUTFILE);
close(MYARTICLE);
} # end Stellent2CQ    
##################################################################    
#######################    subs   ################################   
##################################################################
    
    sub get_h {
       my $tree = HTML::TreeBuilder->new;
       $tree->parse_file($_[0]);
 	  	  my $headings = "";
 		my @heads = $tree->find_by_tag_name(
 		'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
 		);
 		$real_heads = $heads[$i];
 		$headings = $real_heads->as_HTML;
		## print " this is the header tag" . $headings. "\n";
      $tree->delete;     # clear memory
      return $headings;
  } # end of header sub
  
        sub get_par {
		# print " \n now in get_par this was j $j_prime \n ";
        my $tree = HTML::TreeBuilder->new;
        $tree->parse_file($_[0]);
        my $paragraph = "";
   		my @pars = $tree->look_down(
  		'_tag', 'p'
  		);
 		 $real_pars = $pars[$j];
 		 my $parent = $real_pars->parent;
		 ##  print " before $j is j before paramatch is added in get_par\n";
 		 $real_pars = $pars[$j];
 		 # $paragraph = $real_pars->as_text;  # might be blank
 		 $paragraph = $real_pars->as_HTML;
        $tree->delete;     # clear memory
        return $paragraph;
  } # end of paragraph sub
  
   sub get_list {
   if ($_[1] eq "unordered") {
        my $tree = HTML::TreeBuilder->new;
        $tree->parse_file($_[0]);
        my $list = "";
   		my @ul = $tree->look_down(
  		'_tag', 'ul'
  		);
 		$real_lists = $ul[$k];
 		$list = $real_lists->as_HTML;
        $tree->delete;     # clear memory
        return $list;
	} else {
		my $tree = HTML::TreeBuilder->new;
        $tree->parse_file($_[0]);
        my $list = "";
   		my @ol = $tree->look_down(
  		'_tag', 'ol'
  		);
 		$real_lists = $ol[$q];
 		$list = $real_lists->as_HTML;
        $tree->delete;     # clear memory
        return $list;
		}
    } # end sub list
    
   sub get_blockquote {
        my $tree = HTML::TreeBuilder->new;
        $tree->parse_file($_[0]);
        my $blockquote = "";
   		my @bq = $tree->look_down(
  		'_tag', 'blockquote'
  		);
 		$real_blocks = $bq[$l];
 		$blockquote = $real_blocks->as_HTML;
        $tree->delete;     # clear memory
        return $blockquote;
    } # end sub block quote
	
       sub get_spanclassR {
          my $tree = HTML::TreeBuilder->new;
          $tree->parse_file($_[0]);
		  my $n = $_[1];
          my $spanclass = "";
			my @sc = $tree->look_down('_tag', 'span', 'class', 'image-right');
			$real_spans = $sc[$m];
			$imageURL = $caption = $credit = $border = $height = $width = $alt = "empty" ; 
				@content = "";
				 $num_children = 0;
			if ($real_spans->as_HTML() =~ m/^\s*<span class="image-(right|left|center)">\s*<\/span>\s*$/ig) {
			print ERROR " empty span right $_[0] \n ";
			} else {
                $num_children = $real_spans->content_list();
                @content = $real_spans->content_list();
				 # print " number of children inside $num_children \n";
                  if ($num_children > 0) {
                    for ($item=0; $item <$num_children; $item++) {
                    if (ref $content[$item] and $content[$item]->as_HTML() =~ m/"image-caption"/ig)
                        {
                         $content[$item]->as_HTML() =~              m/"image-caption">(.*)<\/div/ig;           
                        $caption = $1;
                        }
                        elsif (ref $content[$item] and $content[$item]->as_HTML() =~ m/"image-credit"/ig)
                        {
                        $content[$item]->as_HTML() =~              m/"image-credit">(.*)<\/small/ig;           
                        $credit = $1;
                        } elsif  (ref $content[$item] and $content[$item]->as_HTML() =~ m/src="/ig)  
						{
                        $content[$item]->as_HTML() =~ m/src="(.*?\.)(gif|jpg|png)?"/ig;
								$imageURL = "$1$2";	
						# 		print "this should be an image right  $imageURL \n";	
							if ($content[$item]->as_HTML() =~ m/img border="([0-9]+)?"/) {
							$border = $1;
							}	
							if ($content[$item]->as_HTML() =~ m/height="([0-9]+)?"/) {
							$height = $1;
							}
							if ($content[$item]->as_HTML() =~ m/width="([0-9]+)?"/) {
							$width = $1;
							}
							if ($content[$item]->as_HTML() =~ m/alt="(.*?)"+\s/) {
							$alt = $1;
							# print " alt is right $alt \n ";
							}	
                      		
						}
						#	print 	"item is $item \n";					
                    } # end for loop
                  } # end if				
					
			}	# end else
		 print LOGFILE "image url:$imageURL caption:$caption credit:$credit border:$border height:$height width:$width  alt=$alt\n";
 return ($imageURL, $caption, $credit, $border, $height, $width);
			
  } # end class span    
     sub get_spanclassL {
        my $tree = HTML::TreeBuilder->new;
        $tree->parse_file($_[0]);
        my $spanclass = "";
   		my @sc = $tree->look_down('_tag', 'span', 'class', 'image-left');
   		 $real_spans = $sc[$n];
		$imageURL = $caption = $credit = $border = $height = $width = $alt = "empty" ; 
		 		@content = "";
			if ($real_spans->as_HTML() =~ m/^\s*<span class="image-(right|left|center)">\s*<\/span>\s*$/ig) {
			print ERROR " empty span left $_[0] \n ";
			} else {
                $num_children = $real_spans->content_list();
                @content = $real_spans->content_list();

                  if ($num_children > 0) {
                    for ($item=0; $item <$num_children; $item++) {
                    if (ref $content[$item] and $content[$item]->as_HTML() =~ m/"image-caption"/ig)
                        {
                         $content[$item]->as_HTML() =~ m/"image-caption">(.*)<\/div>/ig; 
							if 	($caption eq "empty") {					 
							$caption = $1;
							} else {
							$caption = $caption . " " . $1;
							# print " new caption \n \n $caption \n \n ";
							}
						}
                        elsif (ref $content[$item] and $content[$item]->as_HTML() =~ m/"image-credit"/ig)
                        {
                        $content[$item]->as_HTML() =~              m/"image-credit">(.*)<\/small/ig;           
                        $credit = $1;
                        } elsif  (ref $content[$item] and $content[$item]->as_HTML() =~ m/src="/ig)  
						{
                        $content[$item]->as_HTML() =~ m/src="(.*?\.)(gif|jpg|png)?"/ig;
								$imageURL = "$1$2";	
							# 	print "this should be an image left  $imageURL \n";	
							if ($content[$item]->as_HTML() =~ m/img border="([0-9]+)?"/) {
							$border = $1;
							}	
							if ($content[$item]->as_HTML() =~ m/height="([0-9]+)"?/) {
							$height = $1;
							}
							if ($content[$item]->as_HTML() =~ m/width="([0-9]+)"?/) {
							$width = $1;
							}							
                        	if ($content[$item]->as_HTML() =~ m/alt="(.*?)"+\s/) {
							$alt = $1;
							# print " alt is left $alt \n ";
							}					
						}
						#	print 	"item is $item \n";					
                    } # end for loop
                  } # end if loop 
			} # end else
 print LOGFILE "image url:$imageURL caption:$caption credit:$credit border:$border height:$height width:$width  \n";
 return ($imageURL, $caption, $credit, $border, $height, $width);
		 
  } # end class span
  
     sub get_spanclassC {
        my $tree = HTML::TreeBuilder->new;
        $tree->parse_file($_[0]);
        my $spanclass = "";
   		my @sc = $tree->look_down('_tag', 'span', 'class', 'image-center');
   		 $real_spans = $sc[$p];
		$imageURL = $caption = $credit = $border = $height = $width = $alt = "empty" ; 		 
		 				@content = "";
			if ($real_spans->as_HTML() =~ m/^\s*<span class="image-(right|left|center)">\s*<\/span>\s*$/ig) {
			print ERROR " empty span center $_[0] \n ";
			} else {
                $num_children = $real_spans->content_list();
                @content = $real_spans->content_list();
                  if ($num_children > 0) {
                    for ($item=0; $item <$num_children; $item++) {
                    if (ref $content[$item] and $content[$item]->as_HTML() =~ m/"image-caption"/ig)
                        {
                         $content[$item]->as_HTML() =~              m/"image-caption">(.*)<\/div/ig;           
                        $caption = $1;
                        }
                        elsif (ref $content[$item] and $content[$item]->as_HTML() =~ m/"image-credit"/ig)
                        {
                        $content[$item]->as_HTML() =~              m/"image-credit">(.*)<\/small/ig;           
                        $credit = $1;
                        } elsif  (ref $content[$item] and $content[$item]->as_HTML() =~ m/src="/ig)  
						{
                        $content[$item]->as_HTML() =~ m/src="(.*?\.)(gif|jpg|png)?"/ig;
								$imageURL = "$1$2";	
								# print "this should be an image center  $imageURL \n";	
							if ($content[$item]->as_HTML() =~ m/img border="([0-9]+)?"/) {
							$border = $1;
							}	
							if ($content[$item]->as_HTML() =~ m/height="([0-9]+)"?/) {
							$height = $1;
							}
							if ($content[$item]->as_HTML() =~ m/width="([0-9]+)"?/) {
							$width = $1;
							}							
 							if ($content[$item]->as_HTML() =~ m/alt="(.*?)"+\s/) {
							$alt = $1;
							# print " alt is center  $alt \n ";
							}	                       					
						}
						#	print 	"item is $item \n";					
                    } # end for loop
                  } # end if loop 
				} # end else
 print LOGFILE "image url:$imageURL caption:$caption credit:$credit border:$border height:$height width:$width  \n";
 return ($imageURL, $caption, $credit, $border, $height, $width);
  } # end class span 
 
         sub get_table {
            my $tree = HTML::TreeBuilder->new;
            $tree->parse_file($_[0]);
            my $table = "";
       		my @tbl = $tree->look_down(
       		'_tag', 'table'
  		);
#		foreach (@tbl) {
#		print " table loop  $_ \n";
#		}
   		$real_tables = $tbl[$p];
#		print "real table $real_tables and p as $p\n";
#		print "table as text \n $real_tables->as_text \n";
#		print "table as html \n $real_tables->as_HTML \n";
		if (ref $real_tables->as_HTML) {
		
   		$table = $real_tables->as_HTML;
            $tree->delete;     # clear memory
            return $table;
			} else {
			return "";
			}
  } # end class table
  
  sub Stripping {
  $Z = $/;
  undef $/;
  # print " infile $_[0] \n";
  open (INFILE, "$_[0]") or warn " cant open $_[0] \n";
  $stripfile = "c:\\temp\\stripping";
  open (OUTFILE, ">$stripfile");
  while (<INFILE>)
  {
  
  #take out the various site studio comments
  s/<!--SS_BEGIN_SNIPPET.*?-->//sig;
  s/<!-- SS_BEGIN_SNIPPET\(.*?-->//sig;
  s/<!--SS_END_SNIPPET.*?-->//sig;
  s/<!-- SS_END_SNIPPET.*?-->//sig;
  s/<!--SS_BEGIN_CLOSEREGIONMARKER.*?-->//sig;
  s/<!--SS_BEGIN_CLOSEREGIONMARKER\(.*?-->//sig;
  s/<!--SS_END_CLOSEREGIONMARKER.*?-->//sig;
  s/<!--SS_END_CLOSEREGIONMARKER\(.*?-->//sig;
  s/<!--SS_BEGIN_OPENREGIONMARKER.*?-->//sig;
  s/<!--SS_BEGIN_OPENREGIONMARKER\(.*?-->//sig;
  s/<!--SS_END_OPENREGIONMARKER.*?-->//sig;
  s/<!--SS_END_OPENREGIONMARKER\(.*?-->//sig;
  s/<!--SS_BEGIN_ELEMENT.*?-->//sig;
  s/<!--SS_END_ELEMENT.*?-->//sig;
  s/<COMMENT>//sig;
  s/<\/COMMENT>/""/sig;
  
  #trim white space
  #s/[\t]{1,}?//sig;
  #s/[ ]{2,}?//sig;
  # s/ \n//sig;
  #s/[\n]{3,}?//sig;
  #s/[ ]+</</sig;
  
  #strip out empty paragraphs
  s/<p><\/p>//sig;
  s/<p> <\/p>//sig;
 s/<p>[ ]^?<\/p>//sig; 
 s/<p><br\/>+<\/p>//sig; 
  s/<p><br \/>+<\/p>//sig; 
  # another place I will try and replace xml characters
			
  # strip out breaks
  s/<br \/>//sig;
  

  
  $new = $_; #set variable $new to replaced string
  print OUTFILE $new; #print out replaced string
  }
   close (INFILE) or warn $!;
   close (OUTFILE) or die $!;
  copy("$new","$_[0]");
  $/ = $Z;  
}

sub BuildIt {
my $pwd = cwd();
my $xmldir = $outfile;
print LOGFILE " beginning $xmldir \n";
# print "before: $xmldir \n";

		$xmldir =~ s/\//\\/g;
		my $FromDir = $beginningDir;
		$FromDir =~ s /\\/\\\\/g;
		my $ToDir = $cq5Dir;
		$ToDir  =~ s /\\/\\\\/g;
		$xmldir =~ s/$FromDir/$ToDir/g;  #### just added 8/16
		$xmldir=~ s/\\\\/\\/g;
		$xmldir =~ tr/A-Z/a-z/;

# $xmldir =~ s/$beginningDir/$cq5Dir/;
# print "after: $xmldir \n";
my $xmloutfile = $xmldir . '/' . '.content.xml' ;
 print LOGFILE " \n directory $pwd \n XMLFILE: $xmloutfile \n"; #
  open (XMLFILE, ">$xmloutfile") or print ERROR "cannot open $xmloutfile \n";
	&CloseTags();
	&CreateContentHeader;
 	foreach (@MainPar) {
$output = $_;
$output = &convert($_);
	
 	 	print XMLFILE '				' . $output . "\n";
 	}
  	foreach (@RightPar) {
  	# print " right is $_ \n";
  	 	print XMLFILE '					' . $output . "\n";
 	}
  	foreach (@LeftPar) {
  	 	print XMLFILE  '				' .  $output . "\n";
 	}
  	foreach (@CenterPar) {
  	 	print XMLFILE  '				' .  $output . "\n";
 	}
	&Footer();
	chdir($pwd);
	 print LOGFILE "directory $pwd filename  $outfile  \n";
  #  print " \n directory $pwd and next  $outfile \n \n"; #  good location for fiding things out
   close (XMLFILE);
 } # end build it
 #############################################  start header #######################################################################
  sub CreateContentHeader {
			if ($ArtTitle ne "" && defined $ArtTitle) {
			$ArtTitle = &convert($ArtTitle);
			}
  	    	 print XMLFILE '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
  	    	 print XMLFILE '<jcr:root xmlns:sling="http://sling.apache.org/jcr/sling/1.0" xmlns:cq="http://www.day.com/jcr/cq/1.0" xmlns:jcr="http://www.jcp.org/jcr/1.0" xmlns:mix="http://www.jcp.org/jcr/mix/1.0" xmlns:nt="http://www.jcp.org/jcr/nt/1.0"' . "\n";
			 print XMLFILE '     jcr:primaryType="cq:Page">' . "\n";
  	    	 print XMLFILE '     <jcr:content' . "\n";
			 print XMLFILE ' 		cq:template="/apps/acs/templates/acsArticle"' . "\n";    
			 print XMLFILE '      	cq:lastModifiedBy="admin"' . "\n";
			 print XMLFILE '		jcr:isCheckedOut="{Boolean}true"' . "\n";
			 print XMLFILE '		jcr:mixinTypes="[mix:versionable]"' . "\n";
			 print XMLFILE '		jcr:primaryType="cq:PageContent"' . "\n";
			 print XMLFILE '		jcr:title="' . $ArtTitle . '"' . "\n";
			 print XMLFILE '		articleLayout="2"' ."\n";
			 if ($twocolumn eq "true") {
			 # print XMLFILE '		articleLayout "2"' ."\n";
			 print XMLFILE '		collapseFooter="o0"' ."\n";
			}
			 print XMLFILE '		sling:resourceType="acs/components/pages/acsArticle">' ."\n";
			 			if ($haveimage eq "true") {
					    print XMLFILE '     	       <image' . "\n";
						print XMLFILE '      		   cq:lastModifiedBy="admin"' . "\n";
						print XMLFILE '     	       jcr:primaryType="nt:unstructured"' . "\n";
						print XMLFILE '     	       imageRotate="0"/>' . "\n";
						}

			 print XMLFILE '		<articleContent' ."\n";
			 print XMLFILE '		jcr:primaryType="nt:unstructured"' ."\n";
			 print XMLFILE '		sling:resourceType="foundation/components/parsys">' ."\n";
			 if ($twocolumn eq "true") {
			 print XMLFILE '		<columnbootstrap' ."\n";
			 print XMLFILE '		sling:resourceType="acs/components/general/columnsBootstrap"' ."\n";
			 print XMLFILE '		columnConfiguration="o8x4">' . "\n";;
			print XMLFILE '					<column' . $t  . "\n";
            print XMLFILE '					jcr:primaryType="nt:unstructured"' . "\n";
            print XMLFILE '					sling:resourceType="foundation/components/parsys">' . "\n";
			}

}
sub GenericImage {
# passing:   $imageURL,$caption,$credit,$border,$height,$width,"right"
	my $imagelink = $_[0];
	my $caption = $_[1];
	my $credit = $_[2];
	my $border = $_[3];
	my $height = $_[4];
	my $width = $_[5];
	my $imagefile = basename($_[0]);
	my $Placement = $_[6];
	 print LOGFILE  " from Generic Image: \n filename is $_[0]\n placement is $Placement \n credit is $credit \n caption is $caption  \n end of from generic image \n";
		push(@Array,'<image' . "_$a");
		push(@Array,'jcr:primaryType="nt:unstructured"');
		if ($credit ne "empty") {
		$credit =~ s/</&lt;/ig;
		$credit =~ s/>/&gt;/ig;
		#print " this is the credit \n $credit \n";
		# push(@Array,'jcr:title="' . "$credit" . '"');
		# push(@Array,'alt="' . "$credit" . '"');
		}
		if ($caption ne "empty") {
		$caption =~ s/</&lt;/ig;
		$caption =~ s/>/&gt;/ig;
		#print " this is the caption inside generic  \n $caption \n";
		# push(@Array,'jcr:description="' . "$caption" . '"');
		# push(@Array,'alt="' . "$caption" . '"');
		}		
		push(@Array,'sling:resourceType="acs/components/general/image"');		
		# if ($border ne "empty") {
		#	push(@Array,'border="' . $border . '"');
			push(@Array,'border="' . "Normal" . '"');
		# }	
		# if ($height ne "empty") {
		#	push(@Array,'height="' . $height . '"');
		#}
		#if ($width ne "empty") {
		#push(@Array,'width="' . $width . '"');
		# }
		##### additional variables ########
		 push(@Array,'round="Normal"');
        # push(@Array,'ruleHorizontal="border-bottom"');
        # push(@Array,'style="box-callout"');	
		push(@Array,'style="box-callout"');			
		#   this is where we need to grab the image 
		# push(@Array,'image="' . $imagefile . '"');   #### moved lower
		my $pwd = cwd();
		my $CMSserver = 'https://wcmscontrib.acs.org';
		my $url2get = $CMSserver . $imagelink; 
	#	my $image2save =  $pwd . '/'  . $imagefile . '/'  . $imagefile; # old full directory for image
		my $image2save =  $url4 .  '\_jcr_content\articleContent\\' . "image_$a\\file" ; #  $imagefile; R20
		$image2save =~ s/\//\\/g;
		my $FromDir = $beginningDir;
		$FromDir =~ s /\\/\\\\/g;
		my $ToDir = $cq5Dir;
		$ToDir  =~ s /\\/\\\\/g;
				$image2save =~ s/$FromDir/$ToDir/g;  #### just added 8/16
				$image2save =~ s/\\\\/\\/g;
		# print $image2save . " after \n  \n";
		 my $browser = LWP::UserAgent->new;
		 my $response = $browser->get( $url2get );
	if ($response->is_success) {
		  print LOGFILE " this is the url to get from generic image $url2get and image save place $image2save\n";
		 $image_stub = dirname("$image2save");
		#  print "\n \n $image_stub \n \n ";
		#  print " $url4  is url4 \n";
		$file_dir = $image_stub . '\file.dir\\'; # added R20 for new image requirements
		 if (!-d $image_stub) {
		 $image_stub =~ s/[^:\\0-9a-zA-Z_-]+//g; # strip out all none standard characters
		 mkpath("$image_stub") or print ERROR " Can not make image stub $image_stub \n";
		 mkpath ("$file_dir") or print ERROR " Can not make image stub $file_dir \n";
		 }
		 $FinalImageFile = $file_dir . '.content.xml' ;
		 copy($BegImageFile, $FinalImageFile) or print ERROR "Copy failed: $!";
		 getstore($url2get, $image2save) or print ERROR  'Unable to get page $image2save \n'; #######################################################################
		# $image2save =~ m/\\jcr_root\\(.*)/
		# $image2save =~ s/\\/\//g;
			if ($caption ne "empty") {
				$caption =~ s/</&lt;/g;
				$caption =~  s/>/&gt;/g;
				$caption =~    s/'/&pos;/g;
				$caption =~ s/"/&quot;/g;
			$caption = &convert($caption);
				# push(@Array,'fileReference="' . $image2save . '"'); # Removed R20
					if ($Placement eq "right") {
					push(@Array,'imagealign="Right"'); 
					} elsif ($Placement eq "left") {
					push(@Array,'imagealign="Left"'); 
					} 	elsif ($Placement eq "center") {
					push(@Array,'imagealign="Center"'); 
					}
				push(@Array,'jcr:description="' . $caption . '"');
				push(@Array,'textisRich="true">');  ####  chan
			} 			
			elsif ($credit ne "empty") 
			{
				$credit =~ s/</&lt;/g;
				$credit =~  s/>/&gt;/g;
				$credit =~    s/'/&pos;/g;
				$credit =~ s/"/&quot;/g;
			 $credit = &convert($credit);
				# push(@Array,'fileReference="' . $image2save . '"'); # removed R20
					if ($Placement eq "right") {
					push(@Array,'imagealign="Right"'); 
					} elsif ($Placement eq "left") {
					push(@Array,'imagealign="Left"'); 
					} 	elsif ($Placement eq "center") {
					push(@Array,'imagealign="Center"'); 
					}
				push(@Array,'imageCredit="' . $credit . '"');
				push(@Array,'textisRich="true">');  ####  change
				# $Title = $1;
			}
			else 
			{
					if ($Placement eq "right") {
					push(@Array,'imagealign="Right">'); 
					} elsif ($Placement eq "left") {
					push(@Array,'imagealign="Left">'); 
					} 	elsif ($Placement eq "center") {
					push(@Array,'imagealign="Center">'); 
					}
			# push(@Array,'fileReference="' . $image2save . '"/>'); removed R20
			}
			push(@Array,'<file/>');
			push(@Array,'</image' . "_$a>");
			push(@MainPar,@Array);	
			@Array = ();
	} else {
	print ERROR "Can't get $url2get -- ", $response->status_line . " $cwd \n";
	}
}
			 
sub FindMeta {
			my $extension = "";
			my $title = "";
			my $url = "";
# print " $_[0] and $_[1] this is what was passed to findmeta\n ";
my $list = $_[0]; # list of all metadata on one line
	local $/; #Enable 'slurp' mode
	open my $fh, "<", "$list";
	$content = <$fh>;
	close $fh;
	@ArtData  = split('},', $content);
		my $match = "false";
		for my $elem (@ArtData) {
	#   print $elem . "\n";
		$elem =~ m/([A-Za-z0-9]*_\d*?)":{ "Type":"Article","Title":"(.*)?","Web Extension":"([A-Za-z]*)?","WebSiteSection":"PublicWebSite:\d*/;
		
			if ($_[1] eq $1) {
			# print "match content id $1 title $2 and  ext  $3 \n";
			 $extension = $3;
			 $title = $2;
			 $url = $2;
			$title =~ s/:|\///g;
			# print "\n original url $url \n";
			print LOGFILE " this is original url  $url from find meta \n";
			$url =~ s/\s+/-/g;
			$url =~ s/-{2,5}/-/g;
			$url2 = $url;
			# print "\n this is url after space sub $url2\n";
			$url2 =~ s/,|\?|&|:|\\|"|\///g; # this is the replacement for titles should probably add all non safe URL filesystem encoding characters
			$url2 =~ s/[^0-9a-zA-Z_-]+//g; # strip out all none standard replaces above really
			$url3 = $url2;
			print LOGFILE " this is processed url3 $url3 from find meta \n";
			$match = "true";
			last;
			}  
		}
		##### make sure it doesnt exist first and also check extensions for making dir
		if ($extension eq "doc" || $extension eq "docx" || $extension eq "pdf") {
				$url4 = cwd() . '\\' . $url3;		
					# print "url4 before $url4 \n";
					
							$url4 =~ s/\//\\/g;
							my $FromDir = $beginningDir;
							$FromDir =~ s /\\/\\\\/g;
							my $ToDir = $cq5Dir;
							$ToDir  =~ s /\\/\\\\/g;
							$url4 =~ s/$FromDir/$ToDir/g;  #### just added 8/16
							$url4=~ s/\\\\/\\/g;	
							$url4 =~ tr/A-Z/a-z/;
							
				# $url4 =~ s/$beginningDir/$cq5Dir/;
				# print "\n url4 after $url4 \n";
				print LOGFILE "url4 which will be created $url4 \n";
				if(!-e "$url4" && $match eq "true" ) {
				mkpath($url4);
				}
				
				
		}
		my $cwd = cwd();
		
		if ($match eq "true") {
		print LOGFILE " returning from metadata $_[1]  title:$title, url:$url3, extention:$extension \n"; #  can probably do work from here
		
		return ($title, $url3, $extension, $cwd);
	}	elsif ($_[1] eq "index.htm") {
	return ($_[1], "index.html", "doc", $cwd);
	}
	else {
	print ERROR "miss here so content is not in list $_[1] \n";
	return ("miss", "miss", "miss", "miss");
	}
}
sub CloseTags {
	if ($twocolumn eq "true") {
	push(@MainPar,'</columnbootstrap>' . "\n");
	}
	push(@MainPar,'</articleContent>' . "\n");
	
	if ($imagerighthit eq "true") {
		push(@RightPar,'</rightPar>');
	}
	if ($imagelefthit eq "true") {
		push(@LeftPar,'</leftPar>');
	}
	if ($imagecenterhit eq "true") {
		push(@CenterPar,'</centerPar>');
	}

}


sub Footer {
  	    	 print XMLFILE '</jcr:content>' . "\n";
  	    	 	foreach $folder (@Add2End) {
				print "####################################################################################### \n $folder \n";
				pause(3);
  	    	 		 print XMLFILE '<' . "$folder" . '/>'  . "\n";
  	    	 	}
  	    	 	
		 print XMLFILE '</jcr:root>';
$imagerighthit = "false" ;
$imagelefthit = "false";
$imagecenterhit = "false";
# $sum = $i + $j + $k + $l + $m + $n + $o + $p + $q;
 # print LOGFILE "total is $a and sum is $sum \n";

} # end footer

sub isXML
{
# print $_ . "\n";
    if ($_ =~ m/\.content.xml$/ ) {
	$pwd = cwd();
	$file = $pwd . '/' . $_;
		@ARRAYFILE = ();	
opendir(DIR, $pwd) or print ERROR " couldnt open $pwd \n";
		while (my $directory = readdir(DIR)) {
		next if (($directory =~ m/^\./) || ($directory eq "_jcr_content"));
		next unless (-d "$pwd/$directory");
		push (@ARRAYFILE, $directory);
		}

			rename $file, "$file.orig";
			open ORIG, "<",  "$file.orig";
			 open FILE, ">", $file;
					foreach $line (<ORIG>) {
						if ($line =~ m/<\/jcr:content>/) {
						#print " match  at $line \n";
						print FILE $line;
							foreach (@ARRAYFILE) {
								print FILE "$_ \n";
								}
								print FILE '</jcr:root>';
								last;		
						}  else {
						print FILE $line;
						}
						
					}
			
	} # end if			

}

sub convert 
{

my $input = $_[0];
$input =~ s/&ndash/&#8211/gi; # <!-- en dash, U+2013 ISOpub -->' . "\n";
$input =~ s/&mdash/&#8212/gi; #  <!-- em dash, U+2014 ISOpub -->' . "\n";
$input =~ s/&lsquo/&#8216/gi; # <!-- left single quotation mark, U+2018 ISOnum -->' . "\n";
$input =~ s/&rsquo/&#8217/gi; # <!-- right single quotation mark, U+2019 ISOnum -->' . "\n";
$input =~ s/&sbquo/&#8218/gi; # <!-- single low-9 quotation mark,  U+201A NEW -->' . "\n";
$input =~ s/&ldquo/&#8220/gi; # <!-- left double quotation mark, U+201C ISOnum -->' . "\n";
$input =~ s/&rdquo/&#8221/gi; #<!-- right double quotation mark, U+201D ISOnum -->' . "\n";
$input =~ s/&copy/&#169/gi; #<!-- copyright -->' . "\n";
$input =~ s/&oacute/&#243/gi; #<-- unknown -->
$input =~ s/&nbsp/&#160/gi; #<-- nonbreaking space -->
$input =~ s/&pound/&#163/gi; #<-- pound  -->
$input =~ s/&eacute/&#201/gi; #<-- latin e -->
$input =~ s/&aacute/&#193/gi; #<-- latin a -->
$input =~ s/&iacute/&#205/gi; #<-- latin i -->
$input =~ s/&ntilde/&#209/gi; #<-- latin n -->
$input =~ s/&uacute/&#218/gi; #<-- latin u -->
$input =~ s/&Uuml/&#220/gi; #<-- latin i -->
$input =~ s/&minus;/&#8722;/g; #<-- latin a -->
$input =~ s/&Yacute;/&#221;/g; #<-- latin n -->
$input =~ s/&bull;/&#8226;/g; #<-- latin u -->	
$input =~ s/&hellip;/&#8230;/g; #<-- latin n -->
$input =~ s/&THORN;/&#222;/g; #<-- latin u -->	
$input =~ s/&OElig;/&#338;/g;
$input =~ s/&oelig;/&#339;/g;
$input =~ s/&Scaron;/&#352;/g;
$input =~ s/&scaron;/&#353;/g;
$input =~ s/&Yuml;/&#376;/g;
$input =~ s/&fnof;/&#402;/g;
$input =~ s/&circ;/&#710;/g;
$input =~ s/&tilde;/&#732;/g;
$input =~ s/&ensp;/&#8194;/g;
$input =~ s/&emsp;/&#8195;/g;
$input =~ s/&thinsp;/&#8201;/g;
$input =~ s/&zwnj;/&#8204;/g;
$input =~ s/&zwj;/&#8205;/g;
$input =~ s/&lrm;/&#8206;/g;
$input =~ s/&rlm;/&#8207;/g;
$input =~ s/&ndash;/&#8211;/g;
$input =~ s/&mdash;/&#8212;/g;
$input =~ s/&lsquo;/&#8216;/g;
$input =~ s/&rsquo;/&#8217;/g;
$input =~ s/&sbquo;/&#8218;/g;
$input =~ s/&ldquo;/&#8220;/g;
$input =~ s/&rdquo;/&#8221;/g;
$input =~ s/&bdquo;/&#8222;/g;
$input =~ s/&dagger;/&#8224;/g;
$input =~ s/&Dagger;/&#8225;/g;
$input =~ s/&bull;/&#8226;/g;
$input =~ s/&hellip;/&#8230;/g;
$input =~ s/&permil;/&#8240;/g;
$input =~ s/&prime;/&#8242;/g;
$input =~ s/&Prime;/&#8243;/g;
$input =~ s/&lsaquo;/&#8249;/g;
$input =~ s/&rsaquo;/&#8250;/g;
$input =~ s/&oline;/&#8254;/g;
$input =~ s/&euro;/&#8364;/g;
$input =~ s/&trade;/&#8482;/g;
$input =~ s/&larr;/&#8592;/g;
$input =~ s/&uarr;/&#8593;/g;
$input =~ s/&rarr;/&#8594;/g;
$input =~ s/&darr;/&#8595;/g;
$input =~ s/&harr;/&#8596;/g;
$input =~ s/&crarr;/&#8629;/g;
$input =~ s/&lceil;/&#8968;/g;
$input =~ s/&rceil;/&#8969;/g;
$input =~ s/&lfloor;/&#8970;/g;
$input =~ s/&rfloor;/&#8971;/g;
$input =~ s/&loz;/&#9674;/g;
$input =~ s/&spades;/&#9824;/g;
$input =~ s/&clubs;/&#9827;/g;
$input =~ s/&hearts;/&#9829;/g;
$input =~ s/&diams;/&#9830;/g;
$input =~ s/&Beta;/&#914;/g;
$input =~ s/&Gamma;/&#915;/g;
$input =~ s/&Delta;/&#916;/g;
$input =~ s/&Epsilon;/&#917;/g;
$input =~ s/&Zeta;/&#918;/g;
$input =~ s/&Eta;/&#919;/g;
$input =~ s/&Theta;/&#920;/g;
$input =~ s/&Iota;/&#921;/g;
$input =~ s/&Kappa;/&#922;/g;
$input =~ s/&Lambda;/&#923;/g;
$input =~ s/&Mu;/&#924;/g;
$input =~ s/&Nu;/&#925;/g;
$input =~ s/&Xi;/&#926;/g;
$input =~ s/&Omicron;/&#927;/g;
$input =~ s/&Pi;/&#928;/g;
$input =~ s/&Rho;/&#929;/g;
$input =~ s/&Sigma;/&#931;/g;
$input =~ s/&Tau;/&#932;/g;
$input =~ s/&Upsilon;/&#933;/g;
$input =~ s/&Phi;/&#934;/g;
$input =~ s/&Chi;/&#935;/g;
$input =~ s/&Psi;/&#936;/g;
$input =~ s/&Omega;/&#937;/g;
$input =~ s/&alpha;/&#945;/g;
$input =~ s/&beta;/&#946;/g;
$input =~ s/&gamma;/&#947;/g;
$input =~ s/&delta;/&#948;/g;
$input =~ s/&epsilon;/&#949;/g;
$input =~ s/&zeta;/&#950;/g;
$input =~ s/&eta;/&#951;/g;
$input =~ s/&theta;/&#952;/g;
$input =~ s/&iota;/&#953;/g;
$input =~ s/&kappa;/&#954;/g;
$input =~ s/&lambda;/&#955;/g;
$input =~ s/&mu;/&#956;/g;
$input =~ s/&nu;/&#957;/g;
$input =~ s/&xi;/&#958;/g;
$input =~ s/&omicron;/&#959;/g;
$input =~ s/&pi;/&#960;/g;
$input =~ s/&rho;/&#961;/g;
$input =~ s/&sigmaf;/&#962;/g;
$input =~ s/&sigma;/&#963;/g;
$input =~ s/&tau;/&#964;/g;
$input =~ s/&upsilon;/&#965;/g;
$input =~ s/&phi;/&#966;/g;
$input =~ s/&chi;/&#967;/g;
$input =~ s/&psi;/&#968;/g;
$input =~ s/&omega;/&#969;/g;
$input =~ s/&thetasym;/&#977;/g;
$input =~ s/&upsih;/&#978;/g;
$input =~ s/&piv;/&#982;/g;
$input =~ s/&forall;/&#8704;/g;
$input =~ s/&part;/&#8706;/g;
$input =~ s/&exist;/&#8707;/g;
$input =~ s/&empty;/&#8709;/g;
$input =~ s/&nabla;/&#8711;/g;
$input =~ s/&isin;/&#8712;/g;
$input =~ s/&notin;/&#8713;/g;
$input =~ s/&ni;/&#8715;/g;
$input =~ s/&prod;/&#8719;/g;
$input =~ s/&sum;/&#8721;/g;
$input =~ s/&minus;/&#8722;/g;
$input =~ s/&lowast;/&#8727;/g;
$input =~ s/&radic;/&#8730;/g;
$input =~ s/&prop;/&#8733;/g;
$input =~ s/&infin;/&#8734;/g;
$input =~ s/&ang;/&#8736;/g;
$input =~ s/&and;/&#8743;/g;
$input =~ s/&or;/&#8744;/g;
$input =~ s/&cap;/&#8745;/g;
$input =~ s/&cup;/&#8746;/g;
$input =~ s/&int;/&#8747;/g;
$input =~ s/&there4;/&#8756;/g;
$input =~ s/&sim;/&#8764;/g;
$input =~ s/&cong;/&#8773;/g;
$input =~ s/&asymp;/&#8776;/g;
$input =~ s/&ne;/&#8800;/g;
$input =~ s/&equiv;/&#8801;/g;
$input =~ s/&le;/&#8804;/g;
$input =~ s/&ge;/&#8805;/g;
$input =~ s/&sub;/&#8834;/g;
$input =~ s/&sup;/&#8835;/g;
$input =~ s/&nsub;/&#8836;/g;
$input =~ s/&sube;/&#8838;/g;
$input =~ s/&supe;/&#8839;/g;
$input =~ s/&oplus;/&#8853;/g;
$input =~ s/&otimes;/&#8855;/g;
$input =~ s/&perp;/&#8869;/g;
$input =~ s/&sdot;/&#8901;/g;
$input =~ s/&iexcl;/&#161;/g;
$input =~ s/&cent;/&#162;/g;
$input =~ s/&pound;/&#163;/g;
$input =~ s/&curren;/&#164;/g;
$input =~ s/&yen;/&#165;/g;
$input =~ s/&brvbar;/&#166;/g;
$input =~ s/&sect;/&#167;/g;
$input =~ s/&uml;/&#168;/g;
$input =~ s/&copy;/&#169;/g;
$input =~ s/&ordf;/&#170;/g;
$input =~ s/&laquo;/&#171;/g;
$input =~ s/&not;/&#172;/g;
$input =~ s/&shy;/&#173;/g;
$input =~ s/&reg;/&#174;/g;
$input =~ s/&macr;/&#175;/g;
$input =~ s/&deg;/&#176;/g;
$input =~ s/&plusmn;/&#177;/g;
$input =~ s/&sup2;/&#178;/g;
$input =~ s/&sup3;/&#179;/g;
$input =~ s/&acute;/&#180;/g;
$input =~ s/&micro;/&#181;/g;
$input =~ s/&para;/&#182;/g;
$input =~ s/&middot;/&#183;/g;
$input =~ s/&cedil;/&#184;/g;
$input =~ s/&sup1;/&#185;/g;
$input =~ s/&ordm;/&#186;/g;
$input =~ s/&raquo;/&#187;/g;
$input =~ s/&frac14;/&#188;/g;
$input =~ s/&frac12;/&#189;/g;
$input =~ s/&frac34;/&#190;/g;
$input =~ s/&iquest;/&#191;/g;
$input =~ s/&times;/&#215;/g;
$input =~ s/&divide;/&#247;/g;
$input =~ s/&Aring;/&#197;/g;
$input =~ s/&auml;/&#228;/g;
$input =~ s/&iuml;/&#239;/g;
$input =~ s/&ocirc;/&#212;/g;
$input =~ s/&egrave;/&#232;/g;
$input =~ s/&ograve;/&#242;/g;
$input =~ s/&atilde;/&#227;/g;
$input =~ s/&ccedil;/&#229;/g;
$input =~ s/&aring;/&#163;/g;
$input =~ s/&euml;/&#235;/g;
$input =~ s/&auml;/&#228;/g;
$input =~ s/&ouml;/&#246;/g;
$input =~ s/&acirc;/&#226;/g;
$input =~ s/&ldquo;/&#8220;/g;
return $input;
}

sub delXML
{
# print $_ . "\n";
    if ($_ =~ m/\.content\.xml.orig$/ ) {
	$delfile = $_;
	unlink($delfile) ;
	}
	
} 


open PDFMAP, ">>$PDFMAPPING" || warn " could not open pdf map ";
  for my $key ( keys %PDFhash ) {
        my $value = $PDFhash{$key};
         print PDFMAP "$key => $value\n";
    }
close(PDFMAP);
 close(ERROR);
 close(FILES);
	print LOGFILE " doc  $doccounter pdf  $pdfcounter other  $othercounter \n" ;
	print time - $^T;
	print LOGFILE " number converted $final_counter \n";