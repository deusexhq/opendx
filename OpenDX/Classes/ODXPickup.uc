//=============================================
// Master class Psuedo-Unreal pickup object
//=============================================
Class ODXPickup extends DeusExDecoration;

var() class<Inventory> ODXInv;
var class<inventory> CurClass;
var string EffectString;
var bool bNeverDestroy;
var bool bSleeping;
var DeusExPlayer Pup;
var() int SleepTimer;
var() class<Augmentation> ODXAug;
var() string ODXPerk;
var int Count;
var() int JumpVel;

enum EPMode
{
   EP_None,
   EP_Jump,
   EP_Pickup,
   EP_Aug,
   EP_Perk
};

var EPMode PickupMode;

function BeginPlay()
{
	SetTimer(1,True);
}

function SilentAdd(class<inventory> addClass, DeusExPlayer addTarget)
{ 
	local Inventory anItem;
	
	anItem = Spawn(addClass,,,addTarget.Location); 
	anItem.SpawnCopy(addTarget);
	anItem.Destroy();
}

function Tick(float deltatime)
{
	local DeusExPlayer DXP;
	
	super.Tick(deltatime);
	
	if(bSleeping)
		return;

	RadialCollect();
	
	if(PickupMode == EP_None)
		bHidden=True;
		
	if(PickupMode == EP_Pickup && ODXInv != None && curclass != ODXInv)
	{
		bHidden=False;
		CurClass = ODXInv;
		DrawType=DT_Mesh;
		Style=STY_Normal;
		Mesh = ODXInv.default.Mesh;
		Drawscale = ODXInv.default.Drawscale;
		SetCollisionSize(ODXInv.default.CollisionRadius, ODXInv.default.CollisionHeight);
	}
}

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
		PickupGet(winp);
}

function Timer()
{
	if(bSleeping)
	{
		Count--;
		if(Count <= 0)
		{
			Log(Self$" respawned.");
			bHidden=False;
			bSleeping=False;
		}
	}
}

function PickupGet(TCPlayer myActivator)
{
	
	myActivator.PlaySound(Sound'DeusExSounds.UserInterface.LogGoalCompleted',,,, 256);
	if(PickupMode == EP_Pickup)
		SilentAdd(ODXInv, myActivator);
	
	if(PickupMode == EP_Perk)
	{
		myActivator.GetPerk(ODXPerk);
	}
	
	if(PickupMode == EP_Aug)
	{
		myActivator.AugmentationSystem.GivePlayerAugmentation(ODXAug);
		myActivator.AugmentationSystem.GivePlayerAugmentation(ODXAug);
	}	
	
	if(PickupMode == EP_Jump)
	{
		myActivator.DoJump();
		myActivator.Velocity.Z = JumpVel;
		myActivator.SetPhysics(Phys_Falling);	
	}
	bHidden=True;
	bSleeping=True;
	Count=SleepTimer;
	return;
}

function PSUEffect(DeusExPlayer DXP, string EffectStr)
{}

function Destroyed()
{
if(bNeverDestroy)
	return;

Super.Destroyed();
}

defaultproperties
{
	JumpVel=750
	SleepTimer=30
     bInvincible=True
     HitPoints=100
     ItemName="PSUPICKUP"
     //bMovable=False
     bPushable=False
     bHighlight=False
     LightBrightness=100
     Physics=PHYS_Rotating
     Lighttype=LT_Steady
     LightRadius=10
     Ambientglow=255
     LightSaturation=255
	 Drawscale=1
	 Fatness=140
	 style=sty_translucent
	 bBlockPlayers=False
     Mesh=LodMesh'DeusExDeco.Lightbulb'
     Texture=Texture'DeusExUI.UserInterface.AugIconCombat_Small';
     CollisionRadius=5.000000
     CollisionHeight=8.000000
          bFixedRotationDir=True
     RotationRate=(Yaw=8192)
}
