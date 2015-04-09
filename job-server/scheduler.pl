
use strict;
use Athena::Lib;
use Data::Dumper;
use Athena::DateTime;
use AnyEvent;
use RMI::Client::Tcp;

my $c = RMI::Client::Tcp->new(
        host => 'dev210.athenahealth.com',
        port => 10625
);
my $name_ready = AnyEvent->condvar;
my $watch = AnyEvent->io(
                poll=>'r',
                fh => \*STDIN,
                cb => sub {
                $name_ready->send;
                });


my @time = localtime(time);
my %jobs = (	2 => {
		'p4/intranet/scripts/qa/aglimpse_notification.pl'=>{
			scheduledtime => '10:30',
			createdby => 'venkat',
			}
		},
		1 => { 'p4/intranet/scripts/qa/ise_task_tracker.pl'=> {
			scheduledtime => '12:00',
			createdby=> 'sgoutham',
			},
			'p4/intranet/scripts/qa/aglimpse_report.pl' => {
			scheduledtime => '14:00',
			createdby=>'mohan'
			}
		},
		);
my @order = ('p4/intranet/scripts/qa/aglimpse_report.pl','p4/intranet/scripts/qa/ise_task_tracker.pl');
my $event = AnyEvent->timer(after => 2,
			interval=>3600,
			cb=> sub {
				my @time = localtime(time);
				my $job = $jobs{$time[2]};
				print $time[2];
				print Dumper($job);
				my $res = $c->send_request_and_receive_response('call_function','main::build_process_queue',\@order,$job);
				print $res;

			});
$name_ready->recv;
print "Done for the day";
