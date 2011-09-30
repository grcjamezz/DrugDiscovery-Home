#!/usr/bin/perl -w
#Check if already running

$receptor_gro=$ARGV[0];

$ARG="date";
print $ARG."\n";
system($ARG);

$check = system("ps ax | grep mdrun.pl | wc -l");
chomp($check);
print "Checking if script is running\n";
if ($check > 3) {
print "Already running\n";
exit 0;
}

#Set Variables
#Project Directory
#$steps=50000;
$nsteps = 2500000;
$steps=50000;
$start=0;
$end = $start + $steps;
$nstxout=($steps * 0.10);
$nstvout=($steps * 0.10);
$nstxtcout=($steps * 0.10);
$rsc_fpops_est = ($steps * 319500000);
$rsc_fpops_bound = ($rsc_fpops_est * 1000);
$rsc_memory_bound = 500000000;
$delay_bound = ($steps * 7);
#$delay_bound = ($steps * 70);
$PROJECT="/home/boincadm/projects/DrugDiscovery";
$OPS=$PROJECT."/html/ops";

        $time=`date '+%s%N'`;
        chomp ($time);

$job_file = "
<job_desc>
    <task>
        <application>mdrun.exe</application>
        <command_line> -v -x -c -o -e -cpi md.cpt -cpt 1 -deffnm md</command_line>
        <weight>100</weight>
        <fraction_done_filename>progress.txt</fraction_done_filename>
    </task>
    <task>
        <application>7za.exe</application>
        <weight>1</weight>
        <command_line> a -y out.7z Ligand.acpypi.7z *.log *.tpr *.gro *.mdp *.edr *.cpt job.xml *.xtc *.top *.itp</command_line>
    </task>
</job_desc>
";

$make_ndx = "0 q ";
$protein_lig = "protein LIG ";
$g_energy = "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ";

#use the Cwd methods
        use Cwd;
#save the original directory path
        my $orig_dir = Cwd::abs_path;
#clean the path string
        chomp($OPS);
#change to new directory
        chdir($OPS);

#change to original 
        chdir($orig_dir);

#remove old assignment files

#Sample Results Directory
$results=$PROJECT."/sample_results";
$tmp=$results."/tmp";

if (-d $tmp) {
system("rm -rf ".$tmp);
}

$create_tmp="mkdir ".$tmp;
print $create_tmp . "\n";
system($create_tmp);

#Change to cp for asgn
$mv_to_tmp="mv ".$results."/autodock_ga_run_10_bt_1ijy*.7z ".$tmp;
print $mv_to_tmp . "\n";
system($mv_to_tmp);

#All Priority groups in sample_results directory
@files = </home/boincadm/projects/DrugDiscovery/sample_results/tmp/autodock_ga_run_10_bt_1ijy*.7z>;

#Loop through the list of Priority results to generate top 100 scores
foreach $file (@files) {

$ARG="date";
print $ARG."\n";
system($ARG);

#Check if already running
$check = system("ps ax | grep mdrun.pl | wc -l");
chomp($check);
print "Checking if script is running\n";
if ($check > 3) {
print "Already running\n";
exit 0;
}

#Calculate file size
$filesize = -s $file;
print "file size".$filesize;

#Error handle: If file size is not greater than 0 bytes, skip this file
  if ($filesize > 0) {
  print $file."\n";
#Extract the workunit name from the file path, removes the .7z file extension from name
$wu_name=substr($file,0,length($file)-3);

#Remove existing analysis directory for this workunit if its still exists from last run
  $ARG1="rm -rf ".$wu_name;
  system($ARG1);
  print $ARG1."\n";
#Creates a working directory for this workunit
  $ARG2="mkdir ".$wu_name;
  system($ARG2);
  print $ARG2."\n";
#copy the receptor file pdb file to the working directory
  $ARG3="cp ".$PROJECT."/bin/receptor.pdb ".$wu_name;
  system($ARG3);
  print $ARG3."\n";
#Extract the result file into working directory
  $ARG4="7za e -y -o".$wu_name." ".$file;
  print $ARG4."\n";
  system($ARG4);
#use the Cwd methods
	use Cwd;
#save the original directory path
	my $orig_dir = Cwd::abs_path;
#clean the path string
	chomp($wu_name);
#change to new directory
	chdir($wu_name);

#summarize the results of the workunit to get the top docking complexes and interaction energy, prints the energy in workunitname_summary.txt
  $ARG5="/usr/local/bin/pythonsh /usr/local/MGLTools-1.5.4/MGLToolsPckgs/AutoDockTools/Utilities24/summarize_results4.py -v -d ".$wu_name." -r receptor.pdb -o ".$wu_name."_summary.txt";
  print $ARG5."\n"; 
  system($ARG5);
#remove the workunit directory don't need it at this moment
   $ARG6="rm -rf ".$wu_name;
   print $ARG6."\n";
   system($ARG6);
  chdir($orig_dir);
	}
}

#use the Cwd methods
	use Cwd;
#save the original directory path
#	my $orig_dir = Cwd::abs_path;
#clean the path string
	chomp($tmp);
#change to new directory
	chdir($tmp);

#write every summary file into summary_1.0.txt
  $ARG7="cat ".$tmp."/*_summary.txt > ".$tmp."/summary_1.0.txt";
  print $ARG7."\n";
  system($ARG7);
#remove the redundant lines such as headers from the file
  $ARG8="sed \'\/\#dlgfn                      \#in cluster \#LE   \#rmsd \#ats \#tors/d\' ".$tmp."/summary_1.0.txt > ".$tmp."/summary_2.0.txt";
  print $ARG8."\n";
  system($ARG8);
#Sort the file, ascending by LE
  $ARG9="cat ".$tmp."/summary_2.0.txt | sort -k3n -t, > ".$tmp."/summary_2.0.sort";
  print $ARG9."\n";
  system($ARG9);
#Remove the remaining summaries
  $ARG10="rm -rf ".$tmp."/*.txt";
  print $ARG10."\n";
  system($ARG10);
#take the top 100 from summary_2.0.sort and print file summary_3.0.sort
  $ARG11="cat ".$tmp."/summary_2.0.sort | awk \'{ print substr( \$0, 0, match(\$0, /,/) - 5 ) }\' | sed \-n \'G\; s\/\\n\/\&\&\/\; \/\^\\\(\[ \-\~\]\*\\n\\\).\*\\n\\1\/d\; s\/\\n\/\/\; h\; P\' > " .$tmp."/summary_3.0.sort && echo EOF >> " .$tmp."/summary_3.0.sort";
  print $ARG11."\n";
  system($ARG11);
  $ARG12="cat " .$tmp."/summary_3.0.sort | sed \'\$\!N\; \/\^\\(.\*\\\)\\n\\1\$\/\!P\; D\' > ".$tmp."/tmp.txt && cp ".$tmp."/tmp.txt ".$tmp."/summary_3.0.sort"; 
  print $ARG12."\n";
  system($ARG12);

  $ARG="cp " .$tmp."/summary_2.0.sort " .$tmp."/summary_".$time.".txt";
  print $ARG."\n";
  system($ARG);

#use the Cwd methods
        use Cwd;
#save the original directory path
        my $orig_dir = Cwd::abs_path;
#clean the path string
        chomp($OPS);
#change to new directory
        chdir($OPS);

#  $ARG = "cp ".$tmp."/summary_".$time.".txt ".$results."/autodock_scores_".$time.".txt";
  $ARG = "cut -f 1,3 -d , ".$tmp."/summary_".$time.".txt >".$results."/autodock_scores_".$time.".txt";
  print $ARG."\n";
  system($ARG);

  $ARG="php update_docking_results.php ".$tmp."/summary_".$time.".txt";
  print $ARG."\n";
  system($ARG);

#change to original
        chdir($orig_dir);


$top_scores="/home/boincadm/projects/DrugDiscovery/sample_results/tmp/summary_3.0.sort";
open (TOP_SCORES,$top_scores) or die ("Error trying to open top scores.\n");
# process top scores

 do {$new_score = <TOP_SCORES>;

$ARG="date";
print $ARG."\n";
system($ARG);

#generate seed
#  use strict;
#  use warnings;
  my $range = 1000000;
  my $seed = int(rand($range));
  print $seed . "\n";

$md_param="integrator \= md
nsteps \= ".$steps."
dt \= 0.002
nstvout \= ".$nstvout."
nstlog \= 500
nstenergy \= 250
nstxtcout \= ".$nstxtcout."
nstxout \= ".$nstxout."
xtc_grps \= Protein SOL
energygrps \= Protein  SOL
constraints \= all-bonds
nstcomm \= 1
ns_type \= grid
rlist \= 1.2
rcoulomb \= 1.1
rvdw \= 1.0
vdwtype \= shift
rvdw-switch \= 0.9
coulombtype \= PME-Switch
Tcoupl \= v-rescale
tau_t \= 0.1 0.1
tc-grps \= protein non-protein
ref_t \= 300 300
Pcoupl \= parrinello-rahman
PcOupltype \= isotropic
tau_p \= 0.5
compressibility \= 4.5e-5
ref_p \= 1.0
gen_vel \= yes
lincs-iter \= 2
DispCorr \= EnerPres
optimize_fft \= yes
gen_seed = ".$seed;


$df=`df | head -n 3 | tail -n 1 | awk \'{ print substr( \$0, length(\$0) - 4, 2 ) }\'`;
chomp($df);
$df=$df-1;
print $df."% full\n";
if ($df >70) {
print "over 70% full \n";
sleep(5200);
}

	chomp($new_score);
	print $new_score . "\n"; 
#if not at the end of file
	if ($new_score ne "EOF")
	{
	$time=`date '+%s%N'`;
	chomp ($time);

#create a new score directory
	$ARG1="mkdir ".$new_score;
	system($ARG1);
	print $ARG1."\n";
 	$ARG2="7za e -o".$new_score." ".$new_score.".7z";
        print $ARG2."\n";
 	system($ARG2);

print $wu_name."\n";
#use the Cwd methods
        use Cwd;
#save the original directory path
        my $orig_dir = Cwd::abs_path;
#clean the path string
        chomp($new_score);
#change to new directory
	chdir($new_score);

#name of workunit extracted again
#  	$wu_name=substr($new_score,57,length($new_score)-3);

$bt=substr($new_score, rindex($new_score,"_bt_")+4, rindex($new_score,"_lig_") - rindex($new_score,"_bt_")-4);
print "bt: ".$bt."\n";
$lig=substr($new_score, rindex($new_score,"_lig_")+5, rindex($new_score,"_ts_") - rindex($new_score,"_lig_")-5);
print "lig: ".$lig."\n";
$ts=substr($new_score, rindex($new_score,"_ts_")+4);
print "ts: ".$ts."\n";
$wu_name="nsteps_".$nsteps."_int_".$start."_-_".$end."_bt_".$bt."_lig_".$lig."_ts_".$ts;

	print "\n".$wu_name."\n";


$ENV{'PATH'} = '/usr/local/gromacs/bin/:/usr/kerberos/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/antechamber-1.27:/usr/local/antechamber-1.27/exe:/home/boincadm/bin';
$ENV{'ACHOME'} = '/usr/local/antechamber-1.27';
$ENV{'AMBERHOME'} = '/usr/local/antechamber-1.27/exe';
$results=$PROJECT."/sample_results";

#MGLTools Script writes the largest cluster of ligands into a ligand_BC.pdbqt
	$ARG1="/usr/local/bin/pythonsh /usr/local/MGLTools-1.5.4/MGLToolsPckgs/AutoDockTools/Utilities24/write_largest_cluster_ligand.py";
	print $ARG1 . "\n";
	system($ARG1);

$file=$new_score."/ligand_BC.pdbqt";
print $file . "\n";
#Calculate file size

$filesize = -s $file;
#Error handle: If file size is not greater than 10 bytes, skip this file
print "\nFilesize: ".$filesize ."\n";

#Convert PDBQT format to PDB
	$ARG2="/usr/local/bin/pythonsh /usr/local/MGLTools-1.5.4/MGLToolsPckgs/AutoDockTools/Utilities24/pdbqt_to_pdb.py -f ligand_BC.pdbqt -o ligand_BC.pdb";        
	print $ARG2 . "\n";        
	system($ARG2);
	
#Babel adds protons
	$ARG3="babel -ipdb ligand_BC.pdb -opdb ligand_BC.pdb -h";
        system($ARG3);
        print $ARG3 . "\n";
        $ARG3="sed -i \'s\/<0>\/LIG\/g\' ligand_BC.pdb";
        system($ARG3);
        print $ARG3 . "\n";


#Output only LIG residues
        $ARG4="grep \"LIG\" ligand_BC.pdb > Ligand.pdb";
        system($ARG4);
        print $ARG4 . "\n";

#Acpypi preps the Ligand file for GROMACS
        $ARG5="/usr/local/bin/acpypi -f -d -n 0 -i Ligand.pdb -s 120";
        print $ARG5 . "\n";
	system($ARG5);

	$filename=$new_score."/Ligand.acpypi/Ligand_GMX.itp";
if (-e $filename) {

#Copy the Protein file previously preped with Amber
        $ARG6="cp ".$PROJECT."/biotarget/".$receptor_gro." .";
        print $ARG6 . "\n";
        system($ARG6);

#Copy the Protein2.pdb file to working directory
        #$ARG7="cp ".$PROJECT."/bin/Protein2.pdb .";
        #print $ARG7 . "\n";
        #system($ARG7);

#Prep the Protein2.pb useing pdb2gmx
        $ARG8="pdb2gmx -ff amber99sb -f ".$receptor_gro." -o Protein2.pdb -p Protein.top -water spce -ignh";
        print $ARG8 . "\n";
        system($ARG8);

#Extract the ATOM Residues from Protein2.pdb and Ligand_NEW.pdb and redirect to Complex.pdb
        $ARG9="grep -h ATOM Protein2.pdb Ligand.acpypi/Ligand_NEW.pdb >| Complex.pdb";
        print $ARG9 . "\n";
        system($ARG9);

#Copy the Ligand_GMX.itp to Ligand.itp
        $ARG10="cp Ligand.acpypi/Ligand_GMX.itp Ligand.itp";
        print $ARG10 . "\n";
        system($ARG10);

#Copy the Protein topology file to Complex.top
        $ARG11="cp Protein.top Complex.top";
        print $ARG11 . "\n";
        system($ARG11);

#Copy the Complex.top and insert #include "Ligand.itp" into new file Complex2.top
        $ARG12="cat Complex.top | sed '/#include\ \\\"ffamber99sb.itp\\\"/a \#include \"Ligand.itp\"' >| Complex2.top";
        print $ARG12 . "\n";
        system($ARG12);

#Append Ligand   1 to Complex2.top
        $ARG13="echo \"Ligand   1\" >> Complex2.top";
        print $ARG13 . "\n";
        system($ARG13);

#Rename the Complex2.top to Complex.top
        $ARG14="mv Complex2.top Complex.top";
        print $ARG14 . "\n";
        system($ARG14);

#Copy the em.mdp parameter file to current working directory
        $ARG15="cp ".$PROJECT."/bin/em.mdp .";
        print $ARG15 . "\n";
        system($ARG15);

        $ARG15="cp ".$PROJECT."/bin/em_r.mdp .";
        print $ARG15 . "\n";
        system($ARG15);

        $ARG15="cp ".$PROJECT."/bin/pr.mdp .";
        print $ARG15 . "\n";
        system($ARG15);

#Run editconf on the Complex.pdb
        $ARG15="editconf -bt triclinic -f Complex.pdb -o Complex.pdb -d 1.0";
        print $ARG15 . "\n";
        system($ARG15);

#Run genbox on Complex.pdb
        $ARG16="genbox -cp Complex.pdb -cs ffamber_tip3p.gro -o Complex_b4ion.pdb -p Complex.top";
        print $ARG16 . "\n";
        system($ARG16);

#Run grompp
        $ARG17="grompp -f em_r.mdp -c Complex_b4ion.pdb -p Complex.top -o Complex_b4ion.tpr";
        print $ARG17 . "\n";
        system($ARG17);

#copy the Complex.top to Complex_ion.top
        $ARG18="cp Complex.top Complex_ion.top";
        print $ARG18 . "\n";
        system($ARG18);

#Run genion
        $ARG19="echo 13| genion -s Complex_b4ion.tpr -o Complex_b4em.pdb -neutral -conc 0.15 -p Complex_ion.top -norandom";
        print $ARG19 . "\n";
        system($ARG19);

sleep(1);

#rename the Complex_ion.top Complex.top
        $ARG20="mv Complex_ion.top Complex.top";
        print $ARG20 . "\n";
        system($ARG20);
#Run the grompp
        $ARG21="grompp -f em_r.mdp -c Complex_b4em.pdb -p Complex.top -o em_r.tpr";
        print $ARG21 . "\n";
        system($ARG21);

my $timeout = 180;
my $pid = fork;

if ( defined $pid ) {
  if ( $pid ) {
      # this is the parent process
      local $SIG{ALRM} = sub { die "TIMEOUT" };
      alarm 3600;
      # wait until child returns or timeout occurs
      eval {
          waitpid( $pid, 0 );
      };
      alarm 0;

      if ( $@ && $@ =~ m/TIMEOUT/ ) {
          # timeout, kill the child process
          kill 9, $pid;
      }
  }
  else {
      # this is the child process
      # this call will never return. Note the use of exec instead of system
      exec "mdrun -v -deffnm em_r -maxh 1";
  }
}
else {
  die "Could not fork.";
}

        $ARG21="grompp -f em.mdp -c em_r.gro -p Complex.top -o em.tpr";
        print $ARG21 . "\n";
        system($ARG21);

my $pid = fork;

if ( defined $pid ) {
  if ( $pid ) {
      # this is the parent process
      local $SIG{ALRM} = sub { die "TIMEOUT" };
      alarm 36000;
      # wait until child returns or timeout occurs
      eval {
          waitpid( $pid, 0 );
      };
      alarm 0;

      if ( $@ && $@ =~ m/TIMEOUT/ ) {
          # timeout, kill the child process
          kill 9, $pid;
      }
  }
  else {
      # this is the child process
      # this call will never return. Note the use of exec instead of system
      exec "mdrun -v -deffnm em -maxh 1";
  }
}
else {
  die "Could not fork.";
}

        $ARG21="grompp -f pr.mdp -c em.gro -p Complex.top -o pr.tpr";
        print $ARG21 . "\n";
        system($ARG21);

my $pid = fork;

if ( defined $pid ) {
  if ( $pid ) {
      # this is the parent process
      local $SIG{ALRM} = sub { die "TIMEOUT" };
      alarm 3600;
      # wait until child returns or timeout occurs
      eval {
          waitpid( $pid, 0 );
      };
      alarm 0;

      if ( $@ && $@ =~ m/TIMEOUT/ ) {
          # timeout, kill the child process
          kill 9, $pid;
      }
  }
  else {
      # this is the child process
      # this call will never return. Note the use of exec instead of system
      exec "mdrun -v -s pr.tpr -o pr.trr -c b4md.gro -g pr.log -e pr.edr";
  }
}
else {
  die "Could not fork.";
}


	open (MYFILE, ">>".$new_score."/md.mdp");
	print MYFILE $md_param."\n";
	close (MYFILE);

        $ARG21="grompp -f md.mdp -c b4md.gro -p Complex.top -o md.tpr";
        print $ARG21 . "\n";
        system($ARG21);

        open (MYFILE, ">>".$new_score."/md_job.xml");
        print MYFILE $job_file."\n";
        close (MYFILE);

	$ARG="7za a -r Ligand.acpypi.7z Ligand.acpypi";
        print $ARG . "\n";
        system($ARG);


	chdir($PROJECT);

#copy the md.tpr used by mdrun workunit. Copy to the download directory using the dir_hier_path which sets the proper fanout directory
        $ARG1="cp ".$new_score."/md.tpr \`bin/dir_hier_path md_".$wu_name.".tpr\`";
        print $ARG1 . "\n";
        system($ARG1);

        $ARG1="cp ".$new_score."/md.mdp \`bin/dir_hier_path md_".$wu_name.".mdp\`";
        print $ARG1 . "\n";
        system($ARG1);

        $ARG1="cp ".$new_score."/md_job.xml \`bin/dir_hier_path md_job_".$wu_name.".txt\`";
        print $ARG1 . "\n";
        system($ARG1);

        $ARG1="cp ".$new_score."/Complex.top \`bin/dir_hier_path complex".$wu_name.".txt\`";
        print $ARG1 . "\n";
        system($ARG1);

	$ARG="cp ".$new_score."/Ligand.acpypi.7z \`bin/dir_hier_path Ligand.acpypi_".$wu_name.".7z\`";
        print $ARG . "\n";
        system($ARG);

        $ARG="cp ".$new_score."/Ligand.itp \`bin/dir_hier_path Ligand_".$wu_name.".itp\`";
        print $ARG . "\n";
        system($ARG);

        $ARG1="chmod -R a+r ".$PROJECT."/download";
        print $ARG1 . "\n";
        system($ARG1);


$ARG2=$PROJECT."/bin/create_work -appname mdrun -wu_name ".$wu_name." -wu_template ".$PROJECT."/templates/mdrun_wu_assign -result_template templates/mdrun_result --rsc_fpops_est ".$rsc_fpops_est." --rsc_fpops_bound ".$rsc_fpops_bound." --delay_bound ".$delay_bound." md_".$wu_name.".tpr md_".$wu_name.".mdp md_job_".$wu_name.".txt complex".$wu_name.".txt Ligand.acpypi_".$wu_name.".7z Ligand_".$wu_name.".itp";
       
        print $ARG2 . "\n";
        system($ARG2);
	system("touch ".$PROJECT."/reread_db");

	$ARG="date";
	print $ARG."\n";
	system($ARG);

	}

	chdir($orig_dir);
#   	 $ARG1="7za a /home/boincadm/projects/DrugDiscovery/html/ops/complexes/".$new_score.".7z ".$new_score;
#        system($ARG1);
#        print $ARG1."\n";

	$ARG3="rm -rf ".$new_score." ".$new_score.".7z";
	print $ARG3 . "\n";
	system($ARG3);
	}
    } while ($new_score ne "EOF");
close (TOP_SCORE);

	$ARG="date";
	print $ARG."\n";
	system($ARG);

	chdir($results);

	$ARG="mv ".$tmp."/*.7z ".$PROJECT."/backup";
	print $ARG."\n";
	system($ARG);

	system("rm -rf ".$tmp);
	print "Finished \n";

