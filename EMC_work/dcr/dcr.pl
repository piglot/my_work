#!/usr/bin/perl
#

# Program: dcr.pl
# About  : DOS Command Recorder helps saving history of executed commands and their output
# Author : Raul Davalos
# Date   : 2004/11/22
# Syntax : perl dcr.pl <log_file>
#
# Modified: Haifeng
# Date:     2012/07/31


#use Win32::Registry;
use sigtrap 'handler' => \&SignalCatcher, 'HUP';
use sigtrap 'handler' => \&SignalCatcher, 'INT';
use sigtrap 'handler' => \&SignalCatcher, 'QUIT';
use strict;


####################
sub getStamp{
	# Date & Time Stamps
	my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
	$Year = $Year + 1900;
	$Month = $Month+1;
	$Month = "0".$Month if $Month < 10;
	$Day   = "0".$Day if $Day < 10;
	$Hour  = "0".$Hour if $Hour < 10;
	$Minute  = "0".$Minute if $Minute < 10;
	$Second  = "0".$Second if $Second < 10;
	return "".$Year."/".$Month."/".$Day." ".$Hour.":".$Minute.":".$Second;
}
####################


####################
sub SignalCatcher {
   my $abortExec=1;
   print "To interrupt DCR type EXIT...\n";
}
####################


####################
sub ExitFailure {
   print "Error: $!\n";
   print "Would you like to continue (y/n)? ";
   my $cont=<STDIN>;
   chomp $cont;
   return 1 if $cont =~ /y/i;
   print "DCR EXECUTION ABORTED!!!\n";
   exit 1;
}
####################


sub makeFolder {
  my $dir=shift;
  my $tDir="";
  foreach(split(/\/|\\/,$dir)){
     $tDir.="$_\/";
     if (-e $tDir) {
        #print "Exists: $tDir\n";
     } else {
        #print "Creating: $tDir\n";
        return -1 if ! mkdir ("$tDir", 0777); # "Error creating $tDir!"
     }
  }
  return 1; # "The log folder $tDir was created successfully!"
}


####################
sub logMsg{
   my $logFile=shift;
   my $msg=shift;
   
   #if (open (LOG, ">$logFile")) {
   #} else {
   #   print "DCR                     | \nDCR                     | Unable to log results to $logFile.\nDCR                     |\n";
   #   exit;
   #}
   open (LOG, ">>$logFile") || ExitFailure();
   print LOG $msg;
   if ($msg eq "\n"){
       print "";
   }
   else{
       print $msg;
   }
   close(LOG);
}
####################

sub logMsg2{
   my $logFile=shift;
   my $msg=shift;

   open (LOG, ">>$logFile") || ExitFailure();
   print LOG $msg;
   if ($msg eq "\n"){
       print "";
   }
   close(LOG);
}


####################
MAIN:
####################
my $javaCLI = "java -jar \"C:\\Program Files\\EMC\\Navisphere CLI\\navicli.jar\" -User GlobalAdmin -Password password  -Address";
my $naviCLI = "\"C:\\Program Files\\EMC\\Navisphere CLI\\navicli.exe\" -h";
my $naviSecCLI = "\"C:\\Program Files\\EMC\\Navisphere CLI\\naviseccli.exe\" -user GlobalAdmin -password password -scope 0 -h";

my $helpDesc=<<EOFHD;
DCR | 
DCR | *********
DCR | Shortcuts
DCR | *********
DCR | 
DCR | When inside the execution of DCR, you may type the following shortcuts at the begining
DCR | of the command line to expand an actual command and some of its arguments.
DCR | 
DCR |  +----------+---------------------------------------------------------------------------
DCR |  | Shortcut | Expands
DCR |  +----------+---------------------------------------------------------------------------
DCR |  | h        | This help window.
DCR |  |          |
DCR |  | j        | $javaCLI
DCR |  |          |
DCR |  | n        | $naviCLI
DCR |  |          |
DCR |  | ns       | $naviSecCLI
DCR |  |          |
DCR |  | a <name> | set assertion_name=<name>
DCR |  |          |
DCR |  | s p      | set staus=PASSED
DCR |  |          |
DCR |  | s f      | set staus=FAILED
DCR |  |          |
DCR |  | .        | Exit 
DCR |  |          |
DCR |  +----------+---------------------------------------------------------------------------
DCR | 
DCR | Raul Davalos - 11/22/2004
DCR | 
EOF
EOFHD

goto SYNTAX if $ARGV[0] eq "-h";

my $userName=`logname`;
chomp $userName;
$userName=~s/USERNAME\=(.*)/$1/i;


my ($main, $key, %vals);
my $logDir=`logname`;
chomp $logDir;
my $DCRFolder="DCRFolder";

##########################
# to read values of a key
#$main::HKEY_CURRENT_USER->Open("Environment", $key) || die "Open: $!";
#$key->GetValues(\%vals); 		# get sub keys and value -hash ref
#OBforeach my $k (keys %vals) {		# iterate over keys
#    $key = $vals{$k};			# get ref to list
#    #print "$$key[0] = $$key[2]\n";	# dereference as list
#    $logDir=$$key[2] if "$$key[0]" eq "$DCRFolder";
#}
#print "$DCRFolder: $logDir\n";

my $batchFile = $ARGV[0];
my $repeatFactor = $ARGV[1];
my @bf;
my $errMsg="";
my $bfLines = 0;
my $abortExec=0;
my $status="UNKNOWN";

my $logFile=getStamp();
chomp $logFile;
$logFile=~s/\///g;
$logFile=~s/://g;
$logFile=~s/ /_/g;
my $renLogfile="$logFile";

print "\nDCR ".getStamp." | Welcome $userName\!";
print "\nDCR ".getStamp." | Saving results to: $logDir";
print "\nDCR ".getStamp." | If desired enter a different folder name or leave empty: ";
my $tempLD=<STDIN>;
chomp $tempLD;
if ($tempLD ne "") {
   $logDir=$tempLD;
#   $main::HKEY_CURRENT_USER->Open("Environment", $key) || die "Open: $!";
#   $key->SetValueEx("$DCRFolder", 0, REG_SZ, "$tempLD"); # to create a folder
   if ( !(-e $logDir) ) {
      mkdir($logDir,0777)|| die "can not create a folder";
   }
}

$logFile="$logDir/DCR_$userName\_$logFile.log";
#open(my $lf, ">", $logFile) or die;

#print "$logFile\n";#add here to test
#print "\nDCR ".getStamp." | Temp Logfile: $logFile\n";

$repeatFactor = "1" if $repeatFactor eq "";
$repeatFactor =~ /(\d*)/;
$errMsg="Repeat Factor must be a number";
goto SYNTAX if $repeatFactor ne $1;


if ($batchFile ne "") {
  $errMsg="DCR ".getStamp." | Unable to open Batch File $batchFile";
  open(BF, $batchFile) || goto SYNTAX;
  @bf=<BF>;
  close(BF);
  foreach(@bf){
     chomp;
     #print "BATCH_FILE: $_\n";
     $bfLines++;
  }
}

$errMsg="";

if (makeFolder("$logDir") == -1) {
   print "DCR ".getStamp." |\nDCR                     | Unable to create $logDir log folder.\nDCR                     |\n";
   exit;
}
print "DCR ".getStamp." | Log folder $logDir ready! \n";

my $ts=getStamp;
print "DCR ".getStamp." | Assertion Name: ";
my $assertion=<STDIN>;
chop $assertion;
print "DCR ".getStamp." | Description   : ";
my $desc=<STDIN>;
chop $desc;
my $comments="\n";
my $bbff="";
$bbff="DCR $ts | # Executing Bacth File: $batchFile\n" if $batchFile ne "";
logMsg($logFile,
	"DCR $ts | #########################################################\n".
	"DCR $ts | # Entering DCR - DOS Command Recorder                   #\n".
	"DCR $ts | #########################################################\n".
	"DCR $ts | #\n".
	"DCR $ts | # Saving results temporarily to: $logFile #\n".
	"DCR $ts | # Assertion: $assertion\n".
	"DCR $ts | # Comments: $desc\n".
	"$bbff".
	"DCR $ts |\n".
	"DCR $ts |\n");
if ($bfLines > 0) {
   for(my $r=0; $r<$repeatFactor; $r++) {
      logMsg($logFile,"DCR ".getStamp." | LOOP: $r +++++++++++++++\n");
      for(my $l=0; $l<$bfLines; $l++) {
         goto EXIT if $abortExec;
         my $cmd=$bf[$l];
         my $prompt="cd";
	 my $run=`$prompt 2>&1`;
	 chomp $run;
	 logMsg($logFile,"DCR ".getStamp." | $run>$cmd\n");
	 if ($cmd eq "") {
	    next;
	 }
         goto EXIT if uc $cmd eq "EXIT" || $cmd eq ".";
	    $cmd=~s/^j /$javaCLI /i;
	    $cmd=~s/^n /$naviCLI /i;
	    $cmd=~s/^ns /$naviSecCLI /i;
	    $assertion=$1     if $cmd=~s/^a (.*)/echo \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* Assertion: $1/i;
            $status="PASSED"  if $cmd=~s/^s p/echo \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* Status: PASSED/i;
            $status="FAILED"  if $cmd=~s/^s f/echo \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* Status: FAILED/i;
            $comments.="$1\n" if $cmd=~s/^c (.*)/echo \*\*\*\*\*\*\*\* Comment: $1/i;
	    logMsg($logFile,"DCR ".getStamp." | Executing: $cmd\n") if $cmd !~ /\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*/;
	    $run=`$cmd 2>&1`;
	    $run=~s/\n/\nDCR                     | /g;
            logMsg($logFile,"DCR ".getStamp." | $run\n");
      }
   }
} else {
   for(;;){
      my $prompt="cd";
      my $run=`$prompt 2>&1`;
      chomp $run;
      logMsg($logFile,"DCR ".getStamp." | $run>");
      my $cmd=<STDIN>;
      chop $cmd;
      if ($cmd eq ""){
	 logMsg($logFile, "\n");
	 next;    
      }
      goto EXIT if uc $cmd eq "EXIT" || $cmd eq ".";
      if (uc $cmd eq "CLS"){
         system "cls";
         next;
      }
      $cmd=~s/^j /$javaCLI /i;
      $cmd=~s/^n /$naviCLI /i;
      $cmd=~s/^ns /$naviSecCLI /i;
      $assertion=$1     if $cmd=~s/^a (.*)/echo \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* Assertion: $1/i;
      $status="PASSED"  if $cmd=~s/^s p/echo \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* Status: PASSED/i;
      $status="FAILED"  if $cmd=~s/^s f/echo \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* Status: FAILED/i;
      $comments.="$1\n" if $cmd=~s/^c (.*)/echo \*\*\*\*\*\*\*\* Comment: $1/i;

      if ($cmd =~ /dcr.pl/){
         print "***Cannot run dcr.pl inside dcr environment\n";
         next;
      }

      logMsg($logFile,"DCR ".getStamp." | Executing: $cmd\n") if $cmd !~ /\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*/;

      my $log_tmp = "log_tmp";
      system ("echo DCR > $log_tmp");

      if (uc $cmd eq "H" || uc $cmd eq "HELP") {
         print "***Help $cmd\n";
         $run=$helpDesc;
         logMsg($logFile,"DCR ".getStamp." | $run\n");
      } else {
         system ("$cmd 2>&1 | wtee $log_tmp") ; 
         open FILE, $log_tmp or die "Couldn't open file: $!";
         while (<FILE>){
            $run .= $_;
         }
         close FILE;
         $run=~s/\n/\nDCR                     | /g;
         logMsg2($logFile,"DCR ".getStamp." | $run\n");
      }

      print "--------------------------\n";
      
      CONT:
   }
}
   
   ####################
   EXIT:
   ####################
   $ts=getStamp;
   my $ren="$userName\_$assertion\_$renLogfile\_$status.log";
   logMsg($logFile,"DCR $ts | CTRL-C PRESSED. ABORTING EXECUTION!!!\n") if $abortExec;
   logMsg($logFile,
	"DCR $ts |\n".
	"DCR $ts |\n".
	"DCR $ts |\n".
	"DCR $ts | # Execution Status  : $assertion\n".
	"DCR $ts | # Execution Comments: ");
	#print "-$comments-";
   $comments=~s/\n/\nDCR                     \|      /g;
   $comments=~s/\n$//;
   logMsg($logFile,
   	$comments."\n".
	"DCR $ts | # Results saved to log file  : $logDir\/$ren\n".
	"DCR $ts | #########################################################\n".
	"DCR $ts | # Leaving DCR - DOS Command Recorder                    #\n".
	"DCR $ts | #########################################################\n");
   $ren="rename $logFile \"$ren\" 2>&1";
   #print $ren;
   print `$ren`;
   exit;




####################
ERROR:
####################
print<<EOF;
DCR |
DCR | Invalid Command. Too few parameters 
DCR | usage:  perl dcr.pl $0 <log_file>
DCR |   log_file: Name of the output file in which to record DOS Commands and their output.
DCR |  
EOF
exit;


SYNTAX:
$errMsg="\nDCR | Error: $errMsg\nDCR | " if $errMsg ne "";
print<<EOF;
DCR |
DCR | DCR - DOS Command Recorder
DCR | 
DCR | DCR helps saving historic commands and their output
DCR | $errMsg
DCR | Usage:  perl dcr.pl [-h | BatchFile [RepeatFactor]] 
DCR | 
DCR |     -h            Shows this help file.
DCR |     BatchFile     Any text file that contains any DOS executable commands. One command per line.
DCR |     RepeatFactor  The number of time the BatchFile will be executed.
EOF
print $;

exit;


# End of dcr.pl
####################

#CC ***************************************************************
#CC Document : dcr.pl
#CC Version  : \main\release_26\1
#CC Release  : release_26
#CC Modified : 05-Oct-06 04:42:55
#CC User     : rdavalos
#CC Mail     : davalos_raul@emc.com
#CC ***************************************************************
