use RMI::Server::Tcp;
use Data::Dumper;
use Athena::Lib;
use AthenaUtils;
#use Storable qw( nfreeze thaw );
#use JSON;

my @jobqueue;
my %jobstatus = ();
my @jobstatus1= ();
my $clients; #Client hash - ipaddress and perfrank

$s = RMI::Server::Tcp->new(
	port => 10625           # defaults to 4409
);
$s->run;

sub serve 
{
=pod
	print Dumper(\@jobqueue);
	foreach(@jobstatus1){
		print Dumper($_);
	}
#	print($a);
	print Dumper(\@jobqueue);
	return 'helo';
=cut
	my $stat = shift;
	my $currentjob = get_next_job();

	$clients->{$stat->{ipaddress}} = $stat->{perfrank};
	
	if(get_first_client() eq $stat->{ipaddress})
	{
		if( $currentjob )
		{
			#get next job name, get details from hash and return.
			delete $clients->{$stat->{ipaddress}};
#return "Okay";
			$response = '';
			while ( my($k,$v) = each(%{$jobstatus{$currentjob}}))
			{
				$response .= $k . '&' . $v . '&';
			}
			return $jobstatus{$currentjob};#$response;
			
#return DeepCopyStructure($jobstatus->{$currentjob});
#return nfreeze($jobstatus->{$currentjob});
#return encode_json($jobstatus->{$currentjob});
		}
		else
		{
			delete $clients->{$stat->{ipaddress}};
			return 'Wait';
		}
	}
	else
	{
		delete $clients->{$stat->{ipaddress}};
		return 'Wait';
	}

}

sub build_process_queue
{
	my ($order, $getlist) = @_;
	my $localgetlist = DeepCopyStructure($getlist); 
	push @jobqueue, @$order;
	foreach my $temp (sort keys %$localgetlist)
	{
		$jobstatus{$temp} = $localgetlist->{$temp};
		push @jobstatus1, {$temp=>$localgetlist->{$temp}};
	}
	print Dumper(\@jobqueue);
	print Dumper(\%jobstatus);
	print Dumper(\@jobstatus1);
}

sub get_first_client
{
	my ($lkey,$lvalue);
	while( my ($key,$value) = each %$clients)
	{
		if( $value > $lvalue )
		{
			$lkey = $key;
			$lvalue = $value;
		}
	}
	return $lkey;
}

sub get_next_job
{
	# shift values from jobsqueue
	return shift @jobqueue;
}

