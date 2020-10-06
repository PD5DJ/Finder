---- ##########################################################################################################
---- #                                                                                                        #
---- # GPS INFO                   			                                                                      #
-----#                                                                                                        #
---- # License GPLv3: http://www.gnu.org/licenses/gpl-3.0.html                                                #
---- #                                                                                                        #
---- # This program is free software; you can redistribute it and/or modify                                   #
---- # it under the terms of the GNU General Public License version 3 as                                      #
---- # published by the Free Software Foundation.                                                             #
---- #                                                                                                        #
---- #                                                                                                        #
---- # Björn Pasteuning / Hobby4life 2020                                                                     #
---- # Website: https://www.hobby4life.nl                                                                     #
---- #                                                                                                        #
---- ##########################################################################################################


  local ALL_FUNCTIONS = 0

local options = {
  { "Input"  , SOURCE  , 1     },
  { "Input1"  , SOURCE  , 1     },--Define a source for trigger a reset of all  values
  { "Imperial"  , VALUE   , 0,0,1 },  --Toggle between Metric or Imperial notation, note that correct settings have to be set on the sensor page too!
}


-- in the create function you add all shared variables to the array containing the widget data ('thisWidget')
local function create(zone, options)
  
  local thisWidget  = {zone=zone, options=options,counter = 0}

  --create array containing all sensor ID's used for quicker retrieval
  local ID = {}
  ID.GPS        = getFieldInfo("GPS")  and getFieldInfo("GPS").id	 or 0
  ID.GSpd       = getFieldInfo("GSpd") and getFieldInfo("GSpd").id or 0
  ID.GAlt       = getFieldInfo("GAlt") and getFieldInfo("GAlt").id or 0  -- Vario Altimeter has priority over GPS Altimeter
  ID.Tmp1       = getFieldInfo("Tmp1") and getFieldInfo("Tmp1").id or 0 -- used with OpenXsenor or sallites in view indicator
  ID.Tmp2       = getFieldInfo("Tmp2") and getFieldInfo("Tmp2").id or 0  
  ID.Hdg        = getFieldInfo("Hdg")  and getFieldInfo("Hdg").id  or 0
  
  --add ID to thisWidget
  thisWidget.ID = ID	
 
  Background      = Bitmap.open("/widgets/Finder/images/background.png")
 
  Arrow_Up        = Bitmap.open("/widgets/Finder/images/arrowup.png")
  Arrow_Right     = Bitmap.open("/widgets/Finder/images/arrowright.png")
  Arrow_Left      = Bitmap.open("/widgets/Finder/images/arrowleft.png")
  Arrow_Up_bg     = Bitmap.open("/widgets/Finder/images/arrowup_bg.png")
  Arrow_Right_bg  = Bitmap.open("/widgets/Finder/images/arrowright_bg.png")
  Arrow_Left_bg   = Bitmap.open("/widgets/Finder/images/arrowleft_bg.png")
  
 
 
  --return the thisWidget array to the opentx API, containing all data to be shared across functions
  return thisWidget
  
end

local function update(thisWidget, options)
  thisWidget.options = options
end

--***********************************************************************
--*                        BACKGROUND FUNCTION                          *
--***********************************************************************
local function background(thisWidget)
  
  ImperialSet = thisWidget.options.Imperial or 0
  
  thisWidget.gpsLatLong = getValue(thisWidget.ID.GPS)
  
  
  
  if  (type(thisWidget.gpsLatLong) ~= "table") then
    thisWidget.ID.GPS       = getFieldInfo("GPS")  and getFieldInfo("GPS").id	 or 0
    thisWidget.ID.GSpd      = getFieldInfo("GSpd") and getFieldInfo("GSpd").id or 0
    thisWidget.ID.GAlt      = getFieldInfo("GAlt") and getFieldInfo("GAlt").id or 0
    thisWidget.ID.Tmp1      = getFieldInfo("Tmp1") and getFieldInfo("Tmp1").id or 0
    thisWidget.ID.Tmp2      = getFieldInfo("Tmp2") and getFieldInfo("Tmp2").id or 0
    thisWidget.ID.Hdg       = getFieldInfo("Hdg")  and getFieldInfo("Hdg").id  or 0
    return
  end
  
  thisWidget.Plane_Speed      = getValue(thisWidget.ID.GSpd)
  thisWidget.Plane_Altitude   = getValue(thisWidget.ID.GAlt)
  thisWidget.Plane_Tmp1       = getValue(thisWidget.ID.Tmp1)
  thisWidget.Plane_Tmp2       = getValue(thisWidget.ID.Tmp2)
  thisWidget.Plane_Hdg        = getValue(thisWidget.ID.Hdg)

  
  thisWidget.Plane_gpsLat     = thisWidget.gpsLatLong.lat
  thisWidget.Plane_gpsLong    = thisWidget.gpsLatLong.lon
  

end
---------------------------------------------------------------------------------------------------------


--***********************************************************************
--*                           REFRESH FUNCTION                          *
--***********************************************************************
local function refresh(thisWidget)
  
  --local StickInput = getValue(thisWidget.options.Input) or 0
  --local StickInput1 = getValue(thisWidget.options.Input1) or 0
  
  --StickInput = StickInput / (1024 / 360)
  --StickInput1 = StickInput1  + 1024  
    
  Pilot_GPSTable = getTxGPS()
  
  lcd.drawBitmap(Background, 0 , 0, 100) 
  
  local FM        = ""
  local SPD       = ""

  local Pilot_NS  = ""
  local Pilot_EW  = ""
    
  local Plane_NS  = ""
  local Plane_EW  = ""  
  local Plane_Lat   = thisWidget.Plane_gpsLat or 0
  local Plane_Long  = thisWidget.Plane_gpsLong or 0 
  local Plane_Speed = thisWidget.Plane_Speed or 0
  local Plane_Alt   = thisWidget.Plane_Altitude or 0
  local Plane_Sats  = thisWidget.Plane_Tmp1 or 0  
  local Plane_Hdop  = thisWidget.Plane_Tmp2 or 0
  local Plane_Hdg   = thisWidget.Plane_Hdg or 0
  local Plane_Fix   = false
  
  
------------------ Get proper Satellite number readout -----------------
  if Plane_Sats > 100 then
    Plane_Sats = math.abs(Plane_Sats  - 100)
    Plane_Fix  = true
  else
    Plane_Sats = 0
    Plane_Fix  = false
  end


  


  if (Pilot_GPSTable.fix == true) then
    PilotToPlaneDistance = CalcLOS(Pilot_GPSTable.alt,Plane_Alt,CalcDistance(Pilot_GPSTable.lat ,Pilot_GPSTable.lon ,Plane_Lat,Plane_Long)) or 0
  else
    PilotToPlaneDistance = 0
  end  
    
  ----------- Corrects some readout internal X12S GPS ----------------------
  local Pilot_Hdg = Pilot_GPSTable.heading / 10
  local Pilot_Speed = Pilot_GPSTable.speed / 10



------------ Calculates Heading and Bearing from previous and new location of the plane ----------------------

  local Position_Bearing = CalcBearing(Pilot_GPSTable.lat,Pilot_GPSTable.lon,Plane_Lat,Plane_Long)
  local Deviation_Bearing = 0

  Deviation_Bearing = (Pilot_Hdg) - Position_Bearing
  
  --Deviation_Bearing = StickInput
  --PilotToPlaneDistance = StickInput1
  
  
      -- Preset info
  if Plane_Lat > 0 then
    Plane_NS = "N" 
  else
    Plane_NS = "S"
  end

  if Plane_Long > 0 then
    Plane_EW = "E"
  else
    Plane_EW = "W" 
  end


	if Pilot_GPSTable.lat > 0 then
		Pilot_NS = "N" 
	else
		Pilot_NS = "S"
	end

	if Pilot_GPSTable.lon > 0 then
		Pilot_EW = "E"
	else
		Pilot_EW = "W" 
	end  
	
	if ImperialSet == 1 then
		FM  = "ft"
    SPD = "mph"
	else
		FM  = "m"
    SPD = "kmh"
	end  
  
  if thisWidget.zone.w == 460 then
  
    lcd.drawText((thisWidget.zone.x + 90)  - CharColorShift(thisWidget,PilotToPlaneDistance) , thisWidget.zone.y + 98, math.floor(PilotToPlaneDistance).." "..FM, DBLSIZE + CUSTOM_COLOR + SHADOWED)
    lcd.drawText((thisWidget.zone.x + 355) - CharColorShift(thisWidget,math.abs(Deviation_Bearing))  , thisWidget.zone.y + 98, math.floor(Deviation_Bearing).." ".." deg", DBLSIZE + CUSTOM_COLOR + SHADOWED)
    lcd.setColor(CUSTOM_COLOR, lcd.RGB(248,254,248))
    lcd.drawText(thisWidget.zone.x + 16 , thisWidget.zone.y + 80, "Distance to Plane", CUSTOM_COLOR + SHADOWED)
    lcd.drawText(thisWidget.zone.x + 305, thisWidget.zone.y + 80, "Bearing Deviation", CUSTOM_COLOR + SHADOWED)

    
    
    local A = ""
    lcd.setColor(CUSTOM_COLOR, lcd.RGB(248,254,248))
    ------------------------- Show Pilot satellite fix/sats -------------------------------------
    if Pilot_GPSTable.fix == true then
      A = Pilot_GPSTable.numsat
        lcd.drawText(thisWidget.zone.x + 10, 60, "Lat: "..string.format("%f",Pilot_GPSTable.lat), LEFT + CUSTOM_COLOR + SHADOWED);
    else
      A = "No GPS"
    end
    lcd.drawText(65,15, A, MIDSIZE + CUSTOM_COLOR + SHADOWED)
  
    ------------------------- Show plane satellite fix/sats -------------------------------------
    if (type(thisWidget.gpsLatLong) ~= "table") then
      A = "No GPS"
    else
      A = Plane_Sats 
    end
    lcd.drawText(415,15, A, RIGHT + MIDSIZE + CUSTOM_COLOR + SHADOWED)
    

  
    DrawBgArrows(thisWidget)
    DrawArrows(thisWidget, Deviation_Bearing,PilotToPlaneDistance)

    DrawNeedle(thisWidget,Deviation_Bearing)
  
  else
  
    lcd.setColor(CUSTOM_COLOR, lcd.RGB(248,0,0))
    lcd.drawText(thisWidget.zone.x , thisWidget.zone.y + (thisWidget.zone.h / 2), "FULL SCREEN ONLY", CUSTOM_COLOR + SMLSIZE + SHADOWED)
  
  end
  
end




--***********************************************************************
--*                          SPECIAL FUNCTIONS                          *
--***********************************************************************

----------------------- Function to calculated bearing angle between 2 coordinates ----------------------
function CalcBearing(PrevLat,PrevLong,NewLat,NewLong)
  local yCalc = math.sin(math.rad(NewLong)-math.rad(PrevLong)) * math.cos(math.rad(NewLat))
  local xCalc = math.cos(math.rad(PrevLat)) * math.sin(math.rad(NewLat)) - math.sin(math.rad(PrevLat)) * math.cos(math.rad(NewLat)) * math.cos(math.rad(NewLat) - math.rad(PrevLat))
  local Bearing = math.deg(math.atan2(yCalc,xCalc))
  if Bearing < 0 then
    Bearing = 360 + Bearing
  end  
  return Bearing
end

----------------------- Function to calculate distance between 2 coordinates -----------------------------
function CalcDistance(PrevLat,PrevLong,NewLat,NewLong)
  local earthRadius = 0
  if ImperialSet == 1 then
    earthRadius = 20902000  --feet  --3958.8 miles
  else
    earthRadius = 6371000   --meters
  end
  local dLat = math.rad(NewLat-PrevLat)
  local dLon = math.rad(NewLong-PrevLong)
  PrevLat = math.rad(PrevLat)
  NewLat = math.rad(NewLat)
  local a = math.sin(dLat/2) * math.sin(dLat/2) + math.sin(dLon/2) * math.sin(dLon/2) * math.cos(PrevLat) * math.cos(NewLat) 
  local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
  return (earthRadius * c)
end    

  -------------------------------- Calculates (max) Line Of Sight Distance ---------------------------------
function CalcLOS(Alt_1,Alt_2,Distance)
	local a = math.floor(Alt_2 - Alt_1)
	local b = math.floor(Distance)
	local c = math.floor(math.sqrt((a * a) + (b * b)))
  return c
end

function CharColorShift(thisWidget,value)
  
    local Shift = 0        
        
    if value > 999 then
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(248,0,0))
      Shift = 55
    elseif value > 99 then
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(248,100,0))
      Shift = 45
    elseif value > 9 then
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(248,254,0))
      Shift = 40
    else
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(248,254,248))
      Shift = 20
    end
    
    return Shift
    
end


function DrawNeedle(thisWidget,deviation)
  
    if deviation > 88 then
      deviation = 90
    elseif deviation < -89 then
      deviation = -90
    end
    
    if deviation > -91 and deviation < 91 then
      local Angle = 360 - ((deviation) + 90)
      local Radius = 150
      local CenterX = (thisWidget.zone.x + (thisWidget.zone.w / 2))
      local CenterY = (thisWidget.zone.y + (thisWidget.zone.y + 225 ))
      local EndX = CenterX + (Radius * math.cos(Angle * (math.pi / 180))) 
      local EndY = CenterY + (Radius * math.sin(Angle * (math.pi / 180)))
   
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(248,0,0))
      lcd.drawLine( CenterX - 2, CenterY , EndX , EndY , SOLID , CUSTOM_COLOR )
      lcd.drawLine( CenterX , CenterY , EndX , EndY , SOLID , CUSTOM_COLOR )
      lcd.drawLine( CenterX + 2, CenterY , EndX , EndY , SOLID , CUSTOM_COLOR )
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(248,255,0))
      lcd.drawLine( CenterX - 5, CenterY , EndX , EndY , SOLID , CUSTOM_COLOR )
      lcd.drawLine( CenterX - 4, CenterY , EndX , EndY , SOLID , CUSTOM_COLOR )
      lcd.drawLine( CenterX - 3, CenterY , EndX , EndY , SOLID , CUSTOM_COLOR )
      lcd.drawLine( CenterX + 3, CenterY , EndX , EndY , SOLID , CUSTOM_COLOR )
      lcd.drawLine( CenterX + 4, CenterY , EndX , EndY , SOLID , CUSTOM_COLOR )
      lcd.drawLine( CenterX + 5, CenterY , EndX , EndY , SOLID , CUSTOM_COLOR )  
      
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(248,0,0))
      circle(CenterX,CenterY,10,CUSTOM_COLOR)
    end    
end



----------------------------- Draws all the backgroup arrows --------------------------------------------------
function DrawBgArrows(thisWidget)
  
  lcd.drawBitmap(Arrow_Left_bg , thisWidget.zone.x + (thisWidget.zone.w / 2) - 115 , (thisWidget.zone.y + 148), 100)
  lcd.drawBitmap(Arrow_Left_bg , thisWidget.zone.x + (thisWidget.zone.w / 2) - 150 , (thisWidget.zone.y + 148), 100)
  lcd.drawBitmap(Arrow_Left_bg , thisWidget.zone.x + (thisWidget.zone.w / 2) - 185 , (thisWidget.zone.y + 148), 100)
  lcd.drawBitmap(Arrow_Left_bg , thisWidget.zone.x + (thisWidget.zone.w / 2) - 220 , (thisWidget.zone.y + 148), 100)  
  
  lcd.drawBitmap(Arrow_Up_bg   , thisWidget.zone.x + (thisWidget.zone.w / 2) - 50  , thisWidget.zone.y + 93, 100)  
  lcd.drawBitmap(Arrow_Up_bg   , thisWidget.zone.x + (thisWidget.zone.w / 2) - 50  , thisWidget.zone.y + 128, 100)
  lcd.drawBitmap(Arrow_Up_bg   , thisWidget.zone.x + (thisWidget.zone.w / 2) - 50  , thisWidget.zone.y + 163, 100)
  lcd.drawBitmap(Arrow_Up_bg   , thisWidget.zone.x + (thisWidget.zone.w / 2) - 50  , thisWidget.zone.y + 198, 100)
    
  lcd.drawBitmap(Arrow_Right_bg, thisWidget.zone.x + (thisWidget.zone.w / 2) + 170 , (thisWidget.zone.y + 148), 100)
  lcd.drawBitmap(Arrow_Right_bg, thisWidget.zone.x + (thisWidget.zone.w / 2) + 135 , (thisWidget.zone.y + 148), 100)
  lcd.drawBitmap(Arrow_Right_bg, thisWidget.zone.x + (thisWidget.zone.w / 2) + 100 , (thisWidget.zone.y + 148), 100)
  lcd.drawBitmap(Arrow_Right_bg, thisWidget.zone.x + (thisWidget.zone.w / 2) + 65  , (thisWidget.zone.y + 148), 100)    

end

------------------- Draws the heading arrows compared to heading deviation and Distance -----------
function DrawArrows(thisWidget,Deviation,Distance)

  if Deviation > 10 then
    lcd.drawBitmap(Arrow_Left , thisWidget.zone.x + (thisWidget.zone.w / 2) - 115 , (thisWidget.zone.y + 148), 100)
    if Deviation > 60 then
      lcd.drawBitmap(Arrow_Left , thisWidget.zone.x + (thisWidget.zone.w / 2) - 150 , (thisWidget.zone.y + 148), 100)
    end
    if Deviation > 120 then 
      lcd.drawBitmap(Arrow_Left , thisWidget.zone.x + (thisWidget.zone.w / 2) - 185 , (thisWidget.zone.y + 148), 100)  
    end
    if Deviation > 180 then
       lcd.drawBitmap(Arrow_Left , thisWidget.zone.x + (thisWidget.zone.w / 2) - 220 , (thisWidget.zone.y + 148), 100)  
    end
  end
     
  if Deviation < 10 and Deviation > -10 then
    if Distance > 5 then
      lcd.drawBitmap(Arrow_Up , thisWidget.zone.x + (thisWidget.zone.w / 2) - 50  , thisWidget.zone.y + 198, 100)
    end
    if Distance > 15 then
      lcd.drawBitmap(Arrow_Up , thisWidget.zone.x + (thisWidget.zone.w / 2) - 50  , thisWidget.zone.y + 163, 100)
    end
    if Distance > 40 then
      lcd.drawBitmap(Arrow_Up , thisWidget.zone.x + (thisWidget.zone.w / 2) - 50  , thisWidget.zone.y + 128, 100)
    end
    if Distance > 60 then
      lcd.drawBitmap(Arrow_Up , thisWidget.zone.x + (thisWidget.zone.w / 2) - 50  , thisWidget.zone.y + 93, 100)
    end    
  end
  
  if Deviation < -10 then
    lcd.drawBitmap(Arrow_Right, thisWidget.zone.x + (thisWidget.zone.w / 2) + 65  , (thisWidget.zone.y + 148), 100)    
    if Deviation < -60 then
      lcd.drawBitmap(Arrow_Right, thisWidget.zone.x + (thisWidget.zone.w / 2) + 100 , (thisWidget.zone.y + 148), 100)
    end
    if Deviation < -120 then
        lcd.drawBitmap(Arrow_Right, thisWidget.zone.x + (thisWidget.zone.w / 2) + 135 , (thisWidget.zone.y + 148), 100)
    end
    if Deviation < -180 then
          lcd.drawBitmap(Arrow_Right, thisWidget.zone.x + (thisWidget.zone.w / 2) + 170 , (thisWidget.zone.y + 148), 100)
    end
  end
  
end





function circle(xCenter, yCenter, radius, color)
  local y, x
  for y=-radius, radius do
    for x=-radius, radius do
        if(x*x+y*y <= radius*radius) then
            lcd.drawPoint(xCenter+x, yCenter+y, color)
        end
    end
  end
end








return { name="Finder", options=options, create=create, update=update, background=background, refresh=refresh }