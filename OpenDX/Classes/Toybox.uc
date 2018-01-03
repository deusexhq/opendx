//=============================================================================
// yee
//=============================================================================
class Toybox expands TCDeathmatch;

event PlayerPawn Login (string Portal, string Z56, out string Z57, Class<PlayerPawn> SpawnClass)
{
	local TCPlayer Z5B;
	local string Z68;
	local string Z69;
	local int Z6A;
	local string myString;
	local class<scriptedpawn> spawn;
	local int j,p;
	
	if ( (MaxPlayers > 0) && (NumPlayers >= MaxPlayers) )
	{
		Z57=TooManyPlayers;
		return None;
	}
	SpawnClass=DefaultPlayerClass;
	Z68=ParseOption(Z56,"Class");
	Z6A=InStr(Z68,".");
	if ( Z6A != -1 )
	{
		Z69=Mid(Z68,Z6A + 1);
		Z68=Left(Z68,Z6A);
	} else {
		Z69=Z68;
		Z68="";
	}

	SpawnClass=Class'ToyMC';
	
	ChangeOption(Z56,"Class",string(SpawnClass));
	Z5B=TCPlayer(Super.Login(Portal,Z56,Z57,SpawnClass));
	if ( Z5B != None )
	{
		Z5B.V52(Z5B.PlayerReplicationInfo.PlayerName);
	}
	
		j=Rand(10);
		Z5B.Mesh = PSKIN[j].default.Mesh;
		Z5B.DrawScale = 0.18;
		for (p = 0; p < 8; p++)
		{
			Z5B.MultiSkins[p] = PSKIN[j].default.MultiSkins[p];
		}
			
	return Z5B;
}

defaultproperties
{
	bToybox=True
    DefaultPlayerClass=Class'ToyMC'
    GameReplicationInfoClass=Class'TCGRI'
}
