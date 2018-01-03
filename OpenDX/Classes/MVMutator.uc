class MVMutator extends Mutator config(Mutators);

enum ETimeToDisplay
{
 TTD_OnDeath,
 TTD_Immediatly
};

enum ECycleType
{
 CT_Static,
 CT_Random,
 CT_Cycle
};

enum eDefaultVote   //Ayleth: Default vote for nonvoters.
{
    DV_Yes,
    DV_No,
    DV_Ignore     //doesn't count them in the votes.
};
//Ayleth: Removed the "NeverVote" and "Autovote" features as they were never implemented.

var config string ExcludeList[32];
var config ECycleType CycleType;
var config eDefaultVote DefaultVote;
var config ETimeToDisplay TimeToDisplay;
var config bool bUseMapListOnly, bFilterSPMaps, bAllowRepeatMap;
var int VoteTime;
var int CountDown;  //Ayleth: for changemap.

var string Maps[250];
var int MapCount;
var byte VoteTotals[arraycount(Maps)];

var DXL DXLList;
var string sNextMap;
var float CWTime;
var int LoadingTime, iDefMap, iNextMap, iListSize, EggTimer;
var bool bInit, bVoteDone, bDoAdminVote, bDoMapChange;

//Ayleth: Any Function or Variable that names AdminVote refers to
//the admin prompting for a serverwide decision to switch to the
//most popular vote b4 the match ends. These are all my addition.
//Somewhat hacky in places tho. Sorry for the indent mess. Too
//lazy to clean up his mess. Throws off my indenting as well :(

function PostBeginPlay() {
   local string CM;
   local int I;

   if (bInit)
    return;

   bInit = true;
   MapCount = 0;

   if (bUseMapListOnly)
    GetMapList();
   else
    GetMapFiles();

   CM = Left(Self, InStr(Self, "."));

   if (MapCount <= 0) {
    MapCount = 1;
    Maps[0] = CM;
    iListSize += Len(CM);
   }

   log(MapCount @ "Maps," @ iListSize @ "Bytes", 'MVMutator');

   if (CycleType == CT_Random)
    iDefMap = Rand(MapCount);
   else {
    iDefMap = -1;
    for (I = 0; I < MapCount; I++)
     if (Maps[I] ~= CM) {
      iDefMap = I;
     break;
     }
    if (iDefMap >= 0) {
     if ((CycleType == CT_Cycle) && (++iDefMap >= MapCount))
      iDefMap = 0;
   }
   else
    iDefMap = Rand(MapCount);
  }

   ChooseWinner();
   DXLList = Spawn(class'DXL', Self);
   DXLList.DoesNotVote=True;   //used later on to differentiate between
   SetTimer(1, true);                //player DXLs and the Master DXL.
   SaveConfig();
   Level.Game.BaseMutator.AddMutator(Self);
}


// 'mutate mapvote' shows the menu.
// 'mutate voteresult' shows current leading map.
// trm101:
// 'mutate cycletype' toggles between the cycletypes
// 'mutate usemaplist' toggles bUseMapListOnly
// 'mutate filtersp' toggles bFilterSPMaps

// Ayleth:Fixed spelling mistake in filtersp  (was fildersp)
// and added Vote and StartVote.
function Mutate(string S, PlayerPawn P)
{
  Local DXL GetVotes;
  local DeusExPlayer Player;
  if (DXLList != None)
  {
   if (S ~= "MapVote")
   {
    if (!bVoteDone)
    {
     GetDXL(P, true).OpenMVMenu();
    }
   }
   else if (S ~= "VoteResult")
   {
     GetDXL(P, true).ShowWinner();
   }
   else if (S~= "Vote")     //allows the player to vote for immediate changemap
   {
   if(bDoAdminVote==True)
   GetDXL(P,true).OpenAVMenu(True);
   else
   DeusExPlayer(P).Clientmessage("There is no vote in progress to change the map");
   }
   //trm
   else if (P.bAdmin)
   {
    if (S ~= "filtersp")
    {
     bFilterSPMaps=!bFilterSPMaps;
     P.ClientMessage("MAPVOTE: Filtering SP Maps:"@bFilterSPMaps);
    }
    else if (S ~= "usemaplist")
    {
     bUseMapListOnly=!bUseMapListOnly;
     P.ClientMessage("MAPVOTE: Using Map List Only:"@bUseMapListOnly);
    }
    else if (S ~= "cycletype")
    {
     if (CycleType==CT_Static)
     {
      CycleType = CT_Random;
      P.ClientMessage("MAPVOTE: CycleType now [Random].");
     }
     else if (CycleType==CT_Random)
     {
      CycleType = CT_Cycle;
      P.ClientMessage("MAPVOTE: CycleType now [Cycle].");
     }
     else
     {
      CycleType = CT_Static;
      P.ClientMessage("MAPVOTE: CycleType now [Static].");
     }
    }
    Else if (S~= "StartVote")  //admin calls this to begin changemap vote.
    {
      if(!bDoAdminVote)
      {
      foreach allactors(class'DXL',GetVotes)
     {
         GetVotes.ClientResetAdminVote();
         GetVotes.ServerResetAdminVote();
         GetVotes.bAdminVoteDone=false;
     }
      if(TimeToDisplay==TTD_Immediatly)
      BroadCastMessage("An administrator has called for a servertravel mapvote to the map"@Maps[iNextMap]$". Please cast your vote when you have died or type 'Mutate Vote' to cast your vote now.");
      Else
      BroadCastMessage("An administrator has called for a servertravel mapvote to the map"@Maps[iNextMap]$".");
      bDoAdminVote=True;
      settimer(1,true);
      if(TimeToDisplay==TTD_Immediatly)
      foreach allactors(Class'DeusExPlayer',Player)
       GetDXL(Player, true).OpenAVMenu(false);
      }
      else  DeusExPlayer(P).Clientmessage("A vote is already in progress.");
    }
   }
  }

  Super.Mutate(S, P);
}

function ModifyPlayer(Pawn P) {
   if (!bVoteDone && (DeusExPlayer(P) != None) && (GetDXL(P) == None))
    AddDXL(P);
   Super.ModifyPlayer(P);
}


function ScoreKill(pawn Killer, pawn Other)
{
   if(bDoAdminVote && TimeToDisplay==TTD_OnDeath)   //this is where the player recieves the message window to vote.
       GetDXL(Other, true).OpenAVMenu(false);
}

function Tick(float Delta) {
   if (bVoteDone)
    return;

   CWTime += Delta / Level.TimeDilation;
   if (CWTime < 1)
    return;

   CWTime = 0;
   ChooseWinner();
   UpdateVoteData();
}


// Check if its end of match, if so, travel to our new map.
//Ayleth: the +1 -1 crap refers to an extra DXL that is the Master DXL, and needs to be ignored.
//take care that you disinclude this DXL in any calculations.
simulated function Timer() {
 local DXL GetVotes;
 local int Yeses, Nos, NumVotes;
	local string gtv;
	local ODXVoteActor VA;
	
 if(bDoAdminVote)  //this part does the checks when a vote is in progress.
 {
     if (EggTimer>=VoteTime)  //if we haven't gone past the time limit...
     {
        foreach allactors(class'DXL',GetVotes)
        {
            if(!GetVotes.DoesNotVote)   //there is one extra DXL always. IgNore this DXL
            {
                IF (!GetVotes.bAdminVoteDone && DefaultVote==DV_No) GetVotes.ClientAdminVote(False);  //these are for non-voters.
                IF (!GetVotes.bAdminVoteDone && DefaultVote==DV_Yes) GetVotes.ClientAdminVote(True);  //basically server sees them as voted
            }                                                                                         //if they havent voted. Defined bt DefaultVote.
        }

         bDoAdminVote=False;  //stop the vote.
         BroadCastMessage("The current vote has run past its time limit of"@VoteTime@"seconds.");
         EggTimer=0;
     }
     foreach allactors(class'DXL',GetVotes)
     {                         //talley up the votes. Also get number of voters
                 NumVotes++;
                 if (GetVotes.bAdminVoteDone && GetVotes.bAdminVoteYes==False) Nos++;
                 if (GetVotes.bAdminVoteDone && GetVotes.bAdminVoteYes==True) Yeses++;
     }
     If ((Yeses>(NumVotes/2)) || (NumVotes==Yeses+1)) //if the votes are > than 1/2..
     {
         bDoAdminVote=False;      //then close down the vote and get ready for mapchange.
         bDoMapChange=True;
         BroadcastMessage("Prepare for ServerTravel in:");
         BroadCastMessage("|P25 Seconds");
         CountDown=5;       //sets for 5 second delay until mapchange.
         Return;
     }
     If (Nos>=((NumVotes/2))&& !bDoMapChange)  //if Nos are > or = to 1/2 server population
     {
         bDoAdminVote=False;   //just cancel the vote.
         EggTimer=0;
         BroadCastMessage("The vote has been cancelled; not enough players voted for a servertravel");
     }
     EggTimer++;
 }
 if(bDoMapChange)
 {
     if (Countdown>0)
     {
         CountDown--;
         if (CountDown!=1)                             //actual countdown code.
         BroadCastMessage("|P2"$CountDown@"Seconds");
         Else
         BroadCastMessage("|P2"$CountDown@"Second");   //"1 Seconds" looks kinda weird ^^
     }
     if (CountDown==0)
     {
         Level.Game.SetTimer(0,false);
		foreach AllActors(class'ODXVoteActor', VA)
			gtv = VA.FinalVoteStr;
		  
		  if(gtv != "")
			Level.ServerTravel( sNextMap$"?Game=OpenDX."$gtv, False );
		else
			Level.ServerTravel( sNextMap, False );
     }
 }
 if ((DeusExMPGame(Level.Game) != None) && DeusExMPGame(Level.Game).bNewMap) {
  Level.Game.SetTimer(0, false);
  if (!bVoteDone) {
   ChooseWinner(true);
   UpdateVoteData(true);
   LoadingTime = 0;
   bVoteDone = true;
  }
  if (LoadingTime++ == 11)
	{
		foreach AllActors(class'ODXVoteActor', VA)
			gtv = VA.FinalVoteStr;
		  
		  if(gtv != "")
			Level.ServerTravel( sNextMap$"?Game=OpenDX."$gtv, False );
		else
			Level.ServerTravel( sNextMap, False );
	}
 }
}

final function UpdateVoteData(optional bool bFinal) {
   local DXL D;
   local int I;

   if (DXLList != None)
    for (D = DXLList.Next; D != None; D = D.Next) {
     D.iNextMap = iNextMap;
     for (I = 0; I < MapCount; I++)
      D.VoteTotals[I] = VoteTotals[I];
     if (bFinal)
      D.CloseMVMenu(sNextMap);
    }
}


final function AddDXL(Actor A) {
   local DXL D;
   local int I;

   if ((A != None) && !A.bDeleteMe && (DXLList != None)) {
    D = A.Spawn(class'DXL', A);
    D.Prev = DXLList;
    D.Next = DXLList.Next;
    if (DXLList.Next != None)
     DXLList.Next.Prev = D;
    DXLList.Next = D;
    D.MapCount = MapCount;
    for (I = 0; I < MapCount; I++)
     D.Maps[I] = Maps[I];
   }
}


final function DXL GetDXL(Actor A, optional bool bSafe) {
   local DXL D;

   if ((A != None) && (DXLList != None))
    for (D = DXLList.Next; D != None; D = D.Next)
     if (D.Owner == A)
      return D;

   if (bSafe)
    return DXLList;

   return None;
}


final function ChooseWinner(optional bool bFinal) {
   local DXL D;
   local int I;
   local byte BestScore;

   if (bVoteDone)
    return;

   for (I = 0; I < MapCount; I++)
    VoteTotals[I] = 0;

   I = 0;
   if (DXLList != None)
    for (D = DXLList.Next; D != None; D = D.Next)
     if ((D.iCurrentVote >= 0) && (D.iCurrentVote < MapCount)) {
      VoteTotals[D.iCurrentVote]++;
      I = 1;
     }

   iNextMap = iDefMap;
   if (I != 0)
    for (I = 0; I < MapCount; I++) {
     if (VoteTotals[I] > BestScore) {
      BestScore = VoteTotals[I];
      iNextMap = I;
     }
     else if (bFinal && (BestScore > 0) && (VoteTotals[I] == BestScore) && (FRand() < 0.5))
      iNextMap = I;
  }

   sNextMap = Maps[iNextMap];
}


final function AddMap(string M) {
   local string S;
   local int I;

   if ((M != "") && (MapCount < arraycount(Maps))) {
    if (bFilterSPMaps) {
     S = Left(M, 3);
     if ((S ~= "00_") || ((int(S) != 0) && (Right(S, 1) ~= "_")))
      return;
    }
    if (((M~=left(string(level),instr(string(level),"."))) && !bAllowRepeatMap) ||
    (M ~= "AutoPlay") || (M ~= "DX") || (M ~= "DXOnly") ||
    (M ~= "Entry") || (M ~= "Index"))
     return;

    for (I = 0; I < arraycount(ExcludeList); I++)
     if (ExcludeList[I] ~= M)
      return;

    Maps[MapCount++] = M;
    iListSize += Len(M);
   }
}


final function GetMapList() {
   local string S;
   local int I, C;

   for (I = 0; I < arraycount(class'DXMapList'.Default.Maps); I++) {
    S = class'DXMapList'.Default.Maps[I];
    if (S != "") {
     C = InStr(S, ".");
     if (C >= 0)
      S = Left(S, C);
     if (S != "") {
      for (C = 0; C < MapCount; C++)
       if (Maps[C] ~= S) {
        S = "";
        break;
       }
      AddMap(S);
     }
    }
   }
}


final function GetMapFiles() {
   local string First, Next, Last;

   First = GetMapName("", "", 0);
   Next = First;

   while (!(Last ~= First) && (Next != "") && (MapCount < arraycount(Maps))) {
    if (Right(Next, 3) ~= ".dx")
     AddMap(Left(Next, Len(Next) - 3));

   Next = GetMapName("", Next, 1);
   Last = Next;
  }
}


defaultproperties
{
    CycleType=2
    DefaultVote=1
    bFilterSPMaps=True
    VoteTime=45
}
