#!/usr/bin/perl -w
#Check if already running
$check = system("ps ax | grep analyze_flex.pl | wc -l");
chomp($check);
print "Checking if script is running\n";
if ($check > 3) {
print "Already running\n";
exit 0;
}

#Set Variables
#Project Directory
$steps=5000;
$rsc_fpops_est = ($steps * 319500000);
$rsc_fpops_bound = ($rsc_fpops_est * 100);
$delay_bound = ($steps * 70);

$PROJECT="/home/boincadm/projects/DrugDiscovery";
#Sample Results Directory
$results=$PROJECT."/sample_results";
$tmp=$results."/tmp";

if (-d $tmp) {
system("rm -rf ".$tmp);
}

$create_tmp="mkdir ".$tmp;
print $create_tmp . "\n";
system($create_tmp);

$mv_to_tmp="mv ".$results."/autodock_*.7z ".$tmp;
print $mv_to_tmp . "\n";
system($mv_to_tmp);

#All Priority groups in sample_results directory
@files = </home/boincadm/projects/DrugDiscovery/sample_results/tmp/autodock_*.7z>;

$md_param="integrator \= md \n
nsteps \= ".$steps." \n
dt \= 0.002 \n
constraints \= all-bonds \n
nstcomm \= 1 \n
ns_type \= grid \n
rlist \= 1.2 \n
rcoulomb \= 1.1 \n
rvdw \= 1.0 \n
vdwtype \= shift \n
rvdw-switch \= 0.9 \n
coulombtype \= PME-Switch \n
Tcoupl \= v-rescale \n
tau_t \= 0.1 0.1 \n
tc-grps \= protein non-protein \n
ref_t \= 300 300 \n
Pcoupl \= parrinello-rahman \n
PcOupltype \= isotropic \n
tau_p \= 0.5 \n
compressibility \= 4.5e-5 \n
ref_p \= 1.0 \n
gen_vel \= yes \n
nstxout \= ".$steps." \; write coords every \# step \n
lincs-iter \= 2 \n
DispCorr \= EnerPres \n
optimize_fft \= yes \n
gen_seed = -1 \n";


#Loop through the list of Priority results to generate top 100 scores
foreach $file (@files) {

#Check if already running
$check = system("ps ax | grep analyze_flex.pl | wc -l");
chomp($check);
print "Checking if script is running\n";
if ($check > 3) {
print "Already running\n";
exit 0;
}

#Calculate file size
$filesize = -s $file;
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
  $ARG5="/usr/local/bin/pythonsh /usr/local/MGLTools-1.5.2/mgltools_i86Linux2_1.5.2/MGLToolsPckgs/AutoDockTools/Utilities24/summarize_results4.py -v -d ".$wu_name." -r receptor.pdb -o ".$wu_name."_summary.txt";
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
	my $orig_dir = Cwd::abs_path;
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

$top_scores="/home/boincadm/projects/DrugDiscovery/sample_results/tmp/summary_3.0.sort";
open (TOP_SCORES,$top_scores) or die ("Error trying to open top scores.\n");
# process top scores

 do {$new_score = <TOP_SCORES>;
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
  	system($ARG2);
  	print $ARG2."\n";

print $wu_name."\n";
#use the Cwd methods
        use Cwd;
#save the original directory path
        my $orig_dir = Cwd::abs_path;
#clean the path string
        chomp($new_score);
#change to new directory
	chdir($new_score);

sleep(1);
#name of workunit extracted again
  	$wu_name=substr($new_score,57,length($new_score)-3);
	print "\n".$wu_name."\n";

$ENV{'PATH'} = '/usr/local/gromacs/bin/:/usr/kerberos/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/antechamber-1.27:/usr/local/antechamber-1.27/exe:/home/boincadm/bin';
$ENV{'ACHOME'} = '/usr/local/antechamber-1.27';
$ENV{'AMBERHOME'} = '/usr/local/antechamber-1.27/exe';


#MGLTools Script writes the largest cluster of ligands into a ligand_BC.pdbqt
	$ARG1="/usr/local/bin/pythonsh /usr/local/MGLTools-1.5.2/mgltools_i86Linux2_1.5.2/MGLToolsPckgs/AutoDockTools/Utilities24/write_largest_cluster_ligand.py";
	print $ARG1 . "\n";
	system($ARG1);

$file=$new_score."/ligand_BC.pdbqt";
print $file . "\n";
#Calculate file size

$filesize = -s $file;
#Error handle: If file size is not greater than 10 bytes, skip this file
print "\nFilesize: ".$filesize ."\n";

#Convert PDBQT format to PDB
	$ARG2="/usr/local/bin/pythonsh /usr/local/MGLTools-1.5.2/mgltools_i86Linux2_1.5.2/MGLToolsPckgs/AutoDockTools/Utilities24/pdbqt_to_pdb.py -f ligand_BC.pdbqt -o ligand_BC.pdb";        
	print $ARG2 . "\n";        
	system($ARG2);
	
#Babel adds protons
	$ARG3="babel -ipdb ligand_BC.pdb -opdb ligand_BC.pdb -h";
        system($ARG3);
        print $ARG3 . "\n";
sleep(1);
#Output only LIG residues
        $ARG4="grep LIG ligand_BC.pdb > Ligand.pdb";
        system($ARG4);
        print $ARG4 . "\n";
	#sleep(10);
sleep(1);
#Acpypi preps the Ligand file for GROMACS
        $ARG5="/usr/local/bin/acpypi -n 0 -i Ligand.pdb -s 240";
        print $ARG5 . "\n";
	system($ARG5);

	$filename=$new_score."/Ligand.acpypi/Ligand_GMX.itp";
if (-e $filename) {

#Copy the Protein file previously preped with Amber
        $ARG6="cp ".$PROJECT."/bin/ProteinAmber.pdb .";
        print $ARG6 . "\n";
        system($ARG6);

#Copy the Protein2.pdb file to working directory
        $ARG7="cp ".$PROJECT."/bin/Protein2.pdb .";
        print $ARG7 . "\n";
        system($ARG7);

#Prep the Protein2.pb useing pdb2gmx
        $ARG8="pdb2gmx -ff amber99sb -f ProteinAmber.pdb -o Protein2.pdb -p Protein.top -water spce -ignh";
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

#Run editconf on the Complex.pdb
        $ARG15="editconf -bt triclinic -f Complex.pdb -o Complex.pdb -d 1.0";
        print $ARG15 . "\n";
        system($ARG15);

#Run genbox on Complex.pdb
        $ARG16="genbox -cp Complex.pdb -cs ffamber_tip3p.gro -o Complex_b4ion.pdb -p Complex.top";
        print $ARG16 . "\n";
        system($ARG16);

#Run grompp
        $ARG17="grompp -f em.mdp -c Complex_b4ion.pdb -p Complex.top -o Complex_b4ion.tpr";
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

#rename the Complex_ion.top Complex.top
        $ARG20="mv Complex_ion.top Complex.top";
        print $ARG20 . "\n";
        system($ARG20);

#Run the grompp
        $ARG21="grompp -f em.mdp -c Complex_b4em.pdb -p Complex.top -o em.tpr";
        print $ARG21 . "\n";
        system($ARG21);

my $timeout = 180;
my $pid = fork;

if ( defined $pid ) {
  if ( $pid ) {
      # this is the parent process
      local $SIG{ALRM} = sub { die "TIMEOUT" };
      alarm 300;
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
      exec "mdrun -v -deffnm em -maxh 0.08";
  }
}
else {
  die "Could not fork.";
}

	open (MYFILE, ">>".$new_score."/md.mdp");
	print MYFILE $md_param."\n";
	close (MYFILE);


#Prep the molecular dynamics parameters
        $ARG23="grompp -f md.mdp -c em.gro -p Complex.top -o md.tpr";
        print $ARG23 . "\n";
        system($ARG23);

	chdir($PROJECT);

#copy the md.tpr used by mdrun workunit. Copy to the download directory using the dir_hier_path which sets the proper fanout directory
        $ARG1="cp ".$new_score."/md.tpr \`bin/dir_hier_path md_".$steps."_steps_".$wu_name."_".$time.".tpr\`";
        print $ARG1 . "\n";
        system($ARG1);

        $ARG1="cp ".$new_score."/md.mdp \`bin/dir_hier_path md_".$steps."_steps_".$wu_name."_".$time.".mdp\`";
        print $ARG1 . "\n";
        system($ARG1);

        $ARG1="chmod -R a+r ".$PROJECT."/download";
        print $ARG1 . "\n";
        system($ARG1);

#create workunit using the mdrun application. The input parameters and workunits must be immutable. Template file will give the input file a logical name so when it is copied to the slot it will be called md.tpr
        $ARG2=$PROJECT."/bin/create_work -appname mdrun -wu_name md_".$steps."_steps_".$wu_name."_".$time." -wu_template ".$PROJECT."/templates/mdrun_wu -result_template templates/mdrun_result --rsc_fpops_est ".$rsc_fpops_est." --rsc_fpops_bound ".$rsc_fpops_bound." --delay_bound ".$delay_bound." md_".$steps."_steps_".$wu_name."_".$time.".tpr md_".$steps."_steps_".$wu_name."_".$time.".mdp";
        print $ARG2 . "\n";
        system($ARG2);

	}
	chdir($orig_dir);
 	$ARG1="rm -rf ".$new_score;
        system($ARG1);
        print $ARG1."\n";

	$ARG3="mv ".$new_score.".7z ".$results;
	print $ARG3 . "\n";
	system($ARG3);
	sleep(1);
	}

    } while ($new_score ne "EOF");
close (TOP_SCORE);

	chdir($results);
	system("rm -rf ".$tmp);
	print "Finished \n";
	exit;
