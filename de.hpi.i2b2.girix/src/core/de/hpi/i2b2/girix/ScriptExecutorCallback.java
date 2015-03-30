package de.hpi.i2b2.girix;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.rosuda.REngine.REngine;
import org.rosuda.REngine.REngineCallbacks;
import org.rosuda.REngine.REngineConsoleHistoryInterface;
import org.rosuda.REngine.REngineInputInterface;
import org.rosuda.REngine.REngineOutputInterface;
import org.rosuda.REngine.REngineUIInterface;

//This class defines callback methods that are called by the main loop of R if a certain event occurs
class ScriptExecutorCallbackClass implements
REngineCallbacks,
REngineConsoleHistoryInterface,
REngineOutputInterface,
REngineInputInterface,
REngineUIInterface {	

	private static Log log = LogFactory.getLog(ScriptExecutorCallbackClass.class);
	
	// If R writes something to the console this method will be called
	public synchronized void RWriteConsole(REngine eng, String text, int oType) {
	  // Normal output
	  if (oType == 0) {
	    log.info("Output from R (normal): " + text);
	    JRIProcessor.appendROutput(text);
	    // Error output
	  } else {
	    log.info("Output from R (error): " + text);
	    // Do not send back the error 'Error: object 'girix.output.x' not found' because this 'error' appears every time
	    // when looking for the last set output variable (see method getOutputVariables). So it's not an error but the normal case.
	    // To prevent confusion, this error output is omitted
	    if ( !(text.contains("Error: object 'girix.output.") && text.contains("not found")) ) {
	      JRIProcessor.appendRErrors(text);
	      // Give a hint to the possible cause of this common error
	      if (text.contains("data length exceeds size of matrix")) {
	        JRIProcessor.appendRErrors("Possible cause: Trying to access an empty data.frame\n");
	      }
	    }
	  }
	}
	
	// Following events have no influence at all. So they're just logged
	public void RBusyState(REngine re, int which) {
	  log.info("rBusy called");
	}
	
	public void RFlushConsole (REngine re) {
	  log.info("rFlushConsole called");
	}
	
	// An R "message" is counted as normal R output
	public void RShowMessage(REngine re, String message) {
	  log.info("Message from R: " + message);
	  JRIProcessor.appendROutput("R message: " + message);
	}
	
	// Some R methods cause events, that aren't supported by this program like choosing a file interactively via a GUI window
	// Hence the R script could be buggy -> The user is warned by a message
	public String RChooseFile(REngine re, boolean newFile) {
	  log.error("rChooseFile called");
	  JRIProcessor.appendRErrors("GIRIX-Warning: Forbidden R method (choose file) called. Please check your R script");
	  return "";
	}
	
	public String RReadConsole(REngine re, String prompt, int addToHistory) {
	  log.info("rReadConsole called");
	  JRIProcessor.appendRErrors("GIRIX-Warning: Forbidden R method (read from console) called. Please check your R script");
	  return null;
	}
	
	public void RLoadHistory (REngine re, String filename) {
	  log.error("rLoadHistory called");
	  JRIProcessor.appendRErrors("GIRIX-Warning: Forbidden R method (load history) called. Please check your R script");
	}			
	
	public void RSaveHistory (REngine re, String filename) {
	  log.error("rSaveHistory called");
	  JRIProcessor.appendRErrors("GIRIX-Warning: Forbidden R method (save history) called. Please check your R script");
	}		
}