local bit = require("bit")
local socket = require("socket")
winwing_device = nil;
function init_winwing_device()

    --detect winwing fcu, efis l and/or efis r  
    for i = 1,NUMBER_OF_HID_DEVICES do
        local device = ALL_HID_DEVICES[i]
        if ((device.vendor_id == 0x4098) and (device.product_id == 0xbb10) )
        then
            winwing_device = {product_id = device.product_id, mask = "FCU"}
        elseif ((device.vendor_id == 0x4098) and (device.product_id == 0xbc1e) ) then
            winwing_device = {product_id = device.product_id, mask = "FCU | EFISR"}
        elseif ((device.vendor_id == 0x4098) and (device.product_id == 0xbc1d) ) then
            winwing_device = {product_id = device.product_id, mask = "FCU | EFISL"}
        elseif ((device.vendor_id == 0x4098) and (device.product_id == 0xba01) ) then
            winwing_device = {product_id = device.product_id, mask = "FCU | EFISL | EFISR"}
        end 

        if (winwing_device ~= nil) then
            logMsg("found winwing device: "..winwing_device.mask)
            init_switches()
            assign_button()
            lcd_init()
            --set_led_brightness()
            break
        end

    end

    --stop executing the script if no winwing fcu/efis is found or
    --start refresh function
    if (winwing_device == nil) then
        logMsg("No winwing device found")
        return
    else
        do_every_frame("refresh_dataref()")
    end

end

--init switches. apply current switch positions from winwing fcu/efisr to xp
function init_switches()

    init_fcu_switches()

    init_efisr_switches()

end

function init_fcu_switches()

    local winwing_hid_dev = hid_open(0x4098, winwing_device.product_id)
    local data_in = {hid_read(winwing_hid_dev,42)}
    hid_close(winwing_hid_dev)
    
    local n = data_in[1] -- index start from 1.....
    if (n ~= 41)
    then
        --logMsg("invalid input data len skip "..n)
        return
    end

    --alt 100/1000 switch
    -- data_in[6]: value 0x02 = 100ft, 0x04 = 1000ft
    local is100_active = isBitSet(data_in[6],0x02)
    local is1000_active = isBitSet(data_in[6],0x04)
    if(is100_active and not is1000_active) then
        command_once("laminar/A333/autopilot/alt_step_left")
    elseif(not is100_active and is1000_active) then
        command_once("laminar/A333/autopilot/alt_step_right")
    else
        logMsg("Can't read Winwing FCU altitude 100/1000ft switch position");
    end

end

--todo transfer to efis l
function init_efisr_switches()

    local winwing_hid_dev = hid_open(0x4098, winwing_device.product_id)
    local data_in = {hid_read(winwing_hid_dev,42)}
    hid_close(winwing_hid_dev)

    local n = data_in[1] -- index start from 1.....
    if (n ~= 41)
    then
        --logMsg("invalid input data len skip "..n)
        return
    end
    
    --inHg/hPa switch
    --data_in[12], value 0x08 = inhg, 0x10 = hpa
    local inhg_active = isBitSet(data_in[12],0x08)
    local hpa_active = isBitSet(data_in[12],0x10)
    if(inhg_active and not hpa_active) then
        command_once("laminar/A333/knob/baro/fo_inHg")
    elseif(not inhg_active and hpa_active) then
        command_once("laminar/A333/knob/baro/fo_hPa")
    else
        LogMsg("Can't read Winwing EFIS R inHg/hPa switch position");
    end

    --ADF/OFF/VOR 1 switch
    --data_in[14], value 0x01 = vor1, 0x02 = off1, 0x04 = adf1
    local vor1_active = isBitSet(data_in[14],0x01)
    local off1_active = isBitSet(data_in[14],0x02)
    local adf1_active = isBitSet(data_in[14],0x04)
    if(vor1_active and not off1_active and not adf1_active) then
        --VOR 1
        command_once("sim/instruments/EFIS_1_copilot_sel_vor")
    elseif(not vor1_active and off1_active and not adf1_active) then
        --OFF 1
        command_once("sim/instruments/EFIS_1_copilot_sel_off")
    elseif(not vor1_active and not off1_active and adf1_active) then
        --ADF 1
        command_once("sim/instruments/EFIS_1_copilot_sel_adf")
    else
        LogMsg("Can't read Winwing EFIS R ADF/OFF/VOR 1 switch position");
    end

    --ADF/OFF/VOR 2 switch
    --data_in[14], 0x08 = vor2, 0x10 = off2, 0x20 = adf2
    local vor2_active = isBitSet(data_in[14],0x08)
    local off2_active = isBitSet(data_in[14],0x10)
    local adf2_active = isBitSet(data_in[14],0x20)
    if(vor2_active and not off2_active and not adf2_active) then
        --VOR 2
        command_once("sim/instruments/EFIS_2_copilot_sel_vor")
    elseif(not vor2_active and off2_active and not adf2_active) then
        --OFF 2
        command_once("sim/instruments/EFIS_2_copilot_sel_off")
    elseif(not vor2_active and not off2_active and adf2_active) then
        --ADF 2
        command_once("sim/instruments/EFIS_2_copilot_sel_adf")
    else
        LogMsg("Can't read Winwing EFIS R ADF/OFF/VOR 2 switch position");
    end

end

function set_led_brightness()

    --information on electric busses from A333.lighting.lua
    local bus1_is_on = (cache_data["bus1_volts"] > 20) --unit volts
    local bus2_is_on = (cache_data["bus2_volts"] > 20)

    --turn LEDs and LCDs on/off depending on status of electric busses
    if(bus1_is_on or bus2_is_on) then
        led_list_fcu[1].bind = 128
        led_list_fcu[2].bind = 255
        led_list_fcu[3].bind = 255
        led_list_efis_l[1].bind = 128
        led_list_efis_l[2].bind = 255
        led_list_efis_l[3].bind = 255
        led_list_efis_r[1].bind = 128
        led_list_efis_r[2].bind = 255
        led_list_efis_r[3].bind = 255
    else
        led_list_fcu[1].bind = 0
        led_list_fcu[2].bind = 0
        led_list_fcu[3].bind = 0
        led_list_efis_l[1].bind = 0
        led_list_efis_l[2].bind = 0
        led_list_efis_l[3].bind = 0
        led_list_efis_r[1].bind = 0
        led_list_efis_r[2].bind = 0
        led_list_efis_r[3].bind = 0
    end

    --todo allow to set brightness
    --LEDs and LCDs backlight depending on knobs beneath FCU in the sim
    --anunciator LEDs depending on the annunciator bright/dim switch in the overhead panel

end

--determines whether in a given byte a certain bit is set.
--both the byte and the "bit" have to be specified as byte,
--i.e. the third bit (from right to left) means bitValue = 0x08,
--the first bit means bitValue = 0x01, etc.
function isBitSet(byteValue, bitValue)

    return (bit.band(byteValue,bitValue) > 0)

end


function lcd_init()
    local winwing_hid_dev = hid_open(0x4098, winwing_device.product_id)
    hid_write(winwing_hid_dev, 0, 0xf0, 0x2, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)
    logMsg("init lcd")
    hid_close(winwing_hid_dev)
end

--TODO: still working on it to load this button id begin from config automatic  button IDs might change across different machines
--you can find the button id in X-Plane 12/Output/preferences/control profiles/{your device profile}.prf
FCU_BUTTON_BEGIN = 480--1120--800
local btn = {}
--FCU
btn["MACH"] = {id=0,dataref="sim/autopilot/knots_mach_toggle"}
btn["LOC"] = {id=1,dataref="sim/autopilot/NAV"}
btn["TRK"] = {id=2,dataref="sim/autopilot/trkfpa"}
btn["AP1"] = {id=3,dataref="sim/autopilot/servos_toggle"}
btn["AP2"] = {id=4,dataref="sim/autopilot/servos2_toggle"}
btn["A_THR"] = {id=5,dataref="laminar/A333/autopilot/a_thr_toggle"}
btn["EXPED"] = {id=6,dataref="sim/autopilot/altitude_hold"}
btn["METRIC"] = {id=7,dataref="laminar/A333/autopilot/metric_alt_push"}
btn["APPR"] = {id=8,dataref="sim/autopilot/approach"}
btn["SPD_DEC"] = {id=9,dataref="sim/autopilot/airspeed_down"}
btn["SPD_INC"] = {id=10,dataref="sim/autopilot/airspeed_up"}
btn["SPD_PUSH"] = {id=11,dataref="laminar/A333/autopilot/speed_knob_push"}
btn["SPD_PULL"] = {id=12,dataref="laminar/A333/autopilot/speed_knob_pull"}
btn["HDG_DEC"] = {id=13,dataref="sim/autopilot/heading_down"}
btn["HDG_INC"] = {id=14,dataref="sim/autopilot/heading_up"}
btn["HDG_PUSH"] = {id=15,dataref="laminar/A333/autopilot/heading_knob_push"}
btn["HDG_PULL"] = {id=16,dataref="laminar/A333/autopilot/heading_knob_pull"}
btn["ALT_DEC"] = {id=17,dataref="sim/autopilot/altitude_down"}
btn["ALT_INC"] = {id=18,dataref="sim/autopilot/altitude_up"}
btn["ALT_PUSH"] = {id=19,dataref="laminar/A333/autopilot/altitude_knob_push"}
btn["ALT_PULL"] = {id=20,dataref="laminar/A333/autopilot/altitude_knob_pull"}
btn["VS_DEC"] = {id=21,dataref="sim/autopilot/vertical_speed_down"}
btn["VS_INC"] = {id=22,dataref="sim/autopilot/vertical_speed_up"}
btn["VS_PUSH"] = {id=23,dataref="laminar/A333/autopilot/vertical_knob_push"}
btn["VS_PULL"] = {id=24,dataref="laminar/A333/autopilot/vertical_knob_pull"}
btn["ALT100"] = {id=25,dataref="laminar/A333/autopilot/alt_step_left"}
btn["ALT1000"] = {id=26,dataref="laminar/A333/autopilot/alt_step_right"}
--EFIS L
btn["FD_L"] = {id=32,dataref="sim/autopilot/fdir_command_bars_toggle"}
btn["LS_L"] = {id=33,dataref="laminar/A333/buttons/capt_ils_bars_push"}
btn["CSTR_L"] = {id=34,dataref="laminar/A333/buttons/capt_EFIS_CSTR"}
btn["WPT_L"] = {id=35,dataref="sim/instruments/EFIS_fix"}
btn["VORD_L"] = {id=36,dataref="sim/instruments/EFIS_vor"}
btn["NDB_L"] = {id=37,dataref="sim/instruments/EFIS_ndb"}
btn["ARPT_L"] = {id=38,dataref="sim/instruments/EFIS_apt"}
btn["BARO_PUSH_L"] = {id=39,dataref="laminar/A333/push/baro/capt_std"}
btn["BARO_PULL_L"] = {id=40,dataref="laminar/A333/pull/baro/capt_std"}
btn["BARO_DEC_L"] = {id=41,dataref="sim/instruments/barometer_down"}
btn["BARO_INC_L"] = {id=42,dataref="sim/instruments/barometer_up"}
btn["BARO_HG_L"] = {id=43,dataref="laminar/A333/knob/baro/capt_inHg"}
btn["BARO_HPA_L"] = {id=44,dataref="laminar/A333/knob/baro/capt_hPa"} 
btn["MAP_LS_L"] = {id=45,dataref="alha847/lra333/knob/EFIS_L_map_LS"} 
btn["MAP_VOR_L"] = {id=46,dataref="alha847/lra333/knob/EFIS_L_map_VOR"}
btn["MAP_NAV_L"] = {id=47,dataref="alha847/lra333/knob/EFIS_L_map_NAV"} 
btn["MAP_ARC_L"] = {id=48,dataref="alha847/lra333/knob/EFIS_L_map_ARC"}
btn["MAP_PLAN_L"] = {id=49,dataref="alha847/lra333/knob/EFIS_L_map_PLAN"}
btn["MAP_RANGE10_L"] = {id=50,dataref="alha847/lra333/knob/EFIS_L_map_RANGE10"}
btn["MAP_RANGE20_L"] = {id=51,dataref="alha847/lra333/knob/EFIS_L_map_RANGE20"}
btn["MAP_RANGE40_L"] = {id=52,dataref="alha847/lra333/knob/EFIS_L_map_RANGE40"}
btn["MAP_RANGE80_L"] = {id=53,dataref="alha847/lra333/knob/EFIS_L_map_RANGE80"}
btn["MAP_RANGE160_L"] = {id=54,dataref="alha847/lra333/knob/EFIS_L_map_RANGE160"}
btn["MAP_RANGE320_L"] = {id=55,dataref="alha847/lra333/knob/EFIS_L_map_RANGE320"}
btn["ADF1_L"] = {id=56,dataref="sim/instruments/EFIS_1_pilot_sel_adf"}
btn["OFF1_L"] = {id=57,dataref="sim/instruments/EFIS_1_pilot_sel_off"}
btn["VOR1_L"] = {id=58,dataref="sim/instruments/EFIS_1_pilot_sel_vor"}
btn["ADF2_L"] = {id=59,dataref="sim/instruments/EFIS_2_pilot_sel_adf"}
btn["OFF2_L"] = {id=60,dataref="sim/instruments/EFIS_2_pilot_sel_off"}
btn["VOR2_L"] = {id=61,dataref="sim/instruments/EFIS_2_pilot_sel_vor"}
--EFIS R
btn["FD_R"] = {id=64,dataref="sim/autopilot/fdir2_command_bars_toggle"}
btn["LS_R"] = {id=65,dataref="laminar/A333/buttons/fo_ils_bars_push"}
btn["CSTR_R"] = {id=66,dataref="laminar/A333/buttons/fo_EFIS_CSTR"}
btn["WPT_R"] = {id=67,dataref="sim/instruments/EFIS_copilot_fix"}
btn["VORD_R"] = {id=68,dataref="sim/instruments/EFIS_copilot_vor"}
btn["NDB_R"] = {id=69,dataref="sim/instruments/EFIS_copilot_ndb"}
btn["ARPT_R"] = {id=70,dataref="sim/instruments/EFIS_copilot_apt"}
btn["BARO_PUSH_R"] = {id=71,dataref="laminar/A333/push/baro/fo_std"}
btn["BARO_PULL_R"] = {id=72,dataref="laminar/A333/pull/baro/fo_std"}
btn["BARO_DEC_R"] = {id=73,dataref="sim/instruments/barometer_copilot_down"}
btn["BARO_INC_R"] = {id=74,dataref="sim/instruments/barometer_copilot_up"}
btn["BARO_HG"] = {id=75,dataref="laminar/A333/knob/baro/fo_inHg"} --todo add _R in name
btn["BARO_HPA"] = {id=76,dataref="laminar/A333/knob/baro/fo_hPa"} --todo add _R in name
btn["MAP_LS_R"] = {id=77,dataref="alha847/lra333/knob/EFIS_R_map_LS"} 
btn["MAP_VOR_R"] = {id=78,dataref="alha847/lra333/knob/EFIS_R_map_VOR"}
btn["MAP_NAV_R"] = {id=79,dataref="alha847/lra333/knob/EFIS_R_map_NAV"} 
btn["MAP_ARC_R"] = {id=80,dataref="alha847/lra333/knob/EFIS_R_map_ARC"}
btn["MAP_PLAN_R"] = {id=81,dataref="alha847/lra333/knob/EFIS_R_map_PLAN"}
btn["MAP_RANGE10_R"] = {id=82,dataref="alha847/lra333/knob/EFIS_R_map_RANGE10"}
btn["MAP_RANGE20_R"] = {id=83,dataref="alha847/lra333/knob/EFIS_R_map_RANGE20"}
btn["MAP_RANGE40_R"] = {id=84,dataref="alha847/lra333/knob/EFIS_R_map_RANGE40"}
btn["MAP_RANGE80_R"] = {id=85,dataref="alha847/lra333/knob/EFIS_R_map_RANGE80"}
btn["MAP_RANGE160_R"] = {id=86,dataref="alha847/lra333/knob/EFIS_R_map_RANGE160"}
btn["MAP_RANGE320_R"] = {id=87,dataref="alha847/lra333/knob/EFIS_R_map_RANGE320"}
btn["VOR1_R"] = {id=88,dataref="sim/instruments/EFIS_1_copilot_sel_vor"}
btn["OFF1_R"] = {id=89,dataref="sim/instruments/EFIS_1_copilot_sel_off"}
btn["ADF1_R"] = {id=90,dataref="sim/instruments/EFIS_1_copilot_sel_adf"}
btn["VOR2_R"] = {id=91,dataref="sim/instruments/EFIS_2_copilot_sel_vor"}
btn["OFF2_R"] = {id=92,dataref="sim/instruments/EFIS_2_copilot_sel_off"}
btn["ADF2_R"] = {id=93,dataref="sim/instruments/EFIS_2_copilot_sel_adf"}

--Set EFIS map mode in sim
--cpt_side: 0 = captain, 1 = first officer
--desired_mode: 0 = ls, 1 = vor, 2 = nav, 3 = arc, 4 = plan 
function efis_map_mode_cmd_handler(cpt_side, desired_mode)

    --todo efis knobs need to be added to the startup setting

    local isCapt = (cpt_side == 0)
    local isFo = (cpt_side == 1)

    --Get current EFIS map mode
    --source:A333.switches.lua
    local current_mode
    local command_left
    local command_right
    if(isCapt) then
        current_mode = cache_data["map_mode_l"]
        command_left = "laminar/A333/knobs/capt_EFIS_knob_left"
        command_right = "laminar/A333/knobs/capt_EFIS_knob_right"
    elseif(isFo) then
        current_mode = cache_data["map_mode_r"]
        command_left = "laminar/A333/knobs/fo_EFIS_knob_left"
        command_right = "laminar/A333/knobs/fo_EFIS_knob_right"
    else
        logMsg("efis_map_mode_cmd_handler(): Neither capt nor fo selected...")
    end

    --Determine how often the knob has to be turned and in which direction it has to be turned, then
    --turn the knob in the sim to the desired position.
    --This quite complicated solution is necessary, as the actual dataref controlling the map mode 
    --(e.g. laminar/A333/knobs/EFIS_mode_pos_fo) is readonly and can be accessed by certain commands
    --(e.g. laminar/A333/knobs/fo_EFIS_knob_left) only
    local mode_diff = current_mode - desired_mode
    if(mode_diff > 0) then
        for idx=1,mode_diff do
            command_once(command_left)
        end
    elseif(mode_diff < 0) then
        for idx=1,math.abs(mode_diff) do
            command_once(command_right)
        end
    end
    
end

--Set EFIS map range in sim
--cpt_side: 0 = captain, 1 = first officer
--desired_range: 0 = 10, 1 = 20, 2 = 40, 3 = 80, 4 = 160, 5 = 320 
function efis_map_range_cmd_handler(cpt_side, desired_range)

    --todo efis knobs need to be added to the startup setting

    local isCapt = (cpt_side == 0)
    local isFo = (cpt_side == 1)

    --Get current EFIS map range
    --source:A330_vrconfig.txt
    local current_range
    local command_left
    local command_right
    if(isCapt) then
        current_range = cache_data["map_range_l"]
        command_left = "sim/instruments/map_zoom_in"
        command_right = "sim/instruments/map_zoom_out"
    elseif(isFo) then
        current_range = cache_data["map_range_r"]
        command_left = "sim/instruments/map_copilot_zoom_in"
        command_right = "sim/instruments/map_copilot_zoom_out"
    else
        logMsg("efis_map_range_cmd_handler(): Neither capt nor fo selected...")
    end

    --print(current_range.." - "..desired_range)

    --Determine how often the knob has to be turned and in which direction it has to be turned, then
    --turn the knob in the sim to the desired position.
    --This quite complicated solution is necessary, as the actual dataref controlling the map range
    --(e.g. laminar/A333/knobs/EFIS_mode_pos_fo) is readonly and can be accessed by certain commands
    --(e.g. laminar/A333/knobs/fo_EFIS_knob_left) only
    local range_diff = current_range - desired_range
    if(range_diff > 0) then
        for idx=1,range_diff do
            command_once(command_left)
        end
    elseif(range_diff < 0) then
        for idx=1,math.abs(range_diff) do
            command_once(command_right)
        end
    end
    
end

--Custom commands for the EFIS L map mode knob
create_command("alha847/lra333/knob/EFIS_L_map_LS", "Set EFIS L map mode to LS for LR A333", "efis_map_mode_cmd_handler(0,0)","","")
create_command("alha847/lra333/knob/EFIS_L_map_VOR", "Set EFIS L map mode to VOR for LR A333", "efis_map_mode_cmd_handler(0,1)","","")
create_command("alha847/lra333/knob/EFIS_L_map_NAV", "Set EFIS L map mode to NAV for LR A333", "efis_map_mode_cmd_handler(0,2)","","")
create_command("alha847/lra333/knob/EFIS_L_map_ARC", "Set EFIS L map mode to ARC for LR A333", "efis_map_mode_cmd_handler(0,3)","","")
create_command("alha847/lra333/knob/EFIS_L_map_PLAN", "Set EFIS L map mode to PLAN for LR A333", "efis_map_mode_cmd_handler(0,4)","","")

--Custom commands for the EFIS L map range knob
create_command("alha847/lra333/knob/EFIS_L_map_RANGE10", "Set EFIS L map range to 10 for LR A333", "efis_map_range_cmd_handler(0,0)","","")
create_command("alha847/lra333/knob/EFIS_L_map_RANGE20", "Set EFIS L map range to 20 for LR A333", "efis_map_range_cmd_handler(0,1)","","")
create_command("alha847/lra333/knob/EFIS_L_map_RANGE40", "Set EFIS L map range to 40 or LR A333", "efis_map_range_cmd_handler(0,2)","","")
create_command("alha847/lra333/knob/EFIS_L_map_RANGE80", "Set EFIS L map range to 80 for LR A333", "efis_map_range_cmd_handler(0,3)","","")
create_command("alha847/lra333/knob/EFIS_L_map_RANGE160", "Set EFIS L map range to 160 for LR A333", "efis_map_range_cmd_handler(0,4)","","")
create_command("alha847/lra333/knob/EFIS_L_map_RANGE320", "Set EFIS L map range to 320 for LR A333", "efis_map_range_cmd_handler(0,5)","","")

--Custom commands for the EFIS R map mode knob
create_command("alha847/lra333/knob/EFIS_R_map_LS", "Set EFIS R map mode to LS for LR A333", "efis_map_mode_cmd_handler(1,0)","","")
create_command("alha847/lra333/knob/EFIS_R_map_VOR", "Set EFIS R map mode to VOR for LR A333", "efis_map_mode_cmd_handler(1,1)","","")
create_command("alha847/lra333/knob/EFIS_R_map_NAV", "Set EFIS R map mode to NAV for LR A333", "efis_map_mode_cmd_handler(1,2)","","")
create_command("alha847/lra333/knob/EFIS_R_map_ARC", "Set EFIS R map mode to ARC for LR A333", "efis_map_mode_cmd_handler(1,3)","","")
create_command("alha847/lra333/knob/EFIS_R_map_PLAN", "Set EFIS R map mode to PLAN for LR A333", "efis_map_mode_cmd_handler(1,4)","","")

--Custom commands for the EFIS R map range knob
create_command("alha847/lra333/knob/EFIS_R_map_RANGE10", "Set EFIS R map range to 10 for LR A333", "efis_map_range_cmd_handler(1,0)","","")
create_command("alha847/lra333/knob/EFIS_R_map_RANGE20", "Set EFIS R map range to 20 for LR A333", "efis_map_range_cmd_handler(1,1)","","")
create_command("alha847/lra333/knob/EFIS_R_map_RANGE40", "Set EFIS R map range to 40 or LR A333", "efis_map_range_cmd_handler(1,2)","","")
create_command("alha847/lra333/knob/EFIS_R_map_RANGE80", "Set EFIS R map range to 80 for LR A333", "efis_map_range_cmd_handler(1,3)","","")
create_command("alha847/lra333/knob/EFIS_R_map_RANGE160", "Set EFIS R map range to 160 for LR A333", "efis_map_range_cmd_handler(1,4)","","")
create_command("alha847/lra333/knob/EFIS_R_map_RANGE320", "Set EFIS R map range to 320 for LR A333", "efis_map_range_cmd_handler(1,5)","","")

function assign_button()
    for _, info in pairs(btn) do
        set_button_assignment(info.id+FCU_BUTTON_BEGIN, info.dataref)
    end
end

--register event from xp
--sources: e.g. A333.systems.lua, A333.switches.lua
--FCU
dataref("autopilot_spd", "sim/cockpit2/autopilot/airspeed_dial_kts_mach", "readonly")
dataref("autopilot_spd_is_mach" ,"sim/cockpit/autopilot/airspeed_is_mach", "readonly")
dataref("autopilot_hdg_mag", "sim/cockpit/autopilot/heading_mag", "readonly")
dataref("autopilot_alt", "sim/cockpit/autopilot/altitude", "readonly")
dataref("autopilot_vs", "sim/cockpit/autopilot/vertical_velocity", "readonly")
dataref("autopilot_fpa", "sim/cockpit2/autopilot/fpa", "readonly")
dataref("autopilot_ap1", "sim/cockpit2/autopilot/servos_on", "readonly")
dataref("autopilot_ap2", "sim/cockpit2/autopilot/servos2_on", "readonly")
dataref("autopilot_athr","sim/cockpit2/autopilot/autothrottle_arm", "readonly")
dataref("autopilot_appr", "sim/cockpit2/autopilot/approach_status", "readonly")
dataref("autopilot_loc", "sim/cockpit2/autopilot/nav_status", "readonly")
dataref("autopilot_spd_window","sim/cockpit2/autopilot/vnav_speed_window_open", "readonly")
dataref("autopilot_fpa_window", "laminar/A333/autopilot/vvi_fpa_window_open", "readonly")
dataref("autopilot_hdg_window", "laminar/A333/autopilot/hdg_window_open", "readonly")
dataref("autopilot_trkfpa", "sim/cockpit2/autopilot/trk_fpa", "readonly")
dataref("autopilot_alt_mode","laminar/A333/annun/autopilot/alt_mode", "readonly") --annun means annunciator 
dataref("bus1_volts", "sim/cockpit2/electrical/bus_volts", "readonly", 0)
dataref("bus2_volts", "sim/cockpit2/electrical/bus_volts", "readonly", 1)
--EFIS L
dataref("fd_l", "sim/cockpit2/autopilot/flight_director_mode", "readonly")
dataref("ls_l", "laminar/A333/status/capt_ls_bars", "readonly")
dataref("cstr_l", "sim/cockpit2/EFIS/EFIS_data_on", "readonly")
dataref("wpt_l", "sim/cockpit2/EFIS/EFIS_fix_on", "readonly")
dataref("vord_l", "sim/cockpit2/EFIS/EFIS_vor_on", "readonly")
dataref("ndb_l", "sim/cockpit2/EFIS/EFIS_ndb_on", "readonly")
dataref("arpt_l", "sim/cockpit2/EFIS/EFIS_airport_on", "readonly")
dataref("map_mode_l", "laminar/A333/knobs/EFIS_mode_pos_capt", "readonly")
dataref("map_range_l", "sim/cockpit2/EFIS/map_range", "readonly")
dataref("baro_value_l", "sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot", "readonly") --baro value in inHg
dataref("baro_inhg_l", "laminar/A333/barometer/capt_inHg_hPa_pos", "readonly") --0=inhg, 1=hpa
dataref("baro_mode_l", "laminar/A333/barometer/capt_mode", "readonly") --0=qnh, 1=std
--EFIS R
dataref("fd_r", "sim/cockpit2/autopilot/flight_director2_mode", "readonly")
dataref("ls_r", "laminar/A333/status/fo_ls_bars", "readonly")
dataref("cstr_r", "sim/cockpit2/EFIS/EFIS_data_on_copilot", "readonly")
dataref("wpt_r", "sim/cockpit2/EFIS/EFIS_fix_on_copilot", "readonly")
dataref("vord_r", "sim/cockpit2/EFIS/EFIS_vor_on_copilot", "readonly")
dataref("ndb_r", "sim/cockpit2/EFIS/EFIS_ndb_on_copilot", "readonly")
dataref("arpt_r", "sim/cockpit2/EFIS/EFIS_airport_on_copilot", "readonly")
dataref("map_mode_r", "laminar/A333/knobs/EFIS_mode_pos_fo", "readonly")
dataref("map_range_r", "sim/cockpit2/EFIS/map_range_copilot", "readonly")
dataref("baro_value_r", "sim/cockpit2/gauges/actuators/barometer_setting_in_hg_copilot", "readonly") --baro value in inHg
dataref("baro_inhg_r", "laminar/A333/barometer/fo_inHg_hPa_pos", "readonly") --0=inhg, 1=hpa
dataref("baro_mode_r", "laminar/A333/barometer/fo_mode", "readonly") --0=qnh, 1=std

cache_data={}
--FCU
cache_data["autopilot_spd"] = 0
cache_data["autopilot_spd_is_mach"] = 0
cache_data["autopilot_hdg_mag"] = 0
cache_data["autopilot_alt"] = 0
cache_data["autopilot_vs"] = 0
cache_data["autopilot_fpa"] = 0
cache_data["autopilot_ap1"] = 0
cache_data["autopilot_ap2"] = 0
cache_data["autopilot_athr"] = 0
cache_data["autopilot_appr"] = 0
cache_data["autopilot_loc"] = 0
cache_data["autopilot_spd_window"] = 0
cache_data["autopilot_fpa_window"] = 0
cache_data["autopilot_hdg_window"] = 0
cache_data["autopilot_trkfpa"] = 0
cache_data["autopilot_alt_mode"] = 0 
cache_data["bus1_volts"] = 0
cache_data["bus2_volts"] = 0
--EFIS L
cache_data["fd_l"] = 0
cache_data["ls_l"] = 0
cache_data["cstr_l"] = 0
cache_data["wpt_l"] = 0
cache_data["vord_l"] = 0
cache_data["ndb_l"] = 0
cache_data["arpt_l"] = 0
cache_data["map_mode_l"] = 0
cache_data["map_range_l"] = 0
cache_data["baro_value_l"] = 0
cache_data["baro_inhg_l"] = 0
cache_data["baro_mode_l"] = 0
--EFIS R
cache_data["fd_r"] = 0
cache_data["ls_r"] = 0
cache_data["cstr_r"] = 0
cache_data["wpt_r"] = 0
cache_data["vord_r"] = 0
cache_data["ndb_r"] = 0
cache_data["arpt_r"] = 0
cache_data["map_mode_r"] = 0
cache_data["map_range_r"] = 0
cache_data["baro_value_r"] = 0
cache_data["baro_inhg_r"] = 0
cache_data["baro_mode_r"] = 0

--define led 
--FCU
led_list_fcu = {
    {id = 0,    bind="",                    val = 256}, --led backlight
    {id = 1,    bind="",                    val = 256}, --lcd backlight
    {id = 2,    bind="",                    val = 256}, --green annunciator backlight
    {id = 3,    bind="autopilot_loc",       val = 0},
    {id = 5,    bind="autopilot_ap1",       val = 0},
    {id = 7,    bind="autopilot_ap2",       val = 0},
    {id = 9,    bind="autopilot_athr",      val = 0},
    {id = 11,   bind="autopilot_alt_mode",  val = 0},
    {id = 13,   bind="autopilot_appr",      val = 0},
    {id = 17,   bind="",                    val = 0},
    {id = 30,   bind="",  val = 0},
}
--EFIS L
led_list_efis_l = {
    {id = 0,    bind="",                    val = 256}, --led backlight
    {id = 1,    bind="",                    val = 256}, --lcd backlight
    {id = 2,    bind="",                    val = 256},
    {id = 3,    bind="fd_l",                val = 0},
    {id = 4,    bind="ls_l",                val = 0},
    {id = 5,    bind="cstr_l",              val = 0},
    {id = 6,    bind="wpt_l",               val = 0},
    {id = 7,    bind="vord_l",              val = 0},
    {id = 8,    bind="ndb_l",               val = 0},
    {id = 9,    bind="arpt_l",              val = 0}  
}

--EFIS R
led_list_efis_r = {
    {id = 0,    bind="",                    val = 256}, --led backlight
    {id = 1,    bind="",                    val = 256}, --lcd backlight
    {id = 2,    bind="",                    val = 256},
    {id = 3,    bind="fd_r",                val = 0},
    {id = 4,    bind="ls_r",                val = 0},
    {id = 5,    bind="cstr_r",              val = 0},
    {id = 6,    bind="wpt_r",               val = 0},
    {id = 7,    bind="vord_r",              val = 0},
    {id = 8,    bind="ndb_r",               val = 0},
    {id = 9,    bind="arpt_r",              val = 0}  
}

--define lcd
local lcd_flags_fcu = {}
--FCU
lcd_flags_fcu["spd"] = {byte = 1, mask = 0x08, value = 1}
lcd_flags_fcu["mach"] = {byte = 1, mask = 0x04, value = 0}
lcd_flags_fcu["hdg"] = {byte = 0, mask = 0x80, value = 0}
lcd_flags_fcu["trk"] = {byte = 0, mask = 0x40, value = 0}
lcd_flags_fcu["lat"] = {byte = 0, mask = 0x20, value = 1}
lcd_flags_fcu["vshdg"] = {byte = 7, mask = 0x08, value = 1}
lcd_flags_fcu["vs"] = {byte = 7, mask = 0x04, value = 1}
lcd_flags_fcu["ftrk"] = {byte = 7, mask = 0x02, value = 0}
lcd_flags_fcu["ffpa"] = {byte = 7, mask = 0x01, value = 0}
lcd_flags_fcu["alt"] = {byte = 6, mask = 0x10, value = 1}
lcd_flags_fcu["hdg_managed"] = {byte = 0, mask = 0x10, value = 0}
lcd_flags_fcu["spd_managed"] = {byte = 1, mask = 0x02, value = 0}
lcd_flags_fcu["alt_managed"] = {byte = 11, mask = 0x10, value = 0}
lcd_flags_fcu["vs_horz"] = {byte = 2, mask = 0x10, value = 1}
lcd_flags_fcu["vs_vert"] = {byte = 8, mask = 0x10, value = 0}
lcd_flags_fcu["lvl"] = {byte = 4, mask = 0x10, value = 1}
lcd_flags_fcu["lvl_left"] = {byte = 5, mask = 0x10, value = 1}
lcd_flags_fcu["lvl_right"] = {byte = 3, mask = 0x10, value = 1}
lcd_flags_fcu["fvs"] = {byte = 10, mask = 0x40, value = 1}
lcd_flags_fcu["ffpa2"] = {byte = 10, mask = 0x80, value = 0}
lcd_flags_fcu["fpa_comma"] = {byte = 9, mask = 0x10, value = 0}
lcd_flags_fcu["mach_comma"] = {byte = 12, mask = 0x01, value = 0}
--EFIS R
local lcd_flags_efisl = {}
lcd_flags_efisl["qfe"] = {byte = 0, mask = 0x01, value = 1} --todo check value
lcd_flags_efisl["qnh"] = {byte = 0, mask = 0x02, value = 1} --todo check value
lcd_flags_efisl["unitInHg"] = {byte = 2, mask = 0x80, value = 1}
--EFIS R
local lcd_flags_efisr = {}
lcd_flags_efisr["qfe"] = {byte = 0, mask = 0x01, value = 1} --todo check value
lcd_flags_efisr["qnh"] = {byte = 0, mask = 0x02, value = 1} --todo check value
lcd_flags_efisr["unitInHg"] = {byte = 2, mask = 0x80, value = 1}

function config_led(winwing_hid_dev, led, dev)
    if (led.bind ~= "") then
        local val,_= loadstring("return "..led.bind)
        local flag = val()
        if (flag ~= led.val) then
            logMsg("set led "..led.id.." "..flag)
            if(dev == "fcu") then
                hid_write(winwing_hid_dev, 0, 0x02, 0x10, 0xbb, 0 , 0, 3, 0x49, led.id, flag, 0, 0, 0, 0, 0)
            elseif(dev == "efis_l") then
                hid_write(winwing_hid_dev, 0, 0x02, 0x0d, 0xbf, 0 , 0, 3, 0x49, led.id, flag, 0, 0, 0, 0, 0)
            elseif(dev == "efis_r") then
                hid_write(winwing_hid_dev, 0, 0x02, 0x0e, 0xbf, 0 , 0, 3, 0x49, led.id, flag, 0, 0, 0, 0, 0)
            else
                logMsg("config_led(): Neither fcu, nor efis l or efis r selected.")
            end
            led.val = flag
        end
    end
end

function set_led(winwing_hid_dev)
    --FCU
    for i, led in pairs(led_list_fcu) do
        config_led(winwing_hid_dev, led, "fcu")
    end
    --EFIS L
    for i, led in pairs(led_list_efis_l) do
        config_led(winwing_hid_dev, led, "efis_l")
    end
    --EFIS R
    for i, led in pairs(led_list_efis_r) do
        config_led(winwing_hid_dev, led, "efis_r")
    end
end

--      A
--      ---
--   F | G | B
--      ---
--   E |   | C
--      ---
--       D
-- A=0x80, B=0x40, C=0x20, D=0x10, E=0x02, F=0x08, G=0x04
local lcd_mapping = {}
lcd_mapping['0'] = 0xfa
lcd_mapping['1'] = 0x60
lcd_mapping['2'] = 0xd6
lcd_mapping['3'] = 0xf4
lcd_mapping['4'] = 0x6c
lcd_mapping['5'] = 0xbc
lcd_mapping['6'] = 0xbe
lcd_mapping['7'] = 0xe0
lcd_mapping['8'] = 0xfe
lcd_mapping['9'] = 0xfc
lcd_mapping['A'] = 0xee
lcd_mapping['B'] = 0xfe
lcd_mapping['C'] = 0x9a
lcd_mapping['D'] = 0x76
lcd_mapping['E'] = 0x9e
lcd_mapping['F'] = 0x8e
lcd_mapping['G'] = 0xbe
lcd_mapping['H'] = 0x6e
lcd_mapping['I'] = 0x60
lcd_mapping['J'] = 0x70
lcd_mapping['K'] = 0x0e
lcd_mapping['L'] = 0x1a
lcd_mapping['M'] = 0xa6
lcd_mapping['N'] = 0x26
lcd_mapping['O'] = 0xfa
lcd_mapping['P'] = 0xce
lcd_mapping['Q'] = 0xec
lcd_mapping['R'] = 0x06
lcd_mapping['S'] = 0xbc
lcd_mapping['T'] = 0x1e
lcd_mapping['U'] = 0x7a
lcd_mapping['V'] = 0x32
lcd_mapping['W'] = 0x58
lcd_mapping['X'] = 0x6e
lcd_mapping['Y'] = 0x7c
lcd_mapping['Z'] = 0xd6
lcd_mapping['-'] = 0x04
lcd_mapping['#'] = 0x36
lcd_mapping['/'] = 0x60
lcd_mapping['\\'] = 0xa
lcd_mapping[' ']  = 0x0

function swap_nibble(c)
    local high = math.floor(c/16)
    local low = c%16
    return low * 16 + high
end

function data_from_string(l, input, swap)
    local digit = {}
    local str = string.upper(input)
    for i = 0,l do
        digit[l-1-i] = lcd_mapping[string.sub(str,i+1,i+1)]
    end
    if swap ~= true then
        return digit
    end

    digit[l] = 0

    for i  = 0, l do
        digit[i] = swap_nibble(digit[i])
    end

    for i = 0,l - 1 do
        digit[l-i] = digit[l - i]%16 +  math.floor(digit[l-1-i]/16) * 16
        digit[l-1-i] = digit[l-1-i]%16
    end

    return digit
end

--l = number of segments in the EFIS R LCD display -> 4
--input = value to be written as string, without points, e.g. "2992"
function data_from_string_swapped_efis(l, input) 

    --Ensure correct length of input string
    if(string.len(input) ~= 4) then
        return
    end

    --
    local n = {}
    for i=0,l do
        n[i] = 0
    end

    --Encode string letter by letter so that it can be sent via hid to the LCD.
    --Target encoding is suitable for the FCU LCD.
    local d = data_from_string(l, input) 

    --Convert the encoding for the FCU LCD to the encoding for the  EFIS R LCD, which are 
    --not the same (for an unknown reason). The two-step process with the FCU encoding in
    --between has been copied from one of the repos where this is forked from. Probably
    --it is caused by the order in which the code was implemented.
    for i =0,l-1 do 
        n[i] = bit.bor(n[i], bit.band(d[i],0x08)>0 and 0x01 or 0x0 )
        --todo debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
        n[i] = bit.bor(n[i], bit.band(d[i],0x04)>0 and 0x02 or 0x0 )
        --todo debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
        n[i] = bit.bor(n[i], bit.band(d[i],0x02)>0 and 0x04 or 0x0 )
        --todo debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
        n[i] = bit.bor(n[i], bit.band(d[i],0x10)>0 and 0x08 or 0x0 )
        --todo debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
        n[i] = bit.bor(n[i], bit.band(d[i],0x80)>0 and 0x10 or 0x0 )
        --todo debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
        n[i] = bit.bor(n[i], bit.band(d[i],0x40)>0 and 0x20 or 0x0 )
        --todo debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
        n[i] = bit.bor(n[i], bit.band(d[i],0x20)>0 and 0x40 or 0x0 )
        --todo debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
        n[i] = bit.bor(n[i], bit.band(d[i],0x01)>0 and 0x80 or 0x0 )
    end

    --n contains the string to be written to the EFIS R LCD encoded in a format that 
    --can be sent to the LCD via the hid protocol.
    return n

end

function fix_str_len(input, len)
    if type(input) == "string" then
        return string.format("%"..len.."s", input)
    end
    return string.format('%0'..len.."d", input)
end


function ljust(str, width, fillchar)
    fillchar = fillchar or " "
    local padding = width - #str
    if padding <= 0 then
        return str
    end
    return str .. string.rep(fillchar, padding)
end

function rjust(str, width, fillchar)
    fillchar = fillchar or " "
    local padding = width - #str
    if padding <= 0 then
        return str
    end
    return string.rep(fillchar, padding) .. str
end

function draw_efisl_lcd(fcu, baro_l)

    local b = data_from_string_swapped_efis(4, baro_l)

    local bl = {}
    for _, flag in pairs(lcd_flags_efisl) do
        if bl[flag.byte] == nil then
            bl[flag.byte] = 0
        end
        bl[flag.byte] = bit.bor(bl[flag.byte] ,(flag.mask *flag.value))
    end

    local pkg_nr = 1
    hid_write(fcu, 0, 0xf0, 0x0, pkg_nr, 0x1a, 0x0d, 0xbf, 0x0, 0x0, 0x2, 0x1, 0x0, 0x0, 0xff, 0xff, 0x1d, 0x0, 0x0, 0x09, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                b[3], bit.bor(b[2],bl[2]),
                b[1], b[0], 
                bl[0], 
                0x0e, 0xbf, 0x0, 0x0, 0x3, 0x1, 0x0, 0x0, 0x4c, 0xc, 0x1d, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
                )

end

function draw_efisr_lcd(fcu, baro_r)

    local b = data_from_string_swapped_efis(4, baro_r)

    local bl = {}
    for _, flag in pairs(lcd_flags_efisr) do
        if bl[flag.byte] == nil then
            bl[flag.byte] = 0
        end
        bl[flag.byte] = bit.bor(bl[flag.byte] ,(flag.mask *flag.value))
    end

    local pkg_nr = 1
    hid_write(fcu, 0, 0xf0, 0x0, pkg_nr, 0x1a, 0x0e, 0xbf, 0x0, 0x0, 0x2, 0x1, 0x0, 0x0, 0xff, 0xff, 0x1d, 0x0, 0x0, 0x09, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                b[3], bit.bor(b[2],bl[2]),
                b[1], b[0], 
                bl[0], 
                0x0e, 0xbf, 0x0, 0x0, 0x3, 0x1, 0x0, 0x0, 0x4c, 0xc, 0x1d, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
                )

end

function draw_fcu_lcd(winwing_hid_dev ,spd, hdg, alt, vs)
    local s = data_from_string(3, spd)
    local h = data_from_string(3, hdg, true)
    local a = data_from_string(5, alt, true)
    local v = data_from_string(4, vs, true)


    local bl = {}
    for _, flag in pairs(lcd_flags_fcu) do
        if bl[flag.byte] == nil then
            bl[flag.byte] = 0
        end
        bl[flag.byte] = bit.bor(bl[flag.byte] ,(flag.mask *flag.value))
    end

    local pkg_nr = 1
    hid_write(winwing_hid_dev, 0, 0xf0, 0x0, pkg_nr, 0x31, 0x10, 0xbb, 0x0, 0x0, 0x2, 0x1, 0x0, 0x0, 0xff, 0xff, 0x2, 0x0, 0x0, 0x20, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                bit.bor(s[2],bl[12]), s[1],
                s[0], bit.bor(h[3] , bl[1]),
                h[2], h[1], bit.bor(h[0] , bl[0]),  bit.bor(a[5] , bl[7]),
                bit.bor(a[4] , bl[6]), bit.bor(a[3] , bl[5]), bit.bor(a[2] ,bl[4]), bit.bor(a[1] , bl[3]),
                bit.bor(a[0], v[4] , bl[2]),
                bit.bor(v[3],bl[9]), bit.bor(v[2],bl[8]), bit.bor(v[1],bl[11]), bit.bor(v[0],bl[10]),
                0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)


    hid_write(winwing_hid_dev, 0, 0xf0, 0x0, pkg_nr, 0x11, 0x10, 0xbb, 0x0, 0x0, 0x3, 0x1, 0x0, 0x0, 0xff, 0xff, 0x2, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)
end

function round(x)
    return math.floor(x+0.5)
end

function refresh_dataref()
    
    --Check whether refresh is necessary
    local need_refresh = 0
    for ref, v in pairs(cache_data) do
        local val = loadstring("return "..ref)() 
        if ref == "autopilot_spd" and val < 1 then
            val = (val+0.00005)*1000
        end
        -- could be nagetive dont plus fpa here
        if v ~=  val then
            cache_data[ref] = val 
            need_refresh  = 1
        end 
    end
   
    if need_refresh == 0 then
        return
    end
    
    --todo maybe helps to fix the problem of the continuously spinning knobs
    for i = 800,830 do
        if button(i) and last_button(i) then
            logMsg("still press "..i)
        end
    end

    --FCU--
    local spd_is_mach = cache_data["autopilot_spd_is_mach"]
    local trkfpa = cache_data['autopilot_trkfpa']
    --spd 
    local spd = cache_data["autopilot_spd"]
    --hdg
    local hdg = round(cache_data["autopilot_hdg_mag"])
    --alt 
    local alt = cache_data["autopilot_alt"]
    --vs 
    local vs = cache_data["autopilot_vs"]
    if trkfpa == 1 then
        vs = cache_data["autopilot_fpa"]
    end
    if vs < 0 then
        vs = math.abs(vs)
        lcd_flags_fcu["vs_vert"].value = 0
    else 
        lcd_flags_fcu["vs_vert"].value = 1
    end

    lcd_flags_fcu["fpa_comma"].value = 0
    --signal flags 
    lcd_flags_fcu["spd"].value = 1-spd_is_mach
    lcd_flags_fcu["mach"].value = spd_is_mach
    lcd_flags_fcu["mach_comma"].value = spd_is_mach
    lcd_flags_fcu["hdg"].value = 1-trkfpa 
    lcd_flags_fcu["trk"].value = trkfpa 
    lcd_flags_fcu["fvs"].value = 1-trkfpa
    lcd_flags_fcu["vshdg"].value = 1-trkfpa
    lcd_flags_fcu["vs"].value = 1-trkfpa
    lcd_flags_fcu["ftrk"].value = trkfpa 
    lcd_flags_fcu["ffpa"].value = trkfpa 
    lcd_flags_fcu["ffpa2"].value = trkfpa 
    
    local str_spd = fix_str_len(spd,3)
    local str_hdg = fix_str_len(hdg,3)
    local str_alt = fix_str_len(alt,5)
    local str_vs = fix_str_len(vs,4)
    
    --manage
    lcd_flags_fcu['spd_managed'].value = 0
    lcd_flags_fcu['hdg_managed'].value = 0
    lcd_flags_fcu['alt_managed'].value = 0
    if cache_data["autopilot_spd_window"] == 0 then
        str_spd = "---"
        lcd_flags_fcu['mach_comma'].value = 0
        lcd_flags_fcu['spd_managed'].value = 1
    end
    if cache_data["autopilot_hdg_window"] == 0 then
        str_hdg = "---"
        lcd_flags_fcu['hdg_managed'].value = 1
    end
    if cache_data["autopilot_fpa_window"] == 0 then
        str_vs = "----"
        lcd_flags_fcu["vs_vert"].value  = 0
        -- more complicated should depends on autopilot_status
        lcd_flags_fcu['alt_managed'].value = 1
    elseif trkfpa == 0 then 
        str_vs = rjust(tostring(math.floor(vs/100)), 2, '0')
        str_vs = ljust(str_vs, 4, "#")
        -- this knob is used for vs and pfa
        set_button_assignment(FCU_BUTTON_BEGIN+btn["VS_DEC"].id, "sim/autopilot/vertical_speed_down")
        set_button_assignment(FCU_BUTTON_BEGIN+btn["VS_INC"].id, "sim/autopilot/vertical_speed_up")
        
    else
        vs = (vs+0.05)*10
        str_vs = rjust(tostring(math.floor(vs)), 2, '0')
        str_vs = ljust(str_vs, 4, " ")
        lcd_flags_fcu["fpa_comma"].value = 1
        set_button_assignment(FCU_BUTTON_BEGIN+btn["VS_DEC"].id, "laminar/A333/autopilot/fpa_decrease")
        set_button_assignment(FCU_BUTTON_BEGIN+btn["VS_INC"].id, "laminar/A333/autopilot/fpa_increase")
    end

    --EFIS L--
    --QFE marker
    --always off, it has never been observed in the sim
    lcd_flags_efisl["qfe"].value = 0
    --Baro
    local baro_value_l = cache_data["baro_value_l"] 
    local str_baro_l = ""
    local unitIsInHg_l = (cache_data["baro_inhg_l"] == 0)
    local isQnh_l = (cache_data["baro_mode_l"] == 0)
    if(not isQnh_l) then
        --Case: Std
        lcd_flags_efisl["qnh"].value = 0
        lcd_flags_efisl["unitInHg"].value = 0
        str_baro_l = "STD " 
    elseif(isQnh_l and unitIsInHg_l) then
        --Case: Local baro in inHg
        lcd_flags_efisl["unitInHg"].value = 1
        lcd_flags_efisl["qnh"].value = 1
        str_baro_l = fix_str_len(baro_value_l*100,4) --scales by factor 100 to get rid of the point in e.g. 29.92; --todo there is a small rounding error from 29.82 to 29.84
    elseif(isQnh_l and not unitIsInHg_l) then
        --Case: Local baro in hPa
        lcd_flags_efisl["unitInHg"].value = 0
        lcd_flags_efisl["qnh"].value = 1
        str_baro_l = round(baro_value_l * 33.86389) --convert from inhg to hpa
        str_baro_l = rjust(tostring(str_baro_l),4,'0')
    end

    --EFIS R--
    --QFE marker
    --always off, it has never been observed in the sim
    lcd_flags_efisr["qfe"].value = 0
    --Baro
    local baro_value_r = cache_data["baro_value_r"] 
    local str_baro_r = ""
    local unitIsInHg = (cache_data["baro_inhg_r"] == 0) --todo add_r to name
    local isQnh = (cache_data["baro_mode_r"] == 0) --todo add_r to name
    if(not isQnh) then
        --Case: Std
        lcd_flags_efisr["qnh"].value = 0
        lcd_flags_efisr["unitInHg"].value = 0
        str_baro_r = "STD " 
    elseif(isQnh and unitIsInHg) then
        --Case: Local baro in inHg
        lcd_flags_efisr["unitInHg"].value = 1
        lcd_flags_efisr["qnh"].value = 1
        str_baro_r = fix_str_len(baro_value_r*100,4) --scales by factor 100 to get rid of the point in e.g. 29.92
    elseif(isQnh and not unitIsInHg) then
        --Case: Local baro in hPa
        lcd_flags_efisr["unitInHg"].value = 0
        lcd_flags_efisr["qnh"].value = 1
        str_baro_r = round(baro_value_r * 33.86389) --convert from inhg to hpa
        str_baro_r = rjust(tostring(str_baro_r),4,'0')
    end

    --hid_open
    local winwing_hid_dev = hid_open(0x4098, winwing_device.product_id)
    draw_fcu_lcd(winwing_hid_dev, str_spd, str_hdg, str_alt, str_vs)
    draw_efisl_lcd(winwing_hid_dev, str_baro_l)
    draw_efisr_lcd(winwing_hid_dev, str_baro_r)
    set_led_brightness()
    set_led(winwing_hid_dev)
    hid_close(winwing_hid_dev)
   
end

init_winwing_device()



