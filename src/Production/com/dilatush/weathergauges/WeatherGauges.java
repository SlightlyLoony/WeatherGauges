package com.dilatush.weathergauges;

import com.dilatush.util.Config;
import com.dilatush.weathergauges.jetty.handlers.StatsHandler;
import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.handler.DefaultHandler;
import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.server.handler.ResourceHandler;
import org.eclipse.jetty.server.session.DefaultSessionIdManager;
import org.eclipse.jetty.server.session.SessionHandler;

import java.io.File;
import java.util.Timer;
import java.util.logging.Logger;

import static com.dilatush.util.General.isNotNull;
import static java.lang.Thread.sleep;
import static java.util.logging.Level.SEVERE;

/**
 * The main program (with the entry point) for the Weather Gauges program.
 *
 * @author Tom Dilatush  tom@dilatush.com
 */
public class WeatherGauges {

    private Logger LOGGER;
    private Timer timer;


    /**
     * The entry point for the Weather Gauges program.  Only one command line argument is allowed, and it is optional: the path to the Weather Gauges
     * JSON configuration file.  If this argument is missing, the default path ("./configuration.json") is used.
     *
     * @param _args the command line arguments.
     */
    public static void main( String[] _args ) {
        new WeatherGauges().run( _args );
    }


    private void run( final String[] _args ) {

        setupLogging();  // must be done before any logging happens...

        // before anything can possibly go wrong, make a log entry...
        LOGGER.info( "WeatherGauges is starting..." );

        WeatherGaugesConfiguration weatherGaugesConfiguration = getConfiguration( _args );
        if( weatherGaugesConfiguration == null ) {

        }

        // start up the web server...
        Server server = getServer( weatherGaugesConfiguration.webServerPort );



        // TODO: what should I do in the event of an error???
        // Maybe we should bring up the web server first, and launch a browser to an error page if something
        // goes horribly wrong
        // TODO: launch web browser in separate process...
        // we just hang around until something disastrous happens...
        try {
            while( true ) sleep( 1000 );
        }
        catch( Exception _e ) {
            LOGGER.log( SEVERE, "Bad things happened and we're shutting down the server...", _e );
        }
    }


    /**
     * Return a {@link WeatherGaugesConfiguration} instance derived from the Weather Gauges configuration file.  Upon any problem, a
     * <code>null</code> is returned.
     *
     * @param _args the Weather Gauges program command line arguments upon invocation.
     * @return the {@link WeatherGaugesConfiguration} instance derived from the Weather Gauges configuration file, or <code>null</code> if the configuration is invalid.
     */
    private WeatherGaugesConfiguration getConfiguration( final String[] _args ) {

        Config weatherConfig = null;
        WeatherGaugesConfiguration result = null;

        try {
            // figure out the configuration file name...
            String config = "configuration.json";   // the default...
            if( isNotNull( (Object) _args ) && (_args.length > 0) ) config = _args[0];
            if( !new File( config ).exists() ) {
                System.out.println( "WeatherGauges configuration file " + config + " does not exist!" );
                return null;
            }

            // get our config...
            weatherConfig = Config.fromJSONFile( config );
        }
        catch( Exception _e ) {
            // do nothing; we will return a null...
        }

        if( weatherConfig != null ) {
            result = new WeatherGaugesConfiguration( weatherConfig );
        }

        return result;
    }


    /**
     * Set up the logging subsystem, from the logging.properties file.
     */
    private void setupLogging() {
        System.getProperties().setProperty( "java.util.logging.config.file", "logging.properties" );
        LOGGER = Logger.getLogger( new Object(){}.getClass().getEnclosingClass().getSimpleName() );
    }


    /**
     * Initialize the Jetty web server for our private instance.
     *
     * @param _port
     *      the port to use for the web server.
     * @return
     *      the Jetty server instance.
     */
    private Server getServer( final int _port ) {

        // start the Jetty server...
        Server server = new Server( _port );

        ResourceHandler rh1 = new ResourceHandler();
        rh1.setDirectoriesListed( false );
        rh1.setWelcomeFiles( new String[] { "index.html" } );
        rh1.setResourceBase("./pages/html");
        ResourceHandler rh2 = new ResourceHandler();
        rh2.setDirectoriesListed( false );
        rh2.setResourceBase("./pages/js");
        ResourceHandler rh3 = new ResourceHandler();
        rh3.setDirectoriesListed( false );
        rh3.setResourceBase("./pages/resources");

        server.setSessionIdManager( new DefaultSessionIdManager( server ) );

        Handler sessionHandler            = new SessionHandler();
        Handler statsHandler              = new StatsHandler( this );

        HandlerList handlers = new HandlerList();

        handlers.setHandlers( new Handler[] { sessionHandler, statsHandler, rh1, rh2, rh3,
                new DefaultHandler() });
        server.setHandler(handlers);

        try {
            server.start();
        }
        catch( Exception _e ) {

            // this is catastrophic - just log and leave with a null...
            LOGGER.log( SEVERE, "Problem prevents web server startup", _e );
            return null;
        }
        return server;
    }
}
