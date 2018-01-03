//=============================================================================
// ProgressBarWindow
//=============================================================================

class TCProgressBarWindow extends ProgressBarWindow;
var texture foreTexture, backTexture;
var bool bTCE;

event DrawWindow(GC gc)
{
	Super.DrawWindow(gc);

	// First draw the background
	if (bDrawBackground)
	{
		gc.SetTileColor(colBackground);
		gc.DrawPattern(0, 0, width, height, 0, 0, backTexture);
	}

	// Now draw the foreground
	gc.SetTileColor(colForeground);

	if (bVertical)
		gc.DrawPattern(0, height - barSize, width, barSize, 0, 0, foreTexture);
	else
		gc.DrawPattern(0, 0, barSize, height, 0, 0, foreTexture);
}

// ----------------------------------------------------------------------
// ConfigurationChanged()
// ----------------------------------------------------------------------

function ConfigurationChanged()
{
	UpdateBars();
}

// ----------------------------------------------------------------------
// SetValues()
// ----------------------------------------------------------------------

function SetValues(float newLow, float newHigh)
{
	lowValue  = newLow;
	highValue = newHigh;

	// Update bars
	UpdateBars();
}

// ----------------------------------------------------------------------
// SetCurrentValue()
// ----------------------------------------------------------------------

function SetCurrentValue(Float newValue)
{
	// First clamp the value
	newValue = Max(lowValue, newValue);
	newValue = Min(highValue, newValue);

	currentValue = newValue;

	UpdateBars();
}

// ----------------------------------------------------------------------
// UpdateBars()
// ----------------------------------------------------------------------

function UpdateBars()
{
	local Float valuePercent;

	// Now calculate how large the bar is
	valuePercent = currentValue / Abs(highValue - lowValue);

	if (bVertical)
		barSize = valuePercent * height;
	else
		barSize = valuePercent * width;

	// Calculate the bar color
	if (bUseScaledColor)
	{
		colForeground = GetColorScaled(valuePercent);

		if(!bTCE)
		{
			colForeground.r = Int(Float(colForeground.r) * scaleColorModifier);
			colForeground.g = Int(Float(colForeground.g) * scaleColorModifier);
			colForeground.b = Int(Float(colForeground.b) * scaleColorModifier);
		}
		else
		{
			colForeground.r = Int(Float(colForeground.r) * scaleColorModifier);
			colForeground.g = Int(Float(colForeground.g) * scaleColorModifier);
			colForeground.b = Int(Float(colForeground.b) * scaleColorModifier);
		}
	}
	else
	{
		colForeground = Default.colForeground;
	}
}

// ----------------------------------------------------------------------
// SetColors()
// ----------------------------------------------------------------------

function SetColors(Color newBack, Color newFore)
{
	colBackground = newBack;
	colForeground = newFore;
}

// ----------------------------------------------------------------------
// SetBackColor()
// ----------------------------------------------------------------------

function SetBackColor(Color newBack)
{
	colBackground = newBack;
}

// ----------------------------------------------------------------------
// SetScaleColorModifier()
// ----------------------------------------------------------------------

function SetScaleColorModifier(Float newModifier)
{
	scaleColorModifier = newModifier;
}

// ----------------------------------------------------------------------
// SetVertical()
// ----------------------------------------------------------------------

function SetVertical(Bool bNewVertical)
{
	bVertical = bNewVertical;
}

// ----------------------------------------------------------------------
// SetDrawBackground()
// ----------------------------------------------------------------------

function SetDrawBackground(Bool bNewDraw)
{
	bDrawBackground = bNewDraw;
}

// ----------------------------------------------------------------------
// UseScaledColor()
// ----------------------------------------------------------------------

function UseScaledColor(Bool bNewScaled)
{
	bUseScaledColor = bNewScaled;
}

// ----------------------------------------------------------------------
// GetBarColor()
// ----------------------------------------------------------------------

function Color GetBarColor()
{
	return colForeground;
}

// ----------------------------------------------------------------------
// ----------------------------------------------------------------------

defaultproperties
{
    colBackground=(R=255,G=255,B=255,A=0),
    colForeground=(R=32,G=32,B=32,A=0),
    scaleColorModifier=1.00
    foreTexture=texture'Solid'
    backTexture=texture'Solid'
}
