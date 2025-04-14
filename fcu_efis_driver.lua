local bit = require("bit")
local socket = require("socket")
function init_fcu_efis_r()
    for i = 1,NUMBER_OF_HID_DEVICES do
        local device = ALL_HID_DEVICES[i]
        if ((device.vendor_id == 0x4098) and (device.product_id == 0xba01) )
        then
            logMsg("found fcu and efis r device "..device.product_string)
            assign_button()
            lcd_init()
            break
        end
    end

end

function lcd_init()
    local fcu_efis_r = hid_open(0x4098, 0xba01)
    hid_write(fcu_efis_r, 0, 0xf0, 0x2, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)
    logMsg("init lcd")
    hid_close(fcu_efis_r)
end

--TODO: still working on it to load this button id begin from config automatic  button IDs might change across different machines
--you can find the button id in X-Plane 12/Output/preferences/control profiles/{your device profile}.prf
--AH, 2025-04-09, lower case "id" is equal to definition in SimApp Pro minus one
FCU_BUTTON_BEGIN = 480 -- fcu + efisr: 640; efisl + fcu + efisr: 480
local btn = {}
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
--EFIS_R buttons
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
btn["BARO_HG"] = {id=75,dataref="laminar/A333/knob/baro/fo_inHg"}
btn["BARO_HPA"] = {id=76,dataref="laminar/A333/knob/baro/fo_hPa"} 
btn["VOR1_R"] = {id=88,dataref="sim/instruments/EFIS_1_copilot_sel_vor"}
btn["OFF1_R"] = {id=89,dataref="sim/instruments/EFIS_1_copilot_sel_off"}
btn["ADF1_R"] = {id=90,dataref="sim/instruments/EFIS_1_copilot_sel_adf"}
btn["VOR2_R"] = {id=91,dataref="sim/instruments/EFIS_2_copilot_sel_vor"}
btn["OFF2_R"] = {id=92,dataref="sim/instruments/EFIS_2_copilot_sel_off"}
btn["ADF2_R"] = {id=93,dataref="sim/instruments/EFIS_2_copilot_sel_adf"}
--todo missing efis mode and efis range selector

--todo needed
function switch_zero_one(currVar)
    if(currVar == 0) then 
        currVar = 1
    else
        currVar = 0
    end
end

cstr_r_led = 0;

function assign_button()
    for _, info in pairs(btn) do
        set_button_assignment(info.id+FCU_BUTTON_BEGIN, info.dataref)
    end
end


--register event from xp
--AH,2025-04-40, LR A333 uses custom datarefs for the buttons, they can't be used to read data. Check "A333.switches.lua"
--               to see what datarefs the buttons acqually change
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
dataref("fd_r", "sim/cockpit2/autopilot/flight_director2_mode", "readonly")
dataref("ls_r", "laminar/A333/status/fo_ls_bars", "readonly")
dataref("cstr_r", "sim/cockpit2/EFIS/EFIS_data_on_copilot", "readonly")
dataref("wpt_r", "sim/cockpit2/EFIS/EFIS_fix_on_copilot", "readonly")
dataref("vord_r", "sim/cockpit2/EFIS/EFIS_vor_on_copilot", "readonly")
dataref("ndb_r", "sim/cockpit2/EFIS/EFIS_ndb_on_copilot", "readonly")
dataref("arpt_r", "sim/cockpit2/EFIS/EFIS_airport_on_copilot", "readonly")

local cache_data={}
--fcu
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
--efis_r
cache_data["fd_r"] = 0
cache_data["ls_r"] = 0
cache_data["cstr_r"] = 0
cache_data["wpt_r"] = 0
cache_data["vord_r"] = 0
cache_data["ndb_r"] = 0
cache_data["arpt_r"] = 0
--todo probably incomplete, e.g. baro unit missing

--define led 
--AH, 2025-04-09, source:https://github.com/schenlap/winwing_fcu/blob/main/winwing_fcu.py
--AH, 2025-04-09, bind="128" is permitted, "val" is a validity flag, not a variable for the value: If 
--                "bind" is equal to "val", the value in "bind" will not be written, otherwise it will
led_list_fcu = {
    {id = 0,    bind="",                    val = 0}, --led backlight
    {id = 1,    bind="",                    val = 0}, --lcd backlight
    {id = 3,    bind="autopilot_loc",       val = 0},
    {id = 5,    bind="autopilot_ap1",       val = 0},
    {id = 7,    bind="autopilot_ap2",       val = 0},
    {id = 9,    bind="autopilot_athr",      val = 0},
    {id = 11,   bind="autopilot_alt_mode",  val = 0},
    {id = 13,   bind="autopilot_appr",      val = 0},
    {id = 17,   bind="",                    val = 0},
    {id = 30,   bind="",                    val = 0}
}
led_list_efis_r = {
    {id = 0,    bind="",                    val = 0}, --led backlight
    {id = 1,    bind="",                    val = 0}, --lcd backlight
    {id = 3,    bind="fd_r",                val = 0},
    {id = 4,    bind="ls_r",                val = 0},
    {id = 5,    bind="cstr_r",              val = 0},
    {id = 6,    bind="wpt_r",               val = 0},
    {id = 7,    bind="vord_r",              val = 0},
    {id = 8,    bind="ndb_r",               val = 0},
    {id = 9,    bind="arpt_r",              val = 0}  
}

    --EFISR_LS_GREEN = 104


--define lcd
local lcd_flags = {}
lcd_flags["spd"] = {byte = 1, mask = 0x08, value = 1}
lcd_flags["mach"] = {byte = 1, mask = 0x04, value = 0}
lcd_flags["hdg"] = {byte = 0, mask = 0x80, value = 0}
lcd_flags["trk"] = {byte = 0, mask = 0x40, value = 0}
lcd_flags["lat"] = {byte = 0, mask = 0x20, value = 1}
lcd_flags["vshdg"] = {byte = 7, mask = 0x08, value = 1}
lcd_flags["vs"] = {byte = 7, mask = 0x04, value = 1}
lcd_flags["ftrk"] = {byte = 7, mask = 0x02, value = 0}
lcd_flags["ffpa"] = {byte = 7, mask = 0x01, value = 0}
lcd_flags["alt"] = {byte = 6, mask = 0x10, value = 1}
lcd_flags["hdg_managed"] = {byte = 0, mask = 0x10, value = 0}
lcd_flags["spd_managed"] = {byte = 1, mask = 0x02, value = 0}
lcd_flags["alt_managed"] = {byte = 11, mask = 0x10, value = 0}
lcd_flags["vs_horz"] = {byte = 2, mask = 0x10, value = 1}
lcd_flags["vs_vert"] = {byte = 8, mask = 0x10, value = 0}
lcd_flags["lvl"] = {byte = 4, mask = 0x10, value = 1}
lcd_flags["lvl_left"] = {byte = 5, mask = 0x10, value = 1}
lcd_flags["lvl_right"] = {byte = 3, mask = 0x10, value = 1}
lcd_flags["fvs"] = {byte = 10, mask = 0x40, value = 1}
lcd_flags["ffpa2"] = {byte = 10, mask = 0x80, value = 0}
lcd_flags["fpa_comma"] = {byte = 9, mask = 0x10, value = 0}
lcd_flags["mach_comma"] = {byte = 12, mask = 0x01, value = 0}



function config_led(hiddev, led, dev)
    if (led.bind ~= "") then
        local val,_= loadstring("return "..led.bind)
        local flag = val()
        if (flag ~= led.val) then
            logMsg("set led "..led.id.." "..flag)
            --todo the following line needs to be changed for fcu, efisl, efisr
            if(dev == "fcu") then
                hid_write(hiddev, 0, 0x02, 0x10, 0xbb, 0 , 0, 3, 0x49, led.id, flag, 0, 0, 0, 0, 0)
            elseif(dev == "efis_r") then
                hid_write(hiddev, 0, 0x02, 0x0e, 0xbf, 0 , 0, 3, 0x49, led.id, flag, 0, 0, 0, 0, 0)
            end
            led.val = flag
        end
    end
end


function set_led(fcu)
    --todo add efis_l
    for i, led in pairs(led_list_fcu) do
        config_led(fcu, led, "fcu")
    end
    for i, led in pairs(led_list_efis_r) do
        config_led(fcu, led, "efis_r")
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

function draw_lcd(fcu ,spd, hdg, alt, vs)
    local s = data_from_string(3, spd)
    local h = data_from_string(3, hdg, true)
    local a = data_from_string(5, alt, true)
    local v = data_from_string(4, vs, true)


    local bl = {}
    for _, flag in pairs(lcd_flags) do
        if bl[flag.byte] == nil then
            bl[flag.byte] = 0
        end
        bl[flag.byte] = bit.bor(bl[flag.byte] ,(flag.mask *flag.value))
    end

    local pkg_nr = 1
    hid_write(fcu, 0, 0xf0, 0x0, pkg_nr, 0x31, 0x10, 0xbb, 0x0, 0x0, 0x2, 0x1, 0x0, 0x0, 0xff, 0xff, 0x2, 0x0, 0x0, 0x20, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                bit.bor(s[2],bl[12]), s[1],
                s[0], bit.bor(h[3] , bl[1]),
                h[2], h[1], bit.bor(h[0] , bl[0]),  bit.bor(a[5] , bl[7]),
                bit.bor(a[4] , bl[6]), bit.bor(a[3] , bl[5]), bit.bor(a[2] ,bl[4]), bit.bor(a[1] , bl[3]),
                bit.bor(a[0], v[4] , bl[2]),
                bit.bor(v[3],bl[9]), bit.bor(v[2],bl[8]), bit.bor(v[1],bl[11]), bit.bor(v[0],bl[10]),
                0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)


    hid_write(fcu, 0, 0xf0, 0x0, pkg_nr, 0x11, 0x10, 0xbb, 0x0, 0x0, 0x3, 0x1, 0x0, 0x0, 0xff, 0xff, 0x2, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)
end

exped_led_state = 0

function round(x)
    return math.floor(x+0.5)
end

function refresh_dataref()
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
    
    for i = 800,830 do
        if button(i) and last_button(i) then
            logMsg("still press "..i)
        end
    end

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
        lcd_flags["vs_vert"].value = 0
    else 
        lcd_flags["vs_vert"].value = 1
    end

    lcd_flags["fpa_comma"].value = 0
    --signal flags 
    lcd_flags["spd"].value = 1-spd_is_mach
    lcd_flags["mach"].value = spd_is_mach
    lcd_flags["mach_comma"].value = spd_is_mach
    lcd_flags["hdg"].value = 1-trkfpa 
    lcd_flags["trk"].value = trkfpa 
    lcd_flags["fvs"].value = 1-trkfpa
    lcd_flags["vshdg"].value = 1-trkfpa
    lcd_flags["vs"].value = 1-trkfpa
    lcd_flags["ftrk"].value = trkfpa 
    lcd_flags["ffpa"].value = trkfpa 
    lcd_flags["ffpa2"].value = trkfpa 
    
    local str_spd = fix_str_len(spd,3)
    local str_hdg = fix_str_len(hdg,3)
    local str_alt = fix_str_len(alt,5)
    local str_vs = fix_str_len(vs,4)
    
    --manage
    lcd_flags['spd_managed'].value = 0
    lcd_flags['hdg_managed'].value = 0
    lcd_flags['alt_managed'].value = 0
    if cache_data["autopilot_spd_window"] == 0 then
        str_spd = "---"
        lcd_flags['mach_comma'].value = 0
        lcd_flags['spd_managed'].value = 1
    end
    if cache_data["autopilot_hdg_window"] == 0 then
        str_hdg = "---"
        lcd_flags['hdg_managed'].value = 1
    end
    if cache_data["autopilot_fpa_window"] == 0 then
        str_vs = "----"
        lcd_flags["vs_vert"].value  = 0
        -- more complicated should depends on autopilot_status
        lcd_flags['alt_managed'].value = 1
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
        lcd_flags["fpa_comma"].value = 1
        set_button_assignment(FCU_BUTTON_BEGIN+btn["VS_DEC"].id, "laminar/A333/autopilot/fpa_decrease")
        set_button_assignment(FCU_BUTTON_BEGIN+btn["VS_INC"].id, "laminar/A333/autopilot/fpa_increase")
    end
    --hid_open
    local fcu = hid_open(0x4098, 0xba01)
    draw_lcd(fcu, str_spd, str_hdg, str_alt, str_vs)
    set_led(fcu)
    hid_close(fcu)
   
end

init_fcu_efis_r()

do_every_frame("refresh_dataref()")

