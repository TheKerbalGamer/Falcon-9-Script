runPath("0:/My_lib.ks").

WAIT 6.
//runPath("0:/falcon 9/A.S.D.S.ks").
set landingPad to latlng(-0.133452886024334,-74.5576919014068).
//set landingPad to latlng(3.3112048864589,-72.2388104233274).

set boosterAdjustPitch to 10.
SET boosterAdjustLatOffset TO 0. 
SET boosterAdjustLngOffset TO 0.02.// set's the overshot distance

set impactDist to 5000000.
set impactDistance to DistToTarget(landingPad).
SET thrott TO 0.
lock throttle to 0.
toggle ag1.
rcs on.
lock steering to heading(landingPad:heading,80).
wait 0.1.
lock steering to heading(landingPad:heading,70).
wait 0.6.
lock steering to heading(landingPad:heading,60).
wait 0.5.
lock steering to heading(landingPad:heading,50).
wait 0.5.
lock steering to heading(landingPad:heading,40).
wait 0.1.
lock steering to heading(landingPad:heading,30).
wait 0.1.
lock steering to heading(landingPad:heading,20).
wait 2.
lock throttle to 0.2.
lock steering to heading(landingPad:heading,10).
steerToTarget(boosterAdjustPitch,boosterAdjustLatOffset,boosterAdjustLngOffset).

function BoostBack{

	until ImpactDist < 500{
		lock throttle to thrott.
	steerToTarget(boosterAdjustPitch,boosterAdjustLatOffset,boosterAdjustLngOffset).		
	 if(impactDist < 20000){		
		SET thrott TO 0.5.
	}else{
		SET thrott TO 1.
	}
	}	
  if ImpactDist < 500{
	SET thrott TO 0.
	WAIT 1.

  }
		
} 

BoostBack().
runPath("0:/land.ks").





function steerToTarget{
	parameter pitch is 1.
	parameter overshootLatModifier is 0.
	parameter overshootLngModifier is 0.
	local overshootLatLng TO LATLNG(landingPad:LAT + overshootLatModifier, landingPAD:LNG + overshootLngModifier).
	local targetDir TO geoDir(getImpact(),overshootLatLng).
	set impactDist TO calcDistance(overshootLatLng, getImpact()).
	local steeringDir is targetDir - 180.
	print ImpactDist at(3,3) .
	LOCK STEERING TO HEADING(steeringDir,pitch).
  	//lockSteeringToStandardVector(HEADING(steeringDir,pitch):VECTOR).
}

function calcDistance { //Approx in meters
	parameter geo1.
	parameter geo2.
	return (geo1:POSITION - geo2:POSITION):MAG.
}
function DistToTarget{
parameter Targ.
return calcDistance(targ, getImpact()).
}
function geoDir {
	parameter geo1.
	parameter geo2.
	return ARCTAN2(geo1:LNG - geo2:LNG, geo1:LAT - geo2:LAT).
}
