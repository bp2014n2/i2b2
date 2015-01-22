/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */
package de.erlangen.i2b2.giri;

import java.io.File;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.xml.sax.SAXException;

import de.erlangen.i2b2.giri.datavo.i2b2message.BodyType;
import de.erlangen.i2b2.giri.datavo.i2b2message.MessageHeaderType;
import de.erlangen.i2b2.giri.datavo.i2b2message.RequestMessageType;
import de.erlangen.i2b2.giri.datavo.i2b2message.ResponseHeaderType;
import de.erlangen.i2b2.giri.datavo.i2b2message.ResponseMessageType;
import de.erlangen.i2b2.giri.datavo.giriconfig.RscriptletType;
import de.erlangen.i2b2.giri.datavo.girimessages.RScriptletsType;
import edu.harvard.i2b2.common.exception.I2B2Exception;


// This class coordinates the main work for the GetRScriptlets job
public class GetRScriptletsRequestHandler implements RequestHandler{
	
	private static Log log = LogFactory.getLog(GetRScriptletsRequestHandler.class);
	
	public String handleRequest(RequestMessageType input) throws I2B2Exception {
		
		// Request body doesn't matter (and is probably empty). So ignore it
		
		// Build 'RScriptlets' (jaxb) object (to add RScriptlet nodes)
		de.erlangen.i2b2.giri.datavo.girimessages.ObjectFactory girimesFac = new de.erlangen.i2b2.giri.datavo.girimessages.ObjectFactory();
		RScriptletsType girisType = girimesFac.createRScriptletsType();
		
		// Open scriptlet directory and check for errors
		File scriptletdirectory = new File(GIRIUtil.getRSCRIPTLETPATH());
		if (! scriptletdirectory.exists()) {
			String scriptletdirerror = "Scriptlet directory error: Does not exist. Path: " + GIRIUtil.getRSCRIPTLETPATH();
			log.error(scriptletdirerror);
			throw new I2B2Exception("Error delivered from server: " + scriptletdirerror);
		}
		if (! scriptletdirectory.isDirectory()) {
			String scriptletdirerror = "Scriptlet directory error: Not a directory. Path: " + GIRIUtil.getRSCRIPTLETPATH();
			log.error(scriptletdirerror);
			throw new I2B2Exception("Error delivered from server: " + scriptletdirerror);
		}
		if (! scriptletdirectory.canRead()) {
			String scriptletdirerror = "Scriptlet directory error: No access rights for reading. Path: " + GIRIUtil.getRSCRIPTLETPATH();
			log.error(scriptletdirerror);
			throw new I2B2Exception("Error delivered from server: " + scriptletdirerror);
		}

		// For every subdirectory
		String faultyConfigFiles = "";
		for (File f : scriptletdirectory.listFiles()) {
			if ( ! f.isDirectory()) continue;
			
			String subdirectorypath = f.getPath();
			
			// Validate config file against XML schema and unmarshall into a JAXB Object
			RscriptletType giriType = null;
			try {
				giriType = GIRIUtil.validateAndUnmarshallScriptletConfigFile(subdirectorypath, f.getName());
			} catch (SAXException e) {
				// If config file is invalid -> Append hint to faultyConfigFiles and skip this scriptlet
				faultyConfigFiles += f.getName() + "\nError message: " + e.getMessage() + "\n\n";
				continue;
			}
			
			if (giriType == null) {
				String errMsg = "Error during config file validation (giriType==null)";
				log.error(errMsg);
				throw new I2B2Exception("Error delivered from server " + errMsg);
			}

			// Error case: <settings> part is missing
			if (giriType.getSettings() == null) {
				de.erlangen.i2b2.giri.datavo.giriconfig.ObjectFactory confmesFac = new de.erlangen.i2b2.giri.datavo.giriconfig.ObjectFactory();
				giriType.setSettings(confmesFac.createSettingsType());
			}
			// Add subdirectory name
			giriType.getSettings().setSubdirectory(f.getName());

			// Add giriscriptlet object to rscriptlets object (=container)
			girisType.getRscriptlet().add(giriType);
		}
		// Assemble response message and return it
		ResponseHeaderType respHeaderType = MessageUtil.createResponseHeaderType("DONE", "Processing completed");
		
		de.erlangen.i2b2.giri.datavo.i2b2message.ObjectFactory i2b2mesFac = new de.erlangen.i2b2.giri.datavo.i2b2message.ObjectFactory();
		BodyType bodType = i2b2mesFac.createBodyType();
		girisType.setFaultyScriptlets(faultyConfigFiles);
		bodType.getAny().add(girimesFac.createRScriptlets(girisType));
		
		MessageHeaderType mesHead = MessageUtil.createResponseMessageHeaderType(input.getMessageHeader());
		
		ResponseMessageType respMessageType = MessageUtil.createResponseMessageType(mesHead, respHeaderType, bodType);
		
		String response = MessageUtil.convertResponseMessageTypeToXML(respMessageType);
		
		return response;
	}
	
}
