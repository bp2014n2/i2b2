/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */
package de.hpi.i2b2.girix;

import java.io.*;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.rosuda.REngine.REXP;
import org.rosuda.REngine.REXPLogical;
import org.rosuda.REngine.REXPMismatchException;
import org.rosuda.REngine.REngine;
import org.rosuda.REngine.REngineEvalException;
import org.rosuda.REngine.REngineException;
import org.rosuda.REngine.JRI.JRIEngine;

import edu.harvard.i2b2.common.exception.I2B2Exception;
import de.hpi.i2b2.girix.GIRIXUtil;

// This class interacts directly with JRI (Java R Interface) library
public class JRIProcessor {

  private static Log log = LogFactory.getLog(JRIProcessor.class);
  private static JRIEngine re = null;
  private static HashMap<String, REXP> environments = new HashMap<String, REXP>();
  private static StringBuffer Routput;
  private static StringBuffer Rerrors;
  private String sessionKey;
  
  public JRIProcessor(String sessionKey) throws REXPMismatchException, REngineException, I2B2Exception {
	  initializeR();
	  
	  this.sessionKey = sessionKey;
	  if (environments.get(sessionKey) == null) {
	    environments.put(sessionKey, re.newEnvironment(null, false));
	  }
  }

  public static void initializeR() throws I2B2Exception, REngineException, REXPMismatchException {

    // Set some system settings that are required for running R
    GIRIXUtil.setUpREnvironment();

    // Make sure we have the right version of everything
//    boolean versionOK = Rengine.versionCheck();
//    if (!versionOK) {
//      log.error("R version error");
//      throw new I2B2Exception("Error delivered from server: R version error");
//    }

    // Don't do/show unnecessary things (save/restore workspace etc.)
    String[] args = {"--vanilla", "-q"};
    log.info("Starting R...");

    // Look if there's an existing R engine...
    re = (JRIEngine) JRIEngine.getLastEngine();
    // If not create a new one
    if (re == null) {
      log.info("Creating new R engine");
      // Create new R engine but don't start main loop immediately (second argument)
      re = (JRIEngine) JRIEngine.createEngine(args, new ScriptExecutorCallbackClass(), false);
    } else {
      log.info("R engine already exists");
    }    

    // Load required R package 'xtable'
    re.parseAndEval("library(xtable)", null, true);
  }

  // Do some preparation inside the R session for later output (plots, csvs, variables)
  public File prepare(String webDirPath) throws I2B2Exception, REngineException, REXPMismatchException {

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
    REXP ret = re.parseAndEval("svg(\"" + plotDirPath + "/plot%03d.svg\")", getEnv(), true);
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
    REXP ret2 = re.parseAndEval("girix.patients <- c()", getEnv(), true);
    REXP ret3 = re.parseAndEval("girix.observations <- c()", getEnv(), true);
    REXP ret4 = re.parseAndEval("girix.input <- c()", getEnv(), true);
    REXP ret5 = re.parseAndEval("girix.output <- list()", getEnv(), true);
    REXP ret6 = re.parseAndEval("girix.concept.names <- c()", getEnv(), true);
    REXP ret7 = re.parseAndEval("girix.modifiers <- c()", getEnv(), true);
    REXP ret8 = re.parseAndEval("girix.events <- c()", getEnv(), true);
    REXP ret9 = re.parseAndEval("girix.observers <- c()", getEnv(), true);
    if (ret2 == null || ret3 == null || ret4 == null || ret5 == null || ret6 == null || ret7 == null || ret8 == null || ret9 == null) {
      log.error("Error with setting up new vectors in R");
      throw new I2B2Exception("Error delivered from server: Creating vectors");
    } 

    // ========= Handling dates and times =========
    // Define an i2b2 DateTime Class, a helper function and a conversion function for the database DateTime string
    // -> Time is also considered
    re.parseAndEval("setClass(\"i2b2DateTime\")", getEnv(), true);
    re.parseAndEval("girix.swapPlusMinus <- function(x) if (!is.na(x)){if(x==\"-\") {\"+\"} else {\"-\"}}", getEnv(), true);
    re.parseAndEval("setAs(\"character\",\"i2b2DateTime\", function(from){do.call(c,lapply(from, function(x) {as.POSIXlt(x, tz = paste(\"GMT\", girix.swapPlusMinus(substr(x,24,24)), substr(x,26,26), sep=\"\"), format=\"%Y-%m-%dT%H:%M:%S\")}))})", getEnv(), true);
    return f;
  }

  // Read in patient data
  public void readDataFrameFromString(String name, GIRIXCSVContainer s, String colClasses) throws I2B2Exception, REngineException, REXPMismatchException {
    // Uncomment for debugging purposes
    // log.info(name + "\n\n" + s.getString());

    // Case: No data available -> Initialize empty data.frame (read.table would cause an error otherwise) and return
    if (!s.hasData()) {
      String initStr = s.getString().replace(GIRIXUtil.SEP, "=character(),");
      initStr = initStr.concat("=character()");
      re.parseAndEval(name + " <- data.frame(" + initStr +  ")", getEnv(), true);
      return;
    }
    re.assign("tmp", s.getString());
    REXP ret = re.parseAndEval(name + " <- read.table(textConnection(tmp), sep=\"" + GIRIXUtil.SEP + "\", header=T, row.names=NULL, quote=\"\\\"\"," +
        "colClasses = " + colClasses + ", na.string=c(\"\"))", getEnv(), true);
    if (ret == null) {
      log.error("Error reading in patient data into data.frame " + name);
      throw new I2B2Exception("Error delivered from server: Reading in patient data");
    } 
    re.parseAndEval("rm(tmp)", getEnv(), true);
  }

  // Assign additional input parameters in R
  public void assignAdditionalInput(Map<String, String> m) throws I2B2Exception, REngineException, REXPMismatchException {
    // Assign additional input variables as strings
    for (Map.Entry<String, String> entry : m.entrySet()) {
      // Do some replacements in order to prevent errors and security flaws
      String key = entry.getKey().replace("\\", "\\\\");
      key = key.replace("\"", "\\\"");
      String value = entry.getValue().replace("\\", "\\\\");
      value = value.replace("\"", "\\\"");
      REXP ret = re.parseAndEval("girix.input[\"" + key + "\"] = \"" + value + "\"", getEnv(), true);
      if (ret == null) {
        log.error("Error assigning additional inputs");
        throw new I2B2Exception("Error delivered from server: Reading in additional input values");	
      }
    }
  }

  // Make the names of the chosen concepts visible in R
  public void assignConceptNames(String[] names) throws REngineException, REXPMismatchException {
    for (int i = 0; i < names.length; i++) {
      String sanitized = names[i].replace("\\", "\\\\");
      sanitized = sanitized.replace("\"", "\\\"");
      re.parseAndEval("girix.concept.names[" + (i+1) + "] <- \"" + sanitized + "\"", getEnv(), true);
    }
  }

  public void setWorkingDirectory(String scriptletDirectoryPath) throws REngineException, REXPMismatchException {
		
	  re.parseAndEval("setwd(\"" + scriptletDirectoryPath + "\")", getEnv(), true);
		
  }

  public void executeRScript(String scriptPath) throws I2B2Exception, REngineException, REXPMismatchException {
	  re.parseAndEval("source(\"" + scriptPath + "\", local=TRUE)", getEnv(), true);
  }

  public List<String[]> getOutputVariables(List<String[]> outputParametersList, String webPath) throws I2B2Exception, REngineException, REXPMismatchException {
    // Array has 4 elements: Name, description, type, value
    List<String[]> l = new LinkedList<String[]>();

    // Get default output variables
    int i = 1;
    
    while(true) {
      REXP ret = getOrEval(re, "girix.output." + i, getEnv(), true);
      if (ret == null) {
    	  break;
      }
      String name = "girix.output." + (i); // Default name
      String[] array = new String[4];
      array[0] = name;
      array[1] = ""; // Default output variables don't have descriptions
      array[2] = getType(name);
      array[3] = extractResult(array[2], name, webPath + "/csv", name);
      l.add(array);
      i++;
    }

    // Get custom (user defined) output variables
    for (String[] oElement : outputParametersList) {
      // Replacements to prevent errors / security flaws
      String oName = oElement[0].replace("\\", "\\\\");
      oName = oName.replace("\"", "\\\"");
      String Rname = "girix.output[[\"" + oName + "\"]]"; // Name to access output variable in R
      REXP retVal = getOrEval(re, Rname, getEnv(), true);
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
  private String getType(String name) throws I2B2Exception, REngineException, REXPMismatchException {
    REXPLogical df = (REXPLogical) re.parseAndEval("is.data.frame(" + name + ")", getEnv(), true);
    REXPLogical mat = (REXPLogical) re.parseAndEval("is.matrix(" + name + ")", getEnv(), true);
    if (df == null || mat == null) {
      log.error("Error while getting type of output variable");
      throw new I2B2Exception("Error delivered from server: Determining data type of output variable");
    }
    // If it is a data.frame...
    if (df.isTRUE()[0]) {
      return "data.frame";
    } else if(mat.isTRUE()[0]) {
      return "matrix";
    } else {
      return "other";
    }
  }

  // Create HTML table code and a csv file if it is a table-like R type
  // Otherwise just return the result value as a string
  private String extractResult(String type, String name, String csvPath, String filename) throws I2B2Exception, REngineException, REXPMismatchException{
    if (type.equals("data.frame") || type.equals("matrix")) {
      // This is a workaround for a bug in xtable library (Date columns produce an error)
      // See http://stackoverflow.com/questions/8652674/r-xtable-and-dates for details
      REXP newFuncRet = re.parseAndEval("xtable <- function(x, ...) {\n" +
          "for (i in which(sapply(x, function(y) !all(is.na(match(c(\"POSIXt\",\"Date\"),class(y))))))) x[[i]] <- as.character(format(x[[i]], format=\"%Y-%m-%d %H:%M:%S\"))\n" +
          "xtable::xtable(x, ...)\n}\n", getEnv(), true);
      if (newFuncRet == null) {
        log.error("Error while creating function as xtable workaround.");
        throw new I2B2Exception("Error delivered from server: xtable workaround");
      }
      // Write csv file into the web directory
      // This workaround ensures that every DateTime has the same representation in the .csv file
      // (without this the time would be ommited if it is midnight)
      REXP transformRet = re.parseAndEval("girix.tmptable <- as.data.frame(lapply(" + name + ", function(x) if (is(x, \"POSIXt\")) format(x, \"%Y-%m-%d %H:%M:%S\") else x))", getEnv(), true);
      REXP csvRet = re.parseAndEval("write.table(girix.tmptable, file = \"" + csvPath + "/" + filename + ".csv\", append = FALSE, quote=which(sapply(" + name + ", function(x) !is.numeric(x) & !is(x, \"POSIXt\")))," +
          " sep = \",\", eol = \"\\r\\n\", na = \"NULL\", dec = \".\", row.names = FALSE, col.names = TRUE, qmethod=\"double\", fileEncoding = \"UTF-8\")", getEnv(), true);
      REXP rmTab = re.parseAndEval("rm(girix.tmptable)", getEnv(), true);
      if (transformRet == null || csvRet == null || rmTab == null) {
        log.error("Error while writing csv file for table " + name);
        throw new I2B2Exception("Error delivered from server: Writing csv file");
      }
      // Now create the HTML code of the table structure
      REXP ret = re.parseAndEval("paste(capture.output(print(xtable(" + name + "), type = \"html\")), collapse=\"\")", getEnv(), true);
      if (ret == null) {
        re.parseAndEval("write(\"Error while trying to create HTML code out of table " + name + " \n\", stderr())", getEnv(), true);
        return "undefined";
      }  
      return ret.asString();
    } else {
      REXP ret = re.parseAndEval("toString(" + name + ")", getEnv(), true);
      if (ret == null) {
        log.error("Error while extracting results (other)");
        throw new I2B2Exception("Error delivered from server: Extracting result value as string");
      }
      return ret.asString();
    }

  }

  public void doFinalRTasks(String webPath) throws I2B2Exception, REngineException, REXPMismatchException {

    // Create RImage directory if not existing
    File f = new File(webPath + "/RImage/");
    if ( ! f.exists()) {
      if (! f.mkdirs()) {
        log.error("Error while creating RImage directory");
        throw new I2B2Exception("Error while creating RImage directory");
      }
    }

    // Write plot files, write R workspace image and clear workspace
    REXP ret = re.parseAndEval("dev.off()", getEnv(), true);
    REXP ret2 = re.parseAndEval("save.image(file=\"" + webPath + "/RImage/RImage" + "\")", getEnv(), true);
    REXP ret3 = re.parseAndEval("rm(list = ls())", getEnv(), true);
    if (ret == null || ret2 == null || ret3 == null) {
      log.error("Error while doing final tasks");
      throw new I2B2Exception("Error delivered from server: Doing final R tasks");
    }
    // End R thread
    re.close();
  }
  
  private static REXP getOrEval(REngine rengine, String cmd, REXP where, boolean resolve) throws REngineException, REXPMismatchException {
	  REXP ret;
	  try {
    	  ret = rengine.parseAndEval(cmd, where, resolve);
      } catch(REngineEvalException e) {
    	  ret = rengine.get(cmd, where, resolve);
      }
	  return ret;
  }
  
  private REXP getEnv() {
	  return environments.get(sessionKey);
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
