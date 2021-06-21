//Script Creator: Kerbal Gamer
//Flacon 9 Launch Script 
//Version 2.1

runOncePath("0:/My_lib.ks").
runOncePath("0:/lib_lazcalc.ks").

//Mission Parameter's
set targetAP to 300000.//In meter's
set Inclination to 20.
set meco_deltaV to 1500.//ASDS[700],RTLS[1200]
set PitchSpeed to 0.310911.
set PayloadType to "Cargo".//Crew , Cargo

set faringDeployed to False.
set steeringManager:rollts to 50.
set steeringManager:maxstoppingtime to 0.45.
launch().
Ascent().
MECO().
stage2().
cricularize().
Payload_Sep().
//De_Orbit().

function launch{
  clearScreen.
  wait 5.
  lock steering to up.
  lock throttle to 1.
  stage.
  wait 2.
  stage.
  Print "Lift off ".
  wait until alt:radar > 100.
}

function Ascent{
 global az_data is LAZcalc_init(targetAp, Inclination).
  lock targetPitch to 90 - 1.03287 * alt:radar^PitchSpeed.

  until SHIP:STAGEDELTAV(SHIP:STAGENUM):CURRENT < Meco_DeltaV {
  Telemetry().
  local az_Hed is LAZcalc(az_data).
  lock steering to heading(az_Hed, targetPitch).
  }
}

function MECO{
  lock throttle to 0.
  toggle ag8.
  wait 1.
  stage.
  clearScreen.
  print "MECO".
  wait 3.5.

  steeringManager:resettodefault().
}

function stage2{
  clearScreen.
  Print "SES-1".
  rcs on.
  lock throttle to 1.
  until ship:apoapsis > targetAP - 100{
    Telemetry().
    if PayloadType = "Cargo" and faringDeployed = False and alt:radar > 80000{
      stage.
      set faringDeployed to true.
    }

    lock targetPitch to 30.
    local azimuth is LAZcalc(az_data).   
    lock steering to heading(azimuth, targetPitch).    
  }
  lock throttle to 0.
  print "SECO-1".
  wait 5.
}

function cricularize{
  executeManeuver(time:seconds + eta:apoapsis,0,0,circDeltaV()).
}

function Payload_Sep{
  lock steering to prograde.
  wait 20.
  unlock steering .
  sas on.
  wait 2.
  stage.
}

function De_Orbit{
  lock steering to retrograde.
  wait 10.
  lock throttle to 1.
  wait until ship:periapsis < 30000.
  lock throttle to 0.
  set ship:control:pilotmainthrottle to 0.
  sas on.
  shutdown.
}

function Telemetry{
Print "FALCON 9 LAUNCH CONTROL COMPUTER" at ( 2, 1).
Print "-------------------------------------" at ( 2, 2).
Print "____________________________________" at ( 3, 3).
Print "Status: " + ship:status at ( 3, 4).
PRINT "Altitude: " + Alt:radar at (3,5).
Print "Liquide Fule:" + ship:liquidfuel at(3,7).
Print "Oxidizer:" + ship:Oxidizer at(3,8).
}