/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */
package de.erlangen.i2b2.giri.test;

import de.erlangen.i2b2.giri.GIRIService;
import de.erlangen.i2b2.giri.GIRIUtil;

import org.apache.axiom.om.OMElement;
import org.apache.axiom.om.impl.builder.StAXOMBuilder;

import org.apache.axis2.Constants;
import org.apache.axis2.addressing.EndpointReference;
import org.apache.axis2.client.Options;
import org.apache.axis2.client.ServiceClient;

import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.StringReader;
import java.util.Properties;

import javax.xml.stream.FactoryConfigurationError;
import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamReader;

// Class to test GIRI Cell locally

/*
 * Important: Before using this testing program, make sure that the additional properties in the build.properties
 * file are filled correctly!
 */
public class GIRIServiceRESTTest {
	
	// Local method call or request to the deployed service
    private static boolean local;
    // Path to build.properties file
	private static String BUILDPROPERTIES;
    
	// Testing method
    public static void main(String[] args) throws Exception {
    	if (args.length != 1) {
    		System.err.println("Please specify only the first command line parameter as path to build.properties file");
    		return;
    	}
    	BUILDPROPERTIES = args[0];
    	
    	// Modify as desired!
    		// true: Read in sample XML as request and call method locally (program runs outside jboss!)
    		// false: Read in sample XML as request and send it to a running (= deployed in running jboss) GIRI cell on giri.webservice.url
    	local = true;
    	
    	// Configure program for local testing
    	if (local) {
    		GIRIUtil.setTestingmodeON(args[0]);
    	}
    	
    	// Choose one of the requests
    	sendRResultsRequest();
    	// sendRScriptletsRequest();
    }
	
    // Read in XML file and create OMElement
    public static OMElement getPayLoad(String requestpath) {
    	    	
    	// Get a reader
        BufferedReader reader = null;
        try {
        	reader = new BufferedReader(new InputStreamReader(new DataInputStream(new FileInputStream(requestpath))));
        } catch (FileNotFoundException e) {
        	System.err.println("File at " + requestpath + " does not exist.");
        	System.exit(1);
        }
        
        // Read in file
        StringBuffer queryStrBuffer = new StringBuffer();
        String singleLine = null;
        try {
			while ((singleLine = reader.readLine()) != null) {
			    queryStrBuffer.append(singleLine + "\n");
			}
		} catch (IOException e1) {
			e1.printStackTrace();
		}
        String queryStr = queryStrBuffer.toString();
    	
        // Create OMElement from XML string
        OMElement ret = null;
        try {
            StringReader strReader = new StringReader(queryStr);
            XMLInputFactory xif = XMLInputFactory.newInstance();
            XMLStreamReader xmlreader = xif.createXMLStreamReader(strReader);

            StAXOMBuilder builder = new StAXOMBuilder(xmlreader);
            ret = builder.getDocumentElement();

        } catch (FactoryConfigurationError e) {
            e.printStackTrace();
        } catch (XMLStreamException e) {
			e.printStackTrace();
		}

        return ret;
    }
    
    public static void sendRScriptletsRequest() throws Exception {
    	Properties prop = new Properties();
    	prop.load(new FileInputStream(BUILDPROPERTIES));


    	OMElement request = getPayLoad(prop.getProperty("sample.xml.request"));
    	System.out.println("Request:\n" + request.toString());
            
    	OMElement result = null;
    	if (local) {
    			// Just call the service method
            	GIRIService ps = new GIRIService();
            	result = ps.getRScriptlets(request); 
    	} else {
        	EndpointReference targetEPR = new EndpointReference(prop.getProperty("giri.webservice.url") + "/getRScriptlets");
            	Options options = new Options();
            	options.setTo(targetEPR);
            	options.setTransportInProtocol(Constants.TRANSPORT_HTTP);
            	options.setProperty(Constants.Configuration.ENABLE_REST, Constants.VALUE_TRUE);
            	options.setTimeOutInMilliSeconds(5);

            	ServiceClient sender = new ServiceClient();
            	sender.setOptions(options);
            	// Send webservice request
            	result = sender.sendReceive(request); 
    	}
			
    	if (result == null) {
                System.out.println("Result is null");
    	} else {
                String response = result.toString();
                System.out.println("Response:\n" + response);
    	} 
    }
    
    public static void sendRResultsRequest() throws Exception {
    	Properties prop = new Properties();
    	prop.load(new FileInputStream(BUILDPROPERTIES));


    	OMElement request = getPayLoad(prop.getProperty("sample.xml.request"));
    	System.out.println("Request:\n" + request.toString());
            
    	OMElement result = null;
    	if (local) {
    			// Just call the service method
            	GIRIService ps = new GIRIService();
            	result = ps.getRResults(request); 
    	} else {
        	EndpointReference targetEPR = new EndpointReference(prop.getProperty("giri.webservice.url") + "/getRResults");
            	Options options = new Options();
            	options.setTo(targetEPR);
            	options.setTransportInProtocol(Constants.TRANSPORT_HTTP);
            	options.setProperty(Constants.Configuration.ENABLE_REST, Constants.VALUE_TRUE);
            	options.setTimeOutInMilliSeconds(180000);

            	ServiceClient sender = new ServiceClient();
            	sender.setOptions(options);
            	// Send webservice request
            	result = sender.sendReceive(request); 
    	}
			
    	if (result == null) {
                System.out.println("Result is null");
    	} else {
               String response = result.toString();
               System.out.println("Response:\n" + response);
    	} 
    }
    
}


