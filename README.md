# UART
A simple UART core implementation.

This repo contains two simple modules that showcase UART functionality in action.

* uart_btn : A simple module that transmits a message when a button is pressed.
* uart_loopback : A UART loopback that displays each character entered back to the display.

The UART core uses a configurable Baud Rate (change the g_CLKS_PER_BIT generic according to the target frequency) and the 8N1 transmission convension.
The core has been verified to be working on a Digilent Arty A7-35T development board, with an internal clock frequency of 100 MHz and Baud Rate equal to 115.200.
