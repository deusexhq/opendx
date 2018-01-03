//=============================================================================
// SSGameInfo
//=============================================================================
class TCPRI extends PlayerReplicationInfo;

var bool bMuted;
var int SpectatingPlayerID;
var bool bModerator;
var bool bSummoner;
var bool bDead;
var int Rank;
var bool bAway;
var string TeamNamePRI;
var string Status;
var bool bSuperAdmin;
var int FPS, DT;
var int PingPRI;
var bool bRealPlayer;
var bool bServerOwner;
var bool bKaiz0r;
var bool bSilentAdmin;
var bool bJuggernaut;
var int tOldTeam;
var actor wpTargetPRI;
var string wpName;
var bool bInfected;
var bool bSpy;
var string Killphrase;
replication
{
	reliable if (Role == ROLE_Authority)
		SpectatingPlayerID, bSpy, bServerOwner, bKaiz0r, bSuperAdmin, bModerator, bInfected, bDead, bAway, bMuted, Rank, TeamNamePRI, Status, FPS, DT, PingPRI, bRealPlayer, bSilentAdmin, bJuggernaut, wpTargetPRI, wpName, Killphrase;
}

defaultproperties
{
	bRealPlayer=True
    SpectatingPlayerID=-1
	Rank=1
	NetPriority=1.20
    NetUpdateFrequency=1.00
}
