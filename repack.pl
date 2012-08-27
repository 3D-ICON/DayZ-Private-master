#!/usr/bin/perl

use File::Path qw(make_path);

# Ensure required directories exist
make_path(
	'./deploy/@Bliss/addons',
	'./deploy/@BlissLingor/addons',
	'./deploy/MPMissions'
);

my $baseDir = "./bliss/missions";

# Set OS-specific options and copy blisshive.dll into place
my $repackCmd, $copyCmd;
my $editOpts = "";
if ($^O eq "linux") {
	$repackCmd = "wine util/cpbo.exe";
	system("cp ./util/blisshive.dll ./deploy/\@Bliss");
	system("cp ./util/blisshive.dll ./deploy/\@BlissLingor");
} elsif ($^O eq "MSWin32") {
	$repackCmd = "util/cpbo.exe";
	system("copy .\\util\\blisshive.dll .\\deploy\\\@Bliss");
	system("copy .\\util\\blisshive.dll .\\deploy\\\@BlissLingor");
	$editOpts = ".bak";
}

# Pack the server files
system("${repackCmd} -y -p ./bliss/dayz_server ./deploy/\@Bliss/addons/dayz_server.pbo");
system("${repackCmd} -y -p ./bliss/dayz_lingor ./deploy/\@BlissLingor/addons/dayz_server.pbo");

# Find our mission directories
opendir(my $dh, $baseDir) or die ('Could not open ./bliss/missions!');
@missions = grep { !/^\.\.?$/ } readdir($dh);
closedir($dh);

# Replace the instance ID dynamically
foreach my $dir (@missions) {
	my $path = "${baseDir}/${dir}";
	if (-d $path) {	
		if ($dir =~ /dayz_([0-9]{1,}).*/) {
			my $id = $1;
			system("perl -pi${editOpts} -e \"s/dayZ_instance\\s=\\s[0-9]*/dayZ_instance = ${id}/\" ${path}/init.sqf");
			print "Set instance id to ${id} for ${path}/init.sqf\n";
		}
		# Clean up init.sqf.bak in Windows only
		if ($^O eq "MSWin32") {
			(my $winPath = $path) =~ s/\//\\/g;
			system("del \"${winPath}\\init.sqf.bak\"");
		}
		system("${repackCmd} -y -p ${path} ./deploy/MPMissions/${dir}.pbo");
	}
}
