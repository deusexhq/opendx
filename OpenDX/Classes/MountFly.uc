//=============================================================================
// SecurityBot2.
//=============================================================================
class MountFly extends Mountable;

enum ESkinColor
{
	SC_UNATCO,
	SC_Chinese
};

var() ESkinColor SkinColor;

function BeginPlay()
{
	Super.BeginPlay();
    LoopAnim('Fly');
	switch (SkinColor)
	{
		case SC_UNATCO:		MultiSkins[1] = Texture'SecurityBot2Tex1'; break;
		case SC_Chinese:	MultiSkins[1] = Texture'SecurityBot2Tex2'; break;
	}
}

defaultproperties
{
    bFlyingMount=True
     EMPHitPoints=100
     explosionSound=Sound'DeusExSounds.Robot.SecurityBot2Explode'
     WalkingSpeed=1.000000
     WalkSound=Sound'DeusExSounds.Robot.SecurityBot2Walk'
     GroundSpeed=95.000000
     WaterSpeed=50.000000
     AirSpeed=1440.000000
     AccelRate=500.000000
     Health=250
     UnderWaterTime=20.000000
     DrawType=DT_Mesh
     Mesh=LodMesh'DeusExDeco.BlackHelicopter'
     SoundRadius=160
     SoundVolume=192
     AmbientSound=Sound'Ambient.Ambient.Helicopter2'
     CollisionRadius=461.230011
     CollisionHeight=87.839996
     Mass=800.000000
     Buoyancy=100.000000
     ItemName="Helicopter"
}
