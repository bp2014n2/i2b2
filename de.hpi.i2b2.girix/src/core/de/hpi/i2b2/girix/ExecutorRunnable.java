/*
 * Copyright (c) 2006-2007 Massachusetts General Hospital 
 * All rights reserved. This program and the accompanying materials 
 * are made available under the terms of the i2b2 Software License v1.0 
 * which accompanies this distribution. 
 * 
 * Contributors:
 *     Mike Mendis - initial API and implementation
 *     Bastian Weinlich - Adaption to GIRIXCell
 */

package de.hpi.i2b2.girix;

import de.hpi.i2b2.girix.datavo.i2b2message.RequestMessageType;
import edu.harvard.i2b2.common.exception.I2B2Exception;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

// This class is a modification of the ExecutorRunnable class of the PFTCell
/**
 * Implements thread runnable interface, to delegate the work to a handler
 */
public class ExecutorRunnable implements Runnable {
    private static Log log = LogFactory.getLog(ExecutorRunnable.class);
    private RequestMessageType input = null;
    private String outputString = null;
    private I2B2Exception ex = null;
    private boolean jobCompleteFlag = false;
    private RequestHandler handler;

    public RequestHandler getRequestHandler() {
    	return handler;
    }
    
    public void setRequestHandler(RequestHandler handler) {
    	this.handler = handler;
    }

    public boolean isJobCompleteFlag() {
        return jobCompleteFlag;
    }

    public void setJobCompleteFlag(boolean jobCompleteFlag) {
        this.jobCompleteFlag = jobCompleteFlag;
    }

    public I2B2Exception getJobException() {
        return ex;
    }
    
    public void setJobException(I2B2Exception ex) {
        this.ex = ex;
    }

    public RequestMessageType getInput() {
        return input;
    }

    public void setInput(RequestMessageType input) {
        this.input = input;
    }

    public String getOutputString() {
        return outputString;
    }

    public void setOutputString(String outputString) {
        this.outputString = outputString;
    }

    public void run() {
        log.debug("Worker thread started");
        try {
            outputString = handler.handleRequest(input);
            setJobCompleteFlag(true);
            log.debug("Worker thread finished");
        } catch (I2B2Exception e) {
            setJobException(e);
            setJobCompleteFlag(true);
        }

    }
}
