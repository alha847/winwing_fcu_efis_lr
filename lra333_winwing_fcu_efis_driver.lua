--Lua script to sync the buttons, switches, LEDs and LCDs of the Winwing FCU, EFIS L and EFIS R devices with XP12. 
--Designed for the default LR A333 airplane. 
--Tested on a MacBook M1 Pro with macOS 15.4.1, XP12.2.0 beta 4, FlyWithLua NG+ 2.8.12.

--It is automatically detected whether only the FCU or one or both EFIS devices are connected to the computer.
--The devices should be connected before starting XP12. Otherwise, or in the case the USB connection gets lost, 
--please restart this script, instructions see section "Config" below. 

--Many thanks to Github users schenlap and samrq, from which I have forked the basis of this script and learned a lot.  

--alha847, May 2025
--v0.9

----------------------- Config -----------------------

--Settings that can be selected by the user.
--Please reload this script after changing something while the sim is running: XP12 -> Plugins -> FlyWithLua -> Reload all Lua script files

--Default brightness of LED backlight, [0,1,2...255]
LED_BACKLIGHT_DEFAULT = 128

--Default brightness of LCD backlight, [0,1,2,...255]
LCD_BACKLIGHT_DEFAULT = 255

--Default brightness of green annunciator LEDs, [0,1,2...255].
--Two separate values for BRIGHT and DIM, according to the ANN LT switch in the overhead panel.
ANNUN_DEFAULT_BRIGHT = 255
ANNUN_DEFAULT_DIM = 20

--Keep LED and LCD backlights always on, independent from status of electrical busses in the sim, [true/false].
--If false, the backlights will turn on or off depending on battery, generator status, etc.
BACKLIGHT_ALWAYS_ON = false

--Decide whether the annunciator LEDs are synced with the position of the ANN LT switch in the overhead panel, [true/false].
--If false, always only ANNUN_DEFAULT_BRIGHT is used
SYNC_ANNUN_LT_SWITCH = true

----------------------- Constants -----------------------

--Define pseudo-constants
local INV_VAL = -1

----------------------- Datarefs -----------------------

--sources: e.g. A333.systems.lua, A333.switches.lua

--General
dataref("annun_light_switch_pos", "laminar/a333/switches/ann_light_pos", "readonly")
dataref("bus1_volts", "sim/cockpit2/electrical/bus_volts", "readonly", 0)
dataref("bus2_volts", "sim/cockpit2/electrical/bus_volts", "readonly", 1)
--FCU
dataref("autopilot_spd", "sim/cockpit2/autopilot/airspeed_dial_kts_mach", "readonly") --Can contain speed in unit kts or mach, depending on setting in fcu
dataref("autopilot_spd_is_mach" ,"sim/cockpit/autopilot/airspeed_is_mach", "readonly") --1: mach, 0: ias (source: A333.systems.lua)
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
dataref("autopilot_fms_vnav", "sim/cockpit2/autopilot/fms_vnav", "readonly")
dataref("autopilot_hdg_window", "laminar/A333/autopilot/hdg_window_open", "readonly")
dataref("autopilot_trkfpa", "sim/cockpit2/autopilot/trk_fpa", "readonly")
dataref("autopilot_alt_mode","sim/cockpit2/autopilot/altitude_hold_status", "readonly") 
dataref("autopilot_vvi_status", "sim/cockpit2/autopilot/vvi_status", "readonly")
dataref("autopilot_fpa_window", "laminar/A333/autopilot/vvi_fpa_window_open", "readonly")
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
cache_data["autopilot_fms_vnav"] = INV_VAL
cache_data["autopilot_vvi_status"] = INV_VAL
--General
cache_data["bus1_volts"] = 0
cache_data["bus2_volts"] = 0
cache_data["annun_light_switch_pos"] = 0
--EFIS L
cache_data["fd_l"] = 0
cache_data["ls_l"] = 0
cache_data["cstr_l"] = 0
cache_data["wpt_l"] = 0
cache_data["vord_l"] = 0
cache_data["ndb_l"] = 0
cache_data["arpt_l"] = 0
cache_data["map_mode_l"] = INV_VAL
cache_data["map_range_l"] = INV_VAL
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
cache_data["map_mode_r"] = INV_VAL
cache_data["map_range_r"] = INV_VAL
cache_data["baro_value_r"] = 0
cache_data["baro_inhg_r"] = 0
cache_data["baro_mode_r"] = 0

----------------------- Buttons, switches, knobs -----------------------

--FCU
btn_fcu = {}
btn_fcu["MACH"] = {active = false, command="sim/autopilot/knots_mach_toggle", byte = 3, bitval = 0x01, last_active = false}
btn_fcu["LOC"] = {active = false, command="sim/autopilot/NAV", byte = 3, bitval = 0x02, last_active = false}
btn_fcu["TRK"] = {active = false, command="sim/autopilot/trkfpa", byte = 3, bitval = 0x04, last_active = false}
btn_fcu["AP1"] = {active = false, command="sim/autopilot/servos_toggle", byte = 3, bitval = 0x08, last_active = false}
btn_fcu["AP2"] = {active = false, command="sim/autopilot/servos2_toggle", byte = 3, bitval = 0x10, last_active = false}
btn_fcu["A_THR"] = {active = false, command="laminar/A333/autopilot/a_thr_toggle", byte = 3, bitval = 0x20, last_active = false}
btn_fcu["EXPED"] = {active = false, command="sim/autopilot/altitude_hold", byte = 3, bitval = 0x40, last_active = false}
btn_fcu["METRIC"] = {active = false, command="laminar/A333/autopilot/metric_alt_push", byte = 3, bitval = 0x80, last_active = false}
btn_fcu["APPR"] = {active = false, command="sim/autopilot/approach", byte = 4, bitval = 0x01, last_active = false}
btn_fcu["SPD_DEC"] = {active = false, command="sim/autopilot/airspeed_down", byte = 4, bitval = 0x02, last_active = false}
btn_fcu["SPD_INC"] = {active = false, command="sim/autopilot/airspeed_up", byte = 4, bitval = 0x04, last_active = false}
btn_fcu["SPD_PUSH"] = {active = false, command="laminar/A333/autopilot/speed_knob_push", byte = 4, bitval = 0x08, last_active = false}
btn_fcu["SPD_PULL"] = {active = false, command="laminar/A333/autopilot/speed_knob_pull", byte = 4, bitval = 0x10, last_active = false}
btn_fcu["HDG_DEC"] = {active = false, command="sim/autopilot/heading_down", byte = 4, bitval = 0x20, last_active = false}
btn_fcu["HDG_INC"] = {active = false, command="sim/autopilot/heading_up", byte = 4, bitval = 0x40, last_active = false}
btn_fcu["HDG_PUSH"] = {active = false, command="laminar/A333/autopilot/heading_knob_push", byte = 4, bitval = 0x80, last_active = false}
btn_fcu["HDG_PULL"] = {active = false, command="laminar/A333/autopilot/heading_knob_pull", byte = 5, bitval = 0x01, last_active = false}
btn_fcu["ALT_DEC"] = {active = false, command="sim/autopilot/altitude_down", byte = 5, bitval = 0x02, last_active = false}
btn_fcu["ALT_INC"] = {active = false, command="sim/autopilot/altitude_up", byte = 5, bitval = 0x04, last_active = false}
btn_fcu["ALT_PUSH"] = {active = false, command="laminar/A333/autopilot/altitude_knob_push", byte = 5, bitval = 0x08, last_active = false}
btn_fcu["ALT_PULL"] = {active = false, command="laminar/A333/autopilot/altitude_knob_pull", byte = 5, bitval = 0x10, last_active = false}
btn_fcu["VS_DEC"] = {active = false, command="sim/autopilot/vertical_speed_down", byte = 5, bitval = 0x20, last_active = false} --Two commands are assigned to byte 5, bitval 0x20
btn_fcu["FPA_DEC"] = {active = false, command="laminar/A333/autopilot/fpa_decrease", byte = 5, bitval = 0x20, last_active = false}
btn_fcu["VS_INC"] = {active = false, command="sim/autopilot/vertical_speed_up", byte = 5, bitval = 0x40, last_active = false}
btn_fcu["FPA_INC"] = {active = false, command="laminar/A333/autopilot/fpa_increase", byte = 5, bitval = 0x40, last_active = false}
btn_fcu["VS_PUSH"] = {active = false, command="laminar/A333/autopilot/vertical_knob_push", byte = 5, bitval = 0x80, last_active = false}
btn_fcu["VS_PULL"] = {active = false, command="laminar/A333/autopilot/vertical_knob_pull", byte = 6, bitval = 0x01, last_active = false}
btn_fcu["ALT100"] = {active = false, command="laminar/A333/autopilot/alt_step_left", byte = 6, bitval = 0x02, last_active = false}
btn_fcu["ALT1000"] = {active = false, command="laminar/A333/autopilot/alt_step_right", byte = 6, bitval = 0x04, last_active = false}

--EFIS L
btn_l = {}
btn_l["FD_L"] = {active = false, command="sim/autopilot/fdir_command_bars_toggle", byte = 7, bitval = 0x01, last_active = false}
btn_l["LS_L"] = {active = false, command="laminar/A333/buttons/capt_ils_bars_push", byte = 7, bitval = 0x02, last_active = false}
btn_l["CSTR_L"] = {active = false, command="laminar/A333/buttons/capt_EFIS_CSTR", byte = 7, bitval = 0x04, last_active = false}
btn_l["WPT_L"] = {active = false, command="sim/instruments/EFIS_fix", byte = 7, bitval = 0x08, last_active = false}
btn_l["VORD_L"] = {active = false, command="sim/instruments/EFIS_vor", byte = 7, bitval = 0x10, last_active = false}
btn_l["NDB_L"] = {active = false, command="sim/instruments/EFIS_ndb", byte = 7, bitval = 0x20, last_active = false}
btn_l["ARPT_L"] = {active = false, command="sim/instruments/EFIS_apt", byte = 7, bitval = 0x40, last_active = false}
btn_l["BARO_PUSH_L"] = {active = false, command="laminar/A333/push/baro/capt_std", byte = 7, bitval = 0x80, last_active = false}
btn_l["BARO_PULL_L"] = {active = false, command="laminar/A333/pull/baro/capt_std", byte = 8, bitval = 0x01, last_active = false}
btn_l["BARO_DEC_L"] = {active = false, command="sim/instruments/barometer_down", byte = 8, bitval = 0x02, last_active = false}
btn_l["BARO_INC_L"] = {active = false, command="sim/instruments/barometer_up", byte = 8, bitval = 0x04, last_active = false}
btn_l["BARO_HG_L"] = {active = false, command="laminar/A333/knob/baro/capt_inHg", byte = 8, bitval = 0x08, last_active = false}
btn_l["BARO_HPA_L"] = {active = false, command="laminar/A333/knob/baro/capt_hPa", byte = 8, bitval = 0x10, last_active = false} 
btn_l["MAP_LS_L"] = {active = false, command="alha847/lra333/knob/EFIS_L_map_LS", byte = 8, bitval = 0x20, last_active = false} 
btn_l["MAP_VOR_L"] = {active = false, command="alha847/lra333/knob/EFIS_L_map_VOR", byte = 8, bitval = 0x40, last_active = false}
btn_l["MAP_NAV_L"] = {active = false, command="alha847/lra333/knob/EFIS_L_map_NAV", byte = 8, bitval = 0x80, last_active = false} 
btn_l["MAP_ARC_L"] = {active = false, command="alha847/lra333/knob/EFIS_L_map_ARC", byte = 9, bitval = 0x01, last_active = false}
btn_l["MAP_PLAN_L"] = {active = false, command="alha847/lra333/knob/EFIS_L_map_PLAN", byte = 9, bitval = 0x02, last_active = false}
btn_l["MAP_RANGE10_L"] = {active = false, command="alha847/lra333/knob/EFIS_L_map_RANGE10", byte = 9, bitval = 0x04, last_active = false}
btn_l["MAP_RANGE20_L"] = {active = false, command="alha847/lra333/knob/EFIS_L_map_RANGE20", byte = 9, bitval = 0x08, last_active = false}
btn_l["MAP_RANGE40_L"] = {active = false, command="alha847/lra333/knob/EFIS_L_map_RANGE40", byte = 9, bitval = 0x10, last_active = false}
btn_l["MAP_RANGE80_L"] = {active = false, command="alha847/lra333/knob/EFIS_L_map_RANGE80", byte = 9, bitval = 0x20, last_active = false}
btn_l["MAP_RANGE160_L"] = {active = false, command="alha847/lra333/knob/EFIS_L_map_RANGE160", byte = 9, bitval = 0x40, last_active = false}
btn_l["MAP_RANGE320_L"] = {active = false, command="alha847/lra333/knob/EFIS_L_map_RANGE320", byte = 9, bitval = 0x80, last_active = false}
btn_l["ADF1_L"] = {active = false, command="sim/instruments/EFIS_1_pilot_sel_adf", byte = 10, bitval = 0x01, last_active = false}
btn_l["OFF1_L"] = {active = false, command="sim/instruments/EFIS_1_pilot_sel_off", byte = 10, bitval = 0x02, last_active = false}
btn_l["VOR1_L"] = {active = false, command="sim/instruments/EFIS_1_pilot_sel_vor", byte = 10, bitval = 0x04, last_active = false}
btn_l["ADF2_L"] = {active = false, command="sim/instruments/EFIS_2_pilot_sel_adf", byte = 10, bitval = 0x08, last_active = false}
btn_l["OFF2_L"] = {active = false, command="sim/instruments/EFIS_2_pilot_sel_off", byte = 10, bitval = 0x10, last_active = false}
btn_l["VOR2_L"] = {active = false, command="sim/instruments/EFIS_2_pilot_sel_vor", byte = 10, bitval = 0x20, last_active = false}

--EFIS R
btn_r = {}
btn_r["FD_R"] = {active = false, command="sim/autopilot/fdir2_command_bars_toggle", byte = 11, bitval = 0x01, last_active = false} 
btn_r["LS_R"] = {active = false, command="laminar/A333/buttons/fo_ils_bars_push", byte = 11, bitval = 0x02, last_active = false}
btn_r["CSTR_R"] = {active = false, command="laminar/A333/buttons/fo_EFIS_CSTR", byte = 11, bitval = 0x04, last_active = false}
btn_r["WPT_R"] = {active = false, command="sim/instruments/EFIS_copilot_fix", byte = 11, bitval = 0x08, last_active = false}
btn_r["VORD_R"] = {active = false, command="sim/instruments/EFIS_copilot_vor", byte = 11, bitval = 0x10, last_active = false}
btn_r["NDB_R"] = {active = false, command="sim/instruments/EFIS_copilot_ndb", byte = 11, bitval = 0x20, last_active = false}
btn_r["ARPT_R"] = {active = false, command="sim/instruments/EFIS_copilot_apt", byte = 11, bitval = 0x40, last_active = false}
btn_r["BARO_PUSH_R"] = {active = false, command="laminar/A333/push/baro/fo_std", byte = 11, bitval = 0x80, last_active = false}
btn_r["BARO_PULL_R"] = {active = false, command="laminar/A333/pull/baro/fo_std", byte = 12, bitval = 0x01, last_active = false}
btn_r["BARO_DEC_R"] = {active = false, command="sim/instruments/barometer_copilot_down", byte = 12, bitval = 0x02, last_active = false}
btn_r["BARO_INC_R"] = {active = false, command="sim/instruments/barometer_copilot_up", byte = 12, bitval = 0x04, last_active = false}
btn_r["BARO_HG_R"] = {active = false, command="laminar/A333/knob/baro/fo_inHg", byte = 12, bitval = 0x08, last_active = false}
btn_r["BARO_HPA_R"] = {active = false, command="laminar/A333/knob/baro/fo_hPa", byte = 12, bitval = 0x10, last_active = false}
btn_r["MAP_LS_R"] = {active = false, command="alha847/lra333/knob/EFIS_R_map_LS", byte = 12, bitval = 0x20, last_active = false} 
btn_r["MAP_VOR_R"] = {active = false, command="alha847/lra333/knob/EFIS_R_map_VOR", byte = 12, bitval = 0x40, last_active = false}
btn_r["MAP_NAV_R"] = {active = false, command="alha847/lra333/knob/EFIS_R_map_NAV", byte = 12, bitval = 0x80, last_active = false}
btn_r["MAP_ARC_R"] = {active = false, command="alha847/lra333/knob/EFIS_R_map_ARC", byte = 13, bitval = 0x01, last_active = false}
btn_r["MAP_PLAN_R"] = {active = false, command="alha847/lra333/knob/EFIS_R_map_PLAN", byte = 13, bitval = 0x02, last_active = false}
btn_r["MAP_RANGE10_R"] = {active = false, command="alha847/lra333/knob/EFIS_R_map_RANGE10", byte = 13, bitval = 0x04, last_active = false}
btn_r["MAP_RANGE20_R"] = {active = false, command="alha847/lra333/knob/EFIS_R_map_RANGE20", byte = 13, bitval = 0x08, last_active = false}
btn_r["MAP_RANGE40_R"] = {active = false, command="alha847/lra333/knob/EFIS_R_map_RANGE40", byte = 13, bitval = 0x10, last_active = false}
btn_r["MAP_RANGE80_R"] = {active = false, command="alha847/lra333/knob/EFIS_R_map_RANGE80", byte = 13, bitval = 0x20, last_active = false}
btn_r["MAP_RANGE160_R"] = {active = false, command="alha847/lra333/knob/EFIS_R_map_RANGE160", byte = 13, bitval = 0x40, last_active = false}
btn_r["MAP_RANGE320_R"] = {active = false, command="alha847/lra333/knob/EFIS_R_map_RANGE320", byte = 13, bitval = 0x80, last_active = false}
btn_r["VOR1_R"] = {active = false, command="sim/instruments/EFIS_1_copilot_sel_vor", byte = 14, bitval = 0x01, last_active = false}
btn_r["OFF1_R"] = {active = false, command="sim/instruments/EFIS_1_copilot_sel_off", byte = 14, bitval = 0x02, last_active = false}
btn_r["ADF1_R"] = {active = false, command="sim/instruments/EFIS_1_copilot_sel_adf", byte = 14, bitval = 0x04, last_active = false}
btn_r["VOR2_R"] = {active = false, command="sim/instruments/EFIS_2_copilot_sel_vor", byte = 14, bitval = 0x08, last_active = false}
btn_r["OFF2_R"] = {active = false, command="sim/instruments/EFIS_2_copilot_sel_off", byte = 14, bitval = 0x10, last_active = false}
btn_r["ADF2_R"] = {active = false, command="sim/instruments/EFIS_2_copilot_sel_adf", byte = 14, bitval = 0x20, last_active = false}

function config_switches(devName, deviceData)

    --logMsg("devName = "..devName)
    --logMsg("device data byte x = "..deviceData[8])

    --Get buttons configured for the desired device
    local currentButtons = winwing_device[devName].buttons

    --Check if button was updated 
    for btnName,currBtn in pairs(currentButtons) do
        currBtn.active = isBitSet(deviceData[currBtn.byte], currBtn.bitval)
        --debug
        --if(btnName == "MAP_VOR_L") then
        --    debug logMsg("MAP_VOR_L")
        --    logMsg("curr = "..tostring(currBtn.active))
        --    logMsg("last = "..tostring(currBtn.last_active))
        --end
        if(currBtn.active and not currBtn.last_active) then
            command_once(currBtn.command)
            currBtn.last_active = true
        elseif(not currBtn.active and currBtn.last_active) then
            currBtn.last_active = false
        end
    end

end

function sync_switches(deviceData)

    --FCU
    config_switches("FCU", deviceData)
    
    --EFIS L
    if(efisl_avail) then
        config_switches("EFISL", deviceData)
    end

    --EFIS R
    if(efisr_avail) then
        config_switches("EFISR", deviceData)
    end

end

--Set EFIS map mode in sim
--cpt_side: 0 = captain, 1 = first officer
--desired_mode: 0 = ls, 1 = vor, 2 = nav, 3 = arc, 4 = plan 
function efis_map_mode_cmd_handler(cpt_side, desired_mode)

    --debug logMsg("efis_map_mode_cmd_handler started...")
    --debug logMsg("cache map mode l = "..cache_data["map_mode_l"])

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

    --debug logMsg("current_mode = "..current_mode)
    --debug logMsg("desired_mode = "..desired_mode)

    --Just for safety reasons, should actually never be reached
    if(current_mode == INV_VAL) then
        return
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

    --debug print("efis_map_range_cmd_handler started...")

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

    --debug print(current_range.." - "..desired_range)

    --Just for safety reasons, should actually never be reached
    if(current_range == INV_VAL) then
        return
    end

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
    
    --debug print("efis_map_range_cmd_handler executed...")

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

----------------------- LEDs -----------------------

--Define LEDs
--FCU
led_list_fcu = {}
led_list_fcu["LED_BACKLIGHT"] =     {id = 0,    curr_value = LED_BACKLIGHT_DEFAULT,     last_value = 256} --led backlight; [0,255]
led_list_fcu["LCD_BACKLIGHT"] =     {id = 1,    curr_value = LCD_BACKLIGHT_DEFAULT,     last_value = 256} --lcd backlight; [0,255]
led_list_fcu["LOC"] =               {id = 3,    curr_value = 0,                         last_value = 2} --LOC; {0,1}
led_list_fcu["AP1"] =               {id = 5,    curr_value = autopilot_ap1,             last_value = 2} --AP1; {0,1}
led_list_fcu["AP2"] =               {id = 7,    curr_value = autopilot_ap2,             last_value = 2} --AP2; {0,1}
led_list_fcu["ATHR"] =              {id = 9,    curr_value = autopilot_athr,            last_value = 2} --ATHR; {0,1}
led_list_fcu["ALT_HOLD"] =          {id = 11,   curr_value = autopilot_alt_mode,        last_value = 3} --ALT (HOLD); {0,1}; attention: autopilot_alt_mode can have values 0,1,2, so "last_value" needs to be set to 3 to avoid problems
led_list_fcu["APPR"] =              {id = 13,   curr_value = autopilot_appr,            last_value = 2} --APPR; {0,1}
led_list_fcu["ANNUN"] =             {id = 17,   curr_value = ANNUN_DEFAULT_BRIGHT,      last_value = 256} --green annunciator backlight; [0,255]
led_list_fcu["EXPED_BACKLIGHT"] =   {id = 30,   curr_value = LED_BACKLIGHT_DEFAULT,     last_value = 256} --yellow exped button backlight; [0,255]

--EFIS L
led_list_efis_l = {}
led_list_efis_l["LED_BACKLIGHT"] =  {id = 0,    curr_value = LED_BACKLIGHT_DEFAULT,     last_value = 256} --led backlight; [0,255]
led_list_efis_l["LCD_BACKLIGHT"] =  {id = 1,    curr_value = LCD_BACKLIGHT_DEFAULT,     last_value = 256} --lcd backlight; [0,255]
led_list_efis_l["ANNUN"] =          {id = 2,    curr_value = ANNUN_DEFAULT_BRIGHT,      last_value = 256} --green annunciator backlight; [0,255]
led_list_efis_l["FD_L"] =           {id = 3,    curr_value = fd_l,                      last_value = 2} --FD L; {0,1}
led_list_efis_l["LS_L"] =           {id = 4,    curr_value = ls_l,                      last_value = 2} --LS L; {0,1}
led_list_efis_l["CSTR_L"] =         {id = 5,    curr_value = cstr_l,                    last_value = 2} --CSTR L; {0,1}
led_list_efis_l["WPT_L"] =          {id = 6,    curr_value = wpt_l,                     last_value = 2} --WPT L; {0,1}
led_list_efis_l["VORD_L"] =         {id = 7,    curr_value = vord_l,                    last_value = 2} --VORD L; {0,1}
led_list_efis_l["NDB_L"] =          {id = 8,    curr_value = ndb_l,                     last_value = 2} --NDB L; {0,1}
led_list_efis_l["ARPT_L"] =         {id = 9,    curr_value = arpt_l,                    last_value = 2} --ARPT L; {0,1}

--EFIS R
led_list_efis_r = {}
led_list_efis_r["LED_BACKLIGHT"] =  {id = 0,    curr_value = LED_BACKLIGHT_DEFAULT,     last_value = 256} --led backlight; [0,255]
led_list_efis_r["LCD_BACKLIGHT"] =  {id = 1,    curr_value = LCD_BACKLIGHT_DEFAULT,     last_value = 256} --lcd backlight; [0,255]
led_list_efis_r["ANNUN"] =          {id = 2,    curr_value = ANNUN_DEFAULT_BRIGHT,      last_value = 256} --green annunciator backlight; [0,255]
led_list_efis_r["FD_R"] =           {id = 3,    curr_value = fd_r,                      last_value = 2} --FD R; {0,1}
led_list_efis_r["LS_R"] =           {id = 4,    curr_value = ls_r,                      last_value = 2} --LS R; {0,1}
led_list_efis_r["CSTR_R"] =         {id = 5,    curr_value = cstr_r,                    last_value = 2} --CSTR R; {0,1}
led_list_efis_r["WPT_R"] =          {id = 6,    curr_value = wpt_r,                     last_value = 2} --WPT R; {0,1}
led_list_efis_r["VORD_R"] =         {id = 7,    curr_value = vord_r,                    last_value = 2} --VORD R; {0,1}
led_list_efis_r["NDB_R"] =          {id = 8,    curr_value = ndb_r,                     last_value = 2} --NDB R; {0,1}
led_list_efis_r["ARPT_R"] =         {id = 9,    curr_value = arpt_r,                    last_value = 2} --ARPT R; {0,1}

function syncLeds(winwing_hid_dev, devName)

    --debug logMsg("devName = "..devName)

    --Go through all LEDs and set the new values
    for _, led in pairs(winwing_device[devName].leds) do
        config_led(winwing_hid_dev, led, devName)
    end

end

function syncFcuAnnunLeds(winwing_hid_dev)

    --Get current dataref values
    led_list_fcu["LOC"].curr_value = autopilot_loc
    led_list_fcu["AP1"].curr_value = autopilot_ap1
    led_list_fcu["AP2"].curr_value = autopilot_ap2
    led_list_fcu["ATHR"].curr_value = autopilot_athr
    led_list_fcu["ALT_HOLD"].curr_value = autopilot_alt_mode
    led_list_fcu["APPR"].curr_value = autopilot_appr

    --Set new LED values
    syncLeds(winwing_hid_dev, "FCU")

end

function syncEfislAnnunLeds(winwing_hid_dev)

    --Get current dataref values
    led_list_efis_l["FD_L"].curr_value = fd_l
    led_list_efis_l["LS_L"].curr_value = ls_l
    led_list_efis_l["CSTR_L"].curr_value = cstr_l
    led_list_efis_l["WPT_L"].curr_value = wpt_l
    led_list_efis_l["VORD_L"].curr_value = vord_l
    led_list_efis_l["NDB_L"].curr_value = ndb_l
    led_list_efis_l["ARPT_L"].curr_value = arpt_l

    --Set new LED values
    syncLeds(winwing_hid_dev, "EFISL")

end

function syncEfisrAnnunLeds(winwing_hid_dev)

    --Get current dataref values
    led_list_efis_r["FD_R"].curr_value = fd_r
    led_list_efis_r["LS_R"].curr_value = ls_r
    led_list_efis_r["CSTR_R"].curr_value = cstr_r
    led_list_efis_r["WPT_R"].curr_value = wpt_r
    led_list_efis_r["VORD_R"].curr_value = vord_r
    led_list_efis_r["NDB_R"].curr_value = ndb_r
    led_list_efis_r["ARPT_R"].curr_value = arpt_r

    --Set new LED values
    syncLeds(winwing_hid_dev, "EFISR")

end

function config_led(winwing_hid_dev, led, dev)

    --Remarks
    --curr_value can contain two kinds of values, either {0,1} or [0,255], depending on the LED id.
    --attribute "val" stores the current led value to avoid sending the same value to the devices over and over again. 

    if (led.curr_value ~= "") then
        
        --turn on all green annun LEDs at FCU and EFIS when the annun light switch is in position "test",
        --otherwise turn on only the green annun leds according to the FCU and EFIS in the sim
        local curr_value
        if(SYNC_ANNUN_LT_SWITCH and led.id >= 3 and led.id < 16 and annun_light_switch_pos == 2) then
            curr_value = 1
        else
            curr_value = led.curr_value
        end

        --logMsg(curr_value) debug

        --Send command to Winwing devices
        if (curr_value ~= led.last_value) then
            -- debug logMsg("set led "..led.id.." "..curr_value)
            
            if(dev == "FCU") then
                hid_write(winwing_hid_dev, 0, 0x02, 0x10, 0xbb, 0 , 0, 3, 0x49, led.id, curr_value, 0, 0, 0, 0, 0) 
            elseif(dev == "EFISL") then
                hid_write(winwing_hid_dev, 0, 0x02, 0x0d, 0xbf, 0 , 0, 3, 0x49, led.id, curr_value, 0, 0, 0, 0, 0)
            elseif(dev == "EFISR") then
                hid_write(winwing_hid_dev, 0, 0x02, 0x0e, 0xbf, 0 , 0, 3, 0x49, led.id, curr_value, 0, 0, 0, 0, 0)
            else
                logMsg("config_led(): Neither fcu, nor efis l or efis r selected.")
            end
            led.last_value = curr_value
        end

    end
end

function set_led_brightness()

    --information on electric busses from A333.lighting.lua
    local bus1_is_on = BACKLIGHT_ALWAYS_ON or (bus1_volts > 20) --unit volts
    local bus2_is_on = BACKLIGHT_ALWAYS_ON or (bus2_volts > 20)

    --get annunciator light switch status
    --0x0: dim, 0x01: bright, 0x02: test
    local annun_led_brightness = 0
    if(not SYNC_ANNUN_LT_SWITCH) then
        --If annunciator light switch is not synced; position is not important
        annun_led_brightness = ANNUN_DEFAULT_BRIGHT
    elseif(annun_light_switch_pos == 0) then
        --If annunciator light switch is synced and in "dim" position
        annun_led_brightness = ANNUN_DEFAULT_DIM
    elseif(annun_light_switch_pos >= 1) then
        --If annunciator light switch is syned and either in "brt" or "test" position
        annun_led_brightness = ANNUN_DEFAULT_BRIGHT
    end

    --turn LEDs and LCDs on/off depending on status of electric busses
    if(bus1_is_on or bus2_is_on) then
        --FCU
        led_list_fcu["LED_BACKLIGHT"].curr_value = LED_BACKLIGHT_DEFAULT
        led_list_fcu["LCD_BACKLIGHT"].curr_value = 255 --lcd backlight
        led_list_fcu["ANNUN"].curr_value = annun_led_brightness --green annun led brightness. led id = 17, but currently array idx = 9
        led_list_fcu["EXPED_BACKLIGHT"].curr_value = 128 --yellow exped button backlight. led id = 30, but currently array idx = 10
        --EFIS L
        led_list_efis_l["LED_BACKLIGHT"].curr_value = LED_BACKLIGHT_DEFAULT
        led_list_efis_l["LCD_BACKLIGHT"].curr_value = 255
        led_list_efis_l["ANNUN"].curr_value = annun_led_brightness
        --EFIS R
        led_list_efis_r["LED_BACKLIGHT"].curr_value = LED_BACKLIGHT_DEFAULT
        led_list_efis_r["LCD_BACKLIGHT"].curr_value = 255
        led_list_efis_r["ANNUN"].curr_value = annun_led_brightness
    else
        --FCU
        led_list_fcu["LED_BACKLIGHT"].curr_value = 0
        led_list_fcu["LCD_BACKLIGHT"].curr_value = 0
        led_list_fcu["ANNUN"].curr_value = 0
        led_list_fcu["EXPED_BACKLIGHT"].curr_value = 0
        --EFIS L
        led_list_efis_l["LED_BACKLIGHT"].curr_value = 0
        led_list_efis_l["LCD_BACKLIGHT"].curr_value = 0
        led_list_efis_l["ANNUN"].curr_value = 0
        --EFIS R
        led_list_efis_r["LED_BACKLIGHT"].curr_value = 0
        led_list_efis_r["LCD_BACKLIGHT"].curr_value = 0
        led_list_efis_r["ANNUN"].curr_value = 0
    end

end

----------------------- LCDs -----------------------

--Init LCDs.
--Only called once at the beginning, so not important for performance considerations.
function lcd_init()

    --Open connection to USB device
    local winwing_hid_dev = hid_open(0x4098, winwing_device.product_id)
    
    --Write init (?) command to device
    hid_write(winwing_hid_dev, 0, 0xf0, 0x2, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)
    --debug logMsg("init lcd")
    
    --Close connection
    hid_close(winwing_hid_dev)

end

function initLcd()

     --Open connection to USB device
     local winwing_hid_dev = hid_open(0x4098, winwing_device.product_id)
    
     --Sync LCDs of all three devices, otherwise they will show invalid values
     syncFcuLcds(winwing_hid_dev)
     syncEfislLcd(winwing_hid_dev)
     syncEfisrLcd(winwing_hid_dev)
     
     --Close connection
     hid_close(winwing_hid_dev)

end

--define lcd
lcd_flags_fcu = {}
--FCU LCD flags
lcd_flags_fcu["spd"] = {byte = 1, mask = 0x08, value = 1} -- "SPD"
lcd_flags_fcu["mach"] = {byte = 1, mask = 0x04, value = 0} -- "MACH"
lcd_flags_fcu["hdg"] = {byte = 0, mask = 0x80, value = 0} -- "HDG"
lcd_flags_fcu["trk"] = {byte = 0, mask = 0x40, value = 0} -- "TRK"
lcd_flags_fcu["lat"] = {byte = 0, mask = 0x20, value = 1} -- "LAT"
lcd_flags_fcu["vshdg"] = {byte = 7, mask = 0x08, value = 1} -- "HDG" from "HDG V/S" todo clarify ??
lcd_flags_fcu["vs"] = {byte = 7, mask = 0x04, value = 1} -- "VS" from "HDG VS" todo clarify ???
lcd_flags_fcu["ftrk"] = {byte = 7, mask = 0x02, value = 0}  -- "TRK" from "TRK FPA"
lcd_flags_fcu["ffpa"] = {byte = 7, mask = 0x01, value = 0} -- "FPA" from "TRK FPA"
lcd_flags_fcu["alt"] = {byte = 6, mask = 0x10, value = 1} -- "ALT"
lcd_flags_fcu["hdg_managed"] = {byte = 0, mask = 0x10, value = 0} -- HDG managed circle
lcd_flags_fcu["spd_managed"] = {byte = 1, mask = 0x02, value = 0} -- SPD managed circle
lcd_flags_fcu["alt_managed"] = {byte = 11, mask = 0x10, value = 0} -- ALT managed circle
lcd_flags_fcu["vs_horz"] = {byte = 2, mask = 0x10, value = 1} -- Horizontal component of VS + sign
lcd_flags_fcu["vs_vert"] = {byte = 8, mask = 0x10, value = 0} -- Vertical component of VS + sign
lcd_flags_fcu["lvl"] = {byte = 4, mask = 0x10, value = 1} -- "LVL/CH"
lcd_flags_fcu["lvl_left"] = {byte = 5, mask = 0x10, value = 1} -- L shaped line left of "LVL/CH"
lcd_flags_fcu["lvl_right"] = {byte = 3, mask = 0x10, value = 1} -- L shaped line right of "LVL/CH"
lcd_flags_fcu["fvs"] = {byte = 10, mask = 0x40, value = 1} -- "VS"
lcd_flags_fcu["ffpa2"] = {byte = 10, mask = 0x80, value = 0} -- "FPA"
lcd_flags_fcu["fpa_comma"] = {byte = 9, mask = 0x10, value = 0} -- Decimal point for vertical speed in FPA mode
lcd_flags_fcu["mach_comma"] = {byte = 12, mask = 0x01, value = 0} -- Decimal point for speed in mach
--FCU LCD data
lcd_data_fcu = {} 
lcd_data_fcu["spd"] = {val = "---", length = 3}
lcd_data_fcu["hdg"] = {val = "---", length = 3}
lcd_data_fcu["alt"] = {val = "-----", length = 5}
lcd_data_fcu["vs"] = {val = "----", length = 4} --vs or fpa value, e.g. 0100 or 1.7
--EFIS L LCD flags
lcd_flags_efisl = {}
lcd_flags_efisl["qfe"] = {byte = 0, mask = 0x01, value = 1} 
lcd_flags_efisl["qnh"] = {byte = 0, mask = 0x02, value = 1} 
lcd_flags_efisl["unitInHg"] = {byte = 2, mask = 0x80, value = 1}
--EFIS L LCD data
lcd_data_efisl = {}
lcd_data_efisl["baro"] = {val = "----", length = 4} 
--EFIS R LCD flags
lcd_flags_efisr = {}
lcd_flags_efisr["qfe"] = {byte = 0, mask = 0x01, value = 1} 
lcd_flags_efisr["qnh"] = {byte = 0, mask = 0x02, value = 1} 
lcd_flags_efisr["unitInHg"] = {byte = 2, mask = 0x80, value = 1}
--EFIS R LCD data
lcd_data_efisr = {}
lcd_data_efisr["baro"] = {val = "----", length = 4} 

function config_lcd(winwing_hid_dev, lcd_flags, lcd_data, dev)

    --Prepare LCD flags for writing via USB HID
    local bl = {}
    for _, flag in pairs(lcd_flags) do
        if bl[flag.byte] == nil then
            bl[flag.byte] = 0
        end
        bl[flag.byte] = bit.bor(bl[flag.byte] ,(flag.mask *flag.value))
    end

    --Prepare LCD data for writing 
    local pkg_nr = 1
    if(dev == "FCU") then

        local s = data_from_string(lcd_data["spd"].length, lcd_data["spd"].value)
        local h = data_from_string(lcd_data["hdg"].length, lcd_data["hdg"].value, true)
        local a = data_from_string(lcd_data["alt"].length, lcd_data["alt"].value, true)
        local v = data_from_string(lcd_data["vs"].length, lcd_data["vs"].value, true)

        hid_write(winwing_hid_dev, 0, 0xf0, 0x0, pkg_nr, 0x31, 0x10, 0xbb, 0x0, 0x0, 0x2, 0x1, 0x0, 0x0, 0xff, 0xff, 0x2, 0x0, 0x0, 0x20, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                bit.bor(s[2],bl[12]), s[1],
                s[0], bit.bor(h[3] , bl[1]),
                h[2], h[1], bit.bor(h[0] , bl[0]),  bit.bor(a[5] , bl[7]),
                bit.bor(a[4] , bl[6]), bit.bor(a[3] , bl[5]), bit.bor(a[2] ,bl[4]), bit.bor(a[1] , bl[3]),
                bit.bor(a[0], v[4] , bl[2]),
                bit.bor(v[3],bl[9]), bit.bor(v[2],bl[8]), bit.bor(v[1],bl[11]), bit.bor(v[0],bl[10]),
                0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

        hid_write(winwing_hid_dev, 0, 0xf0, 0x0, pkg_nr, 0x11, 0x10, 0xbb, 0x0, 0x0, 0x3, 0x1, 0x0, 0x0, 0xff, 0xff, 0x2, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    elseif(dev == "EFISL") then

        local b = data_from_string_swapped_efis(lcd_data["baro"].length, lcd_data["baro"].value)

        hid_write(winwing_hid_dev, 0, 0xf0, 0x0, pkg_nr, 0x1a, 0x0d, 0xbf, 0x0, 0x0, 0x2, 0x1, 0x0, 0x0, 0xff, 0xff, 0x1d, 0x0, 0x0, 0x09, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                b[3], bit.bor(b[2],bl[2]),
                b[1], b[0], 
                bl[0], 
                0x0e, 0xbf, 0x0, 0x0, 0x3, 0x1, 0x0, 0x0, 0x4c, 0xc, 0x1d, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
                )

    elseif(dev == "EFISR") then

        local b = data_from_string_swapped_efis(lcd_data["baro"].length, lcd_data["baro"].value)

        hid_write(winwing_hid_dev, 0, 0xf0, 0x0, pkg_nr, 0x1a, 0x0e, 0xbf, 0x0, 0x0, 0x2, 0x1, 0x0, 0x0, 0xff, 0xff, 0x1d, 0x0, 0x0, 0x09, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                b[3], bit.bor(b[2],bl[2]),
                b[1], b[0], 
                bl[0], 
                0x0e, 0xbf, 0x0, 0x0, 0x3, 0x1, 0x0, 0x0, 0x4c, 0xc, 0x1d, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
                )

    end

end

function syncFcuLcds(winwining_hid_device)

    --Flags
    lcd_flags_fcu["fpa_comma"].value = 0
    lcd_flags_fcu["spd"].value = 1-autopilot_spd_is_mach
    lcd_flags_fcu["mach"].value = autopilot_spd_is_mach
    lcd_flags_fcu["mach_comma"].value = autopilot_spd_is_mach
    lcd_flags_fcu["hdg"].value = 1-autopilot_trkfpa 
    lcd_flags_fcu["trk"].value = autopilot_trkfpa 
    lcd_flags_fcu["fvs"].value = 1-autopilot_trkfpa
    lcd_flags_fcu["vshdg"].value = 1-autopilot_trkfpa
    lcd_flags_fcu["vs"].value = 1-autopilot_trkfpa
    lcd_flags_fcu["ftrk"].value = autopilot_trkfpa 
    lcd_flags_fcu["ffpa"].value = autopilot_trkfpa 
    lcd_flags_fcu["ffpa2"].value = autopilot_trkfpa 
    
    --Handle speed and heading
    --Selected mode
    local str_spd = ""
    if(autopilot_spd_is_mach == 1) then
        str_spd = fix_str_len(round((autopilot_spd)*1000),3) -- 
    else
        
        str_spd = fix_str_len(round(autopilot_spd) ,3) 
    end
    local str_hdg = fix_str_len(round(autopilot_hdg_mag),3)
    --Managed mode
    lcd_flags_fcu['spd_managed'].value = 0
    lcd_flags_fcu['hdg_managed'].value = 0
    if (autopilot_spd_window == 0) then
        str_spd = "---"
        lcd_flags_fcu['mach_comma'].value = 0
        lcd_flags_fcu['spd_managed'].value = 1
    end
    if (autopilot_hdg_window == 0) then
        str_hdg = "---"
        lcd_flags_fcu['hdg_managed'].value = 1
    end

    --Handle alt and vs. All three variables fms_vnac, vvi_status and fpa_window seems to be
    --necessary to evaluate all possible cases correctly.
    --debug logMsg("autopilot_fms_vnav = "..autopilot_fms_vnav)
    --debug logMsg("autopilot_vvi_status = "..autopilot_vvi_status)
    --debug logMsg("autopilot_fpa_window = "..autopilot_fpa_window)
    local isFpa = (autopilot_trkfpa == 1)
    local vs = autopilot_vs
    if isFpa then
        vs = autopilot_fpa
    end
    if vs < 0 then
        vs = math.abs(vs)
        lcd_flags_fcu["vs_vert"].value = 0
    else 
        lcd_flags_fcu["vs_vert"].value = 1
    end
    local str_alt = fix_str_len(autopilot_alt,5)
    local vs_str_length = 4
    if isFpa then
        vs_str_length = 2
    end
    local str_vs = fix_str_len(vs,vs_str_length)
    if(autopilot_fms_vnav == 0 and autopilot_vvi_status == 0 and autopilot_fpa_window == 1) then
        --alt pull, vs dashed and trkfpa mode
        lcd_flags_fcu['alt_managed'].value = 0
        str_vs = rjust(tostring(round(vs*10)), 2, "0")
        str_vs = ljust(str_vs, 4, " ")
        lcd_flags_fcu["fpa_comma"].value = 1
    elseif(autopilot_fms_vnav == 0 and autopilot_vvi_status == 0 and autopilot_fpa_window == 0) then
        --alt pull, vs dashed and not trkfpa mode
        --debug logMsg("alt pull, vs dashed, not trkfpa")
        lcd_flags_fcu['alt_managed'].value = 0
        str_vs = "----"
        lcd_flags_fcu["vs_vert"].value = 0
    elseif(autopilot_fms_vnav == 0 and autopilot_vvi_status == 2) then
        --alt pull and vs value
        str_vs = rjust(tostring(round(vs/100)), 2, '0')
        str_vs = ljust(str_vs, 4, "#")
        lcd_flags_fcu['alt_managed'].value = 0
    elseif(autopilot_fms_vnav == 1 and autopilot_vvi_status == 0) then
        --alt push and vs dashed
        --debug logMsg("alt push")
        str_vs = "----"
        lcd_flags_fcu['alt_managed'].value = 1
        lcd_flags_fcu["vs_vert"].value = 0
    elseif (autopilot_fms_vnav == 1 and autopilot_vvi_status == 2) then
        --alt push and vs value
        --debug logMsg("alt push")
        str_vs = rjust(tostring(round(vs/100)), 2, '0')
        str_vs = ljust(str_vs, 4, "#")
        lcd_flags_fcu['alt_managed'].value = 1 
    end

    --debug print("str_vs = "..str_vs)

    --Set LCD data
    lcd_data_fcu["spd"].value = str_spd
    lcd_data_fcu["hdg"].value = str_hdg
    lcd_data_fcu["alt"].value = str_alt
    lcd_data_fcu["vs"].value = str_vs

    --Write data to LCD
    config_lcd(winwining_hid_device, winwing_device["FCU"].lcd_flags, winwing_device["FCU"].lcd_data, "FCU")

end

function syncEfislLcd(winwining_hid_device)

    --EFIS L--
    --QFE marker
    --always off, it has never been observed in the sim
    lcd_flags_efisl["qfe"].value = 0
    --Baro
    local str_baro_l = ""
    local unitIsInHg_l = (baro_inhg_l == 0)
    local isQnh_l = (baro_mode_l == 0)
    if(not isQnh_l) then
        --Case: Std
        lcd_flags_efisl["qnh"].value = 0
        lcd_flags_efisl["unitInHg"].value = 0
        str_baro_l = "STD " 
    elseif(isQnh_l and unitIsInHg_l) then
        --Case: Local baro in inHg
        lcd_flags_efisl["unitInHg"].value = 1
        lcd_flags_efisl["qnh"].value = 1
        str_baro_l = fix_str_len(baro_value_l*100,4) --scales by factor 100 to get rid of the point in e.g. 29.92; 
    elseif(isQnh_l and not unitIsInHg_l) then
        --Case: Local baro in hPa
        lcd_flags_efisl["unitInHg"].value = 0
        lcd_flags_efisl["qnh"].value = 1
        str_baro_l = round(baro_value_l * 33.86389) --convert from inhg to hpa
        str_baro_l = rjust(tostring(str_baro_l),4,'0')
    end
    lcd_data_efisl["baro"].value = str_baro_l 

    config_lcd(winwining_hid_device, winwing_device["EFISL"].lcd_flags, winwing_device["EFISL"].lcd_data, "EFISL")

end

function syncEfisrLcd(winwining_hid_device)

    --EFIS R--
    --QFE marker
    --always off, it has never been observed in the sim
    lcd_flags_efisr["qfe"].value = 0
    --Baro
    local str_baro_r = ""
    local unitIsInHg_r = (baro_inhg_r == 0) 
    local isQnh_r = (baro_mode_r == 0)
    if(not isQnh_r) then
        --Case: Std
        lcd_flags_efisr["qnh"].value = 0
        lcd_flags_efisr["unitInHg"].value = 0
        str_baro_r = "STD " 
    elseif(isQnh_r and unitIsInHg_r) then
        --Case: Local baro in inHg
        lcd_flags_efisr["unitInHg"].value = 1
        lcd_flags_efisr["qnh"].value = 1
        str_baro_r = fix_str_len(baro_value_r*100,4) --scales by factor 100 to get rid of the point in e.g. 29.92
    elseif(isQnh_r and not unitIsInHg_r) then
        --Case: Local baro in hPa
        lcd_flags_efisr["unitInHg"].value = 0
        lcd_flags_efisr["qnh"].value = 1
        str_baro_r = round(baro_value_r * 33.86389) --convert from inhg to hpa
        str_baro_r = rjust(tostring(str_baro_r),4,'0')
    end
    lcd_data_efisr["baro"].value = str_baro_r

    config_lcd(winwining_hid_device, winwing_device["EFISR"].lcd_flags, winwing_device["EFISR"].lcd_data, "EFISR")

end


function swap_nibble(c)
    local high = math.floor(c/16)
    local low = c%16
    return low * 16 + high
end

function data_from_string(l, input, swap)

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
        --debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
        n[i] = bit.bor(n[i], bit.band(d[i],0x04)>0 and 0x02 or 0x0 )
        --debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
        n[i] = bit.bor(n[i], bit.band(d[i],0x02)>0 and 0x04 or 0x0 )
        --debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
        n[i] = bit.bor(n[i], bit.band(d[i],0x10)>0 and 0x08 or 0x0 )
        --debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
        n[i] = bit.bor(n[i], bit.band(d[i],0x80)>0 and 0x10 or 0x0 )
        --debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
        n[i] = bit.bor(n[i], bit.band(d[i],0x40)>0 and 0x20 or 0x0 )
        --debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
        n[i] = bit.bor(n[i], bit.band(d[i],0x20)>0 and 0x40 or 0x0 )
        --debug logMsg("n = "..n[0].."-"..n[1].."-"..n[2].."-"..n[3])
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

----------------------- Init -----------------------

winwing_device = {}
fcu_avail = false
efisl_avail = false 
efisr_avail = false

function init_winwing_device()

    logMsg("Running init_winwing_device()...")

    local bit = require("bit")
    local socket = require("socket")

    --0xbb10: fcu only
    --0xbc1e: fcu and efisr
    --0xbc1d: fcu and efisl
    --0xba01: fcu and efisl and efisr
    for i = 1,NUMBER_OF_HID_DEVICES do
        local device = ALL_HID_DEVICES[i]
        --debug print("device id = "..device.product_id)
        if ((device.vendor_id == 0x4098) and (device.product_id == 0xbb10 or device.product_id == 0xbc1e or device.product_id == 0xbc1d or device.product_id == 0xba01) ) then
            winwing_device["FCU"] =     {buttons = btn_fcu,   leds = led_list_fcu,      lcd_data = lcd_data_fcu,    lcd_flags = lcd_flags_fcu   }
            fcu_avail = true
            logMsg("fcu found")
        end
        if ((device.vendor_id == 0x4098) and (device.product_id == 0xbc1e or device.product_id == 0xba01) ) then
            winwing_device["EFISR"] =   {buttons = btn_r,     leds = led_list_efis_r,   lcd_data = lcd_data_efisr,  lcd_flags = lcd_flags_efisr }
            efisr_avail = true
            logMsg("efisr found")
        end
        if ((device.vendor_id == 0x4098) and (device.product_id == 0xbc1d or device.product_id == 0xba01) ) then
            winwing_device["EFISL"] =   {buttons = btn_l,     leds = led_list_efis_l,   lcd_data = lcd_data_efisl,  lcd_flags = lcd_flags_efisl }
            efisl_avail = true
            logMsg("efisl found")
        end 

        --If a Winwing device has been found, assign the product id to the global variable and update the cache of the EFIS devices. There will be 
        --no problem during cache update, if one EFIS is not connected. This step is espectially important to initialize the map mode and map
        --range knobs at the EFIS correctly. 
        if (not isEmpty(winwing_device)) then 
            logMsg("found devices")
            winwing_device["product_id"] = device.product_id
            updateFcuCache()
            updateEfislCache() 
            updateEfisrCache()
            initLcd()
            --clear_all_button_assignments() --todo clear all button assignments to avoid potential duplicates; todo might clear joystick assignments as well
            --lcd_init() --Apparently not needed, thus deactivated
            break
        end

    end

    --stop executing the script if no winwing fcu/efis is found or
    --start refresh function
    if (winwing_device == nil) then
        logMsg("No Winwing device found at all, can't continue.")
        return
    elseif(not fcu_avail) then
        logMsg("No Winwing FCU found, can't continue.")
        return
    else
        do_every_frame("syncDevicesAndSim()")
    end

end

----------------------- Utils -----------------------

function isEmpty(tbl)

    return (next(tbl) == nil)

end

--determines whether in a given byte a certain bit is set.
--both the byte and the "bit" have to be specified as byte,
--i.e. the third bit (from right to left) means bitValue = 0x08,
--the first bit means bitValue = 0x01, etc.
function isBitSet(byteValue, bitValue)

    return (bit.band(byteValue,bitValue) > 0)

end

function round(x)
    return math.floor(x+0.5)
end

--Source: https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console, 2025-04-27
function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

--todo check why reading data sometimes fails due to invalid length if it is done inside of this function
--Remark: Reading data failes (i.e. data_in has wrong length) only in very rare cases, probably nothing
--        to worry about
function readDataFromDevice(winwing_hid_dev)

    local data_in = {hid_read(winwing_hid_dev,42)}

    if(data_in[1] == nil) then
        logMsg("readDataFromDevice(): Can't read from device")
        return
    end

    local n = data_in[1] -- index start from 1.....
    if (n == nil or n ~= 41) then
        logMsg("readDataFromDevice(): invalid input data length... "..n)
        return
    end

    return data_in

end

----------------------- Update -----------------------

function updateGeneralCache()

    local numChanges = 0

    if (cache_data["bus1_volts"] ~= bus1_volts) then cache_data["bus1_volts"] = bus1_volts numChanges = numChanges + 1 end
    if (cache_data["bus2_volts"] ~= bus2_volts) then cache_data["bus2_volts"] = bus2_volts numChanges = numChanges + 1 end
    if (cache_data["annun_light_switch_pos"] ~= annun_light_switch_pos) then cache_data["annun_light_switch_pos"] = annun_light_switch_pos numChanges = numChanges + 1 end

    return (numChanges > 0)

end

function updateFcuCache()

    local numChanges = 0

    if (cache_data["autopilot_spd"] ~= autopilot_spd) then cache_data["autopilot_spd"] = autopilot_spd numChanges = numChanges + 1 end
    if (cache_data["autopilot_spd_is_mach"] ~= autopilot_spd_is_mach) then cache_data["autopilot_spd_is_mach"] = autopilot_spd_is_mach numChanges = numChanges + 1 end
    if (cache_data["autopilot_hdg_mag"] ~= autopilot_hdg_mag) then cache_data["autopilot_hdg_mag"] = autopilot_hdg_mag numChanges = numChanges + 1 end
    if (cache_data["autopilot_alt"] ~= autopilot_alt) then cache_data["autopilot_alt"] = autopilot_alt numChanges = numChanges + 1 end
    if (cache_data["autopilot_vs"] ~= autopilot_vs) then cache_data["autopilot_vs"] = autopilot_vs numChanges = numChanges + 1 end
    if (cache_data["autopilot_fpa"] ~= autopilot_fpa) then cache_data["autopilot_fpa"] = autopilot_fpa numChanges = numChanges + 1 end
    if (cache_data["autopilot_ap1"] ~= autopilot_ap1) then cache_data["autopilot_ap1"] = autopilot_ap1 numChanges = numChanges + 1 end
    if (cache_data["autopilot_ap2"] ~= autopilot_ap2) then cache_data["autopilot_ap2"] = autopilot_ap2 numChanges = numChanges + 1 end
    if (cache_data["autopilot_athr"] ~= autopilot_athr) then  cache_data["autopilot_athr"] = autopilot_athr numChanges = numChanges + 1 end
    if (cache_data["autopilot_appr"] ~= autopilot_appr) then cache_data["autopilot_appr"] = autopilot_appr numChanges = numChanges + 1 end
    if (cache_data["autopilot_loc"] ~= autopilot_loc) then cache_data["autopilot_loc"] = autopilot_loc numChanges = numChanges + 1 end
    if (cache_data["autopilot_spd_window"] ~= autopilot_spd_window) then cache_data["autopilot_spd_window"] = autopilot_spd_window numChanges = numChanges + 1 end
    if (cache_data["autopilot_fpa_window"] ~= autopilot_fpa_window) then cache_data["autopilot_fpa_window"] = autopilot_fpa_window numChanges = numChanges + 1 end
    if (cache_data["autopilot_hdg_window"] ~= autopilot_hdg_window) then cache_data["autopilot_hdg_window"] = autopilot_hdg_window numChanges = numChanges + 1 end
    if (cache_data["autopilot_trkfpa"] ~= autopilot_trkfpa) then cache_data["autopilot_trkfpa"] = autopilot_trkfpa numChanges = numChanges + 1 end
    if (cache_data["autopilot_alt_mode"] ~= autopilot_alt_mode ) then  cache_data["autopilot_alt_mode"] = autopilot_alt_mode  numChanges = numChanges + 1 end
    if (cache_data["autopilot_fms_vnav"] ~= autopilot_fms_vnav ) then  cache_data["autopilot_fms_vnav"] = autopilot_fms_vnav  numChanges = numChanges + 1 end
    if (cache_data["autopilot_vvi_status"] ~= autopilot_vvi_status ) then  cache_data["autopilot_vvi_status"] = autopilot_vvi_status  numChanges = numChanges + 1 end

    return (numChanges > 0)

end

function updateEfislCache()

    local numChanges = 0

    if (cache_data["fd_l"] ~= fd_l) then cache_data["fd_l"] = fd_l numChanges = numChanges + 1 end
    if (cache_data["ls_l"] ~= ls_l) then cache_data["ls_l"] = ls_l numChanges = numChanges + 1 end
    if (cache_data["cstr_l"] ~= cstr_l) then cache_data["cstr_l"] = cstr_l numChanges = numChanges + 1 end
    if (cache_data["wpt_l"] ~= wpt_l) then cache_data["wpt_l"] = wpt_l numChanges = numChanges + 1 end
    if (cache_data["vord_l"] ~= vord_l) then cache_data["vord_l"] = vord_l numChanges = numChanges + 1 end
    if (cache_data["ndb_l"] ~= ndb_l) then cache_data["ndb_l"] = ndb_l numChanges = numChanges + 1 end
    if (cache_data["arpt_l"] ~= arpt_l) then cache_data["arpt_l"] = arpt_l numChanges = numChanges + 1 end
    if (cache_data["map_mode_l"] ~= map_mode_l) then cache_data["map_mode_l"] = map_mode_l numChanges = numChanges + 1 end
    if (cache_data["map_range_l"] ~= map_range_l) then cache_data["map_range_l"] = map_range_l numChanges = numChanges + 1 end
    if (cache_data["baro_value_l"] ~= baro_value_l) then cache_data["baro_value_l"] = baro_value_l numChanges = numChanges + 1 end
    if (cache_data["baro_inhg_l"] ~= baro_inhg_l) then cache_data["baro_inhg_l"] = baro_inhg_l numChanges = numChanges + 1 end
    if (cache_data["baro_mode_l"] ~= baro_mode_l) then cache_data["baro_mode_l"] = baro_mode_l numChanges = numChanges + 1 end

    return (numChanges > 0)

end

function updateEfisrCache()

    local numChanges = 0

    if (cache_data["fd_r"] ~= fd_r) then cache_data["fd_r"] = fd_r numChanges = numChanges + 1 end
    if (cache_data["ls_r"] ~= ls_r) then cache_data["ls_r"] = ls_r numChanges = numChanges + 1 end
    if (cache_data["cstr_r"] ~= cstr_r) then cache_data["cstr_r"] = cstr_r numChanges = numChanges + 1 end
    if (cache_data["wpt_r"] ~= wpt_r) then cache_data["wpt_r"] = wpt_r numChanges = numChanges + 1 end
    if (cache_data["vord_r"] ~= vord_r) then cache_data["vord_r"] = vord_r numChanges = numChanges + 1 end
    if (cache_data["ndb_r"] ~= ndb_r) then cache_data["ndb_r"] = ndb_r numChanges = numChanges + 1 end
    if (cache_data["arpt_r"] ~= arpt_r) then cache_data["arpt_r"] = arpt_r numChanges = numChanges + 1 end
    if (cache_data["map_mode_r"] ~= map_mode_r) then cache_data["map_mode_r"] = map_mode_r numChanges = numChanges + 1 end
    if (cache_data["map_range_r"] ~= map_range_r) then cache_data["map_range_r"] = map_range_r numChanges = numChanges + 1 end
    if (cache_data["baro_value_r"] ~= baro_value_r) then cache_data["baro_value_r"] = baro_value_r numChanges = numChanges + 1 end
    if (cache_data["baro_inhg_r"] ~= baro_inhg_r) then cache_data["baro_inhg_r"] = baro_inhg_r numChanges = numChanges + 1 end
    if (cache_data["baro_mode_r"] ~= baro_mode_r) then cache_data["baro_mode_r"] = baro_mode_r numChanges = numChanges + 1 end

    return (numChanges > 0)

end

function syncDevicesAndSim()

    --Open connection to USB device
    local winwing_hid_dev = hid_open(0x4098, winwing_device.product_id)

    --Read data from USB device
    local currentDeviceData = readDataFromDevice(winwing_hid_dev)

    --Sync positions of switches/buttons/knobs from Winwing devices to XP12.
    --Do this only if the data read from the devices is correct; for an unknown reason
    --it failes for a frame occasionally
    if(currentDeviceData ~= nil and currentDeviceData[1] == 41) then
        sync_switches(currentDeviceData)
    end

    --Sync general parameters from XP12 to Winwing devices
    if(updateGeneralCache()) then

        set_led_brightness()
        syncFcuAnnunLeds(winwing_hid_dev)
        if(efisl_avail) then
            syncEfislAnnunLeds(winwing_hid_dev)
        end
        if(efisr_avail) then
            syncEfisrAnnunLeds(winwing_hid_dev)
        end
        
    end

    --Sync FCU LEDs and LCDs from XP12 to Winwing device
    if(updateFcuCache()) then

        --debug logMsg("Updating FCU...")

        syncFcuAnnunLeds(winwing_hid_dev)
        syncFcuLcds(winwing_hid_dev)
    end


    --Sync EFISL LEDs and LCD from XP12 to device
    if(efisl_avail and updateEfislCache()) then

        --debug logMsg("Updating EFIS L...")

        syncEfislAnnunLeds(winwing_hid_dev)
        syncEfislLcd(winwing_hid_dev)

    end

    --Sync EFISR LEDs and LCD from XP12 to device
    if(efisr_avail and updateEfisrCache()) then

        --debug logMsg("Updating EFIS R...")

        syncEfisrAnnunLeds(winwing_hid_dev)
        syncEfisrLcd(winwing_hid_dev)

    end
    
    --Close connection
    hid_close(winwing_hid_dev)
   
end

----------------------- Main -----------------------

init_winwing_device()

