class N_ShockWave extends Effects;

replication
{
reliable if (Role == ROLE_Authority)
 nscale;
}

var float OldShockDistance, ShockSize;
var float nscale;


function setnscale(float newvalue)
{
nscale = newvalue;
}


simulated function Tick( float DeltaTime )
{
if ( Level.NetMode != NM_DedicatedServer )
 {
// ShockSize = 13 * (Default.LifeSpan - LifeSpan) + 3.5/(LifeSpan/Default.LifeSpan+0.05);
 ShockSize = 59.0 * (Default.LifeSpan - LifeSpan) + 1.0;
 ScaleGlow = Lifespan;
 AmbientGlow = ScaleGlow * 255;
 DrawScale = ShockSize * 0.10 * nscale;  //scale Earth to correct size
 }
}


simulated function Timer()
{
local actor Victims;
local float dist, MoScale;
local vector dir;

ShockSize = 59.0 * (Default.LifeSpan - LifeSpan) + 1.0;
if ( Level.NetMode != NM_DedicatedServer )
 {
 if ( Level.NetMode == NM_Client )
  {
  foreach VisibleCollidingActors( class 'Actor', Victims, ShockSize*6*nscale, Location )
   if ( Victims.Role == ROLE_Authority )
    {
    dir = Victims.Location - Location;
    dist = FMax(1,VSize(dir));
    dir = dir/dist +vect(0,0,0.3); 
    if ( (dist> OldShockDistance) || (dir dot Victims.Velocity <= 0))
     {
     MoScale = FMax(0, 1000 - (1.862 * Dist)/nscale);
     Victims.Velocity = Victims.Velocity + dir * (MoScale + 20);	
     Victims.TakeDamage( MoScale, Instigator,
       Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
       (1000 * dir), 'Burned' );
     }
    }	
  return;
  }
 }

foreach VisibleCollidingActors( class 'Actor', Victims, ShockSize*6*nscale, Location )
 {
 dir = Victims.Location - Location;
 dist = FMax(1,VSize(dir));
 dir = dir/dist + vect(0,0,0.3); 
 if (dist> OldShockDistance || (dir dot Victims.Velocity < 0))
  {
  MoScale = FMax(0, 1000 - (1.862 * Dist)/nscale);
  if ( Victims.bIsPawn )
   Pawn(Victims).AddVelocity(dir * (MoScale + 20));
  else
   Victims.Velocity = Victims.Velocity + dir * (MoScale + 20);	
  Victims.TakeDamage( MoScale, Instigator,
    Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
    (1000 * dir), 'Burned' );
  }
 }	

OldShockDistance = ShockSize*6*nscale;	
}


simulated function PostBeginPlay()
{
local Pawn P;

if ( Role == ROLE_Authority ) 
 {
 for ( P=Level.PawnList; P!=None; P=P.NextPawn )
  if ( P.IsA('Human') && (VSize(P.Location - Location) < (1000 * nscale)) )
   Human(P).ShakeView(0.5, (250000.0*nscale)/VSize(P.Location - Location), 10);

 if ( Instigator != None )
  MakeNoise(10.0*nscale);
 }

SetTimer(0.125, True);

if ( Level.NetMode != NM_DedicatedServer )
 SpawnEffects();
}


simulated function SpawnEffects()
{
local ExplosionLarge E;

PlaySound(sound'LargeExplosion2', SLOT_Misc,,, 2000*nscale);
E = spawn(class'ExplosionLarge',,,Location);
E.RemoteRole = ROLE_None;
}


defaultproperties
{
    nscale=0.75
    LifeSpan=1.50
     DrawType=DT_Mesh
     Style=STY_Translucent
    AmbientGlow=255
    bUnlit=True
    bAlwaysRelevant=True
    MultiSkins(0)=FireTexture'Effects.liquid.Virus_SFX'
    MultiSkins(1)=FireTexture'Effects.liquid.Virus_SFX'
    Skin=FireTexture'Effects.liquid.Virus_SFX'
     Mesh=LodMesh'DeusExItems.SphereEffect'
}
