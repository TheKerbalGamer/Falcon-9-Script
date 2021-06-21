//Creator: Kerbal Gamer
//Credits: nuggreat

function setEngineThrustLimit{
  parameter eng.
  parameter engineThrustLimit. // 0 - 100
  for e IN ship:partstagged(eng) { SET e:THRUSTLIMIT TO engineThrustLimit. }.

}

function setThrustTOWeight{
parameter thrToWeight.
local g to constant:g * body:mass / body:radius^2.
local throttl to thrToWeight * ship:mass * g / ship:availablethrust.
return throttl.
}

function isShip{
	parameter tagName.
	SET thisParts TO SHIP:PARTSTAGGED(tagName).
	if(thisParts:LENGTH>0){
		return true.
	}
	return false.
}

function circDeltaV {
local targetVel is sqrt(ship:body:mu / (ship:orbit:body:radius + ship:orbit:apoapsis)).
local currentVel is sqrt(ship:body:mu * ((2 / (ship:body:radius + ship:orbit:apoapsis) - (1 / ship:orbit:semimajoraxis)))).
    	
return (targetVel - currentVel).	
}

function executeManeuver {
  parameter utime.
  parameter radial.
  parameter normal.
  parameter prog.

  local mnv is node(utime,radial,normal,prog).
  addManeuverToFlightPlan(mnv).
  local startTime is calculateStartTime(mnv).
  lockSteeringAtManeuverTarget(mnv).
  wait until time:seconds > startTime - 10.
  lockSteeringAtManeuverTarget(mnv).
  wait until time:seconds > startTime.
  lock throttle to 1.
  wait until isManeuverComplete(mnv) = true. .

  lock throttle to 0.
  unlock steering.
  removeManeuverFromFlightPlan(mnv).
}

function addManeuverToFlightPlan {
  parameter mnv.
  add mnv.
}

function calculateStartTime {
  parameter mnv.
  return time:seconds + mnv:eta - maneuverBurnTime(mnv) / 2.
}

function maneuverBurnTime {
  parameter mnv.
  local dV is mnv:deltaV:mag.
  local g0 is 9.80665.
  local isp is 0.

  list engines in myEngines.
  for en in myEngines {
    if en:ignition and not en:flameout {
      set isp to isp + (en:isp * (en:availableThrust / ship:availableThrust)).
    }
  }

  local mf is ship:mass / constant():e^(dV / (isp * g0)).
  local fuelFlow is ship:availableThrust / (isp * g0).
  local t is (ship:mass - mf) / fuelFlow.

  return t.
}

function lockSteeringAtManeuverTarget {
  parameter mnv.
  lock steering to mnv:burnvector.
}

function isManeuverComplete {
  parameter mnv.
  if not(defined originalVector) or originalVector = -1 {
    declare global originalVector to mnv:burnvector.
  }
  if vang(originalVector, mnv:burnvector) > 90 {
    declare global originalVector to -1.
    return true.
  }
  return false.
}

function removeManeuverFromFlightPlan {
  parameter mnv.
  remove mnv.
}


function getImpact {
	LOCAL localTime IS TIME:SECONDS.
	IF periapsis > 0 {
		CLEARSCREEN.
		PRINT "no impact detected.".
	} ELSE {
		LOCAL impactData IS impact_UTs().
		LOCAL impactLatLng IS ground_track(POSITIONAT(SHIP,impactData["time"]),impactData["time"]).  
    return impactLatLng.
    }   
SET oldTime TO localTime.   
}

FUNCTION impact_UTs {//returns the UTs of the ship's impact, NOTE: only works for non hyperbolic orbits
	PARAMETER minError IS 1.
	IF NOT (DEFINED impact_UTs_impactHeight) { GLOBAL impact_UTs_impactHeight IS 0. }
	LOCAL startTime IS TIME:SECONDS.
	LOCAL craftOrbit IS SHIP:ORBIT.
	LOCAL sma IS craftOrbit:SEMIMAJORAXIS.
	LOCAL ecc IS craftOrbit:ECCENTRICITY.
	LOCAL craftTA IS craftOrbit:TRUEANOMALY.
	LOCAL orbitPeriod IS craftOrbit:PERIOD.
	LOCAL ap IS craftOrbit:APOAPSIS.
	LOCAL pe IS craftOrbit:PERIAPSIS.
	LOCAL impactUTs IS time_betwene_two_ta(ecc,orbitPeriod,craftTA,alt_to_ta(sma,ecc,SHIP:BODY,MAX(MIN(impact_UTs_impactHeight,ap - 1),pe + 1))[1]) + startTime.
	LOCAL newImpactHeight IS ground_track(POSITIONAT(SHIP,impactUTs),impactUTs):TERRAINHEIGHT.
	SET impact_UTs_impactHeight TO (impact_UTs_impactHeight + newImpactHeight) / 2.
	RETURN LEX("time",impactUTs,//the UTs of the ship's impact
	"impactHeight",impact_UTs_impactHeight,//the aprox altitude of the ship's impact
	"converged",((ABS(impact_UTs_impactHeight - newImpactHeight) * 2) < minError)).//will be true when the change in impactHeight between runs is less than the minError
}

FUNCTION alt_to_ta {//returns a list of the true anomalies of the 2 points where the craft's orbit passes the given altitude
	PARAMETER sma,ecc,bodyIn,altIn.
	LOCAL rad IS altIn + bodyIn:RADIUS.
	LOCAL taOfAlt IS ARCCOS((-sma * ecc^2 + sma - rad) / (ecc * rad)).
	RETURN LIST(taOfAlt,360-taOfAlt).//first true anomaly will be as orbit goes from PE to AP
}

FUNCTION time_betwene_two_ta {//returns the difference in time between 2 true anomalies, traveling from taDeg1 to taDeg2
	PARAMETER ecc,periodIn,taDeg1,taDeg2.
	
	LOCAL maDeg1 IS ta_to_ma(ecc,taDeg1).
	LOCAL maDeg2 IS ta_to_ma(ecc,taDeg2).
	
	LOCAL timeDiff IS periodIn * ((maDeg2 - maDeg1) / 360).
	
	RETURN MOD(timeDiff + periodIn, periodIn).
}

FUNCTION ta_to_ma {//converts a true anomaly(degrees) to the mean anomaly (degrees) NOTE: only works for non hyperbolic orbits
	PARAMETER ecc,taDeg.
	LOCAL eaDeg IS ARCTAN2(SQRT(1-ecc^2) * SIN(taDeg), ecc + COS(taDeg)).
	LOCAL maDeg IS eaDeg - (ecc * SIN(eaDeg) * CONSTANT:RADtoDEG).
	RETURN MOD(maDeg + 360,360).
}

FUNCTION ground_track {	//returns the geocoordinates of the ship at a given time(UTs) adjusting for planetary rotation over time, only works for non tilted spin on bodies 
	PARAMETER pos,posTime,localBody IS SHIP:BODY.
	LOCAL bodyNorth IS v(0,1,0).//using this instead of localBody:NORTH:VECTOR because in many cases the non hard coded value is incorrect
	LOCAL rotationalDir IS VDOT(bodyNorth,localBody:ANGULARVEL) * CONSTANT:RADTODEG. //the number of degrees the body will rotate in one second
	LOCAL posLATLNG IS localBody:GEOPOSITIONOF(pos).
	LOCAL timeDif IS posTime - TIME:SECONDS.
	LOCAL longitudeShift IS rotationalDir * timeDif.
	LOCAL newLNG IS MOD(posLATLNG:LNG + longitudeShift,360).
	IF newLNG < - 180 { SET newLNG TO newLNG + 360. }
	IF newLNG > 180 { SET newLNG TO newLNG - 360. }
	RETURN LATLNG(posLATLNG:LAT,newLNG).
}