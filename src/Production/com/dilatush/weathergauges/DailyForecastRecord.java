package com.dilatush.weathergauges;

import java.time.Instant;

/**
 * Simple immutable class whose instances contain a record of historical weather conditions.
 *
 * @author Tom Dilatush  tom@dilatush.com
 */
public class DailyForecastRecord {

    public final WeatherRecord hi;
    public final WeatherRecord lo;
    public final double                   precipitationProbability;
    public final Instant                  sunset;
    public final Instant                  sunrise;


    public DailyForecastRecord( final WeatherRecord _hi, final WeatherRecord _lo, final double _precipitationProbability,
                                final Instant _sunset, final Instant _sunrise ) {
        hi = _hi;
        lo = _lo;
        precipitationProbability = _precipitationProbability;
        sunset = _sunset;
        sunrise = _sunrise;
    }
}
