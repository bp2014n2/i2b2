/*
 * Copyright (c) 2006-2007 Massachusetts General Hospital 
 * All rights reserved. This program and the accompanying materials 
 * are made available under the terms of the i2b2 Software License v1.0 
 * which accompanies this distribution. 
 * 
 * Contributors:
 *     Mike Mendis - initial API and implementation
 *     Bastian Weinlich - Adaption to GIRICell
 */

package de.erlangen.i2b2.giri;

import de.erlangen.i2b2.giri.datavo.i2b2message.RequestMessageType;
import de.erlangen.i2b2.giri.datavo.i2b2message.ResponseMessageType;
import edu.harvard.i2b2.common.exception.I2B2Exception;

import org.apache.axiom.om.OMElement;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

// This class is a modification of the PFTService class of the main i2b2 project
// It is the entry point for the two possible GIRICell requests
public class GIRIService {
    private static Log log = LogFactory.getLog(GIRIService.class);
    
    // This method parses incoming getRScriptlets requests, checks the header and sets the appropriate handler
    public OMElement getRScriptlets(OMElement getRScriptletsDataElement) throws I2B2Exception {
    	
    	log.info("Incoming getRScriptlets request");
    	GIRIUtil.initializeGIRIUtil();
    	// Check for errors
		if (getRScriptletsDataElement == null) {
			log.error("Incoming request is null");
			ResponseMessageType responseMsgType = MessageUtil.doBuildErrorResponseMessageType(null, "Error message delivered from remote server: Incoming request is null");
			String giriDataResponse = MessageUtil.convertResponseMessageTypeToXML(responseMsgType);
			return MessageUtil.convertXMLToOMElement(giriDataResponse);
		}
    	// Convert request to RequestMessageType instance (jaxb)
		RequestMessageType msg = null;
		try {
			msg = MessageUtil.convertXMLTORequestMessageType(getRScriptletsDataElement.toString());
		} catch (I2B2Exception e) {
			log.error("Incoming XML request is invalid", e);
			ResponseMessageType responseMsgType = MessageUtil.doBuildErrorResponseMessageType(null, "Error message delivered from remote server: Incoming XML request is invalid");
			String giriDataResponse = MessageUtil.convertResponseMessageTypeToXML(responseMsgType);
			return MessageUtil.convertXMLToOMElement(giriDataResponse);
		}
		// Set appropriate handler
		RequestHandler handler = new GetRScriptletsRequestHandler();
		// Call execute to handle request in a new thread
		OMElement ret = execute(handler, msg);
		log.info("Outgoing getRScriptlets response");
		return ret;
    }
    
 // This method parses incoming getRResults requests, checks the header and sets the appropriate handler
    public OMElement getRResults(OMElement getRResultsDataElement) throws I2B2Exception {
    	
    	log.info("Incoming getRResults request");
    	GIRIUtil.initializeGIRIUtil();
    	// Check for errors
		if (getRResultsDataElement == null) {
			log.error("Incoming request is null");
			ResponseMessageType responseMsgType = MessageUtil.doBuildErrorResponseMessageType(null, "Error message delivered from remote server: Incoming request is null");
			String giriDataResponse = MessageUtil.convertResponseMessageTypeToXML(responseMsgType);
			return MessageUtil.convertXMLToOMElement(giriDataResponse);
		}
    	// Convert request to RequestMessageType instance (jaxb)
		RequestMessageType msg = null;
		try {
			msg = MessageUtil.convertXMLTORequestMessageType(getRResultsDataElement.toString());
		} catch (I2B2Exception e) {
			log.error("Incoming XML request is invalid", e);
			ResponseMessageType responseMsgType = MessageUtil.doBuildErrorResponseMessageType(null, "Error message delivered from remote server: Incoming XML request is invalid");
			String giriDataResponse = MessageUtil.convertResponseMessageTypeToXML(responseMsgType);
			return MessageUtil.convertXMLToOMElement(giriDataResponse);
		}
		// Set appropriate handler
		RequestHandler handler = new GetRResultsRequestHandler();
		// Call execute to handle request in a new thread
		OMElement ret = execute(handler, msg);
		log.info("Outgoing getRResults response");
		return ret;
    }
    
    // This method delegates the request processing to a new thread while stopping the time to a given timeout
    // If the thread hasn't finished until timeout or another error (Exception) occurred during processing, an error response message will be created
	private OMElement execute(RequestHandler handler, RequestMessageType message) throws I2B2Exception {
		
		// Extract wait time. If no waitTime is given it defaults to 0 which is equivalent to an infinite waitTime
		long waitTime = 0;
		if (message.getRequestHeader() != null) {
			waitTime = message.getRequestHeader().getResultWaittimeMs();
		}
		
		// Do query processing inside thread, so that service could send back message with timeout error
		String unknownErrorMessage = "Error message delivered from the remote server: Unknown exception. See log file for stack trace.";
		ExecutorRunnable er = new ExecutorRunnable();
		er.setInput(message);
		er.setRequestHandler(handler);
		Thread t = new Thread(er);
		String giriDataResponse = null;
		// Start thread...
		synchronized (t) {
			t.start();
			// ...meanwhile in main thread: count time and check for timeout
			try {
				long startTime = System.currentTimeMillis();
				long deltaTime = -1;
				while ((er.isJobCompleteFlag() == false) && (deltaTime < waitTime)) {
					if (waitTime > 0) {
						t.wait(waitTime - deltaTime);
						deltaTime = System.currentTimeMillis() - startTime;
					} else {
						// wait until job is completed
						t.wait();
					}
				}
				// Now try to extract the result...
				giriDataResponse = er.getOutputString();
				// ...which is null if there was an error
				if (giriDataResponse == null) {
					// Error case 1: There was an exception during thread execution
					if (er.getJobException() != null) {
						// Error case 1.1: Causing exception was set -> Default unknown error message & logging stack trace
						if (er.getJobException().getCause() != null) {
							log.error("Exception stack trace:\n" + GIRIUtil.getStackTraceAsString(er.getJobException()));
							ResponseMessageType responseMsgType = MessageUtil.doBuildErrorResponseMessageType(null, unknownErrorMessage);
							giriDataResponse = MessageUtil.convertResponseMessageTypeToXML(responseMsgType);
						} else {
						// Error case 1.2: Causing exception wasn't set -> Custom error message. Logging is done by throwing method
							ResponseMessageType responseMsgType = MessageUtil.doBuildErrorResponseMessageType(null, er.getJobException().getMessage());
							giriDataResponse = MessageUtil.convertResponseMessageTypeToXML(responseMsgType);
						}
					// Error case 2: Timeout
					} else if (er.isJobCompleteFlag() == false) {
						String timeOuterror = "Remote server timed out \nResult waittime = " + waitTime + " ms elapsed\nPlease try again";
						log.error(timeOuterror);
						log.debug("giri waited " + deltaTime + "ms for " + er.getRequestHandler().getClass().getName());
						ResponseMessageType responseMsgType = MessageUtil.doBuildErrorResponseMessageType(null, timeOuterror);
						giriDataResponse = MessageUtil.convertResponseMessageTypeToXML(responseMsgType);
					// Error case 3: Result was set to null by the thread
					} else {
						log.error("giri data response is null");
						log.debug("giri waited " + deltaTime + "ms for " + er.getRequestHandler().getClass().getName());
						ResponseMessageType responseMsgType = MessageUtil.doBuildErrorResponseMessageType(null, "Error message delivered from the remote server: Result was set to null.");
						giriDataResponse = MessageUtil.convertResponseMessageTypeToXML(responseMsgType);
					}
				}
			} catch (InterruptedException e) {
				log.error(e.getMessage());
				throw new I2B2Exception("Thread error while running GIRI job");
			} finally {
				t.interrupt();
				er = null;
				t = null;
			}
		}
		// Send back answer. giriDataResponse contains either an error message or the proper response if there was no critical error
		return MessageUtil.convertXMLToOMElement(giriDataResponse);
	}
}
