#!/usr/bin/perl
# Sets the projec directory
$PROJECT="/home/boincadm/projects/DrugDiscovery/";
#$df_command="df | head -n 3 | tail -n 1 | awk \'{ print substr( \$0, length(\$0) - 6, 4 ) }\'";
#print $df_command ."\n";
#$df=system($df_command);

#print $wu_name."\n";
#use the Cwd methods
        use Cwd;
#save the original directory path
        my $orig_dir = Cwd::abs_path;
print "my directory: " . $orig_dir."\n";
chdir($PROJECT);
$ga=$ARGV[0];
chomp($ga);

$target=$ARGV[1];
chomp($target);
$bt=substr($target, 10);

# Sets the ligand file index of ligands we have
$ligand_index=$ARGV[2];
chomp($ligand_index);
#$ligand_index=$PROJECT.$ligand_index;
print $ligand_index."\n";

$ligand_dir=$ARGV[3];
chomp($ligand_dir);
#$ligand_dir=$PROJECT.$ligand_dir;
print $ligand_dir."\n";

# opens the ligand file index
open (LIGAND_FILE,$ligand_index) or die ("Error trying to open the ligand file.\n");
# Skipping all receptors yet processed for this ligand


#Set Variables
#Project Directory
$rsc_fpops_est = ($ga * 1955928030229 * 0.1);
$rsc_fpops_bound = ($rsc_fpops_est * 1000);
$delay_bound = ($rsc_fpops_est * 5);
$weight = $ga * 10;

#sleep(10);

# Sets the ligand file index of ligands we have
#$ligand_file_name="/home/boincadm/projects/DrugDiscovery/bin/concord_index.txt";

# opens the ligand file index
open (LIGAND_FILE,$ligand_index) or die ("Error trying to open the ligand file.\n");
# Skipping all receptors yet processed for this ligand

# Reads the substring of the job file takes off the last 4 characters
#$job=substr($job_file, 0, length($job_file)-4);

# prints the output so we can debug
$old_ligand="";

# go through the list of ligands from that ligand index
 do {$new_ligand = <LIGAND_FILE>; 
	chomp ($new_ligand);
print $new_ligand."\n";
$df=`df | head -n 3 | tail -n 1 | awk \'{ print substr( \$0, length(\$0) - 4, 2 ) }\'`;
chomp($df);
$df=$df-1;
print $df."% full\n";
if ($df >70) {
print "over 70% full \n";
sleep(3600);
}

  my $range = 1000000;
  my $seed = int(rand($range));
  print $seed . "\n";


$job="<job_desc>
    <task>
        <application>unzip.exe</application>
        <command_line> -qq -o \"./MGLTools*.zip\" -d \".\"</command_line>
        <weight>1</weight>
    </task>
    <task>
        <application>./Python25/python.exe</application>
        <command_line>make_sitecustomize.py \".\"</command_line>
        <weight>1</weight>
    </task>
    <task>
        <application>./Python25/python.exe</application>
        <command_line>\"./MGLToolsPckgs/Support/sitecustomize.py\"</command_line>
        <weight>1</weight>
    </task>
    <task>
        <application>./Python25/python.exe</application>
        <command_line>\"./MGLToolsPckgs/AutoDockTools/Utilities24/prepare_ligand4.py\" -l ligand.mol2 -o ligand.pdbqt</command_line>
        <weight>1</weight>
    </task>
    <task>
        <application>./Python25/python.exe</application>
        <command_line>\"./MGLToolsPckgs/AutoDockTools/Utilities24/prepare_receptor4.py\" -U nphs_lps_waters -r receptor.pdb -o receptor.pdbqt</command_line>
        <weight>1</weight>
    </task>
    <task>
        <application>./Python25/python.exe</application>
        <stdout_filename>stdout</stdout_filename>
        <stderr_filename>stderr</stderr_filename>
        <command_line>\"./MGLToolsPckgs/AutoDockTools/Utilities24/prepare_gpf4.py\" -l ligand.pdbqt -r receptor.pdbqt -p custom_parameter_file=1 -p parameter_file=AD4_parameters.dat</command_line>
        <weight>1</weight>
    </task>
    <task>
        <application>./Python25/python.exe</application>
        <stdout_filename>stdout</stdout_filename>
        <stderr_filename>stderr</stderr_filename>
        <command_line>\"./MGLToolsPckgs/AutoDockTools/Utilities24/prepare_dpf4.py\" -l ligand.pdbqt -r receptor.pdbqt -p compute_unbound_extended_flag=0 -p ga_run=".$ga." -p seed=".$seed."</command_line>
        <weight>1</weight>
    </task>
    <task>
        <application>autogrid</application>
        <stdout_filename>stdout</stdout_filename>
        <stderr_filename>stderr</stderr_filename>
        <command_line> -p receptor.gpf -l out.glg </command_line>
        <weight>1</weight>
    </task>
    <task>
        <application>autodock</application>
        <stdout_filename>stdout</stdout_filename>
        <stderr_filename>stderr</stderr_filename>
        <command_line> -p ligand_receptor.dpf -l out.dlg</command_line>
        <weight>".$weight."</weight>
        <fraction_done_filename>progress.txt</fraction_done_filename>
    </task>
    <task>
        <application>7za.exe</application>
        <stdout_filename>stdout</stdout_filename>
        <stderr_filename>stderr</stderr_filename>
        <command_line> a out.7z out.dlg out.glg receptor.gpf ligand_receptor.dpf job.xml</command_line>
        <weight>1</weight>
    </task>
</job_desc>";


#change to new directory
        chdir($PROJECT);



# error check to make sure the ligand file has data
if (length($new_ligand) > 1) {

#print $job ."\n";
$ligand=substr($new_ligand,0,length($new_ligand)-8);
print $new_ligand."\n";
#sleep(10);
print "project ".$PROJECT."\n";

$ARG="rm -f ".$PROJECT."/job_".$ga.".xml";
print $ARG."\n";
system($ARG);

        open (MYFILE, ">>".$PROJECT."/job_".$ga.".xml");
        print MYFILE $job."\n";
        close (MYFILE);

$ARG="cp ".$PROJECT.$target." ".$PROJECT."tmp_vps/receptor.pdb";
print $ARG."\n";
system($ARG);

$ARG="cp ".$ligand_dir."/".$new_ligand." ".$PROJECT."tmp_vps/ligand.pdb";
print $ARG."\n";
system($ARG);

$ARG="/usr/local/NAMD_CVS_Linux-x86_64/psfgen < ".$PROJECT."bin/psfgen_ligand.in";
print $ARG."\n";
system($ARG);

$ARG="/usr/local/NAMD_CVS_Linux-x86_64/psfgen < ".$PROJECT."bin/psfgen_receptor.in";
print $ARG."\n";
system($ARG);

# create a time stamp
$time=`date '+%s%N'`;
chomp ($time);

# copy the ligand file from our ligand directory and place in download. Note simply copy and paste wont work
# BOINC requires you place input in a special directory that is specified by dir_hier_path
$ARG="cp ".$ligand_dir."/".$new_ligand." \`/home/boincadm/projects/DrugDiscovery/bin/dir_hier_path  asgn_".$ligand."_".$time.".txt\`";
print $ARG ."\n";

# Use system because other methods of running system commands will not wait until termination.
# For example if you run backtick with these copies, files will not be in the download directory when expected
system($ARG);

# Copy the job file
$ARG="mv ".$PROJECT."job_".$ga.".xml \`/home/boincadm/projects/DrugDiscovery/bin/dir_hier_path asgn_job_".$ga."_".$time.".txt\`";
print $ARG ."\n";
system($ARG);

# copy the protein!
$ARG="cp ".$PROJECT.$target." \`/home/boincadm/projects/DrugDiscovery/bin/dir_hier_path asgn_receptor.pdb_".$time.".txt\`";
print $ARG ."\n";
system($ARG);

$ARG="mv ".$PROJECT."tmp_vps/receptor.psf  \`/home/boincadm/projects/DrugDiscovery/bin/dir_hier_path asgn_receptor.psf_".$time.".txt\`";
print $ARG ."\n";
system($ARG);

$ARG="mv ".$PROJECT."tmp_vps/ligand.psf \`/home/boincadm/projects/DrugDiscovery/bin/dir_hier_path asgn_ligand.psf_".$time.".txt\`";
print $ARG ."\n";
system($ARG);

$ARG="mv ".$PROJECT."tmp_vps/ligand.pdb \`/home/boincadm/projects/DrugDiscovery/bin/dir_hier_path asgn_ligand.pdb_".$time.".txt\`";
print $ARG ."\n";
system($ARG);
# Now we create the workunit!!!! we give it a name specific to the job file_ligand_timestamp
$ARG=$PROJECT."bin/create_work -appname autodock_mgl_beta -wu_name asgn_autodock_ga_run_".$ga."_bt_".$bt."_lig_".$ligand."_ts_".$time." -wu_template /home/boincadm/projects/DrugDiscovery/templates/ad_wu_mgl -result_template ../templates/ad_mgl_result --rsc_fpops_est ".$rsc_fpops_est." --rsc_fpops_bound ".$rsc_fpops_bound." --delay_bound ".$delay_bound."  --assign_team_all 557 asgn_".$ligand."_".$time.".txt asgn_receptor.pdb_".$time.".txt asgn_job_".$ga."_".$time.".txt asgn_receptor.psf_".$time.".txt asgn_ligand.psf_".$time.".txt asgn_ligand.pdb_".$time.".txt";
print $ARG ."\n";
system($ARG);

sleep(1);
# summary_job4.txt";
# pal_wnt_bind.txt";

	#print $ARG3 . "\n";

	# runs the create project script
	#system($ARG3) == 0
        #or die "system @ARG3 failed: $?";
	#sleep(10);
}

    } while ($ligand ne $old_ligand);

close (LIGAND_FILE);

chdir($orig_dir);

