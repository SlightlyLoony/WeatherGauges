package com.dilatush.weathergauges;

import java.time.Instant;

/**
 * Simple immutable class whose instances contain a record of daily weather conditions.
 *
 * @author Tom Dilatush  tom@dilatush.com
 */
public class DailyWeatherRecord {

    public final WeatherRecord hi;
    public final WeatherRecord lo;
    public final double precipitation;   // liquid equivalent precipitation for the day in millimeters...
    public final Instant sunset;
    public final Instant sunrise;


    public DailyWeatherRecord( final WeatherRecord _hi, final WeatherRecord _lo, final double _precipitation,
                               final Instant _sunset, final Instant _sunrise ) {
        hi = _hi;
        lo = _lo;
        precipitation = _precipitation;
        sunset = _sunset;
        sunrise = _sunrise;
    }
}
