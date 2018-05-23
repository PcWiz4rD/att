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
	'0870', '0364',	'088E', '093D',	'0882', '088B',	'08A9', '0881',	'085F', '085E',	'0965', '0871',	'085D', '0867',	'087D', '0892',	'092F', '0894',	'08A7', '0878',	'0943', '0919',	'0811', '0368',	'0963', '0937',	'0893', '0955',	'094C', '0966',	'0936', '089E',	'0888', '0946',	'0949', '02C4',	'0917', '088C',	'087B', '0935',	'0945', '0953',	'0942', '0923',	'0921', '0969',	'08A0', '08A8',	'0874', '089C',	'0802', '0899',	'0896', '092B',	'0817', '0866',	'08AA', '08AB',	'0941', '087A',	'087F', '08A4',	'0365', '0886',	'094D', '0875',	'0880', '095B',	'086C', '095F',	'022D', '0933',	'0367', '0930',	'0947', '0959',	'0369', '096A',	'0952', '0920',	'092D', '0895',	'091F', '0835',	'0928', '0838',	'095A', '0950',	'093E', '091E',	'0861', '0897',	'0884', '095D',	'087E', '0929',	'088A', '0964',	'0360', '0437',	'0864', '085B',	'093C', '0926',	'0967', '0860',	'0868', '0436',	'091B', '091D',	'0939', '0366',	'086A', '0956',	'086F', '0438',	'0363', '0883',	'0931', '0961',	'0815', '095C',	'0927', '0968',	'08A1', '0918',	'086B', '091A',	'08A2', '092A',	'091C', '085C',	'0954', '089A',	'0869', '035F',	'0934', '0960',	'086E', '095E',	'0890', '0819',	'0887', '0944',	'0891', '0924',	'0957', '0885',	'08AC', '094F',	'0862', '0940',	'0948', '0865',	'092E', '089B',	'0938', '0281',	'0932', '0962',	'092C', '0872',	'088F', '086D',	'0877', '0202',	'089D', '0898',
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
