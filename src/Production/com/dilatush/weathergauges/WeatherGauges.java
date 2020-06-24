package com.dilatush.weathergauges;

import com.dilatush.util.Config;

import java.io.File;
import java.util.logging.Logger;

import static com.dilatush.util.General.isNotNull;

/**
 * @author Tom Dilatush  tom@dilatush.com
 */
public class WeatherGauges {

    static private Logger LOGGER;

    public static void main( String[] _args ) {

        // TODO: what should I do in the event of an error???
        // Maybe we should bring up the web server first, and launch a browser to an error page if something
        // goes horribly wrong
        // TODO: launch web browser in separate process...

        // set the configuration file location (must do before any logging actions occur)...
        System.getProperties().setProperty( "java.util.logging.config.file", "logging.properties" );
        LOGGER = Logger.getLogger( new Object(){}.getClass().getEnclosingClass().getSimpleName() );
        LOGGER.info( "WeatherGauges is starting..." );

        // the configuration file...
        String config = "configuration.json";   // the default...
        if( isNotNull( (Object) _args ) && (_args.length > 0) ) config = _args[0];
        if( !new File( config ).exists() ) {
            System.out.println( "WeatherGauges configuration file " + config + " does not exist!" );
            return;
        }

        // get our config...
        Config weatherConfig = Config.fromJSONFile( config );

        // fish out the variables we need...
        double lat = weatherConfig.getDouble( "latitude" );
        double lon = weatherConfig.getDouble( "longitude" );


        weatherConfig.hashCode();
    }
}
