//=============================================================================
// ceskiHUDWaypoint
//=============================================================================
class TCHUDWaypoint extends Window;

//
// waypoints are a bit broken because of improper vector to coordinate conversion
//

var TCPlayer TCP;

var bool bActive;
var Color colBackground;
var Color colBorder;
var Color colText;

function InitWindow()
{
	Super.InitWindow();

	TCP = TCPlayer(GetRootWindow().parentPawn);
}

//mimmick frob window behavior for drawing waypoint indicator
function DrawWindow(GC gc)
{
	local actor wpTarget;
	local float infoX, infoY, infoW, infoH;
	local string strInfo;
	local int dist;
	local float offset;
	local vector centerLoc;
	local float centerX, centerY;
	local float markX, markY, markW, markH;
	local string markInfo;

	//if (bActive)
	//{
		if (TCP != None)
		{
			wpTarget = TCPRI(TCP.PlayerReplicationInfo).wpTargetPRI;
	
			if (wpTarget != None)
			{
				centerLoc = wpTarget.Location;
	
				if (ConvertVectorToCoordinates(centerLoc, centerX, centerY))
				{
					// convert to meters
					dist = int(vsize(TCP.Location-wpTarget.Location)/52);

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
			}
		}
	//}
}

defaultproperties
{
}
