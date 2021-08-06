//=============================================================================
// AugmentationDisplayWindow.
//=============================================================================
class TCAugmentationDisplayWindow extends CBPAugmentationDisplayWindow;

var Color colYellow, colPurple;
var Color	colBlue1, colWhite;
var Color	colGreen1, colLtGreen;
var Color	colRed1, colLtRed;
var string keyFreeMode, keyPersonView, keyMainMenu, keySkills;

function TCPlayer getPlayer()
{
   return TCPlayer(player);
}

function bool GetAllies(TCPlayer POne, TCPlayer PTwo)
{
	if(TCDeathmatch(player.DXGame) != None)
		return TCDeathmatch(player.DXGame).ArePlayersAllied2(POne,PTwo);
		
	if(TCTeam(player.DXGame) != None)
		return TCTeam(player.DXGame).ArePlayersAllied(POne,PTwo);	
}

//EDIT: Added new check for "Smell" system
function bool IsHeatSource(Actor A)
{
	if(A.IsA('ODXHiddenActor')) //Check this first, so it doesnt reach the "Hidden" check below
		return True;
		
   if ((A.bHidden) && (Player.Level.NetMode != NM_Standalone))
      return False;
   if (A.IsA('Pawn'))
   {
      if (A.IsA('ScriptedPawn'))
         return True;
      else if ( (A.IsA('DeusExPlayer')) && (A != Player) )//DEUS_EX AMSD For multiplayer.
         return True;
      return False;
   }
	else if (A.IsA('DeusExCarcass'))
		return True;   
	else if (A.IsA('FleshFragment'))
		return True;
   else
		return False;
}

function GetTargetReticleColor( Actor target, out Color xcolor )
{
	local DeusExPlayer safePlayer;
	local AutoTurret turret;
	local bool bDM, bTeamDM;
	local Vector dist;
	local float SightDist;
	local DeusExWeapon w;
	local int team;
	local String titleString;
	local TCControls TCC;
	local string str;
	local TCStorageBox TCS;
	local string teamstr;
	local TCPRI plPRI, tPRI;
	local TCPlayer tcTarg, tcSelf;
	local ScriptedPawn sPawn;

	bDM = (TCDeathmatch(player.DXGame) != None);
	bTeamDM = (TCTeam(player.DXGame) != None);
	tcSelf = GetPlayer();
	if(tcSelf != None)
		plPRI = TCPRI(tcSelf.PlayerReplicationInfo);
	sPawn = ScriptedPawn(Target);

	if(plPRI == None) // tcSelf == none is implicit if this is true.
	{
		xColor = colWhite;
		return;
	}

	if ( sPawn != None )
	{
		if(tcSelf.HUDTYpe == HUD_Extended) //Shows all info
		{
			targetPlayerName = sPawn.FamiliarName$" ("$Left(VSize(target.Location - Player.Location), Len(VSize(target.Location - Player.Location))-7)$")";
			xcolor = colYellow;
		}
		else if(tcSelf.HUDTYpe == HUD_Basic) //Shows basic info
		{
			targetPlayerName = sPawn.FamiliarName;
			xcolor = colYellow;
		}
		else if(tcSelf.HUDTYpe == HUD_Unified) //Masks bots as players
		{
			targetPlayerName = sPawn.FamiliarName;
			xcolor = colRed;
		}
		else if(tcSelf.HUDTYpe == HUD_Original) //As original DX, bots are friendlies, no name display
		{
			targetPlayerName = "";
			xcolor = colGreen;
		}
		else if(tcSelf.HUDTYpe == HUD_Off)
			targetPlayerName = "";
			
		targetPlayerTime = Player.Level.Timeseconds + targetPlayerDelay;
		targetPlayerColor = xcolor;
	}
	else if ( Player.Level.NetMode != NM_Standalone )	// Only do the rest in multiplayer
	{
		if ( target.IsA('TCStorageBox') )
		{
			TCS = TCStorageBox(Target);
			if (bTeamDM)
			{ 
				if(GetAllies(TCPlayer(TCS.Owner),tcSelf) || tcSelf == TCS.Owner)
					xcolor = colGreen;
				else
					xcolor = colRed;
					
				if(TCS.myName != "")
					str = TCS.myName;
				else str = TCS.OwnerName$"'s storage";
				targetPlayerName = str;
				targetPlayerTime = Player.Level.Timeseconds + targetPlayerDelay;
				targetPlayerColor = xcolor;
			}
			else if(bDM)
			{
				if(GetAllies(TCPlayer(TCS.Owner),tcSelf) || tcSelf == TCS.Owner)
					xcolor = colGreen;
				else
					xcolor = colRed;
				
				if(TCS.myName != "")
					str = TCS.myName;
				else str = TCS.OwnerName$"'s storage";
				targetPlayerName = str;
				targetPlayerTime = Player.Level.Timeseconds + targetPlayerDelay;
				targetPlayerColor = xcolor;
			}
		}
		else if ( target.IsA('DeusExPlayer') && (target != player) )	// Other players IFF
		{
			tcTarg = TCPlayer(Target);
			if(tcTarg != none)
				tPRI = TCPRI(tcTarg.PlayerReplicationInfo);

			if(tPRI != None)
			{
				if (bTeamDM)
				{ 
					str = tPRI.PlayerName;

					if(tPRI.bSpy || GetAllies(tcTarg,tcSelf))
					{
						TargetPlayerHealthString = " (" $ 100 * (tcTarg.Health / tcTarg.Default.Health) $ "%)";
						xcolor = colGreen;
					}
					else
						xcolor = colRed;
					
					targetPlayerName = str;
				}
				else if(bDM && target.Style != STY_Translucent) //Kaiz0r - Adding DM Stuff here
				{					
					if(tcSelf.HUDTYpe == HUD_Extended) //Shows all info
					{
						if(plPRI.TeamNamePRI == "") //If not in team
							xcolor = colPurple;
						
						if(plPRI.TeamNamePRI != "") //if WE are in a team
						{
							if(tPRI.bSpy || GetAllies(tcTarg,tcSelf))
							{
								TargetPlayerHealthString = " (" $ 100 * (tcTarg.Health / tcTarg.Default.Health) $ "%)";
								xcolor = colGreen;
							}
							else
								xcolor = colRed;
						}

						str = tPRI.PlayerName;
						
						str = str$" ("$Left(VSize(target.Location - Player.Location), Len(VSize(target.Location - Player.Location))-7)$")";
						
						if(tPRI.TeamNamePRI != "")
							str = str$" |C616200#|P7"$tPRI.TeamNamePRI;
							
						targetPlayerName = str;
					}
					
					if(tcSelf.HUDTYpe == HUD_Basic) //Shows basic info
					{
						if(tPRI.TeamNamePRI == "")//If not in team
							xcolor = colPurple;
						
						if(tPRI.TeamNamePRI != "") //if WE are in a team
						{
							if(GetAllies(tcTarg,tcSelf))
							{
								TargetPlayerHealthString = " (" $ 100 * (tcTarg.Health / tcTarg.Default.Health) $ "%)";
								xcolor = colGreen;
							}
							else
								xcolor = colRed;
						}

						str = tPRI.PlayerName;
						
						if(tPRI.TeamNamePRI != "")
							str = str$" |C616200#|P7"$TCPRI(TCPlayer(Target).PlayerReplicationInfo).TeamNamePRI;
							
						targetPlayerName = str;
					}
					
					if(tcSelf.HUDTYpe == HUD_Unified || tcSelf.HUDTYpe == HUD_Original)
					{
						targetPlayerName = tPRI.PlayerName;
						xcolor = colRed;
					}
					
					if(tcSelf.HUDTYpe == HUD_Off)
					{
						targetPlayerName = "";
					}
					
					targetPlayerTime = Player.Level.Timeseconds + targetPlayerDelay;
					targetPlayerColor = xcolor;
				}

				SightDist = VSize(target.Location - Player.Location);
				// This was one of the errors - the brackets prioritised the TeamDMGame cast over the bTeamDM check.
				if	(((bTeamDM) && TeamDMGame(player.DXGame).ArePlayersAllied(DeusExPlayer(target),player))
				||	(target.Style != STY_Translucent)
				||	(bVisionActive && (Sightdist <= visionLevelvalue)) )
				{
					//targetPlayerName = DeusExPlayer(target).PlayerReplicationInfo.PlayerName;
					// DEUS_EX AMSD Show health of enemies with the target active.
					if (bTargetActive)
						TargetPlayerHealthString = "(" $ 100 * (tcTarg.Health / tcTarg.Default.Health) $ "%)";

					targetOutOfRange = False;
					w = DeusExWeapon(player.Weapon);
					if (( w != None ) && ( xcolor != colGreen ))
					{
						dist = player.Location - target.Location;
						if ( VSize(dist) > w.maxRange ) 
						{
							if (!(( WeaponAssaultGun(w) != None ) && ( Ammo20mm(WeaponAssaultGun(w).AmmoType) != None )))
							{
								targetRangeTime = Player.Level.Timeseconds + 0.1;
								targetOutOfRange = True;
							}
						}
					}
					targetPlayerTime = Player.Level.Timeseconds + targetPlayerDelay;
					targetPlayerColor = xcolor;
				}
			}
			else
				xcolor = colWhite;	// cloaked enemy
		}
		else if (target.IsA('ThrownProjectile'))	// Grenades IFF
		{
			if ( ThrownProjectile(target).bDisabled )
				xcolor = colWhite;
			else if ( (GetAllies(TCPlayer(target.Owner),tcSelf)) || 
				(player == TCPlayer(target.Owner)) )
				xcolor = colGreen;
			else
				xcolor = colRed;
		}
		else if ( target.IsA('TCAutoTurret') || target.IsA('AutoTurretGun') ) // Autoturrets IFF
		{
			if ( target.IsA('AutoTurretGun') )
			{
				team = AutoTurretGun(target).team;
				titleString = AutoTurretGun(target).titleString;
			}
			else
			{
				team = AutoTurret(target).team;
				titleString = AutoTurret(target).titleString;
				teamstr = TCPRI(TCPlayer(TCAutoTurret(target).safeTarget).PlayerReplicationInfo).TeamNamePRI;
			}
			if ( (TCDeathmatch(player.dxgame) != none && team == plPRI.playerid) || TCTeam(player.dxgame) != none && team == plPRI.team)
				xcolor = colGreen;
			else if (team == -1)
				xcolor = colWhite;
			else
				xcolor = colRed;

			targetPlayerName = titleString$teamstr;
			targetOutOfRange = False;
			targetPlayerTime = Player.Level.Timeseconds + targetPlayerDelay;
			targetPlayerColor = xcolor;
		}
		else if ( target.IsA('ComputerSecurity'))
		{
			if ( ComputerSecurity(target).team == -1 )
				xcolor = colWhite;
			else if ( (bTeamDM && GetAllies(TCPlayer(target.Owner), tcSelf)) ||
				  (!bTeamDM && (player.PlayerReplicationInfo.PlayerID == team || 
				  GetAllies(TCPlayer(target.Owner), tcSelf))) )
				xcolor = colGreen;
			else
				xcolor = colRed;
		}
		else if ( target.IsA('SecurityCamera'))
		{
			if ( !SecurityCamera(target).bActive )
				xcolor = colWhite;
			else if ( SecurityCamera(target).team == -1 )
				xcolor = colWhite;
			else if ( (bTeamDM && GetAllies(TCPlayer(target.Owner), tcSelf)) ||
				  (!bTeamDM && (player.PlayerReplicationInfo.PlayerID == team || 
				  GetAllies(TCPlayer(target.Owner), tcSelf))) )
				xcolor = colGreen;
			else
				xcolor = colRed;
		}
	}
}

function DrawRemoteInventory(GC gc, TCPlayer mmp)
{
	local int xoff, yoff, ytoff, i;

	yoff = height - 48;
	ytoff = yoff + 32;
	xoff = width - 54;

	gc.SetStyle(DSTY_Masked);
	gc.SetTileColorRGB(255, 255, 255);

	gc.SetAlignments(HALIGN_Center, VALIGN_Center);
	gc.EnableWordWrap(false);
	gc.SetTextColorRGB(255, 255, 255);
	gc.SetFont(Font'FontTiny');

	// draw biocells
	if (mmp.TargetBioCells > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconBioCell');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetBioCells);
	}
	xoff -= 48;
	// draw medkit
	if (mmp.TargetMedkits > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconMedKit');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetMedkits);	
	}
	xoff -= 48;
	// draw multitool
	if (mmp.TargetMultitools > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconMultitool');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetMultitools);
	}
	xoff -= 48;
	// draw lockpick
	if (mmp.TargetLockpicks > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconLockPick');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetLockpicks);
	}
	xoff -= 48;
	// draw lam
	if (mmp.TargetLAMs > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconLAM');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetLAMs);
	}

	xoff = 16;

	// draw weapons
	for (i = 0; i < 3; i++)
	{
		if (mmp.TargetWeapons[i] != none)
		{
			gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, mmp.TargetWeapons[i].default.Icon);
		}
		xoff += 48;
	}

	// draw emp
	if (mmp.TargetEMPs > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconEMPGrenade');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetEMPs);
	}
	xoff += 48;
	// draw gas
	if (mmp.TargetGGs > 0)
	{
		gc.DrawTexture(xoff, yoff, 42, 37, 0, 0, Texture'DeusExUI.Icons.BeltIconGasGrenade');
		gc.DrawText(xoff + 1, ytoff, 42, 8, "COUNT:" @ mmp.TargetGGs);
	}
}

function Texture GetGridTexture(Texture tex)
{
	if (tex == None)
		return Texture'BlackMaskTex';
	else if (tex == Texture'BlackMaskTex')
		return Texture'BlackMaskTex';
	else if (tex == Texture'GrayMaskTex')
		return Texture'BlackMaskTex';
	else if (tex == Texture'PinkMaskTex')
		return Texture'BlackMaskTex';
	else if (VisionTargetStatus == VISIONENEMY)         
      return Texture'Virus_SFX';
   else if (VisionTargetStatus == VISIONALLY)
		return Texture'Wepn_Prifle_SFX';
   else if (VisionTargetStatus == VISIONNEUTRAL)
      return Texture'WhiteStatic';
   else
      return Texture'WhiteStatic';
}

function NameAllViewedPlayers(GC gc, TCPlayer mmp)
{
    local Actor target;
	local TCPlayer P;
	local float x, y;
	local vector loc;
	local bool viewenemy;

	foreach mmp.VisibleCollidingActors(class'Actor', target, 3000.0, mmp.Location, false)
	{
	    if (target.IsA('TCPlayer') && (FacingActor(Pawn(target), mmp) > 0.0))
        {
            P = TCPlayer(target);
            if (P.PlayerReplicationInfo.bIsSpectator || (!mmp.bSpecEnemies && P.PlayerReplicationInfo.Team != mmp.PlayerReplicationInfo.Team)) continue;
            loc = P.Location;
            loc.Z -= P.CollisionHeight + 10.0;
            ConvertVectorToCoordinates(loc, x, y);
            DrawPlayerName(gc, x, y, (mmp.PlayerReplicationInfo.Team == P.PlayerReplicationInfo.Team) && mmp.GameReplicationInfo.bTeamGame, P.PlayerReplicationInfo.PlayerName);
        }
    }
}

function DrawPlayerName(GC gc, float x, float y, bool sameteam, string pname)
{
    local float w, h;

    gc.SetFont(Font'FontMenuSmall');
    gc.SetStyle(DSTY_Translucent);
    if (sameteam) gc.SetTextColor(colGreen);
    else gc.SetTextColor(colRed);
    gc.GetTextExtent(0, w, h, pname);
    x -= w * 0.5;
    y -= h * 0.5;
	gc.DrawText(x, y, w, h, pname);
	gc.SetStyle(DSTY_Normal);
}

function PostDrawWindow(GC gc)
{
	local PlayerPawn pp;
	local TCPlayer mmp;
	local color col;
	local string str;
	local color colGold;
	local int tmpVisionLevel, tmpVisionLevelValue;
	local int VotePoints, mVP;
	local float xx;
	local actor wpTarget;
	local float infoX, infoY, infoW, infoH;
	local string strInfo;
	local int dist;
	local float offset;
	local vector centerLoc;
	local float centerX, centerY;
	local float markX, markY, markW, markH;
	local string markInfo;
	local TCPRI tPRI;

	pp = Player.GetPlayerPawn();
	if(TCPlayer(pp) != None)
		mmp = TCPlayer(pp);
	colGold.R = 255;
    colGold.G = 255;

	if(TCPRI(mmp.PlayerReplicationInfo) != None)
		tPRI = TCPRI(mmp.PlayerReplicationInfo);
		
	if(tPRI == None)
		return;
	
	//BEGIN WP
	if(tPRI.wpTargetPRI != None)
		wpTarget = tPRI.wpTargetPRI;

	if (wpTarget != None)
	{
		centerLoc = wpTarget.Location;

		if (ConvertVectorToCoordinates(centerLoc, centerX, centerY))
		{
			// convert to meters
			dist = int(vsize(mmp.Location-wpTarget.Location)/52);

			if(tPRI.wpName != "")
				strInfo = tPRI.wpName $ " (" $ dist $ "m)";
			else
				strInfo = wpTarget.Tag $ " (" $ dist $ "m)";

			gc.SetFont(Font'FontMenuHeaders_DS');
			gc.GetTextExtent(0, infoW, infoH, strInfo);

			infoX = centerX - 0.5*(infoW+12);
			infoY = centerY - 0.5*(infoH+10);

			offset = 0.5*(infoW+12+32);
			if (centerX >= 0.5*width)
			{
				if (centerX < width-infoW-12-32-16)
					infoX += offset;
				else
					infoX -= offset;
			}
			else
			{
				if (centerX > infoW+12+32+16)
					infoX -= offset;
				else
					infoX += offset;
			}

			infoX = FClamp(infoX, 32, width-infoW-12-32);
			infoY = FClamp(infoY, 16, height-infoH-10-72);
		}

		// draw a dark background
		gc.SetStyle(DSTY_Modulated);
		gc.SetTileColorRGB(0, 0, 0);
		gc.DrawPattern(infoX, infoY, infoW+12, infoH+10, 0, 0, Texture'ConWindowBackground');

		// draw the text
		gc.SetTextColor(colText);
		gc.DrawText(infoX+6, infoY+6, infoW, infoH, strInfo);

		// draw the two highlight boxes
		gc.SetStyle(DSTY_Translucent);
		gc.SetTileColor(colBorder);
		gc.DrawBox(infoX, infoY, infoW+12, infoH+10, 0, 0, 1, Texture'Solid');
		gc.SetTileColor(colBackground);
		gc.DrawBox(infoX+1, infoY+1, infoW+10, infoH+8, 0, 0, 1, Texture'Solid');

		//draw waypoint X mark
		markInfo = "X";
		gc.SetFont(Font'FontMenuHeaders_DS');
		gc.GetTextExtent(0, markW, markH, markInfo);
		markX = centerX-0.5*markW;
		markY = centerY-0.5*markH;
		markX = FClamp(markX, 16-0.5*markW, width-16-0.5*markW);
		markY = FClamp(infoY, 16, height-infoH-10-72);
		gc.SetTextColor(colText);
		gc.DrawText(markX, markY+6, markW, markH, markInfo);
	}
	//ENDWP
		 
	if (!tPRI.bIsSpectator) 
    {
		//if (mmp.GetControls().bNameDisplay)
		//	NameAllViewedPlayers(gc, mmp);
			
		Super.PostDrawWindow(gc);
    	//Super(AugmentationDisplayWindow).PostDrawWindow(gc);
    }
    else
    {
		if (mmp.FreeSpecMode)
		{
			NameAllViewedPlayers(gc, mmp);
			DrawStaticText(gc, " < Free spectating >", 0.73, colGold, false);
			DrawStaticText(gc, "Press <" $ keySkills $ "> to spectate players.", 0.75, colGold, false);
		}
		else if (mmp.ViewTarget != none)
		{
			if (PlayerPawn(mmp.ViewTarget).PlayerReplicationInfo.Team != mmp.PlayerReplicationInfo.Team ||
				!mmp.GameReplicationInfo.bTeamGame) col = colRed;
			else col = colGreen;
			str = "Viewing " $ PlayerPawn(mmp.ViewTarget).PlayerReplicationInfo.PlayerName;

			DrawStaticText(gc, str, 0.65, col, true);
			DrawStaticText(gc, "<- LMB       RMB ->", 0.69, colGold, false);
			if (!mmp.bBehindView)
			{
				//DrawRemotePlayerSkills(gc, mmp);
				DrawRemoteInventory(gc, mmp);
			}
			DrawStaticText(gc, "Press <" $ keySkills $ "> to go into free spectator mode.", 0.75, colGold, false);
		}
        
        if(!mmp.bNoRespawn)
			DrawStaticText(gc, "Press <" $ keyMainMenu $ "> or enter chat command /spec to start playing.", 0.77, colGold, false);

        gc.SetFont(Font'FontMenuSmall_DS');
	    gc.SetTextColor(colHeaderText);
	    gc.SetStyle(DSTY_Normal);
	    gc.SetTileColor(colBorder);
		if (mmp.bShowScores)
	    {
            if (DeathMatchGame(mmp.DXGame) != None)
			    DeathMatchGame(mmp.DXGame).ShowDMScoreboard(mmp, gc, width, height);
		    else if (TeamDMGame(mmp.DXGame) != None)
			    TeamDMGame(mmp.DXGame).ShowTeamDMScoreboard(mmp, gc, width, height);
	    }
	}
}

function RefreshMultiplayerKeys()
{
	local String Alias, keyName;
	local int i;

	for ( i = 0; i < 255; i++ )
	{
		keyName = player.ConsoleCommand ( "KEYNAME "$i );
		if ( keyName != "" )
		{
			Alias = player.ConsoleCommand( "KEYBINDING "$keyName );
			if ( Alias ~= "DropItem" )
				keyDropItem = keyName;
			else if ( Alias ~= "Talk" )
				keyTalk = keyName;
			else if ( Alias ~= "TeamTalk" )
				keyTeamTalk = keyName;
			else if ( Alias ~= "ShowInventoryWindow" )
			    keyFreeMode = keyName;
            else if ( Alias ~= "ShowGoalsWindow" )
                keyPersonView = keyName;
            else if ( Alias ~= "ShowMainMenu" )
                keyMainMenu = keyName;
			else if ( Alias ~= "BuySkills" )
				keySkills = KeyName;
		}
	}
	if ( keyDropItem ~= "" )
		keyDropItem = KeyNotBoundString;
	if ( keyTalk ~= "" )
		keyTalk = KeyNotBoundString;
	if ( keyTeamTalk ~= "" )
		keyTeamTalk = KeyNotBoundString;
	if ( keyFreeMode ~= "" )
	    keyFreeMode = KeyNotBoundString;
    if ( keyPersonView ~= "" )
        keyPersonView = KeyNotBoundString;
    if ( keyMainMenu ~= "" )
        keyMainMenu = KeyNotBoundString;
	if ( keySkills ~= "" )
		keySkills = KeyNotBoundString;
}

function DrawStaticText(GC gc, string text, float y_ratio, color col, bool big)
{
    local float x, y, w, h;

    if (big) gc.SetFont(Font'FontMenuTitle');
    else gc.SetFont(Font'FontMenuSmall');
    gc.SetStyle(DSTY_Translucent);
    gc.SetTextColor(col);
    gc.GetTextExtent(0, w, h, text);
    x = (width * 0.5) - (w * 0.5);
	y = height * y_ratio;
	gc.DrawText(x, y, w, h, text);
	gc.SetStyle(DSTY_Normal);
}

function float FacingActor(Pawn A, Pawn B)
{
    local vector X,Y,Z, Dir;

    if (B == None || A == None) return -1.0;
    GetAxes(B.ViewRotation, X, Y, Z);
    Dir = A.Location - B.Location;
    X.Z = 0;
    Dir.Z = 0;
    return Normal(Dir) dot Normal(X);
}

defaultproperties
{
     colWhite=(R=255,G=255,B=255)
     colYellow=(R=255,G=255,B=0)
     colPurple=(R=128,G=0,B=128)
     
}
