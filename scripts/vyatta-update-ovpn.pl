#!/usr/bin/perl

use strict;
use lib "/opt/vyatta/share/perl5";
use Vyatta::OpenVPN::Config;

my $vtun = shift;

my $config = new Vyatta::OpenVPN::Config;
my $oconfig = new Vyatta::OpenVPN::Config;
$config->setup($vtun);
$oconfig->setupOrig($vtun);

if (!($config->isDifferentFrom($oconfig))) {
  if ($config->isEmpty()) {
    print STDERR "Empty Configuration\n";
    exit 1;
  } 
  # config not changed. do nothing.
  exit 0;
}

if ($config->isEmpty()) {
  # deleted
  Vyatta::OpenVPN::Config::kill_daemon($vtun);
  $oconfig->removeBridge();
  exit 0;
}

my ($cmd, $err) = $config->get_command();

if (defined($cmd)) {
  Vyatta::OpenVPN::Config::kill_daemon($vtun);
  $oconfig->removeBridge();
  $config->setupBridge();
  $config->configureBridge();
  if ("$cmd" ne 'disable') { 
     system("$cmd");
     if ($? >> 8) {
       $err = 'Failed to start OpenVPN tunnel';
     }
  }
}
my $description = $config->{_description};
  if ("$description" ne "" && -e "/sys/class/net/$vtun/ifalias")
    {
      my $cmdDesc = "echo \"$description\" >> /sys/class/net/$vtun/ifalias";
      system($cmdDesc);
    }

if (defined($err)) {
  print STDERR "OpenVPN configuration error: $err.\n";
  exit 1;
}

exit 0;

