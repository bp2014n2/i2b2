/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */
package de.erlangen.i2b2.giri;

import java.io.*;

import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.rosuda.JRI.RMainLoopCallbacks;
import org.rosuda.JRI.Rengine;
import org.rosuda.JRI.REXP;

import edu.harvard.i2b2.common.exception.I2B2Exception;

import de.erlangen.i2b2.giri.GIRIUtil;

// This class interacts directly with JRI (Java R Interface) library
public class JRIProcessor {
	
	private static Log log = LogFactory.getLog(JRIProcessor.class);
	private static Rengine re = null;
	private static StringBuffer Routput;
	private static StringBuffer Rerrors;
	
    public static void initializeR() throws I2B2Exception {
    	
    	// Set some system settings that are required for running R
    	GIRIUtil.setUpREnvironment();
    	
    	// Make sure we have the right version of everything
    	boolean versionOK = Rengine.versionCheck();
    	if (!versionOK) {
			log.error("R version error");
			throw new I2B2Exception("Error delivered from server: R version error");
    	}
    	
    	// Don't do/show unnecessary things (save/restore workspace etc.)
        String[] args = {"--vanilla", "-q"};
        log.info("Starting R...");
        
        // Look if there's an existing R engine...
        re = Rengine.getMainEngine();
        // If not create a new one
        if (re == null) {
        	log.info("Creating new R engine");
        	// Create new R engine but don't start main loop immediately (second argument)
        	re = new Rengine(args, false, new ScriptExecutorCallbackClass());
        } else {
        	log.info("R engine already exists");
        }
        
        // Load required R package 'xtable'
		re.eval("library(xtable)");
    }
    
    // Do some preparation inside the R session for later output (plots, csvs, variables)
    public static File prepare(String webDirPath) throws I2B2Exception {
    	    	
    	String plotDirPath = webDirPath + "/plots";
    	String csvDirPath = webDirPath + "/csv";
    	
    	// Clear old output / errors
    	Routput = new StringBuffer(200);
    	Rerrors = new StringBuffer(200);
    	
    	// ========= Plots =========
    	
     	File f = new File(plotDirPath);
     	
    	// Check if directory exists and if permissions are sufficient
     	if ( ! f.exists()) {
    		if (! f.mkdirs()) {
    			log.error("Error while creating plot directory");
    			throw new I2B2Exception("Error while creating plot directory");
    		}
     	}
     	
    	if ( ! (f.exists() && f.isDirectory() && f.canRead() && f.canWrite()) ) {
			log.error("Error with plot directory: " + plotDirPath);
			throw new I2B2Exception("Error delivered from server: Plot directory not available");
    	}
    	
    	// Clear old plot files
    	for (File plotfile : f.listFiles()) {
    		plotfile.delete();
    	}
    	
    	// Set up R to save plots as svg files in the given plot directory
    	REXP ret = re.eval("svg(\"" + plotDirPath + "/plot%03d.svg\")");
    	if (ret == null) {
			log.error("Error while setting plot dir path in R");
			throw new I2B2Exception("Error delivered from server: Setting plot directory path in R");
    	} 
    	
    	// ========= CSVs =========
     	File f2 = new File(csvDirPath);
    	// Check if directory exists and if permissions are sufficient
     	if ( ! f2.exists()) {
    		if (! f2.mkdirs()) {
    			log.error("Error while creating csv directory");
    			throw new I2B2Exception("Error while creating csv directory");
    		}
     	}
     	
    	if ( ! (f2.exists() && f2.isDirectory() && f2.canRead() && f2.canWrite()) ) {
			log.error("Error with csv directory: " + plotDirPath);
			throw new I2B2Exception("Error delivered from server: CSV directory not available");
    	}
    	
    	// Clear old csv files
    	for (File csvfile : f2.listFiles()) {
    		csvfile.delete();
    	}
    	
    	// ========= Create data structures (vectors) =========
    	REXP ret2 = re.eval("GIRI.patients <- c()");
    	REXP ret3 = re.eval("GIRI.observations <- c()");
    	REXP ret4 = re.eval("GIRI.input <- c()");
    	REXP ret5 = re.eval("GIRI.output <- list()");
    	REXP ret6 = re.eval("GIRI.concept.names <- c()");
    	REXP ret7 = re.eval("GIRI.modifiers <- c()");
    	REXP ret8 = re.eval("GIRI.events <- c()");
    	REXP ret9 = re.eval("GIRI.observers <- c()");
    	if (ret2 == null || ret3 == null || ret4 == null || ret5 == null || ret6 == null || ret7 == null || ret8 == null || ret9 == null) {
			log.error("Error with setting up new vectors in R");
			throw new I2B2Exception("Error delivered from server: Creating vectors");
    	} 
    	
    	// ========= Handling dates and times =========
    	// Define an i2b2 DateTime Class, a helper function and a conversion function for the database DateTime string
    	// -> Time is also considered
    	re.eval("setClass(\"i2b2DateTime\")");
    	re.eval("GIRI.swapPlusMinus <- function(x) if (!is.na(x)){if(x==\"-\") {\"+\"} else {\"-\"}}");
    	re.eval("setAs(\"character\",\"i2b2DateTime\", function(from){do.call(c,lapply(from, function(x) {as.POSIXlt(x, tz = paste(\"GMT\", GIRI.swapPlusMinus(substr(x,24,24)), substr(x,26,26), sep=\"\"), format=\"%Y-%m-%dT%H:%M:%S\")}))})");
    	return f;
    }
    
    // Read in patient data
    public static void readDataFrameFromString(String name, GIRICSVContainer s, String colClasses) throws I2B2Exception {
    	// Uncomment for debugging purposes
    	// log.info(name + "\n\n" + s.getString());
    	
    	// Case: No data available -> Initialize empty data.frame (read.table would cause an error otherwise) and return
    	if (!s.hasData()) {
    		String initStr = s.getString().replace(GIRIUtil.SEP, "=character(),");
    		initStr = initStr.concat("=character()");
    		re.eval(name + " <- data.frame(" + initStr +  ")");
    		return;
    	}
    	re.assign("tmp", s.getString());
    	REXP ret = re.eval(name + " <- read.table(textConnection(tmp), sep=\"" + GIRIUtil.SEP + "\", header=T, row.names=NULL, quote=\"\\\"\"," +
    			"colClasses = " + colClasses + ", na.string=c(\"\"))");
    	if (ret == null) {
			log.error("Error reading in patient data into data.frame " + name);
			throw new I2B2Exception("Error delivered from server: Reading in patient data");
    	} 
    	re.eval("rm(tmp)");
    }
    
    // Assign additional input parameters in R
    public static void assignAdditionalInput(Map<String, String> m) throws I2B2Exception {
    	// Assign additional input variables as strings
    	for (Map.Entry<String, String> entry : m.entrySet()) {
    		// Do some replacements in order to prevent errors and security flaws
    		String key = entry.getKey().replace("\\", "\\\\");
    		key = key.replace("\"", "\\\"");
    		String value = entry.getValue().replace("\\", "\\\\");
    		value = value.replace("\"", "\\\"");
    		REXP ret = re.eval("GIRI.input[\"" + key + "\"] = \"" + value + "\"");
    		if (ret == null) {
    			log.error("Error assigning additional inputs");
    			throw new I2B2Exception("Error delivered from server: Reading in additional input values");	
    		}
    	}
    }
    
    // Make the names of the chosen concepts visible in R
    public static void assignConceptNames(String[] names) {
    	for (int i = 0; i < names.length; i++) {
    		String sanitized = names[i].replace("\\", "\\\\");
    		sanitized = sanitized.replace("\"", "\\\"");
        	re.eval("GIRI.concept.names[" + (i+1) + "] <- \"" + sanitized + "\"");
    	}
    }
    
    public static void executeRScript(String scriptPath) throws I2B2Exception {
    	re.eval("source(\"" + scriptPath + "\")");
    }
    
    public static List<String[]> getOutputVariables(List<String[]> outputParametersList, String webPath) throws I2B2Exception {
    	// Array has 4 elements: Name, description, type, value
    	List<String[]> l = new LinkedList<String[]>();
    	
    	// Get default output variables
    	REXP ret = re.eval("GIRI.output.1");
    	for (int i = 2; ret != null; i++) {
    		String name = "GIRI.output." + (i-1); // Default name
    		String[] array = new String[4];
			array[0] = name;
			array[1] = ""; // Default output variables don't have descriptions
			array[2] = getType(name);
			array[3] = extractResult(array[2], name, webPath + "/csv", name);
    		l.add(array);
    		ret = re.eval("GIRI.output." + i);
    	}
    	
    	// Get custom (user defined) output variables
    	for (String[] oElement : outputParametersList) {
    		// Replacements to prevent errors / security flaws
    		String oName = oElement[0].replace("\\", "\\\\");
    		oName = oName.replace("\"", "\\\"");
    		String Rname = "GIRI.output[[\"" + oName + "\"]]"; // Name to access output variable in R
    		REXP retVal = re.eval(Rname);
    		if (retVal != null) {
    			String[] array = new String[4];
    			array[0] = oElement[0];
    			array[1] = oElement[1];
    			array[2] = getType(Rname);
    			array[3] = extractResult(array[2], Rname, webPath + "/csv", oName);
    			l.add(array);
    		}
    	}
    	
    	return l;
    }
    
    // Check if output is table-like
    private static String getType(String name) throws I2B2Exception {
    	REXP df = re.eval("is.data.frame(" + name + ")");
    	REXP mat = re.eval("is.matrix(" + name + ")");
		if (df == null || mat == null) {
			log.error("Error while getting type of output variable");
			throw new I2B2Exception("Error delivered from server: Determining data type of output variable");
		}
    	// If it is a data.frame...
    	if (df.asBool().isTRUE()) {
    		return "data.frame";
    	} else if(mat.asBool().isTRUE()) {
    		return "matrix";
    	} else {
    		return "other";
    	}
    }
    
	// Create HTML table code and a csv file if it is a table-like R type
    // Otherwise just return the result value as a string
    private static String extractResult(String type, String name, String csvPath, String filename) throws I2B2Exception{
    	if (type.equals("data.frame") || type.equals("matrix")) {
    		// This is a workaround for a bug in xtable library (Date columns produce an error)
    		// See http://stackoverflow.com/questions/8652674/r-xtable-and-dates for details
    		REXP newFuncRet = re.eval("xtable <- function(x, ...) {\n" +
    			   "for (i in which(sapply(x, function(y) !all(is.na(match(c(\"POSIXt\",\"Date\"),class(y))))))) x[[i]] <- as.character(format(x[[i]], format=\"%Y-%m-%d %H:%M:%S\"))\n" +
    			   "xtable::xtable(x, ...)\n}\n");
    		if (newFuncRet == null) {
    			log.error("Error while creating function as xtable workaround.");
    			throw new I2B2Exception("Error delivered from server: xtable workaround");
    		}
    		// Write csv file into the web directory
    		// This workaround ensures that every DateTime has the same representation in the .csv file
    		// (without this the time would be ommited if it is midnight)
    		REXP transformRet = re.eval("GIRI.tmptable <- as.data.frame(lapply(" + name + ", function(x) if (is(x, \"POSIXt\")) format(x, \"%Y-%m-%d %H:%M:%S\") else x))");
    		REXP csvRet = re.eval("write.table(GIRI.tmptable, file = \"" + csvPath + "/" + filename + ".csv\", append = FALSE, quote=which(sapply(" + name + ", function(x) !is.numeric(x) & !is(x, \"POSIXt\")))," +
    				" sep = \",\", eol = \"\\r\\n\", na = \"NULL\", dec = \".\", row.names = FALSE, col.names = TRUE, qmethod=\"double\", fileEncoding = \"UTF-8\")");
    		REXP rmTab = re.eval("rm(GIRI.tmptable)");
    		if (transformRet == null || csvRet == null || rmTab == null) {
    			log.error("Error while writing csv file for table " + name);
    			throw new I2B2Exception("Error delivered from server: Writing csv file");
    		}
    		// Now create the HTML code of the table structure
    		REXP ret = re.eval("paste(capture.output(print(xtable(" + name + "), type = \"html\")), collapse=\"\")");
    		if (ret == null) {
    			re.eval("write(\"Error while trying to create HTML code out of table " + name + " \n\", stderr())");
    			return "undefined";
    		}  
    		return ret.asString();
    	} else {
    		REXP ret = re.eval("toString(" + name + ")");
    		if (ret == null) {
    			log.error("Error while extracting results (other)");
    			throw new I2B2Exception("Error delivered from server: Extracting result value as string");
    		}
    		return ret.asString();
    	}

    }
    
    public static void doFinalRTasks(String webPath) throws I2B2Exception {
    	
    	// Create RImage directory if not existing
    	File f = new File(webPath + "/RImage/");
     	if ( ! f.exists()) {
    		if (! f.mkdirs()) {
    			log.error("Error while creating RImage directory");
    			throw new I2B2Exception("Error while creating RImage directory");
    		}
     	}
    	
    	// Write plot files, write R workspace image and clear workspace
    	REXP ret = re.eval("dev.off()");
    	REXP ret2 = re.eval("save.image(file=\"" + webPath + "/RImage/RImage" + "\")");
    	REXP ret3 = re.eval("rm(list = ls())");
    	if (ret == null || ret2 == null || ret3 == null) {
			log.error("Error while doing final tasks");
			throw new I2B2Exception("Error delivered from server: Doing final R tasks");
    	}
    	// End R thread
    	re.end();
    }
    
    // Following methods are used to access the strings saving R output / error stream
    public static void appendROutput(String s) {
    	Routput.append(s);
    }
    
    public static String getROutput() {	
    	return Routput.toString();
    }
    
    public static void appendRErrors(String s) {
    	Rerrors.append(s);
    }
    
    public static String getRErrors() {	
    	return Rerrors.toString();
    }
    
}

//This class defines callback methods that are called by the main loop of R if a certain event occurs
class ScriptExecutorCallbackClass implements RMainLoopCallbacks {	

	private static Log log = LogFactory.getLog(ScriptExecutorCallbackClass.class);
	
	// If R writes something to the console this method will be called
	public void rWriteConsole(Rengine re, String text, int oType) {
		// Normal output
		if (oType == 0) {
			log.info("Output from R (normal): " + text);
			JRIProcessor.appendROutput(text);
		// Error output
		} else {
			log.info("Output from R (error): " + text);
			// Do not send back the error 'Error: object 'GIRI.output.x' not found' because this 'error' appears every time
			// when looking for the last set output variable (see method getOutputVariables). So it's not an error but the normal case.
			// To prevent confusion, this error output is omitted
			if ( !(text.contains("Error: object 'GIRI.output.") && text.contains("not found")) ) {
				JRIProcessor.appendRErrors(text);
				// Give a hint to the possible cause of this common error
				if (text.contains("data length exceeds size of matrix")) {
					JRIProcessor.appendRErrors("Possible cause: Trying to access an empty data.frame\n");
				}
			}
		}
	}
	
	// Following events have no influence at all. So they're just logged
	public void rBusy(Rengine re, int which) {
		log.info("rBusy called");
	}
	
	public void rFlushConsole (Rengine re) {
		log.info("rFlushConsole called");
	}
	
	// An R "message" is counted as normal R output
	public void rShowMessage(Rengine re, String message) {
		log.info("Message from R: " + message);
		JRIProcessor.appendROutput("R message: " + message);
	}
	
	// Some R methods cause events, that aren't supported by this program like choosing a file interactively via a GUI window
	// Hence the R script could be buggy -> The user is warned by a message
	public String rChooseFile(Rengine re, int newFile) {
		log.error("rChooseFile called");
		JRIProcessor.appendRErrors("GIRI-Warning: Forbidden R method (choose file) called. Please check your R script");
		return "";
	}
	
	public String rReadConsole(Rengine re, String prompt, int addToHistory) {
		log.info("rReadConsole called");
		JRIProcessor.appendRErrors("GIRI-Warning: Forbidden R method (read from console) called. Please check your R script");
		return null;
	}
	
	public void rLoadHistory (Rengine re, String filename) {
		log.error("rLoadHistory called");
		JRIProcessor.appendRErrors("GIRI-Warning: Forbidden R method (load history) called. Please check your R script");
	}			
 
	public void rSaveHistory (Rengine re, String filename) {
		log.error("rSaveHistory called");
		JRIProcessor.appendRErrors("GIRI-Warning: Forbidden R method (save history) called. Please check your R script");
	}			
}