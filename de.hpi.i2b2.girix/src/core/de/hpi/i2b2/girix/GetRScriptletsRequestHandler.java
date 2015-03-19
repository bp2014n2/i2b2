/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */
package de.hpi.i2b2.girix;

import java.io.File;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.xml.sax.SAXException;

import de.hpi.i2b2.girix.datavo.i2b2message.BodyType;
import de.hpi.i2b2.girix.datavo.i2b2message.MessageHeaderType;
import de.hpi.i2b2.girix.datavo.i2b2message.RequestMessageType;
import de.hpi.i2b2.girix.datavo.i2b2message.ResponseHeaderType;
import de.hpi.i2b2.girix.datavo.i2b2message.ResponseMessageType;
import de.hpi.i2b2.girix.datavo.girixconfig.RscriptletType;
import de.hpi.i2b2.girix.datavo.girixmessages.RScriptletsType;
import edu.harvard.i2b2.common.exception.I2B2Exception;


// This class coordinates the main work for the GetRScriptlets job
public class GetRScriptletsRequestHandler implements RequestHandler{
	
	private static Log log = LogFactory.getLog(GetRScriptletsRequestHandler.class);
	
	public String handleRequest(RequestMessageType input) throws I2B2Exception {
		
		// Request body doesn't matter (and is probably empty). So ignore it
		
		// Build 'RScriptlets' (jaxb) object (to add RScriptlet nodes)
		de.hpi.i2b2.girix.datavo.girixmessages.ObjectFactory girixmesFac = new de.hpi.i2b2.girix.datavo.girixmessages.ObjectFactory();
		RScriptletsType girixsType = girixmesFac.createRScriptletsType();
		
		// Open scriptlet directory and check for errors
		File scriptletdirectory = new File(GIRIXUtil.getRSCRIPTLETPATH());
		if (! scriptletdirectory.exists()) {
			String scriptletdirerror = "Scriptlet directory error: Does not exist. Path: " + GIRIXUtil.getRSCRIPTLETPATH();
			log.error(scriptletdirerror);
			throw new I2B2Exception("Error delivered from server: " + scriptletdirerror);
		}
		if (! scriptletdirectory.isDirectory()) {
			String scriptletdirerror = "Scriptlet directory error: Not a directory. Path: " + GIRIXUtil.getRSCRIPTLETPATH();
			log.error(scriptletdirerror);
			throw new I2B2Exception("Error delivered from server: " + scriptletdirerror);
		}
		if (! scriptletdirectory.canRead()) {
			String scriptletdirerror = "Scriptlet directory error: No access rights for reading. Path: " + GIRIXUtil.getRSCRIPTLETPATH();
			log.error(scriptletdirerror);
			throw new I2B2Exception("Error delivered from server: " + scriptletdirerror);
		}

		// For every subdirectory
		String faultyConfigFiles = "";
		for (File f : scriptletdirectory.listFiles()) {
			if ( ! f.isDirectory()) continue;
			boolean hasMainScriptFile = false;
			for (File s : f.listFiles()) {
				hasMainScriptFile |= s.getName().equals("mainscript.r");
			}
			if (!hasMainScriptFile) continue;
			
			String subdirectorypath = f.getPath();
			
			// Validate config file against XML schema and unmarshall into a JAXB Object
			RscriptletType girixType = null;
			try {
				girixType = GIRIXUtil.validateAndUnmarshallScriptletConfigFile(subdirectorypath, f.getName());
			} catch (SAXException e) {
				// If config file is invalid -> Append hint to faultyConfigFiles and skip this scriptlet
				faultyConfigFiles += f.getName() + "\nError message: " + e.getMessage() + "\n\n";
				continue;
			}
			
			if (girixType == null) {
				String errMsg = "Error during config file validation (girixType==null)";
				log.error(errMsg);
				throw new I2B2Exception("Error delivered from server " + errMsg);
			}

			// Error case: <settings> part is missing
			if (girixType.getSettings() == null) {
				de.hpi.i2b2.girix.datavo.girixconfig.ObjectFactory confmesFac = new de.hpi.i2b2.girix.datavo.girixconfig.ObjectFactory();
				girixType.setSettings(confmesFac.createSettingsType());
			}
			// Add subdirectory name
			girixType.getSettings().setSubdirectory(f.getName());

			// Add girixscriptlet object to rscriptlets object (=container)
			girixsType.getRscriptlet().add(girixType);
		}
		// Assemble response message and return it
		ResponseHeaderType respHeaderType = MessageUtil.createResponseHeaderType("DONE", "Processing completed");
		
		de.hpi.i2b2.girix.datavo.i2b2message.ObjectFactory i2b2mesFac = new de.hpi.i2b2.girix.datavo.i2b2message.ObjectFactory();
		BodyType bodType = i2b2mesFac.createBodyType();
		girixsType.setFaultyScriptlets(faultyConfigFiles);
		bodType.getAny().add(girixmesFac.createRScriptlets(girixsType));
		
		MessageHeaderType mesHead = MessageUtil.createResponseMessageHeaderType(input.getMessageHeader());
		
		ResponseMessageType respMessageType = MessageUtil.createResponseMessageType(mesHead, respHeaderType, bodType);
		
		String response = MessageUtil.convertResponseMessageTypeToXML(respMessageType);
		
		return response;
	}
	
}
