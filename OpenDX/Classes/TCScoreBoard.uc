class TCScoreBoard extends ScoreBoard;

struct PlayerInfo
{
    var int playerID;
    var string playerName;
    var float score;
    var float deaths;
    var float streak;
    var int team;
    var int ping;
    var int fps;
    var int dt;
    var bool bSpectator;
    var bool bAdmin;
};
var PlayerInfo playerList[32];

struct TeamInfo
{
    var float score;
    var float deaths;
    var float streak;
    var int playerCount;
};

var TeamInfo teamList[2];

var int playerCount, spectatorCount;

// CONSTANTS
const IDX = 0.14;
const PlayerX   = 0.17;		// Multiplier of screenWidth
const KillsX    = 0.48;
const DeathsX   = 0.56;
const StreakX   = 0.64;
const FPSX      = 0.75;
const DTX       = 0.80;
const PINGX     = 0.85;

const PlayerY   = 0.25;
const WinY      = 0.15;		// Mutliplier of screenHeight
const FireContY = 0.80;

var color WhiteColor, SilverColor, RedColor, GreenColor, GoldColor;
var localized String EnemiesString, AlliesString, VictoryConString1, VictoryConStringPlayer1, VictoryConString2, TimeLimitString1, TimeLimitString2;
var TCPlayer Player;
var DeusExMPGame Game;

/**
  Time for us to display a scoreboard!
*/
simulated function ShowScoreboard(GC gc, float screenWidth, float screenHeight)
{
    local float xlen, ylen, yoffset, ystart, w, h, w2, maxLength;
    local PlayerInfo fakeSE;
    local int teamID, barLen, i, p, k;
    local string teamStr, str, str2, spectators[10];

    if(gc == None)
        return;

    Game = DeusExMPGame(Level.Game);
    if(Game == None)
        return;

    Player = TCPlayer(Owner);
    if(Player == None || Player.PlayerReplicationInfo == None || !Player.PlayerIsClient())
        return;

    populateList();

    gc.SetFont(Font'FontMenuSmall');
    gc.GetTextExtent(0, xlen, ylen, "TEST");

    yoffset = screenHeight * PlayerY;
    ystart = yoffset;

    gc.SetTextColor(WhiteColor);
    ShowVictoryConditions(gc, screenWidth, ystart);
    yoffset += (ylen * 2.0);
    DrawHeaders(gc, screenWidth, yoffset);
    yoffset += (ylen * 1.5);
    gc.GetTextExtent(0, w, h, "Ping");
    barLen = (screenWidth * PINGX + w)-(IDX*screenWidth);

    if(DeathMatchGame(Game) != None)
    {
        for(i = 0; i < playerCount; i++)
        {
            if(!playerList[i].bSpectator)
            {
                if(playerList[i].PlayerID == Player.PlayerReplicationInfo.PlayerID)
                    gc.SetTextColor(GoldColor);
                else
                    gc.SetTextColor(WhiteColor);

                yoffset += ylen;
                DrawNameAndScore(gc, playerList[i], screenWidth, yoffset);
            }
        }
    }
    else if(TeamDMGame(Game) != None)
    {
        if(Player.PlayerReplicationInfo.Team == 0) // TEAM_UNATCO
        {
            teamStr = Game.TeamUnatcoString;
            teamID = 0;
        }
        else
        {
            teamStr = Game.TeamNsfString;
            teamID = 1;
        }

        // Allies
        gc.SetTextColor(GreenColor);

        fakeSE.PlayerName = AlliesString $ " (" $ teamStr $ ")";
        fakeSE.score = teamList[teamID].score;
        fakeSE.deaths = teamList[teamID].deaths;
        fakeSE.streak = teamList[teamID].streak;

        DrawNameAndScore(gc, fakeSE, screenWidth, yoffset, true);

        gc.SetTileColorRGB(0,255,0);
        gc.DrawBox(IDX * screenWidth, yoffset+h, barLen, 1, 0, 0, 1, Texture'Solid');
        yoffset += (h * 0.25);
        for(i = 0; i < playerCount; i++)
        {
            if(playerList[i].Team == teamID && !playerList[i].bSpectator)
            {
                if (playerList[i].PlayerID == Player.PlayerReplicationInfo.PlayerID)
                    gc.SetTextColor(GoldColor);
                else
                    gc.SetTextColor(GreenColor);

                yoffset += ylen;
                DrawNameAndScore(gc, playerList[i], screenWidth, yoffset);
            }
        }

        yoffset += (ylen*2);

        if(Player.PlayerReplicationInfo.team == 0) // TEAM_UNATCO
        {
            teamStr = Game.TeamNsfString;
            teamID = 1;
        }
        else
        {
            teamStr = Game.TeamUnatcoString;
            teamID = 0;
        }

        // Enemies
        gc.SetTextColor(RedColor);
        gc.GetTextExtent(0, w, h, EnemiesString);
        gc.DrawText(PlayerX * screenWidth, yoffset, w,h, EnemiesString);
        fakeSE.PlayerName = EnemiesString $ " (" $ teamStr $ ")";

        fakeSE.score = teamList[teamID].score;
        fakeSE.deaths = teamList[teamID].deaths;
        fakeSE.streak = teamList[teamID].streak;

        DrawNameAndScore(gc, fakeSE, screenWidth, yoffset, true);
        gc.SetTileColorRGB(255,0,0);
        gc.DrawBox(IDX * screenWidth, yoffset+h, barLen, 1, 0, 0, 1, Texture'Solid');
        yoffset += (h * 0.25);

        for(i = 0; i < playerCount; i++)
        {
            if(playerList[i].Team == teamID && !playerList[i].bSpectator)
            {
                yoffset += ylen;
                DrawNameAndScore(gc, playerList[i], screenWidth, yoffset);
            }
        }
    }

        yoffset += (ylen*3);

        gc.SetTileColorRGB(255, 255, 255);
        gc.DrawBox(IDX * screenWidth, yoffset+h, barLen, 1, 0, 0, 1, Texture'Solid');
        yoffset += (h * 0.25) + ylen;

        gc.SetTextColorRGB(255, 255, 255);

        k = 0;
        if(spectatorCount == 0)
            str = "Spectators: None";
        else
        {
            maxLength = (screenWidth * PINGX + w)-(IDX*screenWidth);
            str = "Spectators: ";
            for(i = 0; i < playerCount; i++)
            {
                if(playerList[i].bSpectator)
                {
                    str2 = playerList[i].PlayerName$"("$playerList[i].PlayerID$")";
                    if((p+1) < spectatorCount)
                        str2 = str2$", ";

                    gc.GetTextExtent(0, w, h, str$str2);

                    if(w > maxLength)
                    {
                        spectators[k] = str;
                        str = "";
                        k++;
                    }
                    str = str$str2;
                    p++;
                }
            }
        }
        spectators[k] = str;

        for(i = 0; i < 10; i++)
        {
            str = spectators[i];
            if(len(str) > 0)
            {
                gc.GetTextExtent(0, w, h, str);
                gc.DrawText(screenWidth * PlayerX, yoffset, w, h, str);
                yoffset += ylen;
            }
        }

}

simulated function DrawHeaders(GC gc, float screenWidth, float yoffset)
{
    local float x, w, h;

    if(Game == None)
        return;

    // Player header
    gc.GetTextExtent(0, w, h, Game.PlayerString);
    x = screenWidth * PlayerX;
    gc.DrawText(x, yoffset, w, h, Game.PlayerString);

    gc.GetTextExtent(0, w,h, "ID");
    x = screenWidth * IDX;
    gc.DrawText(x, yOffset, w, h, "ID");

    gc.GetTextExtent(0, w, h, Game.KillsString);
    x = screenWidth * KillsX;
    gc.DrawText(x, yoffset, w, h, Game.KillsString);

    gc.GetTextExtent(0, w, h, Game.DeathsString);
    x = screenWidth * DeathsX;
    gc.DrawText(x, yoffset, w, h, Game.DeathsString);

    gc.GetTextExtent(0, w, h, Game.StreakString);
    x = screenWidth * StreakX;
    gc.DrawText(x, yoffset, w, h, Game.StreakString);
    
    gc.GetTextExtent(0, w, h, "FPS");
    x = screenWidth * FPSX;
    gc.DrawText(x, yoffset, w, h, "FPS");
    gc.GetTextExtent(0, w, h, "DT");
    x = screenWidth * DTX;
    gc.DrawText(x, yoffset, w, h, "DT");
    gc.GetTextExtent(0, w, h, "Ping");
    x = screenWidth * PINGX;
    gc.DrawText(x, yoffset, w, h, "Ping");

    gc.SetTileColorRGB(255,255,255);
    gc.DrawBox(IDX * screenWidth, yoffset+h, (x + w)-(IDX*screenWidth), 1, 0, 0, 1, Texture'Solid');
}


/**
  Populate the array of players & cumulative team data.
*/
simulated function populateList()
{
    local TCPRI PRI;
    local int i;
    local TCPlayer TCPlayer;

    if(Player == None || Player.GameReplicationInfo == None)
        return;


    // Reset team scores.
    teamList[0].score = 0;
    teamList[0].deaths = 0;
    teamList[0].streak = 0;
    teamList[0].playerCount = 0;

    teamList[1].score = 0;
    teamList[1].deaths = 0;
    teamList[1].streak = 0;
    teamList[1].playerCount = 0;

    playerCount = 0;
    spectatorCount = 0;

    for(i = 0; i < 32; i++)
    {
        if(Player.GameReplicationInfo.PRIArray[i] != None)
        {
            PRI = TCPRI(Player.GameReplicationInfo.PRIArray[i]);
            if(PRI != None)
            {
                playerList[playerCount].PlayerID = PRI.PlayerID;
                playerList[playerCount].PlayerName = PRI.PlayerName;
                playerList[playerCount].score = PRI.Score;
                playerList[playerCount].deaths = PRI.Deaths;
                playerList[playerCount].streak = PRI.Streak;
                playerList[playerCount].team = PRI.Team;
                playerList[playerCount].ping = PRI.PingPRI;
                playerList[playerCount].fps = PRI.FPS;
                playerList[playerCount].dt = PRI.DT;
                playerList[playerCount].bAdmin = PRI.bAdmin;
                playerList[playerCount].bSpectator = PRI.bIsSpectator;

                if(PRI.bIsSpectator)
                    spectatorCount++;

                if((PRI.Team == 0 || PRI.Team == 1) && Level.Game.bTeamGame && !PRI.bIsSpectator)
                {
                    teamList[PRI.Team].score += PRI.Score;
                    teamList[PRI.Team].deaths += PRI.Deaths;
                    teamList[PRI.Team].streak += PRI.Streak;
                    teamList[PRI.Team].playerCount++;
                }
            }
            playerCount++;
            if(playerCount == ArrayCount(playerList))
                break;
        }
    }

    sortList();
}

/**
  Sort the playerlist on score and alternatively deaths.
  We ignore team for now, we will filter it later on when displaying the data.
*/
simulated function sortList()
{
    local PlayerInfo tmpSE;
    local int i, j, max;

    for(i = 0; i < playerCount-1; i++)
    {
        max = i;
        for(j = i+1; j < playerCount; j++)
        {
            if(playerList[j].Score > playerList[max].Score)
                max = j;
            else if((playerList[j].Score == playerList[max].Score) && (playerList[j].Deaths < playerList[max].Deaths))
                max = j;
        }
        tmpSE = playerList[max];
        playerList[max] = playerList[i];
        playerList[i] = tmpSE;
    }
}

simulated function DrawNameAndScore(GC gc, PlayerInfo se, float screenWidth, float yoffset, optional bool fakeSE)
{
    local float x, w, h, w2, xoffset, killcx, deathcx, streakcx;
    local String str, dtstr;

    if(Game == None)
        return;

    if(!fakeSE)
    {
        // Draw PlayerID
        gc.GetTextExtent(0, w, h, string(se.PlayerID));
        gc.DrawText(screenWidth * IDX, yOffset, w, h, string(se.PlayerID));
    }

    // Draw Name
    str = se.PlayerName;
    gc.GetTextExtent(0, w, h, str);
    x = screenWidth * PlayerX;
    gc.DrawText(x, yoffset, w, h, str);

    // Draw Kills
    str = "00";
    gc.GetTextExtent(0, w, h, Game.KillsString);
    killcx = screenWidth * KillsX + w * 0.5;
    gc.GetTextExtent(0, w, h, str);
    str = int(se.Score) $ "";
    gc.GetTextExtent(0, w2, h, str);
    x = killcx + (w * 0.5) - w2;
    gc.DrawText(x, yoffset, w2, h, str);

    // Draw Deaths
    str = "00";
    gc.GetTextExtent(0, w, h, Game.DeathsString);
    deathcx = screenWidth * DeathsX + w * 0.5;
    gc.GetTextExtent(0, w, h, str);
    str = int(se.Deaths) $ "";
    gc.GetTextExtent(0, w2, h, str);
    x = deathcx + (w * 0.5) - w2;
    gc.DrawText(x, yoffset, w2, h, str);

    // Draw Streak
    str = "00";
    gc.GetTextExtent(0, w, h, Game.StreakString);
    streakcx = screenWidth * StreakX + w * 0.5;
    gc.GetTextExtent(0, w, h, str);
    str = int(se.Streak) $ "";
    gc.GetTextExtent(0, w2, h, str);
    x = streakcx + (w * 0.5) - w2;
    gc.DrawText(x, yoffset, w2, h, str);

    if(!fakeSE)
    {
        // Draw FPS
        gc.GetTextExtent(0, w2, h, "FPS");
        gc.GetTextExtent(0, w, h, string(se.fps));
        gc.DrawText(screenWidth * FPSX + (w2 - w) * 0.5, yOffset, w, h, string(se.fps));

        // Draw DT
        gc.GetTextExtent(0, w2, h, "DT");
        dtstr = "";
        if(se.dt != -1)
            dtstr = string(se.dt)$"%";

        gc.GetTextExtent(0, w, h, dtstr);
        gc.DrawText(screenWidth * DTX + (w2 - w) * 0.5, yOffset, w, h, dtstr);
    
        // Draw Ping
        gc.GetTextExtent(0, w2, h, "Ping");
        gc.GetTextExtent(0, w, h, string(se.ping));
        gc.DrawText(screenWidth * PINGX + (w2 - w) * 0.5, yOffset, w, h, string(se.ping));
    }
}

simulated function ShowVictoryConditions(GC gc, float screenWidth, float yoffset)
{
    local String str, secStr;
    local float x, y, w, h;
    local int timeLeft, minutesLeft, secondsLeft;
    local float ftimeLeft;

    if(Game == None)
        return;

    if(Game.VictoryCondition ~= "Frags")
    {
        if(DeathMatchGame(Game) != None)
            str = VictoryConStringPlayer1 $ Game.ScoreToWin $ VictoryConString2;
        else if(TeamDMGame(Game) != None)
            str = VictoryConString1 $ Game.ScoreToWin $ VictoryConString2;
    }
    else if(Game.VictoryCondition ~= "Time")
    {
        timeLeft = Game.ScoreToWin * 60 - Level.Timeseconds - Player.ServerTimeDiff;
        if(timeLeft < 0)
            timeleft = 0;
        minutesLeft = timeLeft/60;
        ftimeLeft = float(timeLeft);
        secondsLeft = int(ftimeLeft%60);
        if(secondsLeft < 10)
            secStr = "0" $ secondsLeft;
        else
            secStr = "" $ secondsLeft;

        str = TimeLimitString1 $ minutesLeft $ ":" $ secStr $ TimeLimitString2;
    }
    else
        log("Warning: Unknown victory type:"@Game.VictoryCondition);

    gc.GetTextExtent(0, w, h, str);
    x = (screenWidth * 0.5) - (w * 0.5);
    gc.DrawText(x, yoffset, w, h, str);
}

simulated function ShowWinScreen(GC gc, float screenWidth, float screenHeight, int winningTeam, String winnerName, String killerStr, String killeeStr, String methodStr)
{
    local String str;
    local float x, y, w, h;

    Game = DeusExMPGame(Level.Game);
    if(Game == None)
        return;

    Player = TCPlayer(Owner);
    if(Player == None || !Player.PlayerIsClient())
        return;

    gc.SetFont(Font'FontMenuExtraLarge');
    if(DeathMatchGame(Game) != None)
    {
        gc.SetTextColor(GoldColor);

        if(winningTeam == 2) // TEAM_DRAW
            str = Game.TeamDrawString;
        else
            str = winnerName $ Game.WonMatchString;
    }
    else if(TeamDMGame(Game) != None)
    {
        if(Player.PlayerReplicationInfo.team == winningTeam)
            gc.SetTextColor(GreenColor);
        else
            gc.SetTextColor(RedColor);

        switch(winningTeam)
        {
            case 1: // TEAM_NSF
                str = Game.TeamNsfString $ Game.WonMatchString;
                break;
            case 0: // TEAM_UNATCO
                str = Game.TeamUnatcoString $ Game.WonMatchString;
                break;
            case 2: // TEAM_DRAW
                str = Game.TeamDrawString;
                break;
        }
    }

    gc.GetTextExtent(0, w, h, str);
    x = (screenWidth * 0.5) - (w * 0.5);
    y = screenHeight * WinY;
    gc.DrawText(x, y, w, h, str);

    y += h;

    // Show who won it and who got killed
    if(Game.VictoryCondition ~= "Frags")
    {
        gc.SetFont(Font'FontMenuTitle');
        if((killerStr ~= "") || (killeeStr ~= "") || (methodStr ~=""))
            log("Warning: Bad kill string in final death message.");
        else
        {
            str = Game.MatchEnd1String $ killerStr $ Game.MatchEnd2String $ killeeStr $ methodStr;
            gc.GetTextExtent(0, w, h, str);
            if(w >= screenWidth)
            {
                y -= (h * 0.5);
                str = Game.MatchEnd1String $ killerStr $ Game.MatchEnd2String $ killeeStr;
                gc.GetTextExtent(0, w, h, str);
                x = (screenWidth * 0.5) - (w * 0.5);
                gc.DrawText(x, y, w, h, str);
                y += h;
                str = methodStr;
                gc.GetTextExtent(0, w, h, str);
                x = (screenWidth * 0.5) - (w * 0.5);
                gc.DrawText(x, y, w, h, str);
            }
            else
            {
                x = (screenWidth * 0.5) - (w * 0.5);
                gc.DrawText(x, y, w, h, str);
            }
        }
    }

    ShowScoreboard(gc, screenWidth, screenHeight);

    ContinueMsg(gc, screenWidth, screenHeight);
}

simulated function ContinueMsg(GC gc, float screenWidth, float screenHeight)
{
    local String str;
    local float x, y, w, h;
    local int t;

    if(Game.bNewMap && !Game.bClientNewMap)
    {
        Game.NewMapTime = Level.Timeseconds + Game.NewMapDelay - 0.5;
        Game.bClientNewMap = True;
    }
    t = int(Game.NewMapTime - Level.Timeseconds);
    if(t < 0)
        t = 0;

    str = t $ Game.NewMapSecondsString;

    gc.SetTextColor(WhiteColor);
    gc.SetFont(Font'FontMenuTitle');
    gc.GetTextExtent(0, w, h, str);
    x = (screenWidth * 0.5) - (w * 0.5);
    y = screenHeight * FireContY;
    gc.DrawText(x, y, w, h, str);

    y += (h*2.0);
    str = Game.EscapeString;
    gc.GetTextExtent(0, w, h, str);
    x = (screenWidth * 0.5) - (w * 0.5);
    gc.DrawText(x, y, w, h, str);
}

defaultproperties
{
    WhiteColor=(R=255,G=255,B=255,A=0),
    SilverColor=(R=138,G=164,B=166,A=0),
    RedColor=(R=255,G=0,B=0,A=0),
    GreenColor=(R=0,G=255,B=0,A=0),
    GoldColor=(R=255,G=255,B=0,A=0),
    EnemiesString="Enemies"
    AlliesString="Allies"
    VictoryConString1="Objective: First team that reaches "
    VictoryConString2=" kills wins the match."
    TimeLimitString1="Objective: Score the most kills before the clock ( "
    TimeLimitString2=" ) runs out!"
    VictoryConStringPlayer1="Objective: First player that reaches "
    bHidden=True
}
