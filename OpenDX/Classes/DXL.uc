class DXL extends Actor;

var localized string l_lvote, l_wonvote;

var DXL Prev, Next;
var DXMVMapVoteMenu MVM;

var string Maps[arraycount(class'MVMutator'.default.Maps)];
var byte VoteTotals[arraycount(Maps)];

Var MVMutator Mut;
var float RepTime;
var int MapCount, iCurrentVote, iNextMap, iRepMaps;
var bool bVoteDone, bAdminVoteDone, bAdminVoteYes;
var bool DoesNotVote; //Ayleth: used to seperate the master DXL from the player dxls

//Ayleth: Any Function or Variable that names AdminVote refers to
//the admin prompting for a serverwide decision to switch to the
//most popular vote b4 the match ends. These are all my addition.
//Somewhat hacky in places tho. Sorry for the indent mess. Too
//lazy to clean up his mess. Throws off my indenting as well :(

//don't save data and function calls to the demorec
replication
{
  reliable if (!bDemoRecording && bNetOwner && (Role == ROLE_Authority))
   MapCount, iNextMap, VoteTotals;

  reliable if (!bDemoRecording && (Role == ROLE_Authority))
   ClientResetAdminVote, OpenAVMenu, OpenMVMenu, CloseMVMenu, ShowWinner, ClientAddMaps;

  reliable if (!bDemoRecording && (Role < ROLE_Authority))
   ServerSetVote, ServerAdminVote, ServerResetAdminVote;
}

//Ayleth: this allows us to get and set variables within the mutator.
simulated function PostBeginPlay()
{
  local MVMutator c;
  foreach allactors (class'MVMutator', c)
  {
      mut = c;
      return;
  }

    if (c == None)
        Mut = Spawn(class'MVMutator');
  SetTimer(1, true);
}


simulated final function bool ValidOwner() {
  return ( (DeusExPlayer(Owner) != None) && DeusExPlayer(Owner).PlayerIsClient() && (DeusExPlayer(Owner).Player != None) && (DeusExPlayer(Owner).Player.CurrentNetSpeed != 1000000) );  //demo check
}


simulated function Timer() {
  if (ValidOwner()) {
   if (MapCount <= 0)
    return;
   ClientSetVote(-1);
   if (Role == ROLE_Authority)
    iRepMaps = MapCount;
   OpenMVMenu();
  } else if ((Role < ROLE_Authority) && (Owner == None))
     return;

  SetTimer(0, false);
}


simulated final function AddMap(int I, string M) {
  if ((iRepMaps < MapCount) && (I < MapCount) && (M != "") && (Maps[I] == "")) {
   Maps[I] = M;
   iRepMaps++;
  }
}


simulated final function ClientAddMaps(int I, string M, string M1, string M2, string M3) {
  AddMap(I  , M);
  AddMap(I+1, M1);
  AddMap(I+2, M2);
  AddMap(I+3, M3);
}


//use function replication to work around the large array replication GPF
//send about 80 maps/sec
function Tick(float Delta) {
   local string M[4];
   local int I;

  if (Owner == None) {
   Destroy();
   return;
  }

  if ((iRepMaps < MapCount) && (iCurrentVote != -2)) {
   RepTime += Delta / Level.TimeDilation;
   if (RepTime >= 0.05) {
    RepTime = FMin(RepTime - 0.05, 0.01);
    for (I = 0; I < 4; I++) {
     if (iRepMaps < MapCount) {
      M[I] = Maps[iRepMaps];
      iRepMaps++;
     }
     else
     break;
    }
   ClientAddMaps(iRepMaps - I, M[0], M[1], M[2], M[3]);
   }
  }
}


simulated function Destroyed() {
  if (MVM != None)
   MVM.root.PopWindow();

  MVM = None;

  if (Role == ROLE_Authority) {
   if (Prev != None) Prev.Next = Next;
   if (Next != None) Next.Prev = Prev;
   Prev = None;
   Next = None;
  }
}


final function ServerSetVote(int I) {
   iCurrentVote = I;
}

//Allow the player to vote once a new vote has been called. ServerSide.
final function ServerResetAdminVote()
{
    bAdminVoteDone=False;
}

//Set the vote that the player made. ServerSide.
final function ServerAdminVote(bool Vote)
{
    bAdminVoteDone=True;
    bAdminVoteYes=Vote;
}

//Allow the player to vote once a new vote has been called. ClientSide.
Simulated final function ClientResetAdminVote()
{
    bAdminVoteDone=False;
    ServerResetAdminVote();
}

//Set the vote that the player made. ClientSide.
simulated final function ClientAdminVote(bool Vote)
{
    bAdminVoteDone=True;
    bAdminVoteYes=Vote;
    ServerAdminVote(Vote);
}

simulated final function ClientSetVote(int I) {
  if (iCurrentVote != I) {
   iCurrentVote = I;
   ServerSetVote(I);
  }
}

simulated final function OpenMVMenu() {
  local DeusExRootWindow W;

  if (!bVoteDone && (MVM == None) && ValidOwner()) {
   W = DeusExRootWindow(DeusExPlayer(Owner).RootWindow);
   if (W != None) {
    MVM = DXMVMapVoteMenu(W.InvokeMenuScreen(Class'DXMVMapVoteMenu', true));
    if (MVM != None)
     MVM.PlayerVote = Self;
   }
  }
}

//OpenAdminVoteMenu: Opens the admin prompted vote window to alow players to
//vote for immediate mapchange.
Simulated final function OpenAVMenu(bool bForceShow)
{
    local AdminVoteWindow AVW;
    local DeusExRootWindow W;
    if ((!bAdminVoteDone || bForceShow) && ValidOwner())
    {
        W = DeusExRootWindow(DeusExPlayer(Owner).RootWindow);
        if (W != None)
        {
            AVW = AdminVoteWindow(W.InvokeMenuScreen(Class'AdminVoteWindow', true));
    		AVW.SetMessageText("An administrator has instigated a|nservertravel vote. Do you wish to|nchange to the most voted map,|n"@Maps[iNextMap]$"?");
    		AVW.Caller=Self;
            W.ShowCursor(True);
    	}
    }
}

//Sprintf is not simulated - must call it from player

simulated final function CloseMVMenu(string sNextMap) {
 if (!bVoteDone) {
  bVoteDone = true;
  if (MVM != None)
   MVM.root.PopWindow();
  if (ValidOwner())
   DeusExPlayer(Owner).ClientMessage(Owner.Sprintf(l_wonvote, sNextMap), 'Say', true);
 }
}


simulated final function ShowWinner() {
  if ((iNextMap >= 0) && ValidOwner())
   DeusExPlayer(Owner).ClientMessage(Owner.Sprintf(l_lvote, Maps[iNextMap]));
}


defaultproperties
{
    l_lvote="%s is currently leading the vote."
    l_wonvote="%s has won the map vote!"
    iCurrentVote=-2
    iNextMap=-1
    bHidden=True
    RemoteRole=2
    NetPriority=1.50
}
