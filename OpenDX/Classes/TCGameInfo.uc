//=============================================================================
// SSGameInfo
//=============================================================================
class TCGameInfo extends MTLGameInfo; 

/*function bool ApproveClass (Class<PlayerPawn> S40) 
{ 
   return True; 
}
*/
event playerpawn Login
(
	string Portal,
	string Options,
	out string Error,
	class<playerpawn> SpawnClass
)
{
	local DeusExPlayer player;
	local NavigationPoint StartSpot;
	local byte InTeam;
	local DumpLocation dump;

   //DEUS_EX AMSD In non multiplayer games, force JCDenton.
   //KAI_SER ASMR Except no not really, force our new class, DO IT.
   if (!ApproveClass(SpawnClass))
   {
      SpawnClass=class'TCMJ12';
   }

	player = DeusExPlayer(Super.Login(Portal, Options, Error, SpawnClass));

	if ((player != None) && (!HasOption(Options, "Loadgame")))
	{
		player.ResetPlayerToDefaults();

		dump = player.CreateDumpLocationObject();

		if ((dump != None) && (dump.HasLocationBeenSaved()))
		{
			dump.LoadLocation();

			player.Pause();
			player.SetLocation(dump.currentDumpLocation.Location);
			player.SetRotation(dump.currentDumpLocation.ViewRotation);
			player.ViewRotation = dump.currentDumpLocation.ViewRotation;
			player.ClientSetRotation(dump.currentDumpLocation.ViewRotation);

			CriticalDelete(dump);
		}
		else
		{
			InTeam    = GetIntOption( Options, "Team", 0 ); // Multiplayer now, defaults to Team_Unatco=0
         if (Level.NetMode == NM_Standalone)			
            StartSpot = FindPlayerStart( None, InTeam, Portal );
         else
            StartSpot = FindPlayerStart( Player, InTeam, Portal );

			player.SetLocation(StartSpot.Location);
			player.SetRotation(StartSpot.Rotation);
			player.ViewRotation = StartSpot.Rotation;
			player.ClientSetRotation(player.Rotation);
		}
	}
	return player;
}

defaultproperties
{
     DefaultPlayerClass=Class'TCPlayer'
     GameReplicationInfoClass=Class'TCGRI'
}
