/*
 * Copyright (c) 2006-2007 Massachusetts General Hospital 
 * All rights reserved. This program and the accompanying materials 
 * are made available under the terms of the i2b2 Software License v1.0 
 * which accompanies this distribution. 
 * 
 * Contributors:
 *     Mike Mendis - initial API and implementation
 */

package de.erlangen.i2b2.giri;

import edu.harvard.i2b2.common.exception.I2B2Exception;
import edu.harvard.i2b2.common.util.jaxb.DTOFactory;
import edu.harvard.i2b2.common.util.jaxb.JAXBUtil;
import edu.harvard.i2b2.common.util.jaxb.JAXBUtilException;
import de.erlangen.i2b2.giri.datavo.i2b2message.ApplicationType;
import de.erlangen.i2b2.giri.datavo.i2b2message.BodyType;
import de.erlangen.i2b2.giri.datavo.i2b2message.FacilityType;
import de.erlangen.i2b2.giri.datavo.i2b2message.MessageControlIdType;
import de.erlangen.i2b2.giri.datavo.i2b2message.MessageHeaderType;
import de.erlangen.i2b2.giri.datavo.i2b2message.PasswordType;
import de.erlangen.i2b2.giri.datavo.i2b2message.ProcessingIdType;
import de.erlangen.i2b2.giri.datavo.i2b2message.RequestHeaderType;
import de.erlangen.i2b2.giri.datavo.i2b2message.RequestMessageType;
import de.erlangen.i2b2.giri.datavo.i2b2message.ResponseHeaderType;
import de.erlangen.i2b2.giri.datavo.i2b2message.ResponseMessageType;
import de.erlangen.i2b2.giri.datavo.i2b2message.ResultStatusType;
import de.erlangen.i2b2.giri.datavo.i2b2message.SecurityType;
import de.erlangen.i2b2.giri.datavo.i2b2message.StatusType;
import de.erlangen.i2b2.giri.datavo.pdo.query.FactOutputOptionType;
import de.erlangen.i2b2.giri.datavo.pdo.query.FilterListType;
import de.erlangen.i2b2.giri.datavo.pdo.query.GetPDOFromInputListRequestType;
import de.erlangen.i2b2.giri.datavo.pdo.query.InputOptionListType;
import de.erlangen.i2b2.giri.datavo.pdo.query.ItemType;
import de.erlangen.i2b2.giri.datavo.pdo.query.OutputOptionListType;
import de.erlangen.i2b2.giri.datavo.pdo.query.OutputOptionNameType;
import de.erlangen.i2b2.giri.datavo.pdo.query.OutputOptionSelectType;
import de.erlangen.i2b2.giri.datavo.pdo.query.OutputOptionType;
import de.erlangen.i2b2.giri.datavo.pdo.query.PanelType;
import de.erlangen.i2b2.giri.datavo.pdo.query.PatientListType;
import de.erlangen.i2b2.giri.datavo.pdo.query.PdoQryHeaderType;
import de.erlangen.i2b2.giri.datavo.pdo.query.PdoRequestTypeType;
import de.erlangen.i2b2.giri.datavo.pdo.query.RequestType;

import org.apache.axiom.om.OMElement;
import org.apache.axiom.om.impl.builder.StAXOMBuilder;

import java.io.StringReader;
import java.io.StringWriter;

import java.math.BigDecimal;

import java.util.Date;
import java.util.List;

import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamReader;


// Utility class to create and transform message related objects
public class MessageUtil {
	
    /*
     * =============== Response methods (for responses to requesting clients) ===============
     */
    
    // Create normal response message type out of the other message parts
    public static ResponseMessageType createResponseMessageType(MessageHeaderType messageHeader, ResponseHeaderType respHeader, BodyType bodyType) {
        ResponseMessageType respMsgType = new ResponseMessageType();
        respMsgType.setMessageHeader(messageHeader);
        respMsgType.setMessageBody(bodyType);
        respMsgType.setResponseHeader(respHeader);

        return respMsgType;
    }
    
    // Create response message type with given error message
    public static ResponseMessageType doBuildErrorResponseMessageType(MessageHeaderType messageHeaderType, String errorMessage) {
        MessageHeaderType messageHeader = createResponseMessageHeaderType(messageHeaderType);
        ResponseHeaderType respHeader = createResponseHeaderType("ERROR", errorMessage);
        ResponseMessageType respMessageType = createResponseMessageType(messageHeader, respHeader, null);

        return respMessageType;
    }

    // Create response message header based on request message header
    public static MessageHeaderType createResponseMessageHeaderType(MessageHeaderType messageHeaderType) {
        MessageHeaderType messageHeader = new MessageHeaderType();

        messageHeader.setI2B2VersionCompatible(new BigDecimal("1.1"));
		messageHeader.setHl7VersionCompatible(new BigDecimal("2.4"));
		
        ApplicationType appType = new ApplicationType();
        appType.setApplicationName("GIRI Cell");
        appType.setApplicationVersion("1.0");
        messageHeader.setSendingApplication(appType);

        FacilityType facility = new FacilityType();
        facility.setFacilityName("i2b2 Hive");
        messageHeader.setSendingFacility(facility);

        if (messageHeaderType != null) {
            if (messageHeaderType.getSendingApplication() != null) {
                messageHeader.setReceivingApplication(messageHeaderType.getSendingApplication());
            }
            messageHeader.setReceivingFacility(messageHeaderType.getSendingFacility());
        }

        Date currentDate = new Date();
        DTOFactory factory = new DTOFactory();
        messageHeader.setDatetimeOfMessage(factory.getXMLGregorianCalendar(currentDate.getTime()));

        MessageControlIdType mcIdType = new MessageControlIdType();
        mcIdType.setInstanceNum(1);
        if (messageHeaderType != null) {
            if (messageHeaderType.getMessageControlId() != null) {
                mcIdType.setMessageNum(messageHeaderType.getMessageControlId().getMessageNum());
                mcIdType.setSessionId(messageHeaderType.getMessageControlId().getSessionId());
            }
        }
        messageHeader.setMessageControlId(mcIdType);

        ProcessingIdType proc = new ProcessingIdType();
        proc.setProcessingId("P");
        proc.setProcessingMode("I");
        messageHeader.setProcessingId(proc);

        messageHeader.setAcceptAcknowledgementType("AL");
        messageHeader.setApplicationAcknowledgementType("AL");
        messageHeader.setCountryCode("DE");
        if (messageHeaderType != null) {
        	if(messageHeaderType.getProjectId() != null) {
        		messageHeader.setProjectId(messageHeaderType.getProjectId());
        	}
        }
        
        return messageHeader;
    }

    // Creates ResponseHeader for the given type and value
    public static ResponseHeaderType createResponseHeaderType(String type, String value) {
        ResponseHeaderType respHeader = new ResponseHeaderType();
        StatusType status = new StatusType();
        status.setType(type);
        status.setValue(value);

        ResultStatusType resStat = new ResultStatusType();
        resStat.setStatus(status);
        respHeader.setResultStatus(resStat);

        return respHeader;
    }
    
    /*
     * =============== Request methods (for request to CRC cell) ===============
     */
    
    // Create request message type out of the other message parts
    public static RequestMessageType createRequestMessageType(MessageHeaderType messageHeader, RequestHeaderType reqHeader, BodyType bodyType) {
        RequestMessageType reqMsgType = new RequestMessageType();
        reqMsgType.setMessageHeader(messageHeader);
        reqMsgType.setMessageBody(bodyType);
        reqMsgType.setRequestHeader(reqHeader);

        return reqMsgType;
    }
    
    // Create request message header
    public static MessageHeaderType createRequestMessageHeaderType(String domain, String username, String password, String projectid) {
        MessageHeaderType messageHeader = new MessageHeaderType();

        messageHeader.setI2B2VersionCompatible(new BigDecimal("1.1"));
		messageHeader.setHl7VersionCompatible(new BigDecimal("2.4"));
		
        ApplicationType sendAppType = new ApplicationType();
        sendAppType.setApplicationName("GIRI Cell");
        sendAppType.setApplicationVersion("1.0");
        messageHeader.setSendingApplication(sendAppType);

        FacilityType sendFacility = new FacilityType();
        sendFacility.setFacilityName("i2b2 Hive");
        messageHeader.setSendingFacility(sendFacility);
        
        ApplicationType recvAppType = new ApplicationType();
        recvAppType.setApplicationName("i2b2_DataRepositoryCell");
        recvAppType.setApplicationVersion("1.7");
        messageHeader.setReceivingApplication(recvAppType);

        FacilityType recvFacility = new FacilityType();
        recvFacility.setFacilityName("PHS");
        messageHeader.setReceivingFacility(recvFacility);

        Date currentDate = new Date();
        DTOFactory factory = new DTOFactory();
        messageHeader.setDatetimeOfMessage(factory.getXMLGregorianCalendar(currentDate.getTime()));
        
        SecurityType secType = new SecurityType();
        secType.setDomain(domain);
        secType.setUsername(username);
        PasswordType pwt = new PasswordType();
        pwt.setValue(password);
        secType.setPassword(pwt);
        messageHeader.setSecurity(secType);

        MessageControlIdType mcIdType = new MessageControlIdType();
        mcIdType.setInstanceNum(0);
        mcIdType.setMessageNum(generateMessageId());
        mcIdType.setSessionId("1");
        messageHeader.setMessageControlId(mcIdType);

        ProcessingIdType proc = new ProcessingIdType();
        proc.setProcessingId("P");
        proc.setProcessingMode("I");
        messageHeader.setProcessingId(proc);

        messageHeader.setAcceptAcknowledgementType("AL");
        messageHeader.setApplicationAcknowledgementType("AL");
        messageHeader.setCountryCode("DE");
        
        messageHeader.setProjectId(projectid);

        
        return messageHeader;
    }

    // Creates RequestHeader
    public static RequestHeaderType createRequestHeaderType() {
    	
        RequestHeaderType reqHeader = new RequestHeaderType();
        reqHeader.setResultWaittimeMs(25000);
        
        return reqHeader;
    }
    
    // Create PDOHeader
    public static PdoQryHeaderType createPDOHeader() {
    	
    	PdoQryHeaderType pqht = new PdoQryHeaderType();
    	pqht.setPatientSetLimit(0);
    	pqht.setEstimatedTime(180000);
    	pqht.setRequestType(PdoRequestTypeType.GET_PDO_FROM_INPUT_LIST);
    	
    	return pqht;
    }
    
    // Create PDORequest
    public static RequestType createPDORequest(int pdoCollID, List<ItemType> conceptsList) {
    	
    	GetPDOFromInputListRequestType pdoReqType = new GetPDOFromInputListRequestType();
    	
    	// Specify patient list by collection id
    	InputOptionListType iolt = new InputOptionListType();
    	PatientListType plt = new PatientListType();
    	plt.setPatientSetCollId(String.valueOf(pdoCollID));
    	plt.setMin(0);
    	plt.setMax(0);
    	iolt.setPatientList(plt);
    	pdoReqType.setInputList(iolt);
    	
    	boolean conceptAvailable = true;
    	if (conceptsList.size() == 0) conceptAvailable = false;
    	
    	// Specify filter list if a concept was specified
    	if (conceptAvailable) {
    		FilterListType flt = new FilterListType();
    		PanelType pt = new PanelType();
    		pt.setName("The panel name"); // not relevant
    		pt.setPanelNumber(1);
    		pt.setPanelAccuracyScale(1);
    		pt.setInvert(0);
    		pt.getItem().addAll(conceptsList);
    		
    		flt.getPanel().add(pt); 
    		pdoReqType.setFilterList(flt);
    	}
    	
    	// Specify output options
    	OutputOptionListType oolt = new OutputOptionListType();
    	oolt.setNames(OutputOptionNameType.ASATTRIBUTES);
    	// Patient set
    	OutputOptionType ootForPatientSet = new OutputOptionType();
    	ootForPatientSet.setSelect(OutputOptionSelectType.USING_INPUT_LIST);
    	ootForPatientSet.setOnlykeys(false);
    	ootForPatientSet.setTechdata(true);
    	oolt.setPatientSet(ootForPatientSet);
    	// Observation set
    	if (conceptAvailable) {
    		FactOutputOptionType ootForObsSet = new FactOutputOptionType();
    		ootForObsSet.setBlob(false);
    		ootForObsSet.setOnlykeys(false);
    		ootForObsSet.setTechdata(true);
    		oolt.setObservationSet(ootForObsSet);
    		// Concept informations (we need the concept_path)
    		OutputOptionType ootForConceptSet = new OutputOptionType();
    		ootForConceptSet.setSelect(OutputOptionSelectType.USING_FILTER_LIST);
    		ootForConceptSet.setOnlykeys(false);
    		oolt.setConceptSetUsingFilterList(ootForConceptSet);
    		
        	// Create a general OutputOptionType
        	OutputOptionType oot = new OutputOptionType();
        	oot.setOnlykeys(false);
        	oot.setSelect(OutputOptionSelectType.USING_FILTER_LIST);
        	oot.setTechdata(true);
        	
        	// Remaining sets
        	oolt.setModifierSetUsingFilterList(oot);
        	oolt.setEventSet(oot);
        	oolt.setObserverSetUsingFilterList(oot);
    	}

    	pdoReqType.setOutputOption(oolt);
    	return pdoReqType;
    }
    
    /*
     * =============== Conversion and helper methods ===============
     */
    
    // Convert XML string to RequestMessageType (JAXB) = unmarshalling the request (from client)
	public static RequestMessageType convertXMLTORequestMessageType(String xmlString) throws I2B2Exception {
		try {
			RequestMessageType rmt = (RequestMessageType) GIRIUtil.getJAXBUtil().unMashallFromString(xmlString).getValue();
			if (rmt == null) {
				throw new I2B2Exception("Null value from unmarshall for VDO xml : " + xmlString);
			}
			return rmt;
		} catch (JAXBUtilException e) {
			throw new I2B2Exception("Umarshaller error: " + e.getMessage() + xmlString, e);
		}
	}
	
    // Convert XML string to ResponseMessageType (JAXB) = unmarshalling the response (from CRC)
	public static ResponseMessageType convertXMLTOResponseMessageType(String xmlString) throws I2B2Exception {

		try {
			ResponseMessageType rmt = (ResponseMessageType) GIRIUtil.getJAXBUtil().unMashallFromString(xmlString).getValue();
			if (rmt == null) {
				throw new I2B2Exception("Null value from unmarshall for VDO xml : " + xmlString);
			}
			return rmt;
		} catch (JAXBUtilException e) {
			throw new I2B2Exception("Umarshaller error: " + e.getMessage() + xmlString, e);
		}
	}

    // Convert ResponseMessageType (JAXB) to XML string = marshalling the response (to client)
    public static String convertResponseMessageTypeToXML(ResponseMessageType respMessageType) throws I2B2Exception {
        StringWriter strWriter = null;

        try {
            JAXBUtil jaxbUtil = GIRIUtil.getJAXBUtil();
            strWriter = new StringWriter();

            de.erlangen.i2b2.giri.datavo.i2b2message.ObjectFactory objectFactory = new de.erlangen.i2b2.giri.datavo.i2b2message.ObjectFactory();
            jaxbUtil.marshaller(objectFactory.createResponse(respMessageType), strWriter);
        } catch (JAXBUtilException e) {
            throw new I2B2Exception("Error converting response message type to string " + e.getMessage(), e);
        }

        return strWriter.toString();
    }
    
    // Convert RequestMessageType (JAXB) to XML string = marshalling the request (to CRC)
    public static String convertRequestMessageTypeToXML(RequestMessageType reqMessageType) throws I2B2Exception {
        StringWriter strWriter = null;

        try {
            JAXBUtil jaxbUtil = GIRIUtil.getJAXBUtil();
            strWriter = new StringWriter();

            de.erlangen.i2b2.giri.datavo.i2b2message.ObjectFactory objectFactory = new de.erlangen.i2b2.giri.datavo.i2b2message.ObjectFactory();
            jaxbUtil.marshaller(objectFactory.createRequest(reqMessageType), strWriter);
        } catch (JAXBUtilException e) {
            throw new I2B2Exception("Error converting response message type to string " + e.getMessage(), e);
        }

        return strWriter.toString();
    }
    
    
    // Convert XML string to OMElement (for responses after marshalling)
    public static OMElement convertXMLToOMElement(String xmlString) throws I2B2Exception {
        OMElement returnElement = null;

        try {
            StringReader strReader = new StringReader(xmlString);
            XMLInputFactory xif = XMLInputFactory.newInstance();
            XMLStreamReader reader = xif.createXMLStreamReader(strReader);

            StAXOMBuilder builder = new StAXOMBuilder(reader);
            returnElement = builder.getDocumentElement();
        } catch (XMLStreamException e) {
            throw new I2B2Exception("Error while converting XML to OMElement" + e.getMessage(), e);
        }

        return returnElement;
    }
    
	/**
	 * Function to generate i2b2 message header message number
	 * 
	 * @return String
	 */
	private static String generateMessageId() {
		StringWriter strWriter = new StringWriter();
		for(int i=0; i<20; i++) {
			int num = getValidAcsiiValue();
			strWriter.append((char)num);
		}
		return strWriter.toString();
	}
	
	/**
	 * Function to generate random number used in message number
	 * 
	 * @return int 
	 */
	private static int getValidAcsiiValue() {
		int number = 48;
		while(true) {
			number = 48+(int) Math.round(Math.random() * 74);
			if((number > 47 && number < 58) || (number > 64 && number < 91) 
				|| (number > 96 && number < 123)) {
					break;
				}
		}
		return number;
	}

}