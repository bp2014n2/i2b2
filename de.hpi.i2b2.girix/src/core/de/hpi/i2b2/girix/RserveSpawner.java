package de.hpi.i2b2.girix;

import java.io.File;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.rosuda.REngine.Rserve.RConnection;

/**
 * simple class that start Rserve locally if it's not running already - see
 * mainly <code>checkLocalRserve</code> method. It spits out quite some
 * debugging outout of the console, so feel free to modify it for your
 * application if desired.<p>
 * <i>Important:</i> All applications should shutdown every Rserve that they
 * started! Never leave Rserve running if you started it after your application
 * quits since it may pose a security risk. Inform the user if you started an
 * Rserve instance.
 */
public class RserveSpawner {

	private static Log log = LogFactory.getLog(RserveSpawner.class);
	
	/**
	 * shortcut to
	 * <code>launchRserve(cmd, "--no-save --slave", "--no-save --slave", false, port)</code>
	 */
	private static boolean launchRserve(String cmd, int port) {
		return launchRserve(cmd, "--no-save --slave", "--no-save --slave", false, port);
	}

	/**
	 * attempt to start Rserve. Note: parameters are <b>not</b> quoted, so avoid
	 * using any quotes in arguments
	 *
	 * @param cmd command necessary to start R
	 * @param rargs arguments are are to be passed to R
	 * @param rsrvargs arguments to be passed to Rserve
	 * @return <code>true</code> if Rserve is running or was successfully started,
	 * <code>false</code> otherwise.
	 */
	private static boolean launchRserve(String cmd, String rargs, String rsrvargs, boolean debug, int port) {
		try {
			Process p;
			boolean isWindows = false;
			String osname = System.getProperty("os.name");
			if (osname != null && osname.length() >= 7 && osname.substring(0, 7).equals("Windows")) {
				isWindows = true; /* Windows startup */

				p = Runtime.getRuntime().exec("\"" + cmd + "\" -e \"library(Rserve);Rserve(" + (debug ? "TRUE" : "FALSE") + ",port=" + port + ",args='" + rsrvargs + "')\" " + rargs);
			} else /* unix startup */ {
				p = Runtime.getRuntime().exec(new String[]{
						"/bin/sh", "-c",
						"echo 'library(Rserve);Rserve(" + (debug ? "TRUE" : "FALSE") + ",port=" + port + ",args=\"" + rsrvargs + "\")'|" + cmd + " " + rargs
				});
			}
			log.info("Starting new Rserve");
			// we need to fetch the output - some platforms will die if you don't ...
			new RserveConsoleWriter(p.getErrorStream());
			new RserveConsoleWriter(p.getInputStream());
			if (!isWindows) /* on Windows the process will never return, so we cannot wait */ {
				p.waitFor();
			}
			//System.out.println("StartRserve: call terminated, let us try to connect ...");
		} catch (Exception x) {
			//System.out.println("StartRserve: failed to start Rserve process with " + x.getMessage());
			return false;
		}
		int attempts = 5; /* try up to 5 times before giving up. We can be conservative here, because at this point the process execution itself was successful and the start up is usually asynchronous */

		while (attempts > 0) {
			try {
				RConnection c = new RConnection();
				c.close();
				return true;
			} catch (Exception e) {
				//System.out.println("StartRserve: Try failed with: " + e.getMessage());
			}
			/* a safety sleep just in case the start up is delayed or asynchronous */
			try {
				Thread.sleep(500);
			} catch (InterruptedException ix) {
			};
			attempts--;
		}
		return false;
	}

	/**
	 * checks whether Rserve is running and if that's not the case it attempts to
	 * start it using the defaults for the platform where it is run on. This
	 * method is meant to be set-and-forget and cover most default setups. For
	 * special setups you may get more control over R with
	 * <<code>launchRserve</code> instead.
	 */
	public static boolean checkLocalRserve(int port) {
		if (isRserveRunning(port)) {
			log.info("Rserve already running");
			return true;
		}
		String osname = System.getProperty("os.name");
		if (osname != null && osname.length() >= 7 && osname.substring(0, 7).equals("Windows")) {
			//System.out.println("StartRserve: Windows: query registry to find where R is installed ...");
			String installPath = null;
			try {
				Process rp = Runtime.getRuntime().exec("reg query HKLM\\Software\\R-core\\R");
				WindowsRLocator regHog = new WindowsRLocator(rp.getInputStream());
				rp.waitFor();
				regHog.join();
				installPath = regHog.getInstallPath();
			} catch (Exception rge) {
				System.out.println("ERROR: unable to run REG to find the location of R: " + rge);
				return false;
			}
			if (installPath == null) {
				System.out.println("ERROR: canot find path to R. Make sure reg is available and R was installed with registry settings.");
				return false;
			}
			return launchRserve(installPath + "\\bin\\R.exe", port);
		}
		return (launchRserve("R", port)
				|| /* try some common unix locations of R */ ((new File("/Library/Frameworks/R.framework/Resources/bin/R")).exists() && launchRserve("/Library/Frameworks/R.framework/Resources/bin/R", port))
				|| ((new File("/usr/local/lib/R/bin/R")).exists() && launchRserve("/usr/local/lib/R/bin/R", port))
				|| ((new File("/usr/lib/R/bin/R")).exists() && launchRserve("/usr/lib/R/bin/R", port))
				|| ((new File("/usr/local/bin/R")).exists() && launchRserve("/usr/local/bin/R", port))
				|| ((new File("/sw/bin/R")).exists() && launchRserve("/sw/bin/R", port))
				|| ((new File("/usr/common/bin/R")).exists() && launchRserve("/usr/common/bin/R", port))
				|| ((new File("/opt/bin/R")).exists() && launchRserve("/opt/bin/R", port)));
	}

	/**
	 * check whether Rserve is currently running (on local machine and default
	 * port).
	 *
	 * @return <code>true</code> if local Rserve instance is running,
	 * <code>false</code> otherwise
	 */
	public static boolean isRserveRunning(int port) {
		try {
			RConnection c = new RConnection("127.0.0.1", port);
			c.close();
			return true;
		} catch (Exception e) {
			//System.out.println("StartRserve: first connect try failed with: " + e.getMessage());
		}
		return false;
	}

}

