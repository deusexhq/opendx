class TCFPS extends Actor;

var TCPlayer Watcher;
var TCControls Settings;
var TCPRI WPRI;
var int Warns;

function Timer()
{
	if(Watcher != None && WPRI != None)
	{
		if(WPRI.FPS > Settings.FPSCap)
		{
			Watcher.ClientMessage("|P2Warning: An FPS cap is enforced on this server. Please cap your FPS to under "$Settings.FPSCap);
			Watcher.CheatWarns++;
			
			if(Watcher.CheatWarns >= 3)
			{
				BroadcastMessage(WPRI.PlayerName$" was removed from the game. (Reason: FPS above limit)");
				Watcher.Destroy();
			}
		}
	}
	else Destroy();
}

defaultproperties
{
	bHidden=True
}
