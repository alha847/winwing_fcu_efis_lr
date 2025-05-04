# Winwing FCU, EFIS L and EFIS R

## Intro

Status: Currently FCU, EFIS L and EFIS R supported in a preliminary version v0.9.

This script allows to use the Winwing A320 FCU, EFIS L and EFIS R with the Laminar Research A333 on macOS with X-Plane 12. 

The only dependency is FlyWithLua NG+.

For Windows users, there are other alternatives like SimAppPro or MobiFlight, that are lacking support of macOS. This script might work with Windows or Linux as well, but it has never been tested. 

Tested on MacBook M1 Pro with macOS 15.4, XP12.2.0 beta 3 and 4, default LR A333, FlyWithLua NG+ 2.8.12. Winwing FCU hardware V51.00, firmware V1.20, EFIS L hardware V51.00, firmware V0.97, EFIS R hardware V51.00, firmware V0.99 (according to SimAppPro). Running the script might cause a drop of 1-3 FPS (according to one test flight).

This work heavily bases on the work from [schenlap](https://github.com/schenlap/winwing_fcu) and [samrq](https://github.com/samrq/winwing_fcu/tree/main). Thanks a lot to both of them. 

## Features

* When starting X-Plane, LEDs and LCDs at Winwing devices are set according to the sim. 
* When starting X-Plane, the position of physical switches or knobs (e.g. 100/1000ft selector for altitude) at the Winwing devices is applied to X-Plane.
* LEDs and LCDs on Winwing FCU and EFIS are turned on or off depending on the status of the electric system (batteries, generators, external power, annun light test mode). Same behaviour as FCU and EFIS in X-Plane show.
* You can turn switches / knobs in X-Plane as you want without breaking the script. The next time you turn them on the Winwing device, they will take the position from the device again. In this way, you can set the EFIS map mode to "ENG" in the sim, what is not possbile with the Winwing EFIS (the  device is mimicing the A320, not the A330).
* You can do some basic configurations, cf. section "Installation on macOS"
* This script will work with either FCU alone, FCU and one EFIS as well as with FCU and both EFIS 

## Installation on macOS

1. Clone the repo where you want
2. Install FlyWithLua NG+ for XP12, cf. https://forums.x-plane.org/files/file/82888-flywithlua-ng-next-generation-plus-edition-for-x-plane-12-win-lin-mac/
3. Copy lra333_winwing_fcu_efis_driver.lua to {XP12_ROOT}/Resources/plugins/FlyWithLua/Scripts
4. If you want, you can do some configurations (e.g. default LED brightness), just look at the beginning of the script
5. Calibrating the FCU / EFIS inside XP12 is not necessary, you can ignore a pop-up reminding you of it

## Use

1. Connect FCU and optional EFIS to the PC
2. Start X-Plane and enjoy
3. If you disconnect and reconnect the FCU / EFIS while X-Plane is running, go to "Plugins" -> "FlyWithLua" -> "Reload all Lua script files" in order to restart the lua scripts again

Use at your own risk. 

## Next features
* Make LED and LCD brightness adjustable using knobs underneath fcu and annun brightness switch
* No visual motion of buttons visible in X-Plane when they are pressed/pulled for longer time on the Winwing devices


## Known bugs
* FD_L and ALT HOLD annun lights dont switch off sometimes, circumstances unclear, maybe only inflight, further observation needed
* Please open an Github issue if you find any other bugs

