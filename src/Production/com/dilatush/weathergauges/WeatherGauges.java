package com.dilatush.weathergauges;

import com.dilatush.weathergauges.jetty.handlers.StatsHandler;
import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.handler.DefaultHandler;
import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.server.handler.ResourceHandler;
import org.eclipse.jetty.server.session.DefaultSessionIdManager;
import org.eclipse.jetty.server.session.SessionHandler;

import java.util.Timer;
import java.util.logging.Logger;

import static java.lang.Thread.sleep;
import static java.util.logging.Level.SEVERE;

/**
 * The main program (with the entry point) for the Weather Gauges program.
 *
 * @author Tom Dilatush  tom@dilatush.com
 */
public class WeatherGauges {

    private final static int PORT = 8888;

    private Logger LOGGER;
    private Timer timer;


    /**
     * The entry point for the Weather Gauges program.  No command line arguments are used.
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

        // start up the web server...
        Server server = getServer();

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
     * Set up the logging subsystem, from the logging.properties file.
     */
    private void setupLogging() {
        System.getProperties().setProperty( "java.util.logging.config.file", "logging.properties" );
        LOGGER = Logger.getLogger( new Object(){}.getClass().getEnclosingClass().getSimpleName() );
    }


    /**
     * Initialize the Jetty web server for our private instance.
     *
     * @return
     *      the Jetty server instance.
     */
    private Server getServer() {

        // start the Jetty server...
        Server server = new Server( PORT );

        ResourceHandler rh1 = new ResourceHandler();
        rh1.setDirectoriesListed( false );
        rh1.setWelcomeFiles( new String[] { "index.html" } );
        rh1.setResourceBase("./html");
        ResourceHandler rh2 = new ResourceHandler();
        rh2.setDirectoriesListed( false );
        rh2.setResourceBase("./js");
        ResourceHandler rh3 = new ResourceHandler();
        rh3.setDirectoriesListed( false );
        rh3.setResourceBase("./resources");

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
