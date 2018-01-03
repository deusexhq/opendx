class KCObj extends DeusExDecoration;

/* KC RULES *
 * If the activating player is the killer, +1 score to activator
 * If the activating player is the victim, +1 score to activator
 * If the activating player is anyone else, +2 score to activator
 */

var float ScoreMultiplier; //no planned use yet, but future proofing any modifications.
var TCPlayer KillerPlayer, KilledPlayer;
var int tLifespan;

//delay its activation so it doesnt trigger on death
function Timer()
{	
	tLifespan--;
	if(tLifespan <= 0)
	{
		BroadcastMessage("|P2"$GetName(KillerPlayer)$"'s kill against "$GetName(KilledPlayer)$" failed.");
		Destroy();
	}
	RadialCollect();
}

function Tick(float Deltatime)
{
	RadialCollect();
}

// Upon activation, the nearest player will collect the skull.
function RadialCollect()
{
	local TCPlayer P, winP;
	local vector dist;
	local float lowestDist;

	lowestDist = 1024;

	foreach VisibleActors(class'TCPlayer', P, 50)
	{
		if(P != None && !P.IsInState('Dying') && P.Health > 0)
		{
			if(vSize(P.Location - Location) < lowestDist)
			{
				winP = P;
				lowestDist = vSize(P.Location - Location);
			}
		}
	}

	if(winP != None)
		kcTriggered(winp);
}

function kcTriggered(TCPlayer myActivator)
{
	local int modScore;
	
	modScore = 1;
	
	if(myActivator == KillerPlayer)
	{
		modScore *= ScoreMultiplier;
		
		myActivator.ClientMessage("|C8B6914 Confirmed your kill against "$GetName(KilledPlayer)$"! |P2+"$modScore$" |C8B6914score");
		KilledPlayer.ClientMessage("|C8B6914 Your death to "$GetName(KillerPlayer)$" was confirmed!");
	}
	else if(myActivator == KilledPlayer)
	{
		modScore *= ScoreMultiplier;
		
		myActivator.ClientMessage("|C8B6914 Denied your kill by "$GetName(KillerPlayer)$"! |P2+"$modScore$" |C8B6914score");
		KillerPlayer.ClientMessage("|C8B6914 Your kill against "$GetName(KilledPlayer)$" was denied!");
	}	
	else
	{
		modScore += 1;
		modScore *= ScoreMultiplier;
		myActivator.ClientMessage("|C8B6914 Denied "$GetName(KillerPlayer)$"'s kill! |P2+"$modScore$" |C8B6914score");
		KilledPlayer.ClientMessage("|C8B6914 Your death to "$GetName(KillerPlayer)$" was denied by "$GetName(myActivator)$"!");
		KillerPlayer.ClientMessage("|C8B6914 Your kill against "$GetName(KilledPlayer)$" was denied by "$GetName(myActivator)$"!");
	}
	
	Target.PlaySound(Sound'DeusExSounds.UserInterface.LogGoalCompleted',,,, 256);
	myActivator.PlayerReplicationInfo.Score += modScore;
	Destroy();
}

function Bump(actor Other)
{
	if(TCPlayer(Other) != None && !TCPlayer(Other).IsInState('Dying') && TCPlayer(Other).Health > 0)
		kcTriggered(TCPlayer(Other));
}

function Frob(actor Frobber, inventory FrobWith)
{
	kcTriggered(TCPlayer(Frobber));
}

function string GetName(TCPlayer p)
{
	return p.PlayerReplicationInfo.PlayerName;
}

defaultproperties
{
	ScoreMultiplier=1
	bStatic=False
	Physics=PHYS_Rotating
	Texture=Texture'DeusExDeco.Skins.DXLogoTex1'
	bMeshEnviroMap=True
	ItemName="Skull"
    Mesh=LodMesh'DeusExDeco.BoneSkull'
    CollisionRadius=5.800000
    CollisionHeight=4.750000
	bFixedRotationDir=True
	bBlockPlayers=False
    bInvincible=True
    bPushable=False
	Mass=50.000000
	Buoyancy=500.000000
	RotationRate=(Yaw=8192)
}
