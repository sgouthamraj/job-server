use RMI::Client::Tcp;
use Data::Dumper;
use Athena::Lib qw(:intranet :athena);
use Proc;
use Storable qw( freeze thaw );
use JSON;

my $CPU_THRESHOLD = 30;
my $RAM_THRESHOLD = 20;
my $MAX_ERROR_COUNTER = 3;

my $stats;
$stats->{flag} = 0;

$c = RMI::Client::Tcp->new(
	host => 'dev207.athenahealth.com',
	port => 5127
);

# Unconditional loop - to keep sending stats
while (1)
{
	for (1..3)
	{
		getmystats();
		if ($stats->{cpuusage} >= $CPU_THRESHOLD)
		{
			$stats->{flag} += 1 if $stats->{flag} < $MAX_ERROR_COUNTER;
		}	
		else 
		{
			$stats->{flag} -= 0.5;
		}
		if( $stats->{flag} <= 0)
		{
			$stats->{flag} = 0;
		}
		$stats->{perfrank} = ($stats->{cpuusage} + $stats->{ramusage}) / 2;
		delete $stats->{cpuusage};
		delete $stats->{ramusage};
		$stats->{available} = $stats->{flag} > 0 ? 'N' : 'Y' ;
	}	
	if ( $stats->{available} eq 'Y')
	{
		print Dumper($stats);
		$msg_from_server = $c->call_function('main::serve', $stats);
		if ($msg_from_server ne "Wait")
		{
			# Run the script in separate thread
			print Dumper($msg_from_server);
			my $commandline = "$msg_from_server->{COMMANDLINE}" . ' ' ."$stats->{ipaddress}";
			Proc::ForkAndForget({JOB => $commandline});
			print "Running the script.. \t" . $msg_from_server->{SCRIPTNAME} . "\n";
		}
		else
		{	
			print "Waiting..\t\n";
		}
	}
}

###############################################################################
# getmystats
#
# Description:
# 	Collect the following information.
# 	host, ipaddress 	- Identity of the machine
# 	cpuusage 		- CPU usage (by collecting data for 5 seconds)
# 	ramusage		- RAM usage (used space)
#
# Arguments:
# 	None
#
# Return:
# 	Hash - Stats of current machine
#
###############################################################################
sub getmystats 
{
	$stats->{host} = `hostname`;
	$stats->{ipaddress} = `hostname --ip-address`;
	my $cpustring = "sar -u 1 5" . " | " . "grep Average" . " | " . "awk '" . "{print \$3 + \$4 + \$5 + \$6 + \$7}" . "'";
	$stats->{cpuusage} = `$cpustring`;
	my $ramstring = "free -m " . " | " . "grep Mem" . " | " . "awk '{" . "print (\$3/\$2)*100" . "}'";
	$stats->{ramusage} = `$ramstring`;
	chomp(%$stats);
}

