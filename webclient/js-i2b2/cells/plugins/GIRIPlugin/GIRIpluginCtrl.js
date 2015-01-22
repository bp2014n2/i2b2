/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */

// This function is called after the HTML is loaded into the viewer DIV
i2b2.GIRIPlugin.Init = function(loadedDiv) {
	// This map will hold information about all available scriptlets
	i2b2.GIRIPlugin.scriptlets = {};
	// Indicates if at least one drag&drop field holds data
	i2b2.GIRIPlugin.model.prsDirty = false;
	i2b2.GIRIPlugin.model.conceptDirty = false;
	// Holds the currently chosen scriptlet
	i2b2.GIRIPlugin.model.currentScriptlet = "";
	// Holds the concept names that are dropped on additional input values of type 'concept'
	i2b2.GIRIPlugin.model.aiConcpts = {};
	// Holds the highest index of a shown concept dd field (shown at lowest)
	i2b2.GIRIPlugin.model.highestConcDDIndex = 0;
	// Holds the highest index of a shown patient set dd field (shown at lowest)
	i2b2.GIRIPlugin.model.highestPSDDIndex = 0;
	// Holds the records (data of the dropped items) of the fields
	i2b2.GIRIPlugin.model.prsRecords = [];
	i2b2.GIRIPlugin.model.conceptRecords = [];

	// Set some paths dynamically (see injected_screens.html)
	$("giri-loading-scriptlets-gif").src = i2b2.GIRIPlugin.cfg.config.assetDir + "loading.gif";
	$("giri-loading-results-gif").src = i2b2.GIRIPlugin.cfg.config.assetDir + "loading.gif";
	$("giri-environment-link").href = i2b2.GIRIPlugin.cfg.config.assetDir + "userfiles/" + i2b2.h.getUser() + "/RImage/RImage";

	// Specify necessary message parameters for getRScriptlets request (No special parameters needed here)
	var parameters = {};
	// Build callback handler to be executed when the Communicator results are returned (ASYNC method)
	var scoped_callback = new i2b2_scopedCallback;
	scoped_callback.scope = this;
	scoped_callback.callback = function(cbResults){
		// Check for server side errors
		var tmpNode = i2b2.h.XPath(cbResults.refXML, "//status/@type");
		if(tmpNode[0].nodeValue == "ERROR") {
			tmpNode = i2b2.h.XPath(cbResults.refXML, "//status/text()");
			alert(tmpNode[0].nodeValue);
			return;
		}
		// Show dropdownlist and add an empty entry ("no scriptlet selected")
		$("giri-loading-scriptlets").hide();
		$("giri-statfunc-selector").show();
		var selTrgt = $("giri-pilist");
		selTrgt.options[0] = new Option('','');
		// Call parsing function in i2b2_msgs.js -> Populate cbResults.model
		cbResults.parse();
		// Populate drop down list and internal map
		for (var i = 0; i < cbResults.model.length; i++) {
			var t = cbResults.model[i].title;
			var n = new Option(i2b2.h.Escape(t), t);
			selTrgt.options[selTrgt.length] = n;
			i2b2.GIRIPlugin.scriptlets[t] = cbResults.model[i];
		}
		if (cbResults.faultyScriptlets != "" && cbResults.faultyScriptlets != undefined) {	
			alert("Warning: The following scriptlets could not be loaded due to an invalid config.xml file:\n\n" + cbResults.faultyScriptlets);
		}
	}
	// Send message to get all available scriptlets. After response arrived, the callback function above is called
	var commObjRef = eval("(i2b2.GIRI.ajax)");
	commObjRef['getRScriptlets']("GIRIPlugin Client", parameters, scoped_callback);
	// Manage YUI tabs
	var cfgObj = {activeIndex : 0};
	this.yuiTabs = new YAHOO.widget.TabView("giri-TABS", cfgObj);
	this.yuiTabs.on('activeTabChange', function(ev) {
		// If tab is changed to 'View results' -> Call function buildAndSendMsg()
		if (ev.newValue.get('id')=="giri-TAB1") {
			i2b2.GIRIPlugin.buildAndSendMsg();
		}
	});
};

// This function is called when a user selected a scriptlet from drop down list
i2b2.GIRIPlugin.loadPlugin = function(value) {
	
	// Set global variable
	i2b2.GIRIPlugin.model.currentScriptlet = value;

	// Get handles
	var title = $("giri-scriptlet-title");
	var description = $("giri-scriptlet-description");
	// Additional input textfield prototype
	var aiTextProt = $$("DIV#giriplugin-mainDiv .giri-text-prototype")[0];
	// Additional input dropdown prototype
	var aiDropProt = $$("DIV#giriplugin-mainDiv .giri-dropdown-prototype")[0];
	// Additional input concept prototype
	var aiConcProt = $$("DIV#giriplugin-mainDiv .giri-concept-prototype")[0];
	// All non-prototype input fields
	var allNPInput = $$("DIV#giriplugin-mainDiv .giri-input");
	// Container div for additional inputs
	var addInCont = $("giri-scriptlets-inputs");
	// Container div for drag/drop fields
	var ddCont = $("giri-droptrgt-cont");
	// Clear fields button
	var clearFieldsButton = $("giri-clearField");
	// Div with additional inputs
	var piInputsDiv = $("giri-scriptlets-inputs");

	// Hide previously displayed scriptlet
	title.innerHTML = "";
	description.innerHTML = "";
	clearFieldsButton.hide();
	ddCont.hide();
	piInputsDiv.hide();
	for (var i = 0; i < allNPInput.length; i++) {
		allNPInput[i].parentElement.removeChild(allNPInput[i]);
	}
	
	// Clear old additional concepts
	i2b2.GIRIPlugin.model.aiConcpts = {};

	// If empty scriptlet is chosen -> return now
	if (value == '') { return; }

	// Display new scriptlet title and description
	title.innerHTML = i2b2.h.Escape(i2b2.GIRIPlugin.scriptlets[value].title);
	description.innerHTML = i2b2.h.Escape(i2b2.GIRIPlugin.scriptlets[value].descr);
	
	// Clear old and register new drag/drop fields
	i2b2.GIRIPlugin.clearDDFields();
	clearFieldsButton.show();
	ddCont.show();

	
	// Display additional input parameters
	var addIns = i2b2.GIRIPlugin.scriptlets[value].addInputs;
	if (addIns.length > 0) piInputsDiv.show();
	var numberAIConceptFields = 0;
	for (var i = 0; i < addIns.length; i++) {			
		// Clone prototype object, apply parameters, change class, display it
		var newNode;
		if (addIns[i].type == "text") {
			newNode = aiTextProt.cloneNode(true);
			var parTitle = Element.select(newNode, 'h3')[0];
			var parDescr = Element.select(newNode, 'p')[0];
			var parTextfield = Element.select(newNode, 'textarea')[0];
			parTitle.innerHTML = i2b2.h.Escape(addIns[i].name);
			parDescr.innerHTML = i2b2.h.Escape(addIns[i].descr);
			parTextfield.setAttribute("rows", addIns[i].lines);
			newNode.className = "giri-input giri-input-textfield";
		} else if (addIns[i].type == "dropdown") {
			newNode = aiDropProt.cloneNode(true);
			var parTitle = Element.select(newNode, 'h3')[0];
			var parDescr = Element.select(newNode, 'p')[0];
			var parSelect = Element.select(newNode, 'select')[0];
			parTitle.innerHTML = i2b2.h.Escape(addIns[i].name);
			parDescr.innerHTML = i2b2.h.Escape(addIns[i].descr);
			for (var j = 0; j < addIns[i].options.length; j++) {
				var t = addIns[i].options[j];
				var n = new Option(i2b2.h.Escape(t), i2b2.h.Escape(t));
				parSelect.options[parSelect.length] = n;
			}
			newNode.className = "giri-input giri-input-dropdown";
		} else if (addIns[i].type == "concept") {
			newNode = aiConcProt.cloneNode(true);
			var newID = "giri-AICONCPTDROP-" + numberAIConceptFields;
			var parTitle = Element.select(newNode, 'h3')[0];
			var parDescr = Element.select(newNode, 'p')[0];
			var parDragField = Element.select(newNode, 'div')[0];
			parTitle.innerHTML = i2b2.h.Escape(addIns[i].name);
			parTitle.id = newID + "-title";
			parDescr.innerHTML = i2b2.h.Escape(addIns[i].descr);
			parDragField.id = newID;
			var op_trgt = {dropTarget:true};
			i2b2.sdx.Master._sysData[newID] = {}; // hack to get old dd fields (from previously selected scriptlet) unregistered as there's no function for it...
			i2b2.sdx.Master.AttachType(newID, "CONCPT", op_trgt);
			i2b2.sdx.Master.setHandlerCustom(newID, "CONCPT", "DropHandler", i2b2.GIRIPlugin.aiconceptDropped);
			numberAIConceptFields++;
			newNode.className = "giri-input giri-input-concept";
		}
		addInCont.appendChild(newNode);
		Element.show(newNode);
	}
};

// This function is called when a patient set is dropped
i2b2.GIRIPlugin.prsDropped = function(sdxData, droppedOnID) {
	// Check if something was dropped on the lowest field (=field with highest id). If yes create a new field under it
	var fieldIndex = parseInt(droppedOnID.slice(13,14));
	if (i2b2.GIRIPlugin.model.highestPSDDIndex == fieldIndex) {
		i2b2.GIRIPlugin.createNewPSDDField();
	}
	// Save the info to our local data model
	sdxData = sdxData[0];
	i2b2.GIRIPlugin.model.prsRecords[fieldIndex] = sdxData;
	// Change appearance of the drop field
	$("giri-PRSDROP-" + fieldIndex).innerHTML = i2b2.h.Escape(sdxData.sdxInfo.sdxDisplayName);
	$("giri-PRSDROP-" + fieldIndex).style.background = "#CFB"; 
	i2b2.GIRIPlugin.model.prsDirty = true;
};

// This function is called when a concept is dropped
i2b2.GIRIPlugin.conceptDropped = function(sdxData, droppedOnID) {
	// Check if something was dropped on the lowest field (=field with highest id). If yes create a new field under it
	var fieldIndex = parseInt(droppedOnID.slice(16,17));
	if (i2b2.GIRIPlugin.model.highestConcDDIndex == fieldIndex) {
		// Timeout to prevent a browser error that would occur when a new dd field is created too fast here
		// The error is harmless -> so this pseudo-fix is sufficient
		window.setTimeout(i2b2.GIRIPlugin.createNewCONCDDField,200);
	}
	sdxData = sdxData[0];
	// Check for lab / modifier value, open popup etc. (see function)
	i2b2.GIRIPlugin.bringPopup(sdxData, fieldIndex);
	// Save the info to our local data model
	i2b2.GIRIPlugin.model.conceptRecords[fieldIndex] = sdxData;
	// Change appearance of the drop field
	$("giri-CONCPTDROP-" + fieldIndex).innerHTML = i2b2.h.Escape(sdxData.sdxInfo.sdxDisplayName);
	$("giri-CONCPTDROP-" + fieldIndex).style.background = "#CFB"; 
	i2b2.GIRIPlugin.model.conceptDirty = true;
};

// This function is called when a concept is dropped on an additional input drag&drop field
i2b2.GIRIPlugin.aiconceptDropped = function(sdxData, droppedOnID) {
	// Determine name of the additional input variable 
	var divNode = $(droppedOnID);
	var h3Node = $(droppedOnID + "-title");
	var aiName = h3Node.innerHTML;
	// Determine dimcode as value
	var concInfo = sdxData[0].origData.xmlOrig;
	var aiValue = i2b2.h.getXNodeVal(concInfo, "dimcode");
	// Save in local data modal
	i2b2.GIRIPlugin.model.aiConcpts[i2b2.h.Escape(aiName)] = aiValue;
	// Change appearance of the drop field
	$(droppedOnID).innerHTML = i2b2.h.Escape(sdxData[0].sdxInfo.sdxDisplayName);
	$(droppedOnID).style.background = "#CFB"; 
};

// Helper function: It creates & registers a new drag&drop field for a patient set
i2b2.GIRIPlugin.createNewPSDDField = function() {
	// Increment highest field counter
	var ind = ++i2b2.GIRIPlugin.model.highestPSDDIndex;
	// Get handles and create a new visible field by cloning the prototype
	var psFieldProt = $("giri-PRSDROP-PROT");
	var psFieldContainer = $("giri-droptrgt-prs-fields");
	var newNode = psFieldProt.cloneNode(true);
	newNode.className = "giri-droptrgt SDX-PRS";
	newNode.id = "giri-PRSDROP-" + ind;
	newNode.innerHTML = "Patient Set " + (ind + 1);
	psFieldContainer.appendChild(newNode);
	Element.show(newNode);
	// Register as drag&drop target
	i2b2.sdx.Master._sysData["giri-PRSDROP-" + ind] = {}; // hack to get an old dd field unregistered as there's no function for it...
	var op_trgt = {dropTarget:true};
	i2b2.sdx.Master.AttachType("giri-PRSDROP-" + ind, "PRS", op_trgt);
	i2b2.sdx.Master.setHandlerCustom("giri-PRSDROP-" + ind, "PRS", "DropHandler", i2b2.GIRIPlugin.prsDropped);
};

// Helper function: It creates & registers a new drag&drop field for a concept
i2b2.GIRIPlugin.createNewCONCDDField = function() {
	// Increment highest field counter
	var ind = ++i2b2.GIRIPlugin.model.highestConcDDIndex;
	// Get handles and create a new visible field by cloning the prototype
	var concFieldProt = $("giri-CONCPTDROP-PROT");
	var concFieldContainer = $("giri-droptrgt-conc-fields");
	var newNode = concFieldProt.cloneNode(true);
	newNode.className = "giri-droptrgt SDX-CONCPT";
	newNode.id = "giri-CONCPTDROP-" + ind;
	newNode.innerHTML = "Concept " + (ind + 1);
	concFieldContainer.appendChild(newNode);
	Element.show(newNode);
	// Register as drag&drop target
	i2b2.sdx.Master._sysData["giri-CONCPTDROP-" + ind] = {}; // hack to get an old dd field unregistered as there's no function for it...
	var op_trgt = {dropTarget:true};
	i2b2.sdx.Master.AttachType("giri-CONCPTDROP-" + ind, "CONCPT", op_trgt);
	i2b2.sdx.Master.setHandlerCustom("giri-CONCPTDROP-" + ind, "CONCPT", "DropHandler", i2b2.GIRIPlugin.conceptDropped);
};

// Helper function: It clears all drag&drop fields and shows one initial concept & patient set dd field
i2b2.GIRIPlugin.clearDDFields = function() {
	// Remove all drag&drop fields
	var allOldDDFields = $$(".giri-droptrgt");
	for (var i = 0; i < allOldDDFields.length; i++) {
		allOldDDFields[i].parentElement.removeChild(allOldDDFields[i]);
	}
	// Reset counters, tokens and data
	i2b2.GIRIPlugin.model.highestConcDDIndex = -1; // will be increment to 0 shortly after
	i2b2.GIRIPlugin.model.highestPSDDIndex = -1; // will be increment to 0 shortly after
	i2b2.GIRIPlugin.model.prsDirty = false;
	i2b2.GIRIPlugin.model.conceptDirty = false;
	i2b2.GIRIPlugin.model.conceptRecords = [];
	i2b2.GIRIPlugin.model.prsRecords = [];

	// Create one patient set field
	i2b2.GIRIPlugin.createNewPSDDField();
	// Create one concept field
	i2b2.GIRIPlugin.createNewCONCDDField();
};

// This function is called when a user clicks on the tab "View Results"
i2b2.GIRIPlugin.buildAndSendMsg = function() {
	// Get handles
	var piList = $("giri-pilist");
	var errorDivNoPI = $("giri-error-emptyPI");
	var errorDivNoPSCC = $("giri-error-emptyPSorCC");
	var allAIText = $$("DIV#giriplugin-mainDiv .giri-input-textfield");
	var allAIDD = $$("DIV#giriplugin-mainDiv .giri-input-dropdown");
	var allAICO = $$("DIV#giriplugin-mainDiv .giri-input-concept");

	// Hide possibly visible error messages from the past
	errorDivNoPI.hide();
	errorDivNoPSCC.hide();

	// Hide 'Download environment'
	var envLink = $("giri-envionment-div");
	envLink.hide();

	// Hide R output and errors
	var oStreamDiv = $("giri-ostream");
	Element.hide(oStreamDiv);
	var eStreamDiv = $("giri-estream");
	Element.hide(eStreamDiv);

	// Delete old results
	var allOldResults = $$("DIV#giriplugin-mainDiv .giri-result-element");
	for (var i = 0; i < allOldResults.length; i++) {
		allOldResults[i].parentElement.removeChild(allOldResults[i]);
	}

	// Hide old result headline and descriptions
	Element.hide($("giri-result"));

	// Hide old plots
	Element.hide($("giri-plots"));

	// Read out selected scriptlet
	var piTitle = piList.options[piList.selectedIndex].value;
	// Error case: "Empty scriptlet" chosen
	if (piTitle == '') {
		errorDivNoPI.show();
		return;
	}
	// Get subdirectory name
	var piDirName = i2b2.GIRIPlugin.scriptlets[piTitle].subdir;

	// Error case: No patient set selected
	if ( ! i2b2.GIRIPlugin.model.prsDirty ) {
		errorDivNoPSCC.show();
		return;
	}

	// Get URL of the Query Tool Service
	var qtsUrl = i2b2["CRC"].cfg.cellURL;
	
	// Get patient set and concept information
	var patientSets = [];
	for (var i = 0; i < i2b2.GIRIPlugin.model.prsRecords.length; i++) {
		patientSets[i] = i2b2.GIRIPlugin.model.prsRecords[i].sdxInfo.sdxKeyValue;
	}

	var concepts = [];
	for (var i = 0; i < i2b2.GIRIPlugin.model.conceptRecords.length; i++) {
		var t;
		var cdata;
		t = i2b2.GIRIPlugin.model.conceptRecords[i].origData.xmlOrig;
		cdata = {};
		cdata.level = i2b2.h.getXNodeVal(t, "level");
		cdata.key = i2b2.h.getXNodeVal(t, "key");
		cdata.tablename = i2b2.h.getXNodeVal(t, "tablename");
		cdata.dimcode = i2b2.h.getXNodeVal(t, "dimcode");
		cdata.synonym = i2b2.h.getXNodeVal(t, "synonym_cd");
		cdata.constrainString = i2b2.GIRIPlugin.buildConstrainString(i);
		concepts[i] = cdata;
	}
	
	// Get additional inputs: Text fields
	var addIns = [];
	var j = 0;
	for (var i = 0; i < allAIText.length; i++) {
		var name = Element.select(allAIText[i], 'h3')[0].innerHTML;
		var value = Element.select(allAIText[i], 'textarea')[0].value;
		addIns[j] = [name, value];
		j++;
	}

	// Get additional inputs: Drop down lists
	for (var i = 0; i < allAIDD.length; i++) {
		var name = Element.select(allAIDD[i], 'h3')[0].innerHTML;
		var list = Element.select(allAIDD[i], 'select')[0];
		var value = "";
		if (list.options.length != 0) {
			value = list.options[list.selectedIndex].value;
		}
		addIns[j] = [name, value];
		j++;
	}

	// Get additional inputs: Concept drag and drop fields
	for (var i = 0; i < allAICO.length; i++) {
		var name = Element.select(allAICO[i], 'h3')[0].innerHTML;
		var value = i2b2.GIRIPlugin.model.aiConcpts[name];
		if (value == undefined) value = "";
		addIns[j] = [name, value];
		j++;
	}

	// Build patient set message part
	var psMessPart = '';
	for (var i = 0; i < patientSets.length; i++) {
		psMessPart += '					<patient_set_coll_id>' + i2b2.h.Escape(patientSets[i]) + '</patient_set_coll_id>\n';
	}
	// Build concepts message part
	var conceptsMessPart = '';
	for (var i = 0; i < concepts.length; i++) {
		conceptsMessPart +=
		'					<concept>\n'+
		'						<hlevel>' + i2b2.h.Escape(concepts[i].level) + '</hlevel>\n'+
		'						<item_key>' + i2b2.h.Escape(concepts[i].key) + '</item_key>\n'+
		'						<dim_tablename>' + i2b2.h.Escape(concepts[i].tablename) + '</dim_tablename>\n'+
		'						<dim_dimcode>' + i2b2.h.Escape(concepts[i].dimcode) + '</dim_dimcode>\n'+
		'						<item_is_synonym>' + i2b2.h.Escape(concepts[i].synonym) + '</item_is_synonym>\n'+
										concepts[i].constrainString +
		'					</concept>\n';
	}
	// Build additional input message part
	var aiMessPart = '';
	for (var i = 0; i < addIns.length; i++) {
		//alert("name: " + addIns[i][0] + " value: " + addIns[i][1]);
		aiMessPart += '' +
			'				<inputParameter>\n'+
			'					<name>' + i2b2.h.Escape(addIns[i][0]) + '</name>\n'+
			'					<value>' + i2b2.h.Escape(addIns[i][1]) + '</value>\n'+
			'				</inputParameter>\n';
	}
	// Build object holding message parameters
	var messParams = {};
	messParams['r_scriptlet_name'] = i2b2.h.Escape(piDirName);
	messParams['qts_url'] = i2b2.h.Escape(qtsUrl);
	messParams['patient_sets'] = psMessPart;
	messParams['concepts'] = conceptsMessPart;
	messParams['additional_input'] = aiMessPart;
	// Display waiting message
	var resultsDiv = $("giri-result");
	resultsDiv.hide();
	var plotsDiv = $("giri-plots");
	plotsDiv.hide();
	var waitingDiv = $("giri-waiting");
	waitingDiv.show();

	// Send message (see above)
	var scoped_callback = new i2b2_scopedCallback;
	scoped_callback.scope = this;
	scoped_callback.callback = i2b2.GIRIPlugin.displayResults;
	var commObjRef = eval("(i2b2.GIRI.ajax)");
	commObjRef['getRResults']("GIRIPlugin Client", messParams, scoped_callback);

};

// This function processes and displays the results coming from the answer message
i2b2.GIRIPlugin.displayResults = function(cbResults) {
	// Hide waiting screen
	var waitingDiv = $("giri-waiting");
	waitingDiv.hide();

	// Check for server side errors
	var tmpNode = i2b2.h.XPath(cbResults.refXML, "//status/@type");
	if(tmpNode[0].nodeValue == "ERROR") {
		tmpNode = i2b2.h.XPath(cbResults.refXML, "//status/text()");
		alert(tmpNode[0].nodeValue);
		return;
	}
	
	// Show result divs
	var plotsDiv = $("giri-plots");
	plotsDiv.show();
	var resultsDiv = $("giri-result");
	resultsDiv.show();

	// Show custom heading
	var heading = Element.select(resultsDiv, 'h1')[0];
	heading.innerHTML = "Results of scriptlet '" + i2b2.h.Escape(i2b2.GIRIPlugin.scriptlets[i2b2.GIRIPlugin.model.currentScriptlet].title) + "'"

	// Show results descriptions
	var resDescr = Element.select(resultsDiv, 'p')[0];
	resDescr.innerHTML = i2b2.h.Escape(i2b2.GIRIPlugin.scriptlets[i2b2.GIRIPlugin.model.currentScriptlet].resDescr);

	// Parse message
	cbResults.parse();

	// Show result values
	var resultProt = $$("DIV#giriplugin-mainDiv .giri-result-prot")[0];
	var resultCont = $("giri-results-list");
	for (var i = 0; i < cbResults.model.length; i++) {
		var newNode = resultProt.cloneNode(true);
		var parName = Element.select(newNode, 'h3')[0];
		var parDescr = Element.select(newNode, '.giri-result-descr')[0];
		var parValue = Element.select(newNode, '.giri-result-value')[0];
		var parCSVLink = Element.select(newNode, 'a')[0];
		var parCSVDiv = Element.select(newNode, 'div')[0];
		parName.innerHTML = i2b2.h.Escape(cbResults.model[i].title);
		parDescr.innerHTML = i2b2.h.Escape(cbResults.model[i].description);
		// For security reasons the result values are escaped -> No HTML tags will be interpreted
		parValue.innerHTML = i2b2.h.Escape(cbResults.model[i].value);
		newNode.className = "giri-result-element";
		if (cbResults.model[i].type == "data.frame" || cbResults.model[i].type == "matrix") {
			// Do not escape here. Otherwise the table HTML tags will be escaped and therefore the table will not be properly dispayed
			// Note that this is NOT a security flaw here as the 'xtable' R-module is smart enough to output encode the table's content
			parValue.innerHTML = cbResults.model[i].value;
			// Add a link to download csv
			parCSVLink.href = i2b2.GIRIPlugin.cfg.config.assetDir + "userfiles/" + i2b2.h.getUser() + "/csv/" + cbResults.model[i].title + ".csv";
			Element.show(parCSVDiv);
		}
		resultCont.appendChild(newNode);
		Element.show(newNode);
	}
	
	// Delete old plots
	var allOldPlots = $$("DIV#giriplugin-mainDiv .giri-plot");
	for (var i = 0; i < allOldPlots.length; i++) {
		allOldPlots[i].parentElement.removeChild(allOldPlots[i]);
	}

	// Show plot description
	var plotHeading = Element.select(plotsDiv, 'p')[0];
	plotHeading.innerHTML = i2b2.h.Escape(i2b2.GIRIPlugin.scriptlets[i2b2.GIRIPlugin.model.currentScriptlet].plotDescr);	

	// Show plots if available
	var plotProt = $$("DIV#giriplugin-mainDiv .giri-plot-prot")[0];
	for (var i = 1; i <= cbResults.plotNumber; i++) {
		var newNode = plotProt.cloneNode(true);
		var plotIMG = Element.select(newNode, 'img')[0];
		var plotA = Element.select(newNode, 'a')[0];
		var d=new Date(); // This hack forces images with the same name to be reloaded every time. Src: http://jesin.tk/javascript-reload-image/
		plotIMG.src = i2b2.GIRIPlugin.cfg.config.assetDir + "userfiles/" + i2b2.h.getUser() + "/plots/plot00" + i + ".svg?a=" + d.getTime();
		plotA.href= i2b2.GIRIPlugin.cfg.config.assetDir + "userfiles/" + i2b2.h.getUser() + "/plots/plot00" + i + ".svg?a=" + d.getTime();
		newNode.className = "giri-plot";
		plotsDiv.appendChild(newNode);
		Element.show(newNode);
	}
	
	// Don't show plot area if no plots are available
	if (cbResults.plotNumber == 0) Element.hide(plotsDiv);
	
	// Show R output area if desired
	var oStreamDiv = $("giri-ostream");
	if(i2b2.GIRIPlugin.scriptlets[i2b2.GIRIPlugin.model.currentScriptlet].ostream == "true") {
		Element.show(oStreamDiv);
		var outputText = Element.select(oStreamDiv, 'p')[0];
		if (cbResults.Routput == "") {
			outputText.innerHTML = "(R didn't produce any output)";
		} else {
			outputText.innerHTML = i2b2.h.Escape(cbResults.Routput).replace("\n", "<br>");
		}
	}
	
	// Show R error area if desired
	var eStreamDiv = $("giri-estream");
	if(i2b2.GIRIPlugin.scriptlets[i2b2.GIRIPlugin.model.currentScriptlet].estream == "true") {
		Element.show(eStreamDiv);
		var errorsText = Element.select(eStreamDiv, 'p')[0];
		if (cbResults.Rerrors == "") {
			errorsText.innerHTML = "(R didn't produce any errors)";
			errorsText.style.color = 'black';
		} else {
			errorsText.innerHTML = i2b2.h.Escape(cbResults.Rerrors).replace("\n", "<br>");
			errorsText.style.color = 'red';
		}
	}

	// Show 'Download environment'
	var envLink = $("giri-envionment-div");
	envLink.show();

};

// This function brings a popup if a (lab) value or a modifier concept was dropped
i2b2.GIRIPlugin.bringPopup = function(sdxData, fieldIndex) {
	
	// Currently not supported to define modifier values via a popup
	if (sdxData.origData.isModifier) {
		alert("Caution: Modifiers are only partly supported. It is not possible to define modifier values in this version.");		
		return;
	} else {
		// This code is from Timeline_ctrlr.js. It checks if values should be specified in a popup
		var cdetails = i2b2.ONT.ajax.GetTermInfo("CRC:QueryTool", {concept_key_value:sdxData.origData.key, ont_synonym_records: true, ont_hidden_records: true} );
		var c = i2b2.h.XPath(cdetails.refXML, 'descendant::concept');
		if (c.length > 0) {
			sdxData.origData.xmlOrig = c[0];					
		}	
		var lvMetaDatas1 = i2b2.h.XPath(sdxData.origData.xmlOrig, 'metadataxml/ValueMetadata[string-length(Version)>0]');
		if (lvMetaDatas1.length > 0) {
			// Bring up popup
			i2b2.GIRIPlugin.view.modalLabValues.show(this, sdxData.origData.key, sdxData, false, fieldIndex);			
		} else {
			// No values available
			return;
		}
	}
};

// This function builds the constrain string for (lab) values or modifiers
i2b2.GIRIPlugin.buildConstrainString = function(index) {
	if ( ! Object.isUndefined(i2b2.GIRIPlugin.model.conceptRecords[index].LabValues) ) {
		var lvd = i2b2.GIRIPlugin.model.conceptRecords[index].LabValues;
		// This code is from Timeline_ctrlr.js
		var s = '\t\t\t\t\t\t<constrain_by_value>\n';
		switch(lvd.MatchBy) {
			case "FLAG":
				s += '\t\t\t\t\t\t\t<value_type>FLAG</value_type>\n';
				s += '\t\t\t\t\t\t\t<value_operator>EQ</value_operator>\n';
				s += '\t\t\t\t\t\t\t<value_constraint>'+i2b2.h.Escape(lvd.ValueFlag)+'</value_constraint>\n';
				break;
			case "VALUE":
				if (lvd.GeneralValueType=="ENUM") {
					var sEnum = [];
					for (var i2=0;i2<lvd.ValueEnum.length;i2++) {
						sEnum.push(i2b2.h.Escape(lvd.ValueEnum[i2]));
					}
					sEnum = sEnum.join("\',\'");
					sEnum = '(\''+sEnum+'\')';
					s += '\t\t\t\t\t\t\t<value_type>TEXT</value_type>\n';
					s += '\t\t\t\t\t\t\t<value_constraint>'+sEnum+'</value_constraint>\n';
					s += '\t\t\t\t\t\t\t<value_operator>IN</value_operator>\n';								
				} else if (lvd.GeneralValueType=="STRING") {
					s += '\t\t\t\t\t\t\t<value_type>TEXT</value_type>\n';
					s += '\t\t\t\t\t\t\t<value_operator>'+lvd.StringOp+'</value_operator>\n';
					s += '\t\t\t\t\t\t\t<value_constraint><![CDATA['+i2b2.h.Escape(lvd.ValueString)+']]></value_constraint>\n';
				} else if (lvd.GeneralValueType=="LARGESTRING") {
					if (lvd.DbOp) {
						s += '\t\t\t\t\t\t\t<value_operator>CONTAINS[database]</value_operator>\n';
					} else {
						s += '\t\t\t\t\t\t\t<value_operator>CONTAINS</value_operator>\n';											
					}
					s += '\t\t\t\t\t\t\t<value_type>LARGETEXT</value_type>\n';
					s += '\t\t\t\t\t\t\t<value_constraint><![CDATA['+i2b2.h.Escape(lvd.ValueString)+']]></value_constraint>\n';
				} else {
					s += '\t\t\t\t\t\t\t<value_type>'+lvd.GeneralValueType+'</value_type>\n';
					s += '\t\t\t\t\t\t\t<value_unit_of_measure>'+lvd.UnitsCtrl+'</value_unit_of_measure>\n';
					s += '\t\t\t\t\t\t\t<value_operator>'+lvd.NumericOp+'</value_operator>\n';
					if (lvd.NumericOp == 'BETWEEN') {
						s += '\t\t\t\t\t\t\t<value_constraint>'+i2b2.h.Escape(lvd.ValueLow)+' and '+i2b2.h.Escape(lvd.ValueHigh)+'</value_constraint>\n';
					} else {
						s += '\t\t\t\t\t\t\t<value_constraint>'+i2b2.h.Escape(lvd.Value)+'</value_constraint>\n';
					}
				}
				break;
			case "":
				break;
		}
		s += '\t\t\t\t\t\t</constrain_by_value>\n';
		return s;
	}

	if ( ! Object.isUndefined(i2b2.GIRIPlugin.model.conceptRecords[index].ModValues) ) {
		// Currently not supported
		return "";
	}

	return "";
};

// Reset model
i2b2.GIRIPlugin.Unload = function() {
	i2b2.GIRIPlugin.model.aiConcpts = {};
	i2b2.GIRIPlugin.scriptlets = {};
	i2b2.GIRIPlugin.model.currentScriptlet = "";
	i2b2.GIRIPlugin.model.highestConcDDIndex = 0;
	i2b2.GIRIPlugin.model.highestPSDDIndex = 0;
	i2b2.GIRIPlugin.model.prsDirty = false;
	i2b2.GIRIPlugin.model.conceptDirty = false;
	i2b2.GIRIPlugin.model.conceptRecords = [];
	i2b2.GIRIPlugin.model.prsRecords = [];
	return true;
};
