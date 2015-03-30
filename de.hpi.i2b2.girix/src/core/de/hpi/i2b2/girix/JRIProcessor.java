/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */
package de.hpi.i2b2.girix;

import java.io.*;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.rosuda.REngine.REXP;
import org.rosuda.REngine.REXPMismatchException;
import org.rosuda.REngine.REngineException;
import org.rosuda.REngine.JRI.JRIEngine;

import edu.harvard.i2b2.common.exception.I2B2Exception;
import de.hpi.i2b2.girix.GIRIXUtil;

// This class interacts directly with JRI (Java R Interface) library
public class JRIProcessor {

  private static Log log = LogFactory.getLog(JRIProcessor.class);
  private static JRIEngine re = null;
  private static StringBuffer Routput;
  private static StringBuffer Rerrors;

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
    JRIEngine.getLastEngine();
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
    re.eval(re.parse("library(xtable)", false), null, true);
    re.eval(re.parse("setwd('" + GIRIXUtil.getRSCRIPTLETPATH() + "')", false), null, true);
  }

  // Do some preparation inside the R session for later output (plots, csvs, variables)
  public static File prepare(String webDirPath) throws I2B2Exception, REngineException, REXPMismatchException {

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
    REXP ret = re.eval(re.parse("svg(\"" + plotDirPath + "/plot%03d.svg\")", false), null, true);
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
    REXP ret2 = re.eval(re.parse("girix.patients <- c()", false), null, true);
    REXP ret3 = re.eval(re.parse("girix.observations <- c()", false), null, true);
    REXP ret4 = re.eval(re.parse("girix.input <- c()", false), null, true);
    REXP ret5 = re.eval(re.parse("girix.output <- list()", false), null, true);
    REXP ret6 = re.eval(re.parse("girix.concept.names <- c()", false), null, true);
    REXP ret7 = re.eval(re.parse("girix.modifiers <- c()", false), null, true);
    REXP ret8 = re.eval(re.parse("girix.events <- c()", false), null, true);
    REXP ret9 = re.eval(re.parse("girix.observers <- c()", false), null, true);
    if (ret2 == null || ret3 == null || ret4 == null || ret5 == null || ret6 == null || ret7 == null || ret8 == null || ret9 == null) {
      log.error("Error with setting up new vectors in R");
      throw new I2B2Exception("Error delivered from server: Creating vectors");
    } 

    // ========= Handling dates and times =========
    // Define an i2b2 DateTime Class, a helper function and a conversion function for the database DateTime string
    // -> Time is also considered
    re.eval(re.parse("setClass(\"i2b2DateTime\")", false), null, true);
    re.eval(re.parse("girix.swapPlusMinus <- function(x) if (!is.na(x)){if(x==\"-\") {\"+\"} else {\"-\"}}", false), null, true);
    re.eval(re.parse("setAs(\"character\",\"i2b2DateTime\", function(from){do.call(c,lapply(from, function(x) {as.POSIXlt(x, tz = paste(\"GMT\", girix.swapPlusMinus(substr(x,24,24)), substr(x,26,26), sep=\"\"), format=\"%Y-%m-%dT%H:%M:%S\")}))})", false), null, true);
    return f;
  }

  // Read in patient data
  public static void readDataFrameFromString(String name, GIRIXCSVContainer s, String colClasses) throws I2B2Exception, REngineException, REXPMismatchException {
    // Uncomment for debugging purposes
    // log.info(name + "\n\n" + s.getString());

    // Case: No data available -> Initialize empty data.frame (read.table would cause an error otherwise) and return
    if (!s.hasData()) {
      String initStr = s.getString().replace(GIRIXUtil.SEP, "=character(),");
      initStr = initStr.concat("=character()");
      re.eval(re.parse(name + " <- data.frame(" + initStr +  ")", false), null, true);
      return;
    }
    re.assign("tmp", s.getString());
    REXP ret = re.eval(re.parse(name + " <- read.table(textConnection(tmp), sep=\"" + GIRIXUtil.SEP + "\", header=T, row.names=NULL, quote=\"\\\"\"," +
        "colClasses = " + colClasses + ", na.string=c(\"\"))", false), null, true);
    if (ret == null) {
      log.error("Error reading in patient data into data.frame " + name);
      throw new I2B2Exception("Error delivered from server: Reading in patient data");
    } 
    re.eval(re.parse("rm(tmp)", false), null, true);
  }

  // Assign additional input parameters in R
  public static void assignAdditionalInput(Map<String, String> m) throws I2B2Exception, REngineException, REXPMismatchException {
    // Assign additional input variables as strings
    for (Map.Entry<String, String> entry : m.entrySet()) {
      // Do some replacements in order to prevent errors and security flaws
      String key = entry.getKey().replace("\\", "\\\\");
      key = key.replace("\"", "\\\"");
      String value = entry.getValue().replace("\\", "\\\\");
      value = value.replace("\"", "\\\"");
      REXP ret = re.eval(re.parse("girix.input[\"" + key + "\"] = \"" + value + "\"", false), null, true);
      if (ret == null) {
        log.error("Error assigning additional inputs");
        throw new I2B2Exception("Error delivered from server: Reading in additional input values");	
      }
    }
  }

  // Make the names of the chosen concepts visible in R
  public static void assignConceptNames(String[] names) throws REngineException, REXPMismatchException {
    for (int i = 0; i < names.length; i++) {
      String sanitized = names[i].replace("\\", "\\\\");
      sanitized = sanitized.replace("\"", "\\\"");
      re.eval(re.parse("girix.concept.names[" + (i+1) + "] <- \"" + sanitized + "\"", false), null, true);
    }
  }

  public static void executeRScript(String scriptPath) throws I2B2Exception, REngineException, REXPMismatchException {
    re.eval(re.parse("source(\"" + scriptPath + "\")", false), null, true);
  }

  public static List<String[]> getOutputVariables(List<String[]> outputParametersList, String webPath) throws I2B2Exception, REngineException, REXPMismatchException {
    // Array has 4 elements: Name, description, type, value
    List<String[]> l = new LinkedList<String[]>();

    // Get default output variables
    REXP ret = re.get("girix.output.1", null, true);
    for (int i = 2; ret != null; i++) {
      String name = "girix.output." + (i-1); // Default name
      String[] array = new String[4];
      array[0] = name;
      array[1] = ""; // Default output variables don't have descriptions
      array[2] = getType(name);
      array[3] = extractResult(array[2], name, webPath + "/csv", name);
      l.add(array);
      ret = re.get("girix.output." + i, null, true);
    }

    // Get custom (user defined) output variables
    for (String[] oElement : outputParametersList) {
      // Replacements to prevent errors / security flaws
      String oName = oElement[0].replace("\\", "\\\\");
      oName = oName.replace("\"", "\\\"");
      String Rname = "girix.output[[\"" + oName + "\"]]"; // Name to access output variable in R
      REXP retVal = re.get(Rname, null, true);
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
  private static String getType(String name) throws I2B2Exception, REngineException, REXPMismatchException {
    REXP df = re.eval(re.parse("is.data.frame(" + name + ")", false), null, true);
    REXP mat = re.eval(re.parse("is.matrix(" + name + ")", false), null, true);
    if (df == null || mat == null) {
      log.error("Error while getting type of output variable");
      throw new I2B2Exception("Error delivered from server: Determining data type of output variable");
    }
    // If it is a data.frame...
    if (df.asInteger() == 1) {
      return "data.frame";
    } else if(mat.asInteger() == 1) {
      return "matrix";
    } else {
      return "other";
    }
  }

  // Create HTML table code and a csv file if it is a table-like R type
  // Otherwise just return the result value as a string
  private static String extractResult(String type, String name, String csvPath, String filename) throws I2B2Exception, REngineException, REXPMismatchException{
    if (type.equals("data.frame") || type.equals("matrix")) {
      // This is a workaround for a bug in xtable library (Date columns produce an error)
      // See http://stackoverflow.com/questions/8652674/r-xtable-and-dates for details
      REXP newFuncRet = re.eval(re.parse("xtable <- function(x, ...) {\n" +
          "for (i in which(sapply(x, function(y) !all(is.na(match(c(\"POSIXt\",\"Date\"),class(y))))))) x[[i]] <- as.character(format(x[[i]], format=\"%Y-%m-%d %H:%M:%S\"))\n" +
          "xtable::xtable(x, ...)\n}\n", false), null, true);
      if (newFuncRet == null) {
        log.error("Error while creating function as xtable workaround.");
        throw new I2B2Exception("Error delivered from server: xtable workaround");
      }
      // Write csv file into the web directory
      // This workaround ensures that every DateTime has the same representation in the .csv file
      // (without this the time would be ommited if it is midnight)
      REXP transformRet = re.eval(re.parse("girix.tmptable <- as.data.frame(lapply(" + name + ", function(x) if (is(x, \"POSIXt\")) format(x, \"%Y-%m-%d %H:%M:%S\") else x))", false), null, true);
      REXP csvRet = re.eval(re.parse("write.table(girix.tmptable, file = \"" + csvPath + "/" + filename + ".csv\", append = FALSE, quote=which(sapply(" + name + ", function(x) !is.numeric(x) & !is(x, \"POSIXt\")))," +
          " sep = \",\", eol = \"\\r\\n\", na = \"NULL\", dec = \".\", row.names = FALSE, col.names = TRUE, qmethod=\"double\", fileEncoding = \"UTF-8\")", false), null, true);
      REXP rmTab = re.eval(re.parse("rm(girix.tmptable)", false), null, true);
      if (transformRet == null || csvRet == null || rmTab == null) {
        log.error("Error while writing csv file for table " + name);
        throw new I2B2Exception("Error delivered from server: Writing csv file");
      }
      // Now create the HTML code of the table structure
      REXP ret = re.eval(re.parse("paste(capture.output(print(xtable(" + name + "), type = \"html\")), collapse=\"\")", false), null, true);
      if (ret == null) {
        re.eval(re.parse("write(\"Error while trying to create HTML code out of table " + name + " \n\", stderr())", false), null, true);
        return "undefined";
      }  
      return ret.asString();
    } else {
      REXP ret = re.eval(re.parse("toString(" + name + ")", false), null, true);
      if (ret == null) {
        log.error("Error while extracting results (other)");
        throw new I2B2Exception("Error delivered from server: Extracting result value as string");
      }
      return ret.asString();
    }

  }

  public static void doFinalRTasks(String webPath) throws I2B2Exception, REngineException, REXPMismatchException {

    // Create RImage directory if not existing
    File f = new File(webPath + "/RImage/");
    if ( ! f.exists()) {
      if (! f.mkdirs()) {
        log.error("Error while creating RImage directory");
        throw new I2B2Exception("Error while creating RImage directory");
      }
    }

    // Write plot files, write R workspace image and clear workspace
    REXP ret = re.eval(re.parse("dev.off()", false), null, true);
    String cmd = "save.image(file=\"" + webPath + "/RImage/RImage" + "\")";
    re.eval(re.parse(cmd, false), null, true);
    re.get("rm(list = ls())", null, true);
    if (ret == null) {
      log.error("Error while doing final tasks");
      throw new I2B2Exception("Error delivered from server: Doing final R tasks");
    }
    // End R thread
    re.close();
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
