import time
import sys
import rp2
import machine
from machine import UART, Pin, PWM, SPI

@rp2.asm_pio(autopush=True, push_thresh=32, in_shiftdir=rp2.PIO.SHIFT_RIGHT)
def pio_capture():
    in_(pins, 8)
    
def set_divider(val):
    Pin(1, Pin.OUT).value(val & 0x01)
    Pin(3, Pin.OUT).value(val & 0x02)
    Pin(0, Pin.OUT).value(val & 0x04)
    Pin(2, Pin.OUT).value(val & 0x08)
    Pin(5, Pin.OUT).value(val & 0x10)
    Pin(7, Pin.OUT).value(val & 0x20)
    Pin(4, Pin.OUT).value(val & 0x40)
    Pin(6, Pin.OUT).value(val & 0x80)

def run(query=True, stop=True):
    machine.freq(80_000_000)

    for i in range(30):
        Pin(i, Pin.IN, pull=None)

    flash_sel = Pin(17, Pin.IN, Pin.PULL_UP)
    ice_creset_b = machine.Pin(27, machine.Pin.OUT)
    ice_creset_b.value(0)
    
    Pin(1, Pin.IN, pull=None)
    Pin(3, Pin.IN, pull=None)
    Pin(0, Pin.IN, pull=None)
    Pin(2, Pin.IN, pull=None)
    Pin(5, Pin.IN, pull=None)
    Pin(7, Pin.IN, pull=None)
    Pin(4, Pin.IN, pull=None)
    Pin(6, Pin.IN, pull=None)

    ice_done = machine.Pin(26, machine.Pin.IN)
    time.sleep_us(10)
    ice_creset_b.value(1)

    while ice_done.value() == 0:
        print(".", end = "")
        time.sleep(0.001)
    print()

    if query:
        input("Reset? ")

    rst_n = Pin(12, Pin.OUT)
    clk = Pin(24, Pin.OUT)

    clk.off()
    rst_n.on()
    time.sleep(0.001)
    rst_n.off()

    clk.on()
    time.sleep(0.001)
    clk.off()
    time.sleep(0.001)

    for i in range(10):
        clk.off()
        time.sleep(0.001)
        clk.on()
        time.sleep(0.001)

    rst_n.on()
    time.sleep(0.001)
    clk.off()

    if query:
        input("Start? ")

    set_divider(22)
    time.sleep(0.001)
    clk = PWM(Pin(24), freq=40_000_000, duty_u16=32768)

    if not stop:
        return

    if query:
        input("Stop? ")

    del clk
    Pin(12, Pin.IN, pull=Pin.PULL_DOWN)
    Pin(24, Pin.IN, pull=Pin.PULL_DOWN)
