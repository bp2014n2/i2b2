/**
 * @projectDescription	Messages to configure and build a Report cell communicator object.
 * @namespace	i2b2.Report.ajax
 * @author		Bastian Weinlich
 * @version 	0.1
 */

// create the communicator Object
i2b2.Report.ajax = i2b2.hive.communicatorFactory("Report");

// create namespaces to hold all the communicator messages and parsing routines
i2b2.Report.cfg.msgs = {};
i2b2.Report.cfg.parsers = {};


// ================================================================================================== //
// URL: Address: http://localhost:9090/i2b2/rest/ReportService/getRScriptlets
i2b2.Report.cfg.msgs.getRScriptlets = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'+
'<ns4:request xmlns:ns4="http://www.i2b2.org/xsd/hive/msg/1.1/" >\n'+
'	<message_header>\n'+
'		{{{proxy_info}}}\n'+
'		<i2b2_version_compatible>1.1</i2b2_version_compatible>\n'+
'		<sending_application>\n'+
'			<application_name>i2b2 Webclient</application_name>\n'+
'			<application_version>' + i2b2.ClientVersion + '</application_version>\n'+
'		</sending_application>\n'+
'		<sending_facility>\n'+
'			<facility_name>i2b2 Hive</facility_name>\n'+
'		</sending_facility>\n'+
'		<receiving_application>\n'+
'			<application_name>Report Cell</application_name>\n'+
'			<application_version>1.0</application_version>\n'+
'		</receiving_application>\n'+
'		<receiving_facility>\n'+
'			<facility_name>i2b2 Hive</facility_name>\n'+
'		</receiving_facility>\n'+
'		<datetime_of_message>{{{header_msg_datetime}}}</datetime_of_message>\n'+
'		<security>\n'+
'			<domain>{{{sec_domain}}}</domain>\n'+
'			<username>{{{sec_user}}}</username>\n'+
'			{{{sec_pass_node}}}\n'+
'		</security>\n'+
'		<message_control_id>\n'+
'			<message_num>{{{header_msg_id}}}</message_num>\n'+
'			<instance_num>0</instance_num>\n'+
'		</message_control_id>\n'+
'		<processing_id>\n'+
'			<processing_id>P</processing_id>\n'+
'			<processing_mode>I</processing_mode>\n'+
'		</processing_id>\n'+
'		<accept_acknowledgement_type>AL</accept_acknowledgement_type>\n'+
'		<application_acknowledgement_type>AL</application_acknowledgement_type>\n'+
'		<country_code>DE</country_code>\n'+
'		<project_id>{{{sec_project}}}</project_id>\n'+
'	</message_header>\n'+
'	<request_header>\n'+
'		<result_waittime_ms>{{{result_wait_time}}}000</result_waittime_ms>\n'+
'	</request_header>\n'+
'</ns4:request>';
// Parse answer message
i2b2.Report.cfg.parsers.getRScriptlets = function(){
	if (!this.error) {
		this.model = [];
		// Extract fields of every available R-scriptlet
		tmpNode = i2b2.h.XPath(this.refXML, "//faultyScriptlets/text()");
		if (tmpNode[0] == undefined) { this.faultyScriptlets = ""; }
		else { this.faultyScriptlets = tmpNode[0].nodeValue; }
		var nlst = i2b2.h.XPath(this.refXML, "//rscriptlet");
		for (var i = 0; i < nlst.length; i++) {
			var s = nlst[i];
			var nodeData = {};
			// At least a subdirectory name is available
			nodeData.subdir = i2b2.h.getXNodeVal(s, "settings/subdirectory");
			// If other fields aren't available, use default values
			nodeData.title = i2b2.h.getXNodeVal(s, "settings/title");
			if (nodeData.title == undefined) { nodeData.title = nodeData.subdir; }
			nodeData.descr = i2b2.h.getXNodeVal(s, "settings/description");
			if (nodeData.descr == undefined) { nodeData.descr = ""; }
			nodeData.ostream = i2b2.h.getXNodeVal(s, "settings/passROutput");
			if (nodeData.ostream == undefined) { nodeData.ostream = "true"; }
			nodeData.estream = i2b2.h.getXNodeVal(s, "settings/passRErrors");
			if (nodeData.estream == undefined) { nodeData.estream = "true"; }
			nodeData.resDescr = i2b2.h.getXNodeVal(s, "settings/resultDescription");
			if (nodeData.resDescr == undefined) { nodeData.resDescr = ""; }
			nodeData.plotDescr = i2b2.h.getXNodeVal(s, "settings/plotDescription");
			if (nodeData.plotDescr == undefined) { nodeData.plotDescr = ""; }
			nodeData.numberOfPatientSets = i2b2.h.getXNodeVal(s, "settings/numberOfPatientSets");
			if (nodeData.numberOfPatientSets == undefined) { nodeData.numberOfPatientSets = 1; }
			nodeData.numberOfConcepts = i2b2.h.getXNodeVal(s, "settings/numberOfConcepts");
			if (nodeData.numberOfConcepts == undefined) { nodeData.numberOfConcepts = 0; }
			// Process additional inputs if available
			var addInputNodes = i2b2.h.XPath(s, ".//input");
			nodeData.addInputs = [];
			for (var j = 0; j < addInputNodes.length; j++) {
				nodeData.addInputs[j] = {};
				nodeData.addInputs[j].name = i2b2.h.getXNodeVal(addInputNodes[j], "name"); // Can't be undefined if config.xml is valid
				nodeData.addInputs[j].descr = i2b2.h.getXNodeVal(addInputNodes[j], "description");
				if (nodeData.addInputs[j].descr == undefined) { nodeData.addInputs[j].descr = ""; }
				nodeData.addInputs[j].default = i2b2.h.getXNodeVal(addInputNodes[j], "default");
				if (nodeData.addInputs[j].default == undefined) { nodeData.addInputs[j].default = ""; }
				nodeData.addInputs[j].type = i2b2.h.getXNodeVal(addInputNodes[j], "type"); // Can't be undefined if config.xml is valid
				if (nodeData.addInputs[j].type == "dropdown") {
					var options = i2b2.h.XPath(addInputNodes[j], ".//item/text()");
					nodeData.addInputs[j].options = [];
					if (options != undefined) {
						for (var k = 0; k < options.length; k++) {
							nodeData.addInputs[j].options[k] = options[k].nodeValue; // Can't be undefined if config.xml is valid
						}
					}
				} else if (nodeData.addInputs[j].type == "text") {
					nodeData.addInputs[j].lines = i2b2.h.getXNodeVal(addInputNodes[j], "lines");
					if (nodeData.addInputs[j].lines == undefined) { nodeData.addInputs[j].lines = "1"; }
				}
			}
			this.model.push(nodeData);
		}
	} else {
		this.model = false;
		console.error("[getRScriptlets] Could not parse() data!");
	}
	return this;
}
i2b2.Report.ajax._addFunctionCall("getRScriptlets","{{{URL}}}getRScriptlets",i2b2.Report.cfg.msgs.getRScriptlets,null,i2b2.Report.cfg.parsers.getRScriptlets);



// ================================================================================================== //
// URL: Address: http://localhost:9090/i2b2/rest/ReportService/getRResults
i2b2.Report.cfg.msgs.getRResults = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'+
'<ns4:request xmlns:ns4="http://www.i2b2.org/xsd/hive/msg/1.1/"  xmlns:ns2="http://www.i2b2.org/xsd/cell/report/1.0/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/">\n'+
'	<message_header>\n'+
'		{{{proxy_info}}}\n'+
'		<i2b2_version_compatible>1.1</i2b2_version_compatible>\n'+
'		<hl7_version_compatible>2.4</hl7_version_compatible>\n'+
'		<sending_application>\n'+
'			<application_name>i2b2 Webclient</application_name>\n'+
'			<application_version>' + i2b2.ClientVersion + '</application_version>\n'+
'		</sending_application>\n'+
'		<sending_facility>\n'+
'			<facility_name>i2b2 Hive</facility_name>\n'+
'		</sending_facility>\n'+
'		<receiving_application>\n'+
'			<application_name>Report Cell</application_name>\n'+
'			<application_version>1.0</application_version>\n'+
'		</receiving_application>\n'+
'		<receiving_facility>\n'+
'			<facility_name>i2b2 Hive</facility_name>\n'+
'		</receiving_facility>\n'+
'		<datetime_of_message>{{{header_msg_datetime}}}</datetime_of_message>\n'+
'		<security>\n'+
'			<domain>{{{sec_domain}}}</domain>\n'+
'			<username>{{{sec_user}}}</username>\n'+
'			{{{sec_pass_node}}}\n'+
'		</security>\n'+
'		<message_control_id>\n'+
'			<message_num>{{{header_msg_id}}}</message_num>\n'+
'			<instance_num>0</instance_num>\n'+
'		</message_control_id>\n'+
'		<processing_id>\n'+
'			<processing_id>P</processing_id>\n'+
'			<processing_mode>I</processing_mode>\n'+
'		</processing_id>\n'+
'		<accept_acknowledgement_type>AL</accept_acknowledgement_type>\n'+
'		<application_acknowledgement_type>AL</application_acknowledgement_type>\n'+
'		<country_code>DE</country_code>\n'+
'		<project_id>{{{sec_project}}}</project_id>\n'+
'	</message_header>\n'+
'	<request_header>\n'+
'		<result_waittime_ms>{{{result_wait_time}}}000</result_waittime_ms>\n'+
'	</request_header>\n'+
'	<message_body>\n'+
'		<ns2:RScriptletResult>\n'+
'			<RScriptletName>{{{r_scriptlet_name}}}</RScriptletName>\n'+
'			<QTSUrl>{{{qts_url}}}</QTSUrl>\n'+
'			<patientSets>\n{{{patient_sets}}}			</patientSets>\n'+
'			<concepts>\n{{{concepts}}}			</concepts>\n'+
'			<additionalInput>\n{{{additional_input}}}</additionalInput>\n'+
'		</ns2:RScriptletResult>\n'+
'	</message_body>\n'+
'</ns4:request>';
i2b2.Report.cfg.parsers.getRResults = function(){
	if (!this.error) {
		this.model = [];
		// Extract fields of every available R-Results
		var nlst = i2b2.h.XPath(this.refXML, "//result");
		for (var i = 0; i < nlst.length; i++) {
			var s = nlst[i];
			var nodeData = {};
			nodeData.title = i2b2.h.getXNodeVal(s, "name", true);
			if (i2b2.h.getXNodeVal(s, "description", true) == undefined) nodeData.description = "";
			else nodeData.description = i2b2.h.getXNodeVal(s, "description", true);
			nodeData.type = i2b2.h.getXNodeVal(s, "type", true);
			nodeData.value = i2b2.h.getXNodeVal(s, "value", true);
			this.model.push(nodeData);
		}
		var tmpNode = i2b2.h.XPath(this.refXML, "//plotNumber/text()");
		this.plotNumber = tmpNode[0].nodeValue;
		tmpNode = i2b2.h.XPath(this.refXML, "//Routput/text()");
		if (tmpNode[0] == undefined) { this.Routput = ""; }
		else { this.Routput = tmpNode[0].nodeValue; }
		tmpNode = i2b2.h.XPath(this.refXML, "//Rerrors/text()");
		if (tmpNode[0] == undefined) { this.Rerrors = ""; }
		else { this.Rerrors = tmpNode[0].nodeValue; }
	} else {
		this.model = false;
		console.error("[getRResults] Could not parse() data!");
	}
	return this;
}
i2b2.Report.ajax._addFunctionCall("getRResults","{{{URL}}}getRResults",i2b2.Report.cfg.msgs.getRResults,["patient_sets", "additional_input", "concepts"],i2b2.Report.cfg.parsers.getRResults);
