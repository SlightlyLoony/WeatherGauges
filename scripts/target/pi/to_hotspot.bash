#!/usr/bin/env bash
set -euo pipefail

  # TODO: is there a way to somehow let the user choose this?
  # set the country code to US, the frequency band to 2.4GHz (most general settings)...
  wpa_cli -i wlan0 set country "US"
  wpa_cli -i wlan0 save_config > /dev/null 2>&1
  iw reg set "US" 2> /dev/null

  # unblock the RF for WiFi...
  if hash rfkill 2> /dev/null; then
    rfkill unblock wifi
  fi

sudo systemctl unmask hostapd

# add to /etc/dhcpcd.conf:
interface wlan0
static ip_address=192.168.0.10/24
denyinterfaces eth0
denyinterfaces wlan0

sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig

# make new /etc/dnsmasq.conf with:
interface=wlan0
  dhcp-range=192.168.0.11,192.168.0.30,255.255.255.0,24h

# make new /etc/hostapd/hostapd.conf
country_code=US   # change for selected country
interface=wlan0
ssid=WeatherGauges  # our SSID
hw_mode=g  # g=2.4GHz, a=5GHz, b=2.4GHz
channel=7
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=WeatherGauges # our password
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP

# add to end of /etc/default/hostapd:
DAEMON_CONF="/etc/hostapd/hostapd.conf"

# how to set the country and enable wifi, taken from raspi-config
#  /usr/share/zoneinfo/iso3166.tab has list of countries, like this:
#  UM	US minor outlying islands
#  US	United States
#  UY	Uruguay
#  UZ	Uzbekistan
#  VA	Vatican City

# sets the country and saves the configuration...
    wpa_cli -i "$IFACE" set country "$COUNTRY"
    wpa_cli -i "$IFACE" save_config > /dev/null 2>&1

# sets the regulatory agent, whatever that is...
    if ! iw reg set "$COUNTRY" 2> /dev/null; then
        ASK_TO_REBOOT=1

# unblocks wifi
    if hash rfkill 2> /dev/null; then
        rfkill unblock wifi


