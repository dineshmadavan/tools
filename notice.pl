#!/usr/bin/perl
#############################################################################
#
# ALERT NOTIFICATION FOR SPACE
#
# by Dinesh Madavin
#
# 20-Jan-2015 : Initial concept
#
#############################################################################

use Net::SMTP;

my $HOST = `hostname`; chomp ($HOST);
my $THRESHOLD = 90;
my $SLEEP_TIME = 60;

### SMTP SETTINGS
my $SMTP_HOST = "atom.host.com";
my $SMTP_FROM = "abc\@xyz.com";
my $SMTP_TO   = "abc\@xyz.com;abc\@xyz.com";
   #$SMTP_TO   = "abc\@xyz.com;abc\@xyz.com;";
my @ARRAY_TO  = split (/;/,$SMTP_TO);
my $args = "@ARGV";
if ($args =~ /--debug/) { $DEBUG = 1; }

### MAIN PROGRAM
while(1)
{
  my $MSG_BODY;
  my $MSG_ALERT;
  my $TIME_EPOCH = time();
  my $TIME_LOCAL = localtime();
  $TIME_LOCAL =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/;
  my $FILE_DATE = "$3-$2-$5";
  my $SMTP_DATE = "$1 $3-$2-$5 $4";

  if (!-e $HOST)
  {
    mkdir ($HOST);
  }

  ### DF -H
  my $cmd_exec = "df -h";
  if ($DEBUG) { print "CMD:  $cmd_exec\n"; }
  my @ARRAY_OUTPUT = `$cmd_exec`;
  for (my $i = 1; $i <= $#ARRAY_OUTPUT; $i++)
  {
    my $line = $ARRAY_OUTPUT[$i];
    chomp ($line);
    my @ARRAY_ITEMS = split (/ +/,$line);
    my $CAP = "$ARRAY_ITEMS[$#ARRAY_ITEMS - 1]";
    if ($CAP > $THRESHOLD)
    { $MSG_ALERT .= "$line\n";
    }
  }
  ### GENERATE DAILY EMAIL
  if (!-e "$HOST/$FILE_DATE")
  {
    print "Generating daily - $HOST/$FILE_DATE\n";
    $MSG_BODY = "MIME-Version: 1.0\n";
    $MSG_BODY .= "From: Daily Git Report - $HOST\n";
    $MSG_BODY .= "To: ";
    foreach (@ARRAY_TO) {  $MSG_BODY .= "$_ ; "; }
    $MSG_BODY .= "\n";
    $MSG_BODY .= "Date: $SMTP_DATE\n";
    $MSG_BODY .= "Subject: Git -- Daily space report from $HOST\n\n";
    $MSG_BODY .= "@ARRAY_OUTPUT\n";
    open (OUTFILE, ">$HOST/$FILE_DATE");
    print OUTFILE "@ARRAY_OUTPUT";
    close (OUTFILE);
    my $smtp = Net::SMTP->new($SMTP_HOST);
    if(!defined($smtp) || !($smtp))
    {
      print "SMTP ERROR: Unable to open smtp session.\n";
      exit 0;
    }
    $smtp->mail( $SMTP_FROM );
    foreach (@ARRAY_TO) { $smtp->recipient ($_); }
    $smtp->data($MSG_BODY);
    $smtp->quit;
  }

  ### GENERATE ALERT EMAIL
  if ($MSG_ALERT)
  {
    print "Generating alert\n";
    $COUNT_ALERTS++;
    $INC_SLEEP = $COUNT_ALERTS * $SLEEP_TIME;
    $MSG_ALERT = "MIME-Version: 1.0\n";
    $MSG_ALERT .= "From: Git Alert - $HOST\n";
    $MSG_ALERT .= "To: ";
    foreach (@ARRAY_TO) {  $MSG_BODY .= "$_ ; "; }
    $MSG_ALERT .= "\n";
    $MSG_ALERT .= "Date: $SMTP_DATE\n";
    $MSG_ALERT .= "Subject: Git -- Alert on space from $HOST\n\n";
    $MSG_ALERT .= "One or more partitions exceeded threshold:  $THRESHOLD\%\n\n";
    $MSG_ALERT .= "@ARRAY_OUTPUT\n";
    $MSG_ALERT .= "Next e-mail in $SLEEP_TIME + $INC_SLEEP seconds to reduce spam\n";

    my $smtp = Net::SMTP->new( $SMTP_HOST);
    if(!defined($smtp) || !($smtp))
    {
      print "SMTP ERROR: Unable to open smtp session.\n";
      exit 0;
    }
    $smtp->mail( $SMTP_FROM );
    foreach (@ARRAY_TO) { $smtp->recipient ($_); }

    $smtp->data($MSG_ALERT);
    $smtp->quit;
    print "Sleeping $SLEEP_TIME + $INC_SLEEP\n";
  } else
  { $COUNT_ALERTS = 0;
    $INC_SLEEP    = 0;
  }
  sleep ($SLEEP_TIME + $INC_SLEEP);
}
