package com.dilatush.weathergauges.jetty.handlers;

import com.dilatush.util.PersistentJSONObject;
import com.dilatush.weathergauges.WeatherGauges;
import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.server.handler.AbstractHandler;
import org.json.JSONObject;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.IOException;
import java.util.logging.Logger;

/**
 * Implements a Jetty handler that keeps statistics (hits) for various pages in the system.  These stats are persisted once a minute to a JSON file,
 * so that if the server is restarted only a few stats (up to a minute's worth) are lost.  Note that this handler, by design, <i>never</i> actually
 * handles a request - they're just noted and passed through.
 *
 * @author Tom Dilatush  tom@dilatush.com
 */
public class StatsHandler extends AbstractHandler implements Handler {

    final static private Logger LOGGER = Logger.getLogger( new Object(){}.getClass().getEnclosingClass().getCanonicalName() );
    final static private String STATS_FILE_NAME = "stats.json";

    final private WeatherGauges weatherGauges;

    private PersistentJSONObject stats;
    private Dumper dumper;


    public StatsHandler( final WeatherGauges _weatherGauges ) {
        weatherGauges = _weatherGauges;

        // if we have a stats file, load it; otherwise create an empty one...
        File statsFile = new File( STATS_FILE_NAME );
        if( statsFile.exists() )
            stats = PersistentJSONObject.load( statsFile );
        else
            stats = PersistentJSONObject.create( "{}", statsFile );

        // start up our thread that persists this thing every 60 seconds...
        dumper = new Dumper();
    }


    @Override
    synchronized public void handle( final String _s, final Request _request, final HttpServletRequest _httpServletRequest,
                                     final HttpServletResponse _httpServletResponse ) throws IOException, ServletException {

        // get our request...
        String request = _request.getOriginalURI();

        // if it's one we're tracking, update the stat...
        switch( request ) {
            case "/weather_js.html":            incStat( "currentWeatherPage" ); break;
            case "/req/getCurrentWeather.json": incStat( "currentWeatherData" ); break;
        }
    }


    /**
     * Saves the current state of the statistics to disk.
     */
    private synchronized void persist() {
        stats.save();
    }


    /**
     * the current state of statistics is added to the given response object, under the key "stats".
     *
     * @param _response the response to add stats to
     */
    public synchronized void addStats( final JSONObject _response ) {

        // get a copy of our stats...
        JSONObject copy = new JSONObject( stats, JSONObject.getNames( stats ) );

        // now poke it into our response...
        _response.put( "stats", copy );
    }


    /**
     * Increments the given statistic in our stat.  If the stat with the given name does not exist, it is created and set to 1.
     *
     * @param _name the name of the stat to increment.
     */
    private void incStat( final String _name ) {
        long stat = stats.optLong( _name, 0 );
        stats.put( _name, ++stat );
    }


    private class Dumper extends Thread {

        private Dumper() {
            setDaemon( true );
            setName( "StatsDumper" );
            start();
        }

        public void run() {

            // we stay in this loop basically forever...
            while( !interrupted() ) {

                // wait for 60 seconds...
                try {
                    sleep( 60 * 1000 );
                }
                catch( InterruptedException _e ) {
                   break;
                }

                // trigger the persistence event...
                persist();
            }
        }
    }
}
