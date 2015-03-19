/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */
package de.hpi.i2b2.girix;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.Field;
import java.net.URL;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;

import javax.xml.XMLConstants;
import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.xml.sax.SAXException;

import com.sun.jna.Library;
import com.sun.jna.Native;

import de.hpi.i2b2.girix.datavo.girixconfig.RscriptletType;
import de.hpi.i2b2.girix.datavo.girixmessages.InputParameterType;

import edu.harvard.i2b2.common.exception.I2B2Exception;
import edu.harvard.i2b2.common.util.jaxb.JAXBUtil;

// Helper class with some useful methods and constants
public class GIRIXUtil {
	
	// Needed for jaxb initialization
    private static final String[] DEFAULT_PACKAGE_NAME = new String[] {
        "de.hpi.i2b2.girix.datavo.i2b2message",
        "de.hpi.i2b2.girix.datavo.pdo",
        "de.hpi.i2b2.girix.datavo.pdo.query",
        "de.hpi.i2b2.girix.datavo.girixconfig",
        "de.hpi.i2b2.girix.datavo.girixmessages"
    };
    private static Log log = LogFactory.getLog(GIRIXUtil.class);
    private static boolean initialized = false;
    private static JAXBUtil jaxbutil = null;
    // This is the separator character used for csv string that is imported into R
	public final static String SEP = ";";
    
    // testingmode is for local testing without binding aar/jar packages and deploying it to jboss. Just call a service method in GIRIXService
    // from a testing main class. Note that testingmode won't work in jboss and non-testingmode won't work locally!
    private static boolean testingmode = false;
    
    // Remains null if not in testingmode
    private static String BUILDPROPERTIESPATH = null;
    // Path to the scriptlet directory
	private static String RSCRIPTLETPATH = null;
	// Path to the XML schema (.xsd) file for config.xml files
	private static String CONFIGSCHEMAPATH = null;
	// Path to R program
	private static String RHOME = null;
	// Path to JRI lib
	private static String JRILIBPATH = null;
	// Path to the web directory
	private static String WEBDIRPATH = null;
	// Path to the web directory
	private static String UPLOADURL = null;
	
	// Calling this method will configure the program for running locally (without jboss)
	public static void setTestingmodeON(String path) {
		testingmode = true;
		BUILDPROPERTIESPATH = path;
	}
	
	// Initializes some important constants
		// a) from a build.properties file on the local file system (in testingmode)
		// b) from the build.properties file that was packed by ant into the aar file (that runs in jboss)
	public static void initializeGIRIXUtil() {
		if (initialized) return;
		if (testingmode) {
			Properties testingprops = new Properties();
			try {
				testingprops.load(new FileInputStream(BUILDPROPERTIESPATH));
				RSCRIPTLETPATH = testingprops.getProperty("girix.directory");
				RHOME = testingprops.getProperty("r.home");
				CONFIGSCHEMAPATH = testingprops.getProperty("config.schema.path");
				JRILIBPATH = testingprops.getProperty("jri.libpath");
				WEBDIRPATH = testingprops.getProperty("web.dir");
				UPLOADURL = testingprops.getProperty("upload.url");
			} catch (Exception e) {
				// In testing mode a stack trace is sufficient
				e.printStackTrace();
			} 			
		} else {
			Properties prop = new Properties();
			Enumeration<URL> resources = null;
			try {
				resources = GIRIXUtil.class.getClassLoader().getResources("etc/build.properties");
				prop.load(resources.nextElement().openStream());
				RSCRIPTLETPATH = prop.getProperty("girix.directory");
				RHOME = prop.getProperty("r.home");
				String jbosshome = prop.getProperty("jboss.home");
				JRILIBPATH = jbosshome + "/standalone/lib/ext";
				WEBDIRPATH = prop.getProperty("web.dir");
				UPLOADURL = prop.getProperty("upload.url");
			} catch (IOException e) {
				log.error("Exception stack trace:\n" + getStackTraceAsString(e));
			}
		}
		initialized = true;
	}
	
	public static String getWEBDIRPATH() {
		return WEBDIRPATH;
	}
	
	public static String getUPLOADURL() {
		return UPLOADURL;
	}
    
	public static JAXBUtil getJAXBUtil() {
		if(jaxbutil == null) {
			jaxbutil = new JAXBUtil(DEFAULT_PACKAGE_NAME);
		}
		return jaxbutil;
	}
	
	public static String getStackTraceAsString(Exception e) {
		StringWriter sw = new StringWriter();
		PrintWriter pw = new PrintWriter(sw);
		e.printStackTrace(pw);
		return sw.toString();
	}
	
	public static String getRSCRIPTLETPATH() throws I2B2Exception {
			return RSCRIPTLETPATH;
	}
	
	public static URL getCONFIGSCHEMAURL() throws I2B2Exception {
		if (testingmode) {
			// Convert file path string to an URL object
			URL ret = null;
				try {
					ret = new File(CONFIGSCHEMAPATH).toURI().toURL();
					if (ret == null) {
						throw new NullPointerException();
					}
				} catch (Exception e) {
					throw new I2B2Exception("Error accessing local config schema file path", e);
				}
			return ret;
		} else {
			// Schema file GIRIXConfig.xsd is packed into the archive file GIRIX.aar and is accessed by the following code
			Enumeration<URL> resources = null;
			try {
				resources = GIRIXUtil.class.getClassLoader().getResources("etc/GIRIXConfig.xsd");
			} catch (IOException e) {
				throw new I2B2Exception("Error accessing resource: Config schema file", e);
			}
			return resources.nextElement();
		}
	}
		
	public static RscriptletType validateAndUnmarshallScriptletConfigFile(String scriptletPath, String scriptletName) throws I2B2Exception, SAXException {
		
		RscriptletType girixType = null;
		
		String scriptletconfigpath = scriptletPath + "/config.xml";
		File scriptletconfig = new File(scriptletconfigpath);
		// If a config file exists...
		if (scriptletconfig.exists()) {
			// ...that is no directory and readable...
			if (scriptletconfig.isDirectory() || ! scriptletconfig.canRead()) {
				log.error("Scriptlet config file error (Is a directory? Access rights?) at path: " + scriptletconfigpath);
				String scriptletconferror = "Error delivered from server: Scriptlet config file access error with scriptlet " + scriptletName + " \n" +
										"Please contact the server admin.";
				throw new I2B2Exception(scriptletconferror);
			}
			// ...read in config file and validate against xml schema
			Source xmlFile = new StreamSource(scriptletconfig);
			validateXML(xmlFile, getCONFIGSCHEMAURL());

			// Unmarshall XML file into a 'rscriptlet' (jaxb) object
			try {
				girixType = (RscriptletType) getJAXBUtil().unMashallerRequest(scriptletconfigpath).getValue();
				if (girixType == null) throw new NullPointerException();
			} catch (Exception e) {
				throw new I2B2Exception("Error during unmarshalling a scriptlet config file", e);
			}
			
		} else {
			// If no config file is provided, just create a minimal GIRIX object
			de.hpi.i2b2.girix.datavo.girixconfig.ObjectFactory girixconfFac = new de.hpi.i2b2.girix.datavo.girixconfig.ObjectFactory();
			girixType = girixconfFac.createRscriptletType();
			girixType.setSettings(girixconfFac.createSettingsType());
		}
		
		return girixType;
	}
	
	// Validate an XML file against an XML schema
	public static void validateXML(Source xmlFile, URL schemaFile) throws I2B2Exception, SAXException {
		SchemaFactory schemaFactory = SchemaFactory.newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
		try {
			Schema schema = schemaFactory.newSchema(schemaFile);
			Validator validator = schema.newValidator();
			validator.validate(xmlFile);
			log.info("XML file " + xmlFile.getSystemId() + " is valid");
		}  catch (IOException e) {
			throw new I2B2Exception("Error during XML file validation (IOException)", e);
		} 
	}
	
	// Helper method
	public static Map<String, String> convertListIntoMapAndDecodeHTML(List<InputParameterType>  l)  {

		if (l == null) return null;
		Map<String, String> m = new HashMap<String, String>();
		
		for (InputParameterType ipt : l) {
			String name = ipt.getName().replace("&amp;", "&");
			name = name.replace("&lt;", "<");
			name = name.replace("&gt;", ">");
			m.put(name, ipt.getValue());
		}
		
		return m;
	}
	
	// This method does two things: a) Update library path at runtime to be able to access libjri.so library
	// b) Setting the R_HOME environment variable
	public static void setUpREnvironment() throws I2B2Exception {
		
		String updatedLibPath = System.getProperty("java.library.path");
		if (!updatedLibPath.contains(JRILIBPATH)) {
			updatedLibPath = updatedLibPath + ":" + JRILIBPATH;

			System.setProperty("java.library.path", updatedLibPath);
			Field sysPathsField = null;
				try {
					sysPathsField = ClassLoader.class.getDeclaredField("sys_paths");
					sysPathsField.setAccessible(true);
					sysPathsField.set(null, null);
				} catch (Exception e) {
					throw new I2B2Exception("Error while setting library path", e);
				}
		}
		
		// Comment this line and set R_HOME by yourself for platform independence
		Environment.libc.setenv("R_HOME", RHOME, 0);
	}
	
}

// Using hack from http://quirkygba.blogspot.de/2009/11/setting-environment-variables-in-java.html
// Note that this works only on unix system!
class Environment {
	public interface LibC extends Library {
		public int setenv(String name, String value, int overwrite);
		public int unsetenv(String name);
	}
	static LibC libc = (LibC) Native.loadLibrary("c", LibC.class);
}
