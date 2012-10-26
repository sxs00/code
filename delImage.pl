#!c:/strawberry/perl/bin/perl.exe 
  use warnings;
  use File::Copy;
  use File::Basename;
  use File::Find;
  use File::Path qw(mkpath);

$cq5Dir = 'G:\acs\structure\jcr_root\content\acsstevesiteconfiguration\acs-steve-home-page';
find(\&isImage, $cq5Dir);

sub isImage {
if ($_ =~ m/\w.jpg$/ || m/\.content.xml.orig/ || m/\w.pdfffff$/) {
print " image $_ \n";
 unlink $_;
}
}