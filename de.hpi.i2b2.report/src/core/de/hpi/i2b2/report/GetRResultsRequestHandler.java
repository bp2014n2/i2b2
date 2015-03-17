/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */
package de.hpi.i2b2.report;


import java.io.File;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import org.apache.axiom.om.OMElement;
import org.apache.axis2.AxisFault;
import org.apache.axis2.Constants;
import org.apache.axis2.addressing.EndpointReference;
import org.apache.axis2.client.Options;
import org.apache.axis2.client.ServiceClient;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.xml.sax.SAXException;

import de.hpi.i2b2.report.datavo.i2b2message.BodyType;
import de.hpi.i2b2.report.datavo.i2b2message.MessageHeaderType;
import de.hpi.i2b2.report.datavo.i2b2message.RequestHeaderType;
import de.hpi.i2b2.report.datavo.i2b2message.RequestMessageType;
import de.hpi.i2b2.report.datavo.i2b2message.ResponseHeaderType;
import de.hpi.i2b2.report.datavo.i2b2message.ResponseMessageType;
import de.hpi.i2b2.report.datavo.pdo.ConceptSet;
import de.hpi.i2b2.report.datavo.pdo.EventSet;
import de.hpi.i2b2.report.datavo.pdo.ModifierSet;
import de.hpi.i2b2.report.datavo.pdo.ObservationSet;
import de.hpi.i2b2.report.datavo.pdo.ObserverSet;
import de.hpi.i2b2.report.datavo.pdo.PatientSet;
import de.hpi.i2b2.report.datavo.pdo.query.ItemType;
import de.hpi.i2b2.report.datavo.pdo.query.PatientDataResponseType;
import de.hpi.i2b2.report.datavo.pdo.query.PdoQryHeaderType;
import de.hpi.i2b2.report.datavo.pdo.query.RequestType;
import de.hpi.i2b2.report.datavo.reportconfig.InputType;
import de.hpi.i2b2.report.datavo.reportconfig.OutputType;
import de.hpi.i2b2.report.datavo.reportconfig.RscriptletType;
import de.hpi.i2b2.report.datavo.reportmessages.AdditionalInputType;
import de.hpi.i2b2.report.datavo.reportmessages.PatientSetsType;
import de.hpi.i2b2.report.datavo.reportmessages.ConceptsType;
import de.hpi.i2b2.report.datavo.reportmessages.RScriptletResultType;
import de.hpi.i2b2.report.datavo.reportmessages.RResultsType;
import de.hpi.i2b2.report.datavo.reportmessages.ResultType;
import edu.harvard.i2b2.common.exception.I2B2Exception;
import edu.harvard.i2b2.common.util.jaxb.JAXBUnWrapHelper;
import edu.harvard.i2b2.common.util.jaxb.JAXBUtilException;

//This class coordinates the main work for the GetRResults job
public class GetRResultsRequestHandler implements RequestHandler {
	
	private static Log log = LogFactory.getLog(GetRResultsRequestHandler.class);
	
	public String handleRequest(RequestMessageType input) throws I2B2Exception {
		
		// ============== Process the input ==============
		
		// Read out some important informations from message header
		String domain = null;
		String username = null;
		String password = null;
		String project = null;
		try {
			domain = input.getMessageHeader().getSecurity().getDomain();
			username = input.getMessageHeader().getSecurity().getUsername();
			password = input.getMessageHeader().getSecurity().getPassword().getValue();
			project = input.getMessageHeader().getProjectId();
		} catch (Exception e) {
			log.error("Incoming request XML is not valid. Stack trace: " + reportUtil.getStackTraceAsString(e));
			throw new I2B2Exception("Error message delivered from server: Incomplete or invalid XML request header");
		}
		
		// Unwrap request message body and extract information
		JAXBUnWrapHelper unwrapHelper = new JAXBUnWrapHelper();
		RScriptletResultType reportResType = null;
		String scriptletDirectoryName = null;
		String QTSUrl = null;
		PatientSetsType patSetType = null;
		ConceptsType conceptsType = null; 
		try {
			reportResType = (RScriptletResultType) unwrapHelper.getObjectByClass(input.getMessageBody().getAny(), RScriptletResultType.class);
			scriptletDirectoryName = reportResType.getRScriptletName();
			QTSUrl = reportResType.getQTSUrl();
			patSetType = reportResType.getPatientSets();
			conceptsType = reportResType.getConcepts();
			if (scriptletDirectoryName == null || QTSUrl == null || patSetType == null || conceptsType == null) {
				throw new NullPointerException();
			}
		} catch (Exception e) {
			log.error("Incoming XML request body is not valid or complete. Stack trace: " + reportUtil.getStackTraceAsString(e));
			throw new I2B2Exception("Error message delivered from server: Incoming XML request body is not valid or complete.");
		}
		AdditionalInputType addInType = reportResType.getAdditionalInput();
		
		// Assemble scriptlet path
		scriptletDirectoryName.replace("/", ""); // for security
		scriptletDirectoryName.replace("..", ""); // for security
		scriptletDirectoryName.replace("\\", ""); // for security
		String scriptletDirectoryPath = reportUtil.getRSCRIPTLETPATH() + "/" + scriptletDirectoryName;
		File scriptletDirectory = new File(scriptletDirectoryPath);
		if (! scriptletDirectory.exists() || ! scriptletDirectory.canRead() || ! scriptletDirectory.isDirectory()) {
			log.error("Scriptlet directory error (Existing? Is a directory? Access rights?) at path: " + scriptletDirectoryPath);
			throw new I2B2Exception("Error delivered from server: Scriptlet directory not available");
		}
		
		// Validate corresponding config file against XML schema and unmarshall into a JAXB Object
		RscriptletType reportType = null;
		try {
			reportType = reportUtil.validateAndUnmarshallScriptletConfigFile(scriptletDirectoryPath, scriptletDirectoryName);
		} catch (SAXException e) {
			log.error("Error (SAXException) while validateAndUnmarshallScriptletConfigFile: " + e.getMessage());
			throw new I2B2Exception("Error delivered from server: Error while validating / unmarhsalling config.xml file:\n" + e.getMessage());
		}
		
		if (reportType == null) {
			log.error("Error during config file validation (reportType==null)");
			throw new I2B2Exception("Error delivered from server: Validation error (reportTaype==null)");
		}
		
		// Extract additional input values if there are any
		Map<String,String> inputParametersMap = new HashMap<String, String>();
		if (reportType.getAdditionalInputs() != null) {
			// For handy access convert the request input parameter list into a map
			Map<String, String> inputParametersFromRequest = null;
			if (addInType != null) {
				inputParametersFromRequest = reportUtil.convertListIntoMapAndDecodeHTML(addInType.getInputParameter());
			}
			// For every specified (in config file!) additional input value...
			for (InputType ipt : reportType.getAdditionalInputs().getInput()) {
				String iptNameFromConfig = ipt.getName();
				// Check if it is also available in request message
				if (inputParametersFromRequest != null && inputParametersFromRequest.get(iptNameFromConfig) != null) {
					// If yes, escape double quotes at first for security reasons...
					String parValue = inputParametersFromRequest.get(iptNameFromConfig);
					parValue.replace("\"", "\\\"");
					// ...and add key/value pair to the later used map
					inputParametersMap.put(iptNameFromConfig, parValue);
				} else {
					// If not, add an empty string as value
					inputParametersMap.put(iptNameFromConfig, "");
				}
			} 
		}
		
		// Create custom output values list if there are any
		List<String[]> outputParametersList = new LinkedList<String[]>();
		if (reportType.getCustomOutputs() != null) {
			for (OutputType ot : reportType.getCustomOutputs().getOutput()) {
				String[] sa = new String[2];
				if (ot.getName() != null) sa[0] = ot.getName();
				else continue;
				if (ot.getDescription() != null) sa[1] = ot.getDescription();
				else sa[1] = "";
				outputParametersList.add(sa);
			}
		}
		
		// Start R
		JRIProcessor.initializeR();
		
		// Add username suffix to webdir path and create folder
		String extendedWebdirPath = reportUtil.getWEBDIRPATH() + "/userfiles/" + username + "/";
		File extendedWebdirFile = new File(extendedWebdirPath);
		if (! extendedWebdirFile.exists()) {
			if (! extendedWebdirFile.mkdirs()) {
				log.error("Extended webdir subfolder could not be created");
				throw new I2B2Exception("Extended webdir subfolder could not be created");
			}
		}
		
		// Do some preparations in the R environment. Returns File handle to the plot directory (later needed)
		File plotDir = JRIProcessor.prepare(extendedWebdirPath);
			
		// Extract the concept list
		List<ItemType> conceptsList = conceptsType.getConcept();
		// It's not an error if the concept list is empty but it has to exist!
		if (conceptsList == null) {
			log.error("Concepts list missing");
			throw new I2B2Exception("Error delivered from server: No concepts list specified");
		}
		boolean conceptAvailable = true;
		if (conceptsList.size() == 0) conceptAvailable = false;
		// Extract the concept names
		String[] conceptNames = new String[conceptsList.size()];
		for (int i = 0; i < conceptsList.size(); i++) {
			conceptNames[i] = conceptsList.get(i).getDimDimcode();
		}
		
		// For every specified patient set...
		int i = 1;
		for (Integer pst  : patSetType.getPatientSetCollId()) {
			// Extract collection id
			int collID = pst.intValue();
			if (collID == 0) {
				log.error("Patient set collection ID missing");
				throw new I2B2Exception("Error delivered from server: Invalid or missing patient set collection id");
			}
			
			// ============== Communicate with CRC Cell for patient data ==============
			
			// Build message body of CRC request
			PdoQryHeaderType crcPdoqryheader = MessageUtil.createPDOHeader();
			RequestType crcReqType = MessageUtil.createPDORequest(collID, conceptsList);
			de.hpi.i2b2.report.datavo.i2b2message.ObjectFactory i2b2mesFac = new de.hpi.i2b2.report.datavo.i2b2message.ObjectFactory();
			BodyType crcBodType = i2b2mesFac.createBodyType();
			de.hpi.i2b2.report.datavo.pdo.query.ObjectFactory pdoQryFac = new de.hpi.i2b2.report.datavo.pdo.query.ObjectFactory();
			crcBodType.getAny().add(pdoQryFac.createPdoheader(crcPdoqryheader));
			crcBodType.getAny().add(pdoQryFac.createRequest(crcReqType));
			
			// Assemble request message to CRC cell
			OMElement crcResult = null;
			RequestHeaderType crcReqHeaderType = MessageUtil.createRequestHeaderType();	
			MessageHeaderType crcMesHead = MessageUtil.createRequestMessageHeaderType(domain, username, password, project);
			RequestMessageType crcReqMessageType = MessageUtil.createRequestMessageType(crcMesHead, crcReqHeaderType, crcBodType);
			OMElement crcRequest = MessageUtil.convertXMLToOMElement(MessageUtil.convertRequestMessageTypeToXML(crcReqMessageType));
			
			// Uncomment for debugging purposes
			// log.info("Message to CRC cell:\n\n\n" + MessageUtil.convertRequestMessageTypeToXML(crcReqMessageType) + "\n\n\n");
			
			// Send request message to CRC cell and get answer message
    		Options options = new Options();
    		options.setTo(new EndpointReference(QTSUrl + "pdorequest"));
    		options.setTransportInProtocol(Constants.TRANSPORT_HTTP);
    		options.setProperty(Constants.Configuration.ENABLE_REST, Constants.VALUE_TRUE);
    		options.setTimeOutInMilliSeconds(25000);
    		ServiceClient sender;
			try {
				sender = new ServiceClient();
	    		sender.setOptions(options);
	    		crcResult = sender.sendReceive(crcRequest); 
			} catch (AxisFault e) {
				log.error("Error while sending / receiving message to / from CRC cell");
				throw new I2B2Exception("Error delivered from server: Communication with CRC cell failed");
			}
			
			// Uncomment for debugging purposes
			// log.info("Answer message from CRC cell: \n\n\n\n" + crcResult + "\n\n\n\n");
			 
			 
			// Convert response into JAXB (unmarshall)
			ResponseMessageType crcRMT = MessageUtil.convertXMLTOResponseMessageType(crcResult.toString());
				
			// Unwrap response message and check for errors
			ConceptSet crcCS = null;
			PatientSet crcPS = null;
			ObservationSet crcOS = null;
			ModifierSet crcMS = null;
			EventSet crcES = null;
			ObserverSet crcObS = null;
			try {
				String crcStatusType = crcRMT.getResponseHeader().getResultStatus().getStatus().getType();
				if ( ! crcStatusType.equals("DONE")) {
					log.error("Status type of CRC response is not 'DONE'! Message:\n" + crcResult.toString());
					throw new I2B2Exception("Error delivered from server: Status type of CRC response is not 'DONE'. See log files for details.");
				}
				// Unwrap message body
				PatientDataResponseType pdrt = (PatientDataResponseType) unwrapHelper.getObjectByClass(crcRMT.getMessageBody().getAny(), PatientDataResponseType.class);
				if (pdrt.getPatientData() == null) {
					throw new NullPointerException();
				}
				crcPS = pdrt.getPatientData().getPatientSet();
				if (conceptAvailable) {
					crcCS = pdrt.getPatientData().getConceptSet();
					crcOS = pdrt.getPatientData().getObservationSet().get(0);
					crcMS = pdrt.getPatientData().getModifierSet();
					crcES = pdrt.getPatientData().getEventSet();
					crcObS = pdrt.getPatientData().getObserverSet();
					if (crcPS == null || crcMS == null || crcES == null || crcObS == null || crcCS == null || crcOS == null) {
						throw new NullPointerException();
					}
				}
			} catch (NullPointerException e) {
				log.error("CRC response invalid or imcomplete");
				throw new I2B2Exception("Error delivered from server: CRC response is invalid or incomplete");
			} catch (JAXBUtilException e) {
				log.error("Error while unmarshalling CRC response");
				throw new I2B2Exception("Error delivered from server: Unmarshalling CRC response");
			}
			
			// Let R read in strings as data.frame after parsing them
			JRIProcessor.readDataFrameFromString("report.patients[[" + i + "]]", CRCResponseParser.parsePatientSet(crcPS), CRCResponseParser.patientsColClasses);
			if (conceptAvailable) {
				JRIProcessor.readDataFrameFromString("report.observations[[" + i + "]]", CRCResponseParser.parseObservationSet(crcOS, crcCS), CRCResponseParser.conceptsColClasses);
				JRIProcessor.readDataFrameFromString("report.events[[" + i + "]]", CRCResponseParser.parseEventSet(crcES), CRCResponseParser.eventsColClasses);
				JRIProcessor.readDataFrameFromString("report.modifiers[[" + i + "]]", CRCResponseParser.parseModifierSet(crcMS), CRCResponseParser.modifierColClasses);
				JRIProcessor.readDataFrameFromString("report.observers[[" + i + "]]", CRCResponseParser.parseObserverSet(crcObS), CRCResponseParser.observersColClasses);
			}
			i++;
		}
		
		// Error case: No patient data set was specified
		/*if (i == 1) {
			log.error("No patient set specified in request message");
			throw new I2B2Exception("Error delivered from server: No Patient set specified");
		}*/
		
		// ============== R processing ==============
		
		// Initialize additional input variables in R
		JRIProcessor.assignAdditionalInput(inputParametersMap);
		
		// Initialize names of the chosen in R
		JRIProcessor.assignConceptNames(conceptNames);
		
		// Run script in R
		JRIProcessor.executeRScript(scriptletDirectoryPath + "/mainscript.r");
		
		// Read out output variables from R
		List<String[]> oV = JRIProcessor.getOutputVariables(outputParametersList, extendedWebdirPath);
		
		// Get number of plots
		short plotNumber = (short) plotDir.listFiles().length;
		
		// Flush R workspace
		JRIProcessor.doFinalRTasks(extendedWebdirPath);

		String plotDirPath = extendedWebdirPath + "/plots";
    	String csvDirPath = extendedWebdirPath + "/csv";
    	String rImageDirPath = extendedWebdirPath + "/RImage";
    	
    	String uploadURL = reportUtil.getUPLOADURL();
    	ReportFileUploader uploader = new ReportFileUploader(uploadURL, username);
    	File plots = new File(plotDirPath);
	    for (File file : plots.listFiles()) {
	    	uploader.uploadFile(file, file.getName(), "plots");
	    }
	    File csvs = new File(csvDirPath);
	    for (File file : csvs.listFiles()) {
	    	uploader.uploadFile(file, file.getName(), "csv");
	    }
	    File rImages = new File(rImageDirPath);
	    for (File file : rImages.listFiles()) {
	    	uploader.uploadFile(file, file.getName(), "RImage");
	    }
    	
		// ============== Build and send answer message ==============
		
		// Assemble body part of response message (=RResultsType)
		RResultsType rrt = new RResultsType();
		List<ResultType> resultList = rrt.getResult();
		// Add output variables
		for (String[] outputVar : oV) {
			ResultType rT = new ResultType();
			rT.setName(outputVar[0]);
			rT.setDescription(outputVar[1]);
			rT.setType(outputVar[2]);
			rT.setValue(outputVar[3]);
			resultList.add(rT);
		}
		rrt.setPlotNumber(plotNumber);
		
		// Add R output stream text if desired in config file (if not set: passing output is default behaviour)
		if (reportType.getSettings().isPassROutput() == null || reportType.getSettings().isPassROutput()) {
			rrt.setRoutput(JRIProcessor.getROutput());
		}
		
		// Add R error stream text if desired in config file (if not set: passing errors is default behaviour)
		if (reportType.getSettings().isPassRErrors() == null || reportType.getSettings().isPassRErrors()) {
			rrt.setRerrors(JRIProcessor.getRErrors());
		}
		
		// Assemble Response message and return it
		ResponseHeaderType respHeaderType = MessageUtil.createResponseHeaderType("DONE", "Processing completed");
		
		de.hpi.i2b2.report.datavo.i2b2message.ObjectFactory i2b2mesFac = new de.hpi.i2b2.report.datavo.i2b2message.ObjectFactory();
		BodyType bodType = i2b2mesFac.createBodyType();
		de.hpi.i2b2.report.datavo.reportmessages.ObjectFactory reportmesFac = new de.hpi.i2b2.report.datavo.reportmessages.ObjectFactory();
		bodType.getAny().add(reportmesFac.createRResults(rrt));
		
		MessageHeaderType mesHead = MessageUtil.createResponseMessageHeaderType(input.getMessageHeader());
		ResponseMessageType respMessageType = MessageUtil.createResponseMessageType(mesHead, respHeaderType, bodType);
		String response = MessageUtil.convertResponseMessageTypeToXML(respMessageType);
		
		return response;
	}
	
}
