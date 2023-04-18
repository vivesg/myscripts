#!/bin/bash
date > /boot/initramfs-`uname -r`.img
reboot