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
import org.rosuda.REngine.REXPLogical;
import org.rosuda.REngine.REXPMismatchException;
import org.rosuda.REngine.REngine;
import org.rosuda.REngine.REngineEvalException;
import org.rosuda.REngine.REngineException;
import org.rosuda.REngine.Rserve.RConnection;

import edu.harvard.i2b2.common.exception.I2B2Exception;
import de.hpi.i2b2.girix.GIRIXUtil;

// This class interacts directly with JRI (Java R Interface) library
public class JRIProcessor {

  private static Log log = LogFactory.getLog(JRIProcessor.class);
  private RConnection re = null;
  private static StringBuffer Routput;
  private static StringBuffer Rerrors;
  private static final int port = 6311;
  private static final String url = "127.0.0.1";
  
  public JRIProcessor() throws I2B2Exception {
	  initializeR();
	    
	    // Look if there's an existing R engine...
	    try {
			re = new RConnection(url, port);
		} catch (REngineException e) {
			throw new I2B2Exception("Rserve not listening or connection refused");
		}
	    /*// If not create a new one
	    if (re == null) {
	      log.info("Creating new R engine");
	      // Create new R engine but don't start main loop immediately (second argument)
	      re = (JRIEngine) JRIEngine.createEngine(args, new ScriptExecutorCallbackClass(), false);
	    } else {
	      log.info("R engine already exists");
	    }   */ 

	    // Load required R package 'xtable'
	    try {
			re.voidEval("library(xtable)");
		} catch (REngineException e) {
			throw new I2B2Exception("Package 'xtable' not installed");
		}
  }

  public static void initializeR() throws I2B2Exception {

    // Set some system settings that are required for running R
    //GIRIXUtil.setUpREnvironment();

    // Make sure we have the right version of everything
//    boolean versionOK = Rengine.versionCheck();
//    if (!versionOK) {
//      log.error("R version error");
//      throw new I2B2Exception("Error delivered from server: R version error");
//    }

    // Don't do/show unnecessary things (save/restore workspace etc.)
    //String[] args = {"--vanilla", "-q"};
    log.info("Starting R...");

    if(!RserveSpawner.checkLocalRserve(port)) throw new I2B2Exception("Rserve failed to start");
  }

  // Do some preparation inside the R session for later output (plots, csvs, variables)
  public File prepare(String webDirPath) throws I2B2Exception {

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
    try {
    	re.voidEval("svg(\"" + plotDirPath + "/plot%03d.svg\")");
    }
    catch (REngineException e) {
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
    try {
    	re.voidEval("girix.patients <- c()");
	    re.voidEval("girix.observations <- c()");
	    re.voidEval("girix.input <- c()");
	    re.voidEval("girix.output <- list()");
	    re.voidEval("girix.concept.names <- c()");
	    re.voidEval("girix.modifiers <- c()");
	    re.voidEval("girix.events <- c()");
	    re.voidEval("girix.observers <- c()");
    }
    catch (REngineException e) {
      log.error("Error with setting up new vectors in R");
      throw new I2B2Exception("Error delivered from server: Creating vectors");
    } 

    // ========= Handling dates and times =========
    // Define an i2b2 DateTime Class, a helper function and a conversion function for the database DateTime string
    // -> Time is also considered
    try {
		re.voidEval("setClass(\"i2b2DateTime\")");
		re.assign("girix.swapPlusMinus", "function(x) if (!is.na(x)){if(x==\"-\") {\"+\"} else {\"-\"}}");
		re.voidEval("setAs(\"character\",\"i2b2DateTime\", function(from){do.call(c,lapply(from, function(x) {as.POSIXlt(x, tz = paste(\"GMT\", girix.swapPlusMinus(substr(x,24,24)), substr(x,26,26), sep=\"\"), format=\"%Y-%m-%dT%H:%M:%S\")}))})");
	} catch (REngineException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
    return f;
  }

  // Read in patient data
  public void readDataFrameFromString(String name, GIRIXCSVContainer s, String colClasses) throws I2B2Exception {
    // Uncomment for debugging purposes
    // log.info(name + "\n\n" + s.getString());

    // Case: No data available -> Initialize empty data.frame (read.table would cause an error otherwise) and return
    if (!s.hasData()) {
      String initStr = s.getString().replace(GIRIXUtil.SEP, "=character(),");
      initStr = initStr.concat("=character()");
      try {
		re.assign(name, "data.frame(" + initStr +  ")");
      } catch (REngineException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
      }
      return;
    }
    try {
		re.assign("tmp", s.getString());
	} catch (REngineException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	}
    try {
    	re.assign(name, "read.table(textConnection(tmp), sep=\"" + GIRIXUtil.SEP + "\", header=T, row.names=NULL, quote=\"\\\"\"," +
        "colClasses = " + colClasses + ", na.string=c(\"\"))");
    }
    catch (REngineException e) {
      log.error("Error reading in patient data into data.frame " + name);
      throw new I2B2Exception("Error delivered from server: Reading in patient data");
    } 
    try {
		re.voidEval("rm(tmp)");
	} catch (REngineException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
  }

  // Assign additional input parameters in R
  public void assignAdditionalInput(Map<String, String> m) throws I2B2Exception {
    // Assign additional input variables as strings
    for (Map.Entry<String, String> entry : m.entrySet()) {
      // Do some replacements in order to prevent errors and security flaws
      String key = entry.getKey().replace("\\", "\\\\");
      key = key.replace("\"", "\\\"");
      String value = entry.getValue().replace("\\", "\\\\");
      value = value.replace("\"", "\\\"");
      try {
    	  re.voidEval("girix.input[\"" + key + "\"] <- \"" + value + "\"");
      }
      catch (REngineException e) {
        log.error("Error assigning additional inputs");
        throw new I2B2Exception("Error delivered from server: Reading in additional input values");	
      }
    }
  }

  // Make the names of the chosen concepts visible in R
  public void assignConceptNames(String[] names) {
    for (int i = 0; i < names.length; i++) {
      String sanitized = names[i].replace("\\", "\\\\");
      sanitized = sanitized.replace("\"", "\\\"");
      try {
		re.voidEval("girix.concept.names[" + (i+1) + "] <- \"" + sanitized + "\"");
      } catch (REngineException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
      }
    }
  }

  public void setWorkingDirectory(String scriptletDirectoryPath) {
		
	  try {
		re.voidEval("setwd(\"" + scriptletDirectoryPath + "\")");
	  } catch (REngineException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	  }
		
  }

  public void executeRScript(String scriptPath) throws I2B2Exception {
	  try {
		  re.parseAndEval("source(\"" + scriptPath + "\", local=TRUE)");
	  } catch (REngineException | REXPMismatchException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	  }
  }

  public List<GIRIXOutputVariable> getOutputVariables(List<String[]> outputParametersList, String webPath) throws I2B2Exception {
    // Array has 4 elements: Name, description, type, value
    List<GIRIXOutputVariable> l = new LinkedList<GIRIXOutputVariable>();

    // Get default output variables
    int i = 1;
    
    try {
    	while(true) {
	      getOrEval(re, "girix.output." + i);
	      String name = "girix.output." + (i); // Default name
	      GIRIXOutputVariable oV = new GIRIXOutputVariable(name, "", getType(name), extractResult(name, webPath + "/csv", name));
	      l.add(oV);
	      i++;
	    }
    } catch(REXPMismatchException e) {
    	// TODO Auto-generated catch block
    	e.printStackTrace();
    } catch (REngineException e) {
    	//Ignore because an exception will be thrown anyway
    }

    // Get custom (user defined) output variables
    for (String[] oElement : outputParametersList) {
      try {
          // Replacements to prevent errors / security flaws
          String oName = oElement[0].replace("\\", "\\\\");
          oName = oName.replace("\"", "\\\"");
          String Rname = "girix.output[[\"" + oName + "\"]]"; // Name to access output variable in R
    	  getOrEval(re, Rname);
    	  GIRIXOutputVariable oV = new GIRIXOutputVariable(
    			  oElement[0],
    			  oElement[1],
    			  getType(Rname),
    			  extractResult(Rname, webPath + "/csv", oName)
    	  );
          l.add(oV);
      }
      catch (REngineException | REXPMismatchException e) {
    	// TODO Auto-generated catch block
      	e.printStackTrace();
      }
    }

    return l;
  }

  // Check if output is table-like
  private String getType(String name) throws I2B2Exception {
    try {
    	REXPLogical df = (REXPLogical) re.parseAndEval("is.data.frame(" + name + ")");
    	REXPLogical mat = (REXPLogical) re.parseAndEval("is.matrix(" + name + ")");
        // If it is a data.frame...
        if (df.isTRUE()[0]) {
          return "data.frame";
        } else if(mat.isTRUE()[0]) {
          return "matrix";
        } else {
          return "other";
        }
    }
    catch (REngineException | REXPMismatchException e) {
      log.error("Error while getting type of output variable");
      throw new I2B2Exception("Error delivered from server: Determining data type of output variable");
    }
  }

  // Create HTML table code and a csv file if it is a table-like R type
  // Otherwise just return the result value as a string
  private String extractResult(String name, String csvPath, String filename) throws I2B2Exception {
      String type = getType(name);
	  if (type.equals("data.frame") || type.equals("matrix")) {
      // This is a workaround for a bug in xtable library (Date columns produce an error)
      // See http://stackoverflow.com/questions/8652674/r-xtable-and-dates for details
      try {
    	  re.assign("xtable", "function(x, ...) {\n" +
          "for (i in which(sapply(x, function(y) !all(is.na(match(c(\"POSIXt\",\"Date\"),class(y))))))) x[[i]] <- as.character(format(x[[i]], format=\"%Y-%m-%d %H:%M:%S\"))\n" +
          "xtable::xtable(x, ...)\n}\n");
      }
      catch (REngineException e) {
        log.error("Error while creating function as xtable workaround.");
        throw new I2B2Exception("Error delivered from server: xtable workaround");
      }
      // Write csv file into the web directory
      // This workaround ensures that every DateTime has the same representation in the .csv file
      // (without this the time would be ommited if it is midnight)
      try {
    	  re.assign("girix.tmptable", "as.data.frame(lapply(" + name + ", function(x) if (is(x, \"POSIXt\")) format(x, \"%Y-%m-%d %H:%M:%S\") else x))");
    	  re.voidEval("write.table(girix.tmptable, file = \"" + csvPath + "/" + filename + ".csv\", append = FALSE, quote=which(sapply(" + name + ", function(x) !is.numeric(x) & !is(x, \"POSIXt\")))," +
    			  " sep = \",\", eol = \"\\r\\n\", na = \"NULL\", dec = \".\", row.names = FALSE, col.names = TRUE, qmethod=\"double\", fileEncoding = \"UTF-8\")");
    	  re.voidEval("rm(girix.tmptable)");
      }
      catch (REngineException e) {
        log.error("Error while writing csv file for table " + name);
        throw new I2B2Exception("Error delivered from server: Writing csv file");
      }
      // Now create the HTML code of the table structure
      try {
		REXP ret = re.parseAndEval("paste(capture.output(print(xtable(" + name + "), type = \"html\")), collapse=\"\")");
		return ret.asString();
      } catch (REngineException | REXPMismatchException e) {
    	try {
			re.voidEval("write(\"Error while trying to create HTML code out of table " + name + " \n\", stderr())");
		} catch (REngineException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
		return "undefined";
      }
    } else {
      try {
    	  REXP ret = re.parseAndEval("toString(" + name + ")");
          return ret.asString();
      }
      catch (REngineException | REXPMismatchException e) {
        log.error("Error while extracting results (other)");
        throw new I2B2Exception("Error delivered from server: Extracting result value as string");
      }
    }

  }

  public void doFinalRTasks(String webPath) throws I2B2Exception {

    // Create RImage directory if not existing
    File f = new File(webPath + "/RImage/");
    if ( ! f.exists()) {
      if (! f.mkdirs()) {
        log.error("Error while creating RImage directory");
        throw new I2B2Exception("Error while creating RImage directory");
      }
    }

    // Write plot files, write R workspace image and clear workspace
    try {
    	re.voidEval("dev.off()");
    	re.voidEval("save.image(file=\"" + webPath + "/RImage/RImage" + "\")");
    	re.voidEval("rm(list = ls())");
    }
    catch (REngineException e) {
      log.error("Error while doing final tasks");
      throw new I2B2Exception("Error delivered from server: Doing final R tasks");
    }
    // End R thread
    re.close();
  }
  
  private static REXP getOrEval(REngine rengine, String cmd) throws REngineException, REXPMismatchException {
	  REXP ret;
	  try {
    	  ret = rengine.parseAndEval(cmd);
      } catch(REngineEvalException e) {
    	  ret = rengine.get(cmd, null, true);
      }
	  return ret;
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
