class TCSpectatorStartPoints extends Actor;

struct MapIndex
{
	var string MapName;
	var int index;
};

struct DefSpecPosAndRot
{
    var vector Location;
    var int RotSlope;
};

var MapIndex Indexes[10];
var config DefSpecPosAndRot MapSpecs[7];

static function bool GetSpectatorStartPoint(string map, out vector vect, out rotator rot)
{
	local int i;

    for (i = 0; i < arrayCount(default.Indexes); i++)
    {
        if (default.Indexes[i].MapName ~= map)
        {
			vect = default.MapSpecs[default.Indexes[i].index].Location;
			rot.Pitch = (-3200) * default.MapSpecs[default.Indexes[i].index].RotSlope;
            return true;
        }
    }

	return false;
}

defaultproperties
{
    Indexes(0)=(MapName="DXMP_Smuggler",index=0),
    Indexes(1)=(MapName="DXMP_Cmd",index=1),
    Indexes(2)=(MapName="DXMP_TunnelNetwork",index=2),
    Indexes(3)=(MapName="DXMP_Area51Bunker",index=3),
    Indexes(4)=(MapName="DXMP_Silo",index=4),
    Indexes(5)=(MapName="DXMP_Smuggles",index=5),
    Indexes(6)=(MapName="DXMP_Cathedral_GOTY",index=6),
    Indexes(7)=(MapName="DXMP_Paris_Cathedral",index=6),
    Indexes(8)=(MapName="DXMP_Cathedral",index=6),
    Indexes(9)=(MapName="DXMP_Smuggles_Ed",index=5),
    MapSpecs(0)=(Location=(X=-300.00,Y=-700.00,Z=100.00),,RotSlope=1),
    MapSpecs(1)=(Location=(X=-1000.00,Y=3000.00,Z=0.00),,RotSlope=2),
    MapSpecs(2)=(Location=(X=-900.00,Y=0.00,Z=0.00),,RotSlope=1),
    MapSpecs(3)=(Location=(X=-2500.00,Y=2000.00,Z=800.00),,RotSlope=2),
    MapSpecs(4)=(Location=(X=-2000.00,Y=-4000.00,Z=2500.00),,RotSlope=2),
    MapSpecs(5)=(Location=(X=-3500.00,Y=-800.00,Z=400.00),,RotSlope=2),
    MapSpecs(6)=(Location=(X=1000.00,Y=-2000.00,Z=1500.00),,RotSlope=2),
    bHidden=True
}
