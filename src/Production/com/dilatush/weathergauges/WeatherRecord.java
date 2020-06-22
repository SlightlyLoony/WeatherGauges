package com.dilatush.weathergauges;

/**
 * Simple immutable class whose instances contain a record of current weather conditions.
 *
 * @author Tom Dilatush  tom@dilatush.com
 */
public class WeatherRecord {

    final public double temperature;          // temperature in degrees Celsius...
    final public double apparentTemperature;  // apparent temperature ("feels like") in degrees Celcius...
    final public double barometricPressure;   // barometric pressure in hectopascals...
    final public double windSpeed;            // wind speed in meters/second...
    final public double windDirection;        // direction wind is coming from in degrees from north [0..360)...
    final public double cloudCover;           // amount of cloud cover as [0..1]...
    final public double relativeHumidity;     // relative humidity as [0..1]...
    final public double solarRadiation;       // solar radiation in watts/square meter...
    final public double precipitation;        // rain equivalent precipitation rate in millimeters/hour...
    final public double visibility;           // visibility in kilometers...
    final public double airQualityIndex;      // air quality as EPA index [0..500]


    public WeatherRecord( final double _temperature, final double _apparentTemperature, final double _barometricPressure, final double _windSpeed,
                          final double _windDirection, final double _cloudCover, final double _relativeHumidity, final double _solarRadiation,
                          final double _precipitation, final double _visibility, final double _airQualityIndex ) {
        temperature = _temperature;
        apparentTemperature = _apparentTemperature;
        barometricPressure = _barometricPressure;
        windSpeed = _windSpeed;
        windDirection = _windDirection;
        cloudCover = _cloudCover;
        relativeHumidity = _relativeHumidity;
        solarRadiation = _solarRadiation;
        precipitation = _precipitation;
        visibility = _visibility;
        airQualityIndex = _airQualityIndex;
    }
}
