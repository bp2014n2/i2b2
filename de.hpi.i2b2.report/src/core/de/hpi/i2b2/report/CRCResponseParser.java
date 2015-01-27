/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */
package de.hpi.i2b2.report;

import java.util.HashMap;
import java.util.Map;

import de.hpi.i2b2.report.datavo.pdo.ConceptSet;
import de.hpi.i2b2.report.datavo.pdo.ConceptType;
import de.hpi.i2b2.report.datavo.pdo.EventSet;
import de.hpi.i2b2.report.datavo.pdo.EventType;
import de.hpi.i2b2.report.datavo.pdo.ModifierSet;
import de.hpi.i2b2.report.datavo.pdo.ModifierType;
import de.hpi.i2b2.report.datavo.pdo.ObservationSet;
import de.hpi.i2b2.report.datavo.pdo.ObservationType;
import de.hpi.i2b2.report.datavo.pdo.ObserverSet;
import de.hpi.i2b2.report.datavo.pdo.ObserverType;
import de.hpi.i2b2.report.datavo.pdo.ParamType;
import de.hpi.i2b2.report.datavo.pdo.PatientSet;
import de.hpi.i2b2.report.datavo.pdo.PatientType;

// This class extracts the various information of the CRC response and builds csv files which can then be imported into R
// So this class holds information of the structure of the CRC response and determines how data is provided in R
public class CRCResponseParser {
	
	// The R column class informations
	public static final String patientsColClasses = "c(\"character\",\"character\",\"factor\",\"i2b2DateTime\",\"i2b2DateTime\",\"factor\",\"numeric\",\"factor\",\"factor\"," +
			"\"factor\",\"factor\",\"character\",\"character\",\"factor\",\"character\",\"i2b2DateTime\",\"i2b2DateTime\",\"i2b2DateTime\",\"character\",\"character\")";
	public static final String conceptsColClasses = "c(\"character\",\"character\",\"character\",\"numeric\",\"i2b2DateTime\",\"i2b2DateTime\",\"character\",\"numeric\",\"i2b2DateTime\",\"numeric\"" +
			",\"character\",\"character\",\"character\",\"character\",\"character\",\"numeric\",\"character\",\"character\",\"character\"," +
			"\"character\",\"character\",\"numeric\",\"character\",\"i2b2DateTime\",\"character\",\"character\",\"i2b2DateTime\",\"character\",\"character\"," +
			"\"character\",\"character\")";
	public static final String modifierColClasses = "c(\"i2b2DateTime\",\"i2b2DateTime\",\"character\",\"character\",\"character\",\"character\",\"i2b2DateTime\",\"numeric\")";
	public static final String eventsColClasses = "c(\"i2b2DateTime\",\"i2b2DateTime\",\"character\",\"i2b2DateTime\",\"character\",\"character\"," +
			"\"i2b2DateTime\",\"i2b2DateTime\",\"numeric\",\"numeric\",\"character\",\"character\",\"character\",\"character\")";
	public static final String observersColClasses = "c(\"i2b2DateTime\",\"i2b2DateTime\",\"character\",\"character\",\"character\",\"character\",\"i2b2DateTime\",\"numeric\")";
	private static String SEP = reportUtil.SEP;
	
	public static reportCSVContainer parsePatientSet(PatientSet crcPS) {
		
		boolean empty = true;
		
		// Build patient set csv string
		StringBuilder psSB = new StringBuilder(10000);
		// First line of csv string: Column names
		String psString = "patient_num" + SEP + "source" + SEP + "vital_status_cd" + SEP + "birth_date" + SEP + "death_date" + SEP + "sex_cd" 
				+ SEP + "age_in_years_num" + SEP + "language_cd" + SEP + "race_cd" + SEP + "marital_status_cd" + SEP + "religion_cd" 
				+ SEP + "zip_cd" + SEP + "statecityzip_path" + SEP + "income_cd" + SEP + "patient_blob" + SEP + "update_date" 
				+ SEP + "download_date" + SEP + "import_date" + SEP + "sourcesystem_cd" + SEP + "upload_id\n";
		psSB.append(psString);
		for (PatientType patient : crcPS.getPatient()) {
			empty = false;
			// If the parameter doesn't exist just add a single separator character
			psSB.append((patient.getPatientId().getValue() == null)  ? (SEP)  :  (escape(patient.getPatientId().getValue()) + SEP));
			psSB.append((patient.getPatientId().getSource() == null) ? (SEP)  :  (escape(patient.getPatientId().getSource()) + SEP));

			// Order of params is undefined here. So put it all in a map first and append it afterwards in the right order to the string
			Map<String,String> m = new HashMap<String,String>();
			for (ParamType pt : patient.getParam()) {
				m.put(pt.getColumn(), pt.getValue());
			}
			// Now append in the right order
			psSB.append(
					((m.get("vital_status_cd") == null)   ?  (SEP)  :  (escape(m.get("vital_status_cd")) + SEP)) +
					((m.get("birth_date") == null)        ?  (SEP)  :  (m.get("birth_date") + SEP)) +
					((m.get("death_date") == null)        ?  (SEP)  :  (m.get("death_date") + SEP)) +
					((m.get("sex_cd") == null)            ?  (SEP)  :  (escape(m.get("sex_cd")) + SEP)) +
					((m.get("age_in_years_num") == null)  ?  (SEP)  :  (m.get("age_in_years_num") + SEP)) +
					((m.get("language_cd") == null)       ?  (SEP)  :  (escape(m.get("language_cd")) + SEP)) +
					((m.get("race_cd") == null)           ?  (SEP)  :  (escape(m.get("race_cd")) + SEP)) +
					((m.get("marital_status_cd") == null) ?  (SEP)  :  (escape(m.get("marital_status_cd")) + SEP)) +
					((m.get("religion_cd") == null)       ?  (SEP)  :  (escape(m.get("religion_cd")) + SEP)) +
					((m.get("zip_cd") == null)            ?  (SEP)  :  (escape(m.get("zip_cd")) + SEP)) +
					((m.get("statecityzip_path") == null) ?  (SEP)  :  (escape(m.get("statecityzip_path")) + SEP)) +
					((m.get("income_cd") == null)         ?  (SEP)  :  (escape(m.get("income_cd")) + SEP)) +

					((patient.getPatientBlob() == null)    ? (SEP)  :  (escape(patient.getPatientBlob().toString()) + SEP)) +
					((patient.getUpdateDate() == null)     ? (SEP)  :  (patient.getUpdateDate() + SEP)) +
					((patient.getDownloadDate() == null)   ? (SEP)  :  (patient.getDownloadDate() + SEP)) +
					((patient.getImportDate() == null)     ? (SEP)  :  (patient.getImportDate() + SEP)) +
					((patient.getSourcesystemCd() == null) ? (SEP)  :  (escape(patient.getSourcesystemCd()) + SEP)) +
					((patient.getUploadId() == null)       ?   ""   :  (escape(patient.getUploadId()))) +
					"\n" );
		}
		if (empty) return new reportCSVContainer(psSB.toString(), false);
		else return new reportCSVContainer(psSB.toString(), true);
	}
	
	public static reportCSVContainer parseObservationSet(ObservationSet crcOS, ConceptSet crcCS) {
		
		boolean empty = true;
		
		// Build concept_cd -> concept_path map
		Map<String, String> conceptMap = new HashMap<String,String>();
		for(ConceptType ct : crcCS.getConcept()) {
			conceptMap.put(ct.getConceptCd(), ct.getConceptPath());
		}

		// Build observation set csv string
		StringBuilder osSB = new StringBuilder(10000);
		// First line of csv string: Column names
		String osString = "concept_cd_name" + SEP + "concept_cd_value" + SEP + "concept_path" + SEP + "confidence_num" + SEP + "download_date" + SEP + "end_date"
				+ SEP + "event_id_source" + SEP + "event_id_value" + SEP + "import_date" + SEP + "instance_num" + SEP + "location_cd_name" 
				+ SEP + "location_cd_value" + SEP + "modifier_cd_name" + SEP + "modifier_cd_value" + SEP + "nvalnum_units" 
				+ SEP + "nvalnum_value" + SEP + "observation_blob" + SEP + "observer_cd_name" + SEP + "observer_cd_value" 
				+ SEP + "patient_id_source" + SEP + "patient_id_value" + SEP + "quantity_num" + SEP + "sourcesystem_cd" + SEP + "start_date" 
				+ SEP + "tvalchar" + SEP + "units_cd" + SEP + "update_date" + SEP + "upload_id" + SEP + "valueflag_cd_name" 
				+ SEP + "valueflag_cd_value" + SEP + "valuetype_cd\n";
		osSB.append(osString);

		for (ObservationType obs : crcOS.getObservation()) {
			empty = false;
			osSB.append(
					((obs.getConceptCd().getName() == null)     ? (SEP)  :  (escape(obs.getConceptCd().getName()) + SEP)) +
					((obs.getConceptCd().getValue() == null)    ? (SEP)  :  (escape(obs.getConceptCd().getValue()) + SEP)) +
					// Now look at the concept_cd -> concept_path map and add the path. This is equivalent to JOIN concept_path BY concept_cd
					((obs.getConceptCd().getValue() == null || conceptMap.get(obs.getConceptCd().getValue()) == null)
							? (SEP)  :  (escape(conceptMap.get(obs.getConceptCd().getValue())) + SEP)) +			
							((obs.getConfidenceNum() == null)           ? (SEP)  :  (obs.getConfidenceNum() + SEP)) +
							((obs.getDownloadDate() == null)            ? (SEP)  :  (obs.getDownloadDate() + SEP)) +
							((obs.getEndDate() == null)                 ? (SEP)  :  (obs.getEndDate() + SEP)) +
							((obs.getEventId().getSource() == null)     ? (SEP)  :  (escape(obs.getEventId().getSource()) + SEP)) +
							((obs.getEventId().getValue() == null)      ? (SEP)  :  (obs.getEventId().getValue() + SEP)) +
							((obs.getImportDate() == null)              ? (SEP)  :  (obs.getImportDate() + SEP)) +
							((obs.getInstanceNum().getValue() == null)  ? (SEP)  :  (obs.getInstanceNum().getValue() + SEP)) +
							((obs.getLocationCd().getName() == null)    ? (SEP)  :  (escape(obs.getLocationCd().getName()) + SEP)) +
							((obs.getLocationCd().getValue() == null)   ? (SEP)  :  (escape(obs.getLocationCd().getValue()) + SEP)) +
							((obs.getModifierCd().getName() == null)    ? (SEP)  :  (escape(obs.getModifierCd().getName()) + SEP)) +
							((obs.getModifierCd().getValue() == null)   ? (SEP)  :  (escape(obs.getModifierCd().getValue()) + SEP)) +
							((obs.getNvalNum().getUnits() == null)      ? (SEP)  :  (escape(obs.getNvalNum().getUnits()) + SEP)) +
							((obs.getNvalNum().getValue() == null)      ? (SEP)  :  (obs.getNvalNum().getValue() + SEP)) +
							((obs.getObservationBlob() == null)         ? (SEP)  :  (escape(obs.getObservationBlob().toString()) + SEP)) +
							((obs.getObserverCd().getName() == null)    ? (SEP)  :  (escape(obs.getObserverCd().getName()) + SEP)) +
							((obs.getObserverCd().getValue() == null)   ? (SEP)  :  (escape(obs.getObserverCd().getValue()) + SEP)) +
							((obs.getPatientId().getSource() == null)   ? (SEP)  :  (escape(obs.getPatientId().getSource()) + SEP)) +
							((obs.getPatientId().getValue() == null)    ? (SEP)  :  (escape(obs.getPatientId().getValue()) + SEP)) +
							((obs.getQuantityNum() == null)             ? (SEP)  :  (obs.getQuantityNum() + SEP)) +
							((obs.getSourcesystemCd() == null)          ? (SEP)  :  (escape(obs.getSourcesystemCd()) + SEP)) +
							((obs.getStartDate() == null)               ? (SEP)  :  (obs.getStartDate() + SEP)) +
							((obs.getTvalChar() == null)                ? (SEP)  :  (escape(obs.getTvalChar()) + SEP)) +
							((obs.getUnitsCd() == null)                 ? (SEP)  :  (escape(obs.getUnitsCd()) + SEP)) +
							((obs.getUpdateDate() == null)              ? (SEP)  :  (obs.getUpdateDate() + SEP)) +
							((obs.getUploadId() == null)                ? (SEP)  :  (escape(obs.getUploadId() + SEP))) +
							((obs.getValueflagCd().getName() == null)   ? (SEP)  :  (escape(obs.getValueflagCd().getName()) + SEP)) +
							((obs.getValueflagCd().getValue() == null)  ? (SEP)  :  (escape(obs.getValueflagCd().getValue()) + SEP)) +
							((obs.getValuetypeCd() == null)             ?   ""   :  (escape(obs.getValuetypeCd()))) +
							"\n"
					);
		}
		if (empty) return new reportCSVContainer(osSB.toString(), false);
		else return new reportCSVContainer(osSB.toString(), true);
	}
	
	public static reportCSVContainer parseModifierSet(ModifierSet crcMS) {
		boolean empty = true;
		// Build modifier set csv string
		StringBuilder msSB = new StringBuilder(10000);
		// First line of csv string: Column names
		String msString = "download_date" + SEP + "import_date" + SEP + "modifier_cd" + SEP + "modifier_path" 
				+ SEP + "name_char" + SEP + "sourcesystem_cd" + SEP + "update_date" + SEP + "upload_id" + "\n";
		msSB.append(msString);
		for (ModifierType modType : crcMS.getModifier()) {
			empty = false;
			msSB.append(
					((modType.getDownloadDate() == null)              ?  (SEP)  :  (modType.getDownloadDate() + SEP)) +
					((modType.getImportDate() == null)                ?  (SEP)  :  (modType.getImportDate() + SEP)) +
					((modType.getModifierCd() == null)                ?  (SEP)  :  (escape(modType.getModifierCd()) + SEP)) +
					((modType.getModifierPath() == null)              ?  (SEP)  :  (escape(modType.getModifierPath()) + SEP)) +
					((modType.getNameChar() == null)                  ?  (SEP)  :  (escape(modType.getNameChar()) + SEP)) +
					((modType.getSourcesystemCd() == null)            ?  (SEP)  :  (escape(modType.getSourcesystemCd()) + SEP)) +
					((modType.getUpdateDate() == null)                ?  (SEP)  :  (modType.getUpdateDate() + SEP)) +
					((modType.getUploadId() == null)                  ?  (SEP)  :  (modType.getUploadId())) +
					"\n" );
		}
		if (empty) return new reportCSVContainer(msSB.toString(), false);
		else return new reportCSVContainer(msSB.toString(), true);
	}
	
	public static reportCSVContainer parseEventSet(EventSet crcES) {
		boolean empty = true;
		// Build modifier set csv string
		StringBuilder esSB = new StringBuilder(10000);
		// First line of csv string: Column names
		String esString = "download_date" + SEP + "end_date" + SEP + "event_id" + SEP + "import_date" 
				+ SEP + "patient_num" + SEP + "sourcesystem_cd" + SEP + "start_date" + SEP + "update_date"
				+ SEP + "upload_id" + SEP + "length_of_stay" + SEP + "location_path" + SEP + "active_status" 
				+ SEP + "location_cd" + SEP + "inout_cd" + "\n";		
		esSB.append(esString);
		for (EventType evType : crcES.getEvent()) {
			empty = false;
			// Order of params is undefined here. So put it all in a map first and append it afterwards in the right order to the string
			Map<String,String> m = new HashMap<String,String>();
			for (ParamType pt : evType.getParam()) {
				m.put(pt.getColumn(), pt.getValue());
			}
			esSB.append(
					((evType.getDownloadDate() == null)            ?  (SEP)  :  (evType.getDownloadDate() + SEP)) +
					((evType.getEndDate() == null)                 ?  (SEP)  :  (evType.getEndDate() + SEP)) +
					((evType.getEventId().getValue() == null)      ?  (SEP)  :  (escape(evType.getEventId().getValue()) + SEP)) +
					((evType.getImportDate() == null)              ?  (SEP)  :  (evType.getImportDate() + SEP)) +
					((evType.getPatientId().getValue() == null)    ?  (SEP)  :  (escape(evType.getPatientId().getValue()) + SEP)) +
					((evType.getSourcesystemCd() == null)          ?  (SEP)  :  (escape(evType.getSourcesystemCd()) + SEP)) +
					((evType.getStartDate() == null)               ?  (SEP)  :  (evType.getStartDate() + SEP)) +
					((evType.getUpdateDate() == null)              ?  (SEP)  :  (evType.getUpdateDate() + SEP)) +
					((evType.getUploadId() == null)                ?  (SEP)  :  (evType.getUploadId() + SEP)) +
					((m.get("length_of_stay") == null)             ?  (SEP)  :  (m.get("length_of_stay") + SEP)) +
					((m.get("location_path") == null)              ?  (SEP)  :  (escape(m.get("location_path")) + SEP)) +
					((m.get("active_status_cd") == null)           ?  (SEP)  :  (escape(m.get("active_status_cd")) + SEP)) +
					((m.get("location_cd") == null)                ?  (SEP)  :  (escape(m.get("location_cd")) + SEP)) +
					((m.get("inout_cd") == null)                   ?  (SEP)  :  (escape(m.get("inout_cd")))) +
					"\n" );
		}
		if (empty) return new reportCSVContainer(esSB.toString(), false);
		else return new reportCSVContainer(esSB.toString(), true);
	}
	
	public static reportCSVContainer parseObserverSet(ObserverSet crcObS) {
		boolean empty = true;
		// Build modifier set csv string
		StringBuilder obsSB = new StringBuilder(10000);
		// First line of csv string: Column names
		String esString = "download_date" + SEP + "import_date" + SEP + "name_char" + SEP + "observer_cd" 
				+ SEP + "observer_path" + SEP + "sourcesystem_cd" + SEP + "update_date" + SEP + "upload_id" + "\n";		
		obsSB.append(esString);
		for (ObserverType obsType : crcObS.getObserver()) {
			empty = false;
			obsSB.append(
					((obsType.getDownloadDate() == null)   ?  (SEP)  :  (obsType.getDownloadDate() + SEP)) +
					((obsType.getImportDate() == null)     ?  (SEP)  :  (obsType.getImportDate() + SEP)) +
					((obsType.getNameChar() == null)       ?  (SEP)  :  (escape(obsType.getNameChar()) + SEP)) +
					((obsType.getObserverCd() == null)     ?  (SEP)  :  (escape(obsType.getObserverCd()) + SEP)) +
					((obsType.getObserverPath() == null)   ?  (SEP)  :  (escape(obsType.getObserverPath()) + SEP)) +
					((obsType.getSourcesystemCd() == null) ?  (SEP)  :  (escape(obsType.getSourcesystemCd()) + SEP)) +
					((obsType.getUpdateDate() == null)     ?  (SEP)  :  (obsType.getUpdateDate() + SEP)) +
					((obsType.getUploadId() == null)       ?  (SEP)  :  (obsType.getUploadId())) +
					"\n" );
		}
		if (empty) return new reportCSVContainer(obsSB.toString(), false);
		else return new reportCSVContainer(obsSB.toString(), true);
	}
	
	// Helper function for correct handling of separator strings
	private static String escape(String s) {
		
		return "\"" + s.replace("\"", "\"\"") + "\"";
	}
}
