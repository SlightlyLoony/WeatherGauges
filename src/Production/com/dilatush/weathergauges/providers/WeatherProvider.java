package com.dilatush.weathergauges.providers;

import com.dilatush.weathergauges.DailyForecastRecord;
import com.dilatush.weathergauges.DailyWeatherRecord;
import com.dilatush.weathergauges.WeatherRecord;

/**
 * <p>Implemented by classes that provide weather information ("providers") via weather APIs.</p>
 *
 * <p>Providers maintain data on current weather conditions and daily forecasts (the number of days of forecast available is provider-dependent).
 * Providers also maintain historical data by accumulating current weather conditions.  The number of days of historical data avaiable is controlled
 * by a configuration setting.</p>
 *
 * @author Tom Dilatush  tom@dilatush.com
 */
public interface WeatherProvider {


    /**
     * Call this method periodically (by convention, once per minute) to allow the provider to update its data.  The provider uses this method to
     * update its database of historical data, current conditions data, and forecast data.
     */
    void update();


    /**
     * Returns the most recently retrieved record of the current weather conditions, as a record of instantaneous readings.
     *
     * @return the current weather conditions.
     */
    WeatherRecord current();


    /**
     * Returns a daily weather record for a given number of days in the past.  Zero days means today (midnight to present in the current time zone).
     * One day returns yesterday's record, two days returns the day before yesterday's record, and so on.  An attempt to retrieve a record for which
     * the provider does not have data will result in an {@link IllegalArgumentException} being thrown (see {@link #historyDaysAvailable()}).
     *
     * @param days the number of days in the past to retrieve a daily weather record for.
     * @return the daily weather record for the specified day
     */
    DailyWeatherRecord historical( int days );


    /**
     * Returns a daily forecast record for a given number of days in the future.  Zero days returns today's record, one day returns tomorrow's record,
     * two days returns the day after tomorrow's record, and so on.  An attempt to retrieve a record for which the provider does not have data will
     * result in an {@link IllegalArgumentException} being thrown (see {@link #forecastDaysAvailable()}).
     *
     * @param days the number of days in the future to retrieve a daily forecast record for.
     * @return the daily forecast record for the given number of days in the future
     */
    DailyForecastRecord forecast( int days );


    /**
     * Returns the number of days of daily historical weather data that this provider has available.  The returned value will always be zero or a
     * positive value.
     *
     * @return the number of days of daily historical weather data that this provider has available.
     */
    int historyDaysAvailable();


    /**
     * Returns the number of days of daily forecast data that this provider has available.  The returned value will always be zero or a positive
     * value.
     *
     * @return the number of days of daily forecast data that this provider has available.
     */
    int forecastDaysAvailable();
}
