#!/bin/env python3

import time
import usb.core
import usb.util

from enum import Enum

class Leds(Enum):
    BACKLIGHT = 0 # 0 .. 255
    SCREEN_BACKLIGHT = 1 # 0 .. 255
    LOC_GREEN = 3 # all on/off
    AP1_GREEN = 5
    AP2_GREEN = 7
    ATHR_GREEN = 9
    EXPED_GREEN = 11
    APPR_GREEN = 13
    FLAG_GREEN = 17 # 0 .. 255
    EXPED_YELLOW = 30 # 0 .. 255

class Lcd(Enum):
    ALL_ON = 2
    ALL_OFF = 6
    HALF_LCD_ON1 = 7
    HALF_LCD_ON2 = 9


def winwing_fcu_set_led(ep, led, brightness):
    data = [0x02, 0x10, 0xbb, 0, 0, 3, 0x49, led.value, brightness, 0,0,0,0,0]
    cmd = bytes(data)
    ep.write(cmd)


def lcd_init(ep):
    data = [0xf0, 0x2, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0] # init packet
    cmd = bytes(data)
    ep.write(cmd)


def lcd_set(ep, cmd):
    pkg_nr = 1
    data = [0xf0, 0x0, pkg_nr, 0x12, 0x10, 0xbb, 0x0, 0x0, 0x4, 0x1, 0x0, 0x0, 0xff, 0xff, 0x0, 0x0, 0x0, 0x1, 0x0, 0x0, 0x0, cmd.value, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0] # first packet, checksum (byte 13-14) set to 0xff, does not make any problems
    cmd = bytes(data)
    ep.write(cmd)

#      A
#      ---
#   F | G | B
#      ---
#   E |   | C
#      ---
#       D

def lcd_set_heading_xxx(ep):
    spd = 0x08
    hdg1 = 0x80
    lat = 0x20

    h2_a = 0x08
    h2_b = 0x04
    h2_c = 0x02
    h2_d = 0x01
    h2_e = 0x20
    h2_f = 0x80
    h2_g = 0x40 # heading g-segment
    h2_dp = 0x10

    h1_a = 0x08
    h1_b = 0x04
    h1_c = 0x02
    h1_d = 0x01
    h1_e = 0x20
    h1_f = 0x80
    h1_g = 0x40

    h0_a = 0x08
    h0_b = 0x04
    h0_c = 0x02
    h0_d = 0x01
    h0_e = 0x20
    h0_f = 0x80
    h0_g = 0x40

    h2 = 0x01
    h1 = 0x00
    h0 = 0x00


    s1_dp = 0x01
    s1_a = 0x80
    s1_b = 0x40
    s1_c = 0x20
    s1_d = 0x10
    s1_e = 0x02
    s1_f = 0x08
    s1_g = 0x04

    s2_dp = 0x01
    s2_a = 0x80
    s2_b = 0x40
    s2_c = 0x20
    s2_d = 0x10
    s2_e = 0x02
    s2_f = 0x08
    s2_g = 0x04

    s0 = 0xfa
    s1 = 0x00
    s2 = 0x00

    pkg_nr = 1
    data = [0xf0, 0x0, pkg_nr, 0x31, 0x10, 0xbb, 0x0, 0x0, 0x2, 0x1, 0x0, 0x0, 0xff, 0xff, 0x2, 0x0, 0x0, 0x20, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, s2, s1, s0, h2 | h2_e | h2_f | h2_g | spd | h2_dp, h1 | h2_a | h2_b | h2_c | h2_d | h1_e | h1_f | h1_g, h0 | h1_a| h1_b | h1_c | h1_d | h0_e | h0_f | h0_g, hdg1 | lat | h0_a | h0_b | h0_c | h0_d, 0xac, 0xbf, 0x1f, 0xb6, 0xbf, 0xbf, 0xaf, 0x7f, 0x63, 0x43, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]
    cmd = bytes(data)
    ep.write(cmd)

    data = [0xf0, 0x0, pkg_nr, 0x11, 0x10, 0xbb, 0x0, 0x0, 0x3, 0x1, 0x0, 0x0, 0xff, 0xff, 0x2, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]
    cmd = bytes(data)
    ep.write(cmd)

def lcd_set_heading_000(ep):
    pkg_nr = 1

    data = [0xf0, 0x0, pkg_nr, 0x31, 0x10, 0xbb, 0x0, 0x0, 0x2, 0x1, 0x0, 0x0, 0xff, 0xff, 0x2, 0x0, 0x0, 0x20, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x60, 0xfa, 0xfa, 0xa9, 0xaf, 0xaf, 0xaf, 0xac, 0xbf, 0x1f, 0xb6, 0xbf, 0xbf, 0xaf, 0x7f, 0x63, 0x43, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]
    cmd = bytes(data)
    ep.write(cmd)

    data = [0xf0, 0x0, pkg_nr, 0x11, 0x10, 0xbb, 0x0, 0x0, 0x3, 0x1, 0x0, 0x0, 0xff, 0xff, 0x2, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]
    cmd = bytes(data)
    ep.write(cmd)

def lcd_set_heading_888(ep):
    spd = 0x08
    h_e = 0x20
    h_f = 0x80
    h_g = 0x40 # heading g-segment
    pkg_nr = 1
    data = [0xf0, 0x0, pkg_nr, 0x31, 0x10, 0xbb, 0x0, 0x0, 0x2, 0x1, 0x0, 0x0, 0xff, 0xff, 0x2, 0x0, 0x0, 0x20, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x60, 0xfa, 0xfa, 0xe9, 0xef, 0xef, 0xaf, 0xac, 0xbf, 0x1f, 0xb6, 0xbf, 0xbf, 0xaf, 0x7f, 0x63, 0x43, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]
    cmd = bytes(data)
    ep.write(cmd)

    data = [0xf0, 0x0, pkg_nr, 0x11, 0x10, 0xbb, 0x0, 0x0, 0x3, 0x1, 0x0, 0x0, 0xff, 0xff, 0x2, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]
    cmd = bytes(data)
    ep.write(cmd)

device = usb.core.find(idVendor=0x4098, idProduct=0xbb10)
if device is None:
    raise RuntimeError('Device not found')
interface = device[0].interfaces()[0]
if device.is_kernel_driver_active(interface.bInterfaceNumber):
    device.detach_kernel_driver(interface.bInterfaceNumber)


endpoints = device[0].interfaces()[0].endpoints()
print(endpoints)
endpoint_out = endpoints[1]
print(endpoint_out)

lcd_init(endpoint_out)

endpoint_in = endpoints[0]
print(endpoint_in)
while True:
    buf_in = [None] * 7
    num_bytes = endpoint_in.read(0x81, 7)
    print(num_bytes)
    winwing_fcu_set_led(endpoint_out, Leds.AP1_GREEN, 1)
    winwing_fcu_set_led(endpoint_out, Leds.AP2_GREEN, 0)
    #lcd_set(endpoint_out, Lcd.ALL_ON)
    lcd_set_heading_xxx(endpoint_out)
    time.sleep(0.5)
    winwing_fcu_set_led(endpoint_out, Leds.AP1_GREEN, 0)
    winwing_fcu_set_led(endpoint_out, Leds.AP2_GREEN, 1)
    #lcd_set(endpoint_out, Lcd.ALL_OFF)
    lcd_set_heading_000(endpoint_out)
    time.sleep(0.5)
