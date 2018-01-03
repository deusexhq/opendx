class TCLoader extends Actor;

function BeginPlay()
{
    local TCControls curManager;
    local bool bFound;
    local string currentMap;
    local class<GameInfo> currentGameClass, newGameClass;
    local int testint;

    foreach AllActors(class'TCControls', curManager)
    if(curManager != None)
        bFound = true;

    if(!bFound && ROLE == ROLE_Authority)
    {
        currentGameClass = Level.Game.Class;
        currentMap = left(string(Level), instr(string(Level), "."));
        switch(currentGameClass)
        {
            case class'DeathMatchGame':   newGameClass = class'TCDeathmatch'; break;
            case class'TeamDMGame':       newGameClass = class'TCTeam';       break;
            case class'BasicTeamDMGame':  newGameClass = class'TCTeam';  break;
            case class'AdvTeamDMGame':    newGameClass = class'TCTeam';    break;
            case class'MTLDeathMatch':    newGameClass = class'TCDeathmatch'; break;
            case class'MTLTeam':          newGameClass = class'TCTeam';       break;
            case class'MTLBasicTeam':     newGameClass = class'TCTeam';  break;
            case class'MTLAdvTeam':       newGameClass = class'TCTeam';    break;
        }
		
        if(newGameClass != None)
        {
            Log("Loading OpenDX.", 'OpenDX');
               ConsoleCommand("servertravel"@currentMap$"?Game="$string(newGameClass));
        }
    }
    else
        Destroy();
}

defaultproperties
{
	bHidden=True
}
