class DXMVMapVoteMenu extends MenuUIScreenWindow;

var localized string l_help1, l_help2, l_help3, l_help4, l_cvote, l_lmap;
var MenuUIScrollAreaWindow winScroll;
var MenuUIListWindow lstMaps, lstVotes;
var MenuUISmallLabelWindow CurrentVote, LeadingMap;
var DXL PlayerVote;
var float RepTime;
var bool bListDone, bStacking;


event InitWindow() {
   local Window W;

   Super.InitWindow();

   if (actionButtons[2].btn != None)
    if ((Player == None) || (Player.PlayerReplicationInfo == None) || !Player.PlayerReplicationInfo.bAdmin)
     actionButtons[2].btn.SetSensitivity(false);

   winClient.SetBackground(Texture'DeusExUI.MaskTexture');
   winClient.SetBackgroundStyle(DSTY_Modulated);

   W = winClient.NewChild(Class'Window');
   W.SetSize(ClientWidth, ClientHeight-20);
   W.SetBackground(Texture'DeusExUI.MaskTexture');
   W.SetBackgroundStyle(DSTY_Modulated);
   W.Lower();

   CreateLabel(8, 7, l_lmap);
   LeadingMap = CreateLabel(16, 20, "");
   LeadingMap.SetWidth(180);

   lstVotes = MenuUIListWindow(winClient.NewChild(Class'MenuUIListWindow'));
   lstVotes.SetPos(8, 40);
   lstVotes.SetSize(208, 172);
   lstVotes.SetSensitivity(false);
   lstVotes.EnableAutoExpandColumns(false);
   lstVotes.EnableAutoSort(true);
   lstVotes.SetNumColumns(2);
   lstVotes.SetColumnType(0, COLTYPE_Float, "%.0f");
   lstVotes.SetColumnType(1, COLTYPE_String);
   lstVotes.SetSortColumn(0, true, false);  //reverse order
   lstVotes.SetColumnWidth(0, 28);
   lstVotes.SetColumnWidth(1, 180);

   CreateLabel(236, 7, l_cvote);
   CurrentVote = CreateLabel(244, 20, "");
   CurrentVote.SetWidth(180);

   winScroll = CreateScrollAreaWindow(winClient);
   winScroll.SetPos(236, 40);
   winScroll.SetSize(196, 192);

   lstMaps = MenuUIListWindow(winScroll.clipWindow.NewChild(Class'MenuUIListWindow'));
   lstMaps.EnableMultiSelect(false);
   lstMaps.EnableAutoExpandColumns(false);
   lstMaps.EnableAutoSort(false);
   lstMaps.SetNumColumns(2);
   lstMaps.SetColumnType(0, COLTYPE_String);
   lstMaps.SetColumnType(1, COLTYPE_String);
   lstMaps.SetSortColumn(0, false, false);  //case insensitive
   lstMaps.SetColumnWidth(0, 180);
   lstMaps.HideColumn(1);

   bTickEnabled = true;
}


final function MenuUISmallLabelWindow CreateLabel(int X, int Y, string S) {
   local MenuUISmallLabelWindow W;

   W = MenuUISmallLabelWindow(winClient.NewChild(Class'MenuUISmallLabelWindow'));
   W.SetPos(X, Y);
   W.SetText(S);
   W.SetWordWrap(false);

   return W;
}


//do not change this cleanup code
event DestroyWindow() {
   bTickEnabled = false;
   Player = DeusExPlayer(GetPlayerPawn());
   if ((Player != None) && !Player.bDeleteMe) {
    if (ViewPort(Player.Player) != None) {
     Player.ClientMessage(l_help1);
     Player.ClientMessage(l_help2);
     Player.Clientmessage(l_help3);
     if (Player.bAdmin)
     Player.Clientmessage(l_help4);
    }
    foreach Player.allactors(class'DXL', PlayerVote)
     if (PlayerVote.Owner == Player)
      PlayerVote.MVM = None;
   }

   PlayerVote = None;
   Super.DestroyWindow();
}


//close window when death or end game screen displays
function bool CanPushScreen(class<DeusExBaseWindow> C) {
   if (ClassIsChildOf(C, class'HUDMultiplayer') || ClassIsChildOf(C, class'MultiplayerMessageWin')) {
    bStacking = true;
    return true;
   }
   return Super.CanPushScreen(C);
}


function bool CanStack() {
   if (bStacking) {
    bStacking = false;
    return false;
   }
   return Super.CanStack();
}


function Tick(float Delta) {
   local int I, C;
   if ((lstMaps == None) || (lstVotes == None) || (PlayerVote == None))
    return;

   if (bListDone) {
    RepTime += Delta;
    if (RepTime >= 0.1) {
     RepTime = 0;
     if (PlayerVote.iNextMap >= 0)
      LeadingMap.SetText(PlayerVote.Maps[PlayerVote.iNextMap]);

     lstVotes.DeleteAllRows();
     for (I = 0; I < PlayerVote.MapCount; I++)
      if (PlayerVote.VoteTotals[I] != 0)
       lstVotes.AddRow(PlayerVote.VoteTotals[I] $ ";" $ PlayerVote.Maps[I]);
    }
   return;
  }

  lstMaps.DeleteAllRows();
  for (I = 0; I < PlayerVote.MapCount; I++)
   if (PlayerVote.Maps[I] != "") {
    lstMaps.AddRow(PlayerVote.Maps[I] $ ";" $ I);
    C++;
   }

  if (C > 0) {
   lstMaps.Sort();
   if (C == PlayerVote.MapCount) {
    bListDone = true;
    I = MapNumToRow(PlayerVote.iCurrentVote);
    if (I != 0) {
     lstMaps.SetFocusRow(I, true, false);
     lstMaps.SelectRow(I);
     CurrentVote.SetText(lstMaps.GetField(I, 0));
    }
   }
  }
}


final function int MapNumToRow(int N) {
   local int I, R;

   if ((lstMaps != None) && (N >= 0))
    for (I = 0; I < lstMaps.GetNumRows(); I++) {
     R = lstMaps.IndexToRowId(I);
     if (int(lstMaps.GetField(R, 1)) == N)
      return R;
   }

   return 0;
}


event bool ListRowActivated(window W, int R) {
   if ((W == lstMaps) && bListDone) {
    PlayerVote.ClientSetVote(int(lstMaps.GetField(R, 1)));
    CurrentVote.SetText(lstMaps.GetField(R, 0));
    return true;
   }

   return Super.ListRowActivated(W, R);
}


event bool RawKeyPressed(EInputKey key, EInputState iState, bool bRepeat) {
   if ((key == IK_Enter) && (iState == IST_Release)) {
    root.PopWindow();
    return True;
   }
   return Super.RawKeyPressed(key, iState, bRepeat);
}


function ProcessAction(String S) {
   Super.ProcessAction(S);
   if (S == "NOVOTE") {
    PlayerVote.ClientSetVote(-1);
    CurrentVote.SetText("");
   }
   else if (S == "TRAVEL") {
    if (bListDone && (lstMaps.GetSelectedRow() != 0)) {
     Player.SwitchLevel(lstMaps.GetField(lstMaps.GetSelectedRow(), 0));  //server checks for admin
     actionButtons[2].btn.SetSensitivity(false);
    }
   }
}


defaultproperties
{
    l_help1="Type 'Mutate MapVote' to display the menu."
    l_help2="Type 'Mutate VoteResult' to display the leading map."
    l_help3="Type 'Mutate Vote' to display the vote menu when a vote is in effect."
    l_help4="Type 'Mutate StartVote' to begin a vote to immediatly change the map."
    l_cvote="Current Vote:"
    l_lmap="Leading Map:"
    RepTime=1.00
    actionButtons(0)=(Align=2,Action=1,Text="",Key="",btn=None),
    actionButtons(1)=(Align=0,Action=5,Text="Clear Vote",Key="NOVOTE",btn=None),
    actionButtons(2)=(Align=0,Action=5,Text="ServerTravel",Key="TRAVEL",btn=None),
    Title="MapVote Menu v1.1.0"
    ClientWidth=440
    ClientHeight=244
    bUsesHelpWindow=False
}
