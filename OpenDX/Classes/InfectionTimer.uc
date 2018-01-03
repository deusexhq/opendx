//================================================================================
// External time-keeper for Sharpshooter
//================================================================================
class InfectionTimer extends Actor;

var Infection myGame;

function bool bAllInfected()
{
	local TCPRI infecteds;

	foreach AllActors(class'TCPRI', infecteds)
		if(!infecteds.bInfected)
			return False;
	
	return True;
}

function Timer()
{
	local TCPRI infecteds;
	local int c;
	
	foreach AllActors(class'TCPRI', infecteds)
		c++;
	
	if(c != 0)
	{
		//NEW: If all players are infected, the infected "team" wins, naming the main carrier
		if(bAllInfected())
		{
			myGame.PreGameOver();
			myGame.PlayerHasWon( myGame.MainCarrier, myGame.MainCarrier, None, "Infection" );
			myGame.GameOver();
		}
	}
}

defaultproperties
{
    bHidden=true
}
