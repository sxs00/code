#!c:/strawberry/perl/bin/perl.exe 
 use File::Find;
 my $TempDir = 'g:\logs\\';
 my $DirList = $TempDir . 'DirectoryAndContentID.txt';
 
 
 
 sub process_dir {
 if (-d $_) {
 print FILE $File::Find::name, "/", "\n";
 } else {
 print FILE $_ , "\n";
 }
 }
 
 if (-e $DirList) {
 unlink $DirList;
 }
	open FILE, ">$DirList" or die $!;
 
 find(\&process_dir, 'g:\input\\');
 close(FILE);