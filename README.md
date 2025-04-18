# Winwing FCU, EFIS L and EFIS R

## Intro

Status: Currently FCU supported, EFIS R partly supported.

This script allows to use Winwing A320 FCU, EFIS L and EFIS R on macOS with X-Plane 12.

The only dependency is FlyWithLua NG+.

Tested on MacBook M1 Pro with macOS 15.4, XP12.2.0 beta 3, default LR A333, FlyWithLua NG+ 2.8.12. Winwing FCU hardware V51.00, firmware V1.20, EFIS L hardware V51.00, firmware V0.97, EFIS R hardware V51.00, firmware V0.99, according to SimAppPro.

This script might work with Windows or Linux as well, but never tested. 

This work heavily bases on the work from [schenlap](https://github.com/schenlap/winwing_fcu) and [samrq](https://github.com/samrq/winwing_fcu/tree/main). Thanks a lot to both of them. 

## Features

* When starting X-Plane, LEDs and LCDs at Winwing FCU / EFIS are set according to the sim LEDs and LCDs. 
* When starting X-Plane, the current position of physical switches or knobs (e.g. 100/1000ft selector for altitude) at Winwing FCU / EFIS is applied to the sim FCU and EFIS.
* LEDs and LCDs on Winwing FCU and EFIS are turned on or off depending on the status of the electric system (batteries, generators, external power). Same behaviour as sim FCU and EFIS show.
* You can turn switches / knobs in the sim as you want without breaking the script. The next time you turn them on the Winwing device, they will take the position from the device again. In this way, you can set the EFIS map mode to "ENG" in the sim, what is not possbile with the Winwing EFIS (as the Winwing device is mimicing the A320, not the A330).

## Installation on macOS

1. Clone the repo where you want
2. Install FlyWithLua NG+ for XP12, cf. https://forums.x-plane.org/files/file/82888-flywithlua-ng-next-generation-plus-edition-for-x-plane-12-win-lin-mac/
3. Copy (todo).lua to {XP12_ROOT}/Resources/plugins/FlyWithLua/Scripts
4. Manually determine the correct value for the variable FCU_BUTTON_BEGIN in the lua file, cf. below in section "Known bugs" 
5. Calibrating the FCU / EFIS inside XP12 is not necessary, you can ignore a pop-up reminding you of it

## Use

1. Connect FCU and optional EFIS to the PC
2. Start X-Plane and enjoy
3. If you disconnect and reconnect the FCU / EFIS while X-Plane is running, go to "Plugins" -> "FlyWithLua" -> "Reload all Lua script files" in order to init the lua scripts again

Use at your own risk. 

## Next steps
* Make LED and LCD brightness adjustable using knobs underneath fcu and annun brightness switch
* Fix backlight of "EXPED" button
* Finish EFIS R LCD
* Do EFIS L

## Known bugs
* If you turn e.g. the altitude knob at the winwing FCU, sometimes the e.g. altitude value does not stop spinning until it reaches the limit, e.g. 72,000, even when you have stopped turning the knob already
* Before the first use, you manually need to set the offset for the button ids in the variable FCU_BUTTON_BEGIN. It seems that the necessary value is a multiple of 160, it might change if you add / remove one of the EFIS devices from the FCU. If you don't change anything with your physical setup, the value should remain the same. You can determine it by ... todo 
* Please open an Github issue if you find any other bugs

