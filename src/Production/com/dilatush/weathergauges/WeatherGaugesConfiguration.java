package com.dilatush.weathergauges;

import com.dilatush.util.Config;

import java.net.Inet4Address;
import java.net.Inet6Address;
import java.util.Map;
import java.util.TimeZone;

/**
 * @author Tom Dilatush  tom@dilatush.com
 */
public class WeatherGaugesConfiguration {

    public final String              fileFormatVersion;
    public final boolean             provisioned;
    public final String              MAC;
    public final Inet4Address        IPv4Address;
    public final Inet4Address        IPv4NetworkMask;
    public final Inet6Address        IPv6Address;
    public final int                 IPv6PrefixLength;
    public final boolean             shareData;
    public final int                 pollIntervalSeconds;
    public final double              latitude;
    public final double              longitude;
    public final int                 maxHistoryDays;
    public final UnitsType           units;
    public final TimeZone            timeZone;
    public final int                 webServerPort;
    public final Map<String, String> keys;


    public static WeatherGaugesConfiguration fromJSONConfig( final Config _config ) {

        return null;
    }


    private WeatherGaugesConfiguration( final String _fileFormatVersion, final boolean _provisioned, final String _MAC,
                                        final Inet4Address _IPv4Address, final Inet4Address _IPv4NetworkMask, final Inet6Address _IPv6Address,
                                        final int _IPv6PrefixLength, final boolean _shareData, final int _pollIntervalSeconds, final double _latitude,
                                        final double _longitude, final int _maxHistoryDays, final UnitsType _units, final TimeZone _timeZone,
                                        final int _webServerPort, final Map<String, String> _keys ) {

        fileFormatVersion = _fileFormatVersion;
        provisioned = _provisioned;
        MAC = _MAC;
        IPv4Address = _IPv4Address;
        IPv4NetworkMask = _IPv4NetworkMask;
        IPv6Address = _IPv6Address;
        IPv6PrefixLength = _IPv6PrefixLength;
        shareData = _shareData;
        pollIntervalSeconds = _pollIntervalSeconds;
        latitude = _latitude;
        longitude = _longitude;
        maxHistoryDays = _maxHistoryDays;
        units = _units;
        timeZone = _timeZone;
        webServerPort = _webServerPort;
        keys = _keys;
    }
}
