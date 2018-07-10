#############################################################################
#  OpenKore - Network subsystem												#
#  This module contains functions for sending messages to the server.		#
#																			#
#  This software is open source, licensed under the GNU General Public		#
#  License, version 2.														#
#  Basically, this means that you're allowed to modify and distribute		#
#  this software. However, if you distribute modified versions, you MUST	#
#  also distribute the source code.											#
#  See http://www.gnu.org/licenses/gpl.html for the full license.			#
#############################################################################
# bRO (Brazil)
package Network::Receive::bRO;
use strict;
use Log qw(warning debug);
use base 'Network::Receive::ServerType0';
use Globals qw(%charSvrSet $messageSender $monstersList);
use Translation qw(TF);

# Sync_Ex algorithm developed by Fr3DBr
sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	
	my %packets = (
		'0097' => ['private_message', 'v Z24 V Z*', [qw(len privMsgUser flag privMsg)]], # -1
		'0A36' => ['monster_hp_info_tiny', 'a4 C', [qw(ID hp)]],
		'09CB' => ['skill_used_no_damage', 'v v x2 a4 a4 C', [qw(skillID amount targetID sourceID success)]],
	);
	# Sync Ex Reply Array 
	$self->{sync_ex_reply} = {
	'08AA', '093B',	'0956', '0879',	'0951', '0362',	'0889', '088A',	'0890', '0937',	'0945', '0899',	'095A', '0438',	'0862', '0877',	'0835', '0874',	'0893', '093C',	'088C', '0896',	'093A', '0891',	'07E4', '0881',	'0960', '0938',	'0933', '087A',	'0873', '094B',	'0888', '0865',	'0887', '0361',	'094E', '086E',	'0811', '0870',	'0934', '0921',	'0924', '0884',	'0925', '086C',	'092D', '022D',	'0959', '0363',	'092B', '086D',	'0202', '08A6',	'095F', '08A9',	'0871', '095D',	'0930', '08AC',	'0898', '0967',	'023B', '089B',	'0817', '0950',	'0923', '087B',	'085A', '08AB',	'0838', '0966',	'087D', '0875',	'0969', '0968',	'089C', '0936',	'0872', '094F',	'091B', '0819',	'0941', '092F',	'091D', '0367',	'091A', '0952',	'0860', '0961',	'088D', '096A',	'085C', '085F',	'086A', '0876',	'0962', '0364',	'0863', '0958',	'092C', '094C',	'0931', '0954',	'093F', '092A',	'0944', '08A5',	'0920', '091C',	'0942', '092E',	'088F', '0926',	'07EC', '0368',	'0947', '0868',	'095B', '02C4',	'095C', '0802',	'0946', '095E',	'094A', '085E',	'0878', '087E',	'0932', '089E',	'089D', '0935',	'087C', '0885',	'0919', '0867',	'0366', '08A8',	'0928', '0922',	'0949', '0964',	'0886', '083C',	'0917', '088B',	'0360', '0880',	'086B', '08A4',	'0927', '0815',	'08A0', '0882',	'0883', '0894',	'0436', '08A7',	'08A2', '087F',	'0929', '0943',	'0365', '0955',	'08A1', '0281',	'085D', '089A',
	};
		
	foreach my $key (keys %{$self->{sync_ex_reply}}) { $packets{$key} = ['sync_request_ex']; }
	foreach my $switch (keys %packets) { $self->{packet_list}{$switch} = $packets{$switch}; }
	
	my %handlers = qw(
		received_characters 099D
		received_characters_info 082D
		sync_received_characters 09A0
	);

	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;
	
	return $self;
}
	
sub sync_received_characters {
	my ($self, $args) = @_;

	$charSvrSet{sync_Count} = $args->{sync_Count} if (exists $args->{sync_Count});
	
	# When XKore 2 client is already connected and Kore gets disconnected, send sync_received_characters anyway.
	# In most servers, this should happen unless the client is alive
	# This behavior was observed in April 12th 2017, when Odin and Asgard were merged into Valhalla
	for (1..$args->{sync_Count}) {
		$messageSender->sendToServer($messageSender->reconstruct({switch => 'sync_received_characters'}));
	}
}

# 0A36
sub monster_hp_info_tiny {
	my ($self, $args) = @_;
	my $monster = $monstersList->getByID($args->{ID});
	if ($monster) {
		$monster->{hp} = $args->{hp};
		
		debug TF("Monster %s has about %d%% hp left
", $monster->name, $monster->{hp} * 4), "parseMsg_damage"; # FIXME: Probably inaccurate
	}
}

*parse_quest_update_mission_hunt = *Network::Receive::ServerType0::parse_quest_update_mission_hunt_v2;
*reconstruct_quest_update_mission_hunt = *Network::Receive::ServerType0::reconstruct_quest_update_mission_hunt_v2;

1;
