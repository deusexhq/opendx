class Mountable extends DeusExDecoration;
var vector MntMoveTo;
var TCPlayer Mounter;

var float GroundSpeed, WaterSpeed, AirSpeed, SpeedReduction;
var int EMPHitPoints, WalkingSpeed, UnderWaterTime;
var Sound WalkSound;
var int Health;
var bool bFlyingMount;

function PostBeginPlay(){
    HitPoints = Health;
    super.PostBeginPlay();
}
function Frob(Actor Frobber, Inventory frobWith) 
{
    TCPlayer(Frobber).StartMount(Self);
}

defaultproperties
{
    SpeedReduction=0.9
    GroundSpeed=9500.000000
     WaterSpeed=50.000000
     AirSpeed=144.000000
     WalkingSpeed=1
     EMPHitPoints=0
     UnderWaterTime=10
     bPushable=False
     Physics=PHYS_Falling
}
