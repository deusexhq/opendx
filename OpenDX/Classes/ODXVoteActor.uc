//================================================================================
// Votes
//1 tdm
//2 dm
//3 jugger
//4 team jugger
//5 kc
//6 team kc
//7 inf
//8 gg
//9 ss
//================================================================================
class ODXVoteActor extends Actor;

var TCPlayer VPs[32];
var int VoteCounter[10];

var string FinalVoteStr;

function CalcHighest()
{
	local int i, a, s;
	
	i=0;
	
	for(a=0;a<10;a++)
	{
		Log(VoteCounter[a]$" at "$a$" "$GetGT(a));
		if(VoteCounter[a] > i)
		{
			Log("New leader "$a$" "$GetGT(a));
			i = VoteCounter[a];
			s = a;
		}
	}
	
	if(s == 1)
		FinalVoteStr = "TCTeam";
	if(s == 2)
		FinalVoteStr = "TCDeathmatch";
	if(s == 3)
		FinalVoteStr = "JuggernautDM";
	if(s == 4)
		FinalVoteStr = "Juggernaut";
	if(s == 5)
		FinalVoteStr = "KillConfirmed";
	if(s == 6)
		FinalVoteStr = "KillConfirmedTeam";
	if(s == 7)
		FinalVoteStr = "Infection";
	if(s == 8)
		FinalVoteStr = "GunGame";
	if(s == 9)
		FinalVoteStr = "Sharpshooter";
}

function AcceptVote(TCPlayer Voter, int i)
{
	local int f;
	local bool bFound;
	local string n;
	
	for(f=0;f<32;f++)
		if(VPs[f] == Voter)
			bFound=True;
			
	if(!bFound)
	{
		n = GetGT(i);
		VoteCounter[i]++;
		CalcHighest();
		BroadcastMessage(Voter.PlayerReplicationInfo.PlayerName$" voted for "$n$". Game mode will be "$FinalVoteStr$" next.");
		for(f=0;f<32;f++)
			if(VPs[f] == None)
			{
				VPs[f] = Voter;
				return;
			}
	}
}

function string GetGT(int i)
{
	if(i == 1)
		return "Team Deathmatch";
	if(i == 2)
		return "Deathmatch";
	if(i == 3)
		return "Juggernaut";
	if(i == 4)
		return "Team Juggernaut";
	if(i == 5)
		return "Kill Confirmed";
	if(i == 6)
		return "Team Kill Confirmed";
	if(i == 7)
		return "Infection";
	if(i == 8)
		return "Arsenal GunGame";
	if(i == 9)
		return "Sharpshooter";
}
defaultproperties
{
    bHidden=true
}
