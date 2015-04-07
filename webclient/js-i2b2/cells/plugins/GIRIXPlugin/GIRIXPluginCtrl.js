/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */

// This function is called after the HTML is loaded into the viewer DIV
i2b2.GIRIXPlugin.Init = function(loadedDiv) {
	// This map will hold information about all available scriptlets
	i2b2.GIRIXPlugin.scriptlets = {};
	// Indicates if at least one drag&drop field holds data
	i2b2.GIRIXPlugin.model.prsDirty = false;
	i2b2.GIRIXPlugin.model.conceptDirty = false;
	// Holds the currently chosen scriptlet
	i2b2.GIRIXPlugin.model.currentScriptlet = "";
	// Holds the concept names that are dropped on additional input values of type 'concept'
	i2b2.GIRIXPlugin.model.aiConcpts = {};
	// Holds the patient_set_ids that are dropped on additional input values of type 'patient_set'
	i2b2.GIRIXPlugin.model.aiPatientSets = {};
	// Holds the highest index of a shown concept dd field (shown at lowest)
	i2b2.GIRIXPlugin.model.highestConcDDIndex = 0;
	// Holds the highest index of a shown patient set dd field (shown at lowest)
	i2b2.GIRIXPlugin.model.highestPSDDIndex = 0;
	// Holds the records (data of the dropped items) of the fields
	i2b2.GIRIXPlugin.model.prsRecords = [];
	i2b2.GIRIXPlugin.model.conceptRecords = [];

	// Set some paths dynamically (see injected_screens.html)
	$("girix-loading-scriptlets-gif").src = i2b2.GIRIXPlugin.cfg.config.assetDir + "loading.gif";
	$("girix-loading-results-gif").src = i2b2.GIRIXPlugin.cfg.config.assetDir + "loading.gif";

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
		// Show dropdownlist [and add an empty entry ("no scriptlet selected") (commented out)]
		$("girix-loading-scriptlets").hide();
		$("girix-statfunc-selector").show();
		var selTrgt = $("girix-pilist");
		//selTrgt.options[0] = new Option('','');
		// Call parsing function in i2b2_msgs.js -> Populate cbResults.model
		cbResults.parse();
		// Populate drop down list and internal map
		for (var i = 0; i < cbResults.model.length; i++) {
			var t = cbResults.model[i].title;
			var n = new Option(i2b2.h.Escape(t), t);
			selTrgt.options[selTrgt.length] = n;
			i2b2.GIRIXPlugin.scriptlets[t] = cbResults.model[i];
			if(i == 0) {
				selTrgt.selectedIndex = 0;
				i2b2.GIRIXPlugin.loadPlugin(i2b2.h.Escape(t));
			}
		}
		if (cbResults.faultyScriptlets != "" && cbResults.faultyScriptlets != undefined) {	
			alert("Warning: The following templates could not be loaded due to an invalid config.xml file:\n\n" + cbResults.faultyScriptlets);
		}
	}
	// Send message to get all available scriptlets. After response arrived, the callback function above is called
	var commObjRef = eval("(i2b2.GIRIX.ajax)");
	commObjRef['getRScriptlets']("GIRIXPlugin Client", parameters, scoped_callback);
	// Manage YUI tabs
	var cfgObj = {activeIndex : 0};
	this.yuiTabs = new YAHOO.widget.TabView("girix-TABS", cfgObj);
	/*
	this.yuiTabs.on('activeTabChange', function(ev) {
		// If tab is changed to 'View results' -> Call function buildAndSendMsg()
		if (ev.newValue.get('id')=="girix-TAB1") {
			i2b2.GIRIXPlugin.buildAndSendMsg();
		}
	});
	*/
};

i2b2.GIRIXPlugin.runScript = function() {
	this.yuiTabs.selectTab(1);
	$("girix-start-button").hide();
	$("girix-stop-button").show();
	i2b2.GIRIXPlugin.buildAndSendMsg();
};

i2b2.GIRIXPlugin.stopScript = function() {	
	$("girix-no-results").show();
	$("girix-waiting").hide();
	$("girix-stop-button").hide();
	$("girix-start-button").show();
	i2b2.GIRIXPlugin.currentSessionKey = null;
};

// This function is called when a user selected a scriptlet from drop down list
i2b2.GIRIXPlugin.loadPlugin = function(value) {
	
	// Set global variable
	i2b2.GIRIXPlugin.model.currentScriptlet = value;
	scriptlet = i2b2.GIRIXPlugin.scriptlets[i2b2.GIRIXPlugin.model.currentScriptlet];

	// Get handles
	var title = $("girix-scriptlet-title");
	var description = $("girix-scriptlet-description");
	// Container div for drag/drop fields
	var ddCont = $("girix-droptrgt-cont");
	// Clear fields button
	var clearFieldsButton = $("girix-clearField");
	// Div with additional inputs
	var piInputsDiv = $("girix-scriptlets-inputs");

	// Hide previously displayed scriptlet
	title.innerHTML = "";
	description.innerHTML = "";
	clearFieldsButton.hide();
	ddCont.hide();
	piInputsDiv.hide();

	// If empty scriptlet is chosen -> return now
	if (i2b2.GIRIXPlugin.model.currentScriptlet == '') { return; }

	// Display new scriptlet title and description
	title.innerHTML = i2b2.h.Escape(scriptlet.title);
	description.innerHTML = i2b2.h.Escape(scriptlet.descr);
	
	// Clear old and register new drag/drop fields
	i2b2.GIRIXPlugin.initDDFields(scriptlet);
	clearFieldsButton.show();
	ddCont.show();

	
	if (scriptlet.addInputs.length > 0) piInputsDiv.show();
	i2b2.GIRIXPlugin.loadAI();
};

i2b2.GIRIXPlugin.loadAI = function() {
	// Container div for additional inputs
	var addInCont = $("girix-scriptlets-inputs");
	// All non-prototype input fields
	var allNPInput = $$("DIV#girixplugin-mainDiv .girix-input");
	for (var i = 0; i < allNPInput.length; i++) {
		allNPInput[i].parentElement.removeChild(allNPInput[i]);
	}
	
	numberAIDateFields = 0;
	numberAIHiddenFields = 0;
	numberAIConceptFields = 0;
	numberAIPatientSetFields = 0;
	// Clear old additional concepts
	i2b2.GIRIXPlugin.model.aiConcpts = {};
	// Clear old additional patient sets
	i2b2.GIRIXPlugin.model.aiPatientSets = {};

	// Display additional input parameters
	var addIns = i2b2.GIRIXPlugin.scriptlets[i2b2.GIRIXPlugin.model.currentScriptlet].addInputs;
	for (var i = 0; i < addIns.length; i++) {			
		// Clone prototype object, apply parameters, change class, display it
		var newNode;
		if (addIns[i].type == "text") {
			newNode = i2b2.GIRIXPlugin.createNewAITextField(addIns[i]);
		} else if (addIns[i].type == "dropdown") {
			newNode = i2b2.GIRIXPlugin.createNewAIDropdownField(addIns[i]);
		} else if (addIns[i].type == "hidden") {
			var newID = "girix-AIHIDDEN-" + numberAIHiddenFields;
			newNode = i2b2.GIRIXPlugin.createNewAIHiddenField(addIns[i], newID);
			numberAIHiddenFields++;
		} else if (addIns[i].type == "date") {
			var newID = "girix-AIDATE-" + numberAIDateFields;
			newNode = i2b2.GIRIXPlugin.createNewAIDateField(addIns[i], newID);
			numberAIDateFields++;
		} else if (addIns[i].type == "concept") {
			var newID = "girix-AICONCPTDROP-" + numberAIConceptFields;
			newNode = i2b2.GIRIXPlugin.createNewAIConceptField(addIns[i], newID);
			numberAIConceptFields++;
		} else if (addIns[i].type == "patient_set") {
			var newID = "girix-AIPATIENTSETDROP-" + numberAIPatientSetFields;
			newNode = i2b2.GIRIXPlugin.createNewAIPatientSetField(addIns[i], newID);
			numberAIPatientSetFields++;
		}
		addInCont.appendChild(newNode);
		Element.show(newNode);
	}
}

i2b2.GIRIXPlugin.createNewAITextField = function(config) {
	// Additional input textfield prototype
	var aiTextProt = $$("DIV#girixplugin-mainDiv .girix-text-prototype")[0];	
	newNode = aiTextProt.cloneNode(true);
	var parTitle = Element.select(newNode, 'h3')[0];
	var parDescr = Element.select(newNode, 'p')[0];
	var parTextfield = Element.select(newNode, 'textarea')[0];
	parTitle.innerHTML = i2b2.h.Escape(config.name);
	parDescr.innerHTML = i2b2.h.Escape(config.descr);
	parTextfield.setAttribute("rows", config.lines);
	newNode.className = "girix-input girix-input-textfield";
	return newNode;
};

i2b2.GIRIXPlugin.createNewAIDateField = function(config, newID) {
	// Additional input date prototype
	var aiDateProt = $$("DIV#girixplugin-mainDiv .girix-date-select-prototype")[0];	
	numberAIDateFields = $$(".girix-input-date-select").length;
	newNode = aiDateProt.cloneNode(true);
	var parTitle = Element.select(newNode, 'h3')[0];
	var parDescr = Element.select(newNode, 'p')[0];
	var parTextfield = Element.select(newNode, 'input')[0];		
	var parLink = Element.select(newNode, 'a')[0];
	parTitle.innerHTML = i2b2.h.Escape(config.name);
	parDescr.innerHTML = i2b2.h.Escape(config.descr);
	parTextfield.id = newID;
	if (i2b2.h.Escape(config.default) != "") {
		parTextfield.value = i2b2.h.Escape(config.default);
	}
	parLink.href = "Javascript:i2b2.GIRIXPlugin.doShowCalendar('" + parTextfield.id + "')"
	newNode.className = "girix-input girix-input-date-select";
	return newNode;
};

i2b2.GIRIXPlugin.createNewAIDropdownField = function(config) {
	// Additional input dropdown prototype
	var aiDropProt = $$("DIV#girixplugin-mainDiv .girix-dropdown-prototype")[0];
	newNode = aiDropProt.cloneNode(true);
	var parTitle = Element.select(newNode, 'h3')[0];
	var parDescr = Element.select(newNode, 'p')[0];
	var parSelect = Element.select(newNode, 'select')[0];
	parTitle.innerHTML = i2b2.h.Escape(config.name);
	parDescr.innerHTML = i2b2.h.Escape(config.descr);
	for (var j = 0; j < config.options.length; j++) {
		var t = config.options[j];
		var n = new Option(i2b2.h.Escape(t), i2b2.h.Escape(t));
		n.selected = (t == i2b2.h.Escape(config.default));
		parSelect.options[parSelect.length] = n;
	}
	newNode.className = "girix-input girix-input-dropdown";
	return newNode;
};

i2b2.GIRIXPlugin.createNewAIHiddenField = function(config, newID) {
	// Additional input hidden prototype
	var aiHiddenProt = $$("DIV#girixplugin-mainDiv .girix-hidden-prototype")[0];	
	numberAIHiddenFields = $$(".girix-input-hidden").length;
	newNode = aiHiddenProt.cloneNode(true);
	var parTitle = Element.select(newNode, 'h3')[0];
	var parTextfield = Element.select(newNode, 'input')[0];		
	var parLink = Element.select(newNode, 'a')[0];
	parTitle.innerHTML = i2b2.h.Escape(config.name);
	parTextfield.id = newID;
    parTextfield.className = "input-" + i2b2.h.Escape(config.name);
	if (i2b2.h.Escape(config.default) != "") {
		parTextfield.value = i2b2.h.Escape(config.default);
	}
	newNode.className = "girix-input girix-input-hidden";
	return newNode;
};

i2b2.GIRIXPlugin.createNewAIPatientSetField = function(config, newID) {
	// Additional input concept prototype
	var aiPatientSetProt = $$("DIV#girixplugin-mainDiv .girix-patient-set-prototype")[0];
	newNode = aiPatientSetProt.cloneNode(true);
	var parTitle = Element.select(newNode, 'h3')[0];
	var parDescr = Element.select(newNode, 'p')[0];
	var parDragField = Element.select(newNode, 'div')[0];
	parTitle.innerHTML = i2b2.h.Escape(config.name);
	parTitle.id = newID + "-title";
	parDescr.innerHTML = i2b2.h.Escape(config.descr);
	parDragField.id = newID;
	var op_trgt = {dropTarget:true};
	i2b2.sdx.Master._sysData[newID] = {}; // hack to get old dd fields (from previously selected scriptlet) unregistered as there's no function for it...
	i2b2.sdx.Master.AttachType(newID, "PRS", op_trgt);
	i2b2.sdx.Master.setHandlerCustom(newID, "PRS", "DropHandler", i2b2.GIRIXPlugin.aipatientsetDropped);
	newNode.className = "girix-input girix-input-patient-set";
	return newNode;
};

i2b2.GIRIXPlugin.createNewAIConceptField = function(config, newID) {	
	// Additional input concept prototype
	var aiConcProt = $$("DIV#girixplugin-mainDiv .girix-concept-prototype")[0];
    numberAIConceptFields = $$(".girix-input-concept").length;
	newNode = aiConcProt.cloneNode(true);
	var parTitle = Element.select(newNode, 'h3')[0];
	var parDescr = Element.select(newNode, 'p')[0];
	var parDragField = Element.select(newNode, 'div')[0];
	parTitle.innerHTML = i2b2.h.Escape(config.name);
	parTitle.id = newID + "-title";
	parDescr.innerHTML = i2b2.h.Escape(config.descr);
	parDragField.id = newID;
	var op_trgt = {dropTarget:true};
	i2b2.sdx.Master._sysData[newID] = {}; // hack to get old dd fields (from previously selected scriptlet) unregistered as there's no function for it...
	i2b2.sdx.Master.AttachType(newID, "CONCPT", op_trgt);
	i2b2.sdx.Master.setHandlerCustom(newID, "CONCPT", "DropHandler", i2b2.GIRIXPlugin.aiconceptDropped);
	newNode.className = "girix-input girix-input-concept";
	return newNode;
};

// This function is called when a patient set is dropped
i2b2.GIRIXPlugin.prsDropped = function(sdxData, droppedOnID) {
	// Check if something was dropped on the lowest field (=field with highest id). If yes create a new field under it
	var fieldIndex = parseInt(droppedOnID.slice(14,17));
	// [DISABLED] Creation of new field
	if (false && i2b2.GIRIXPlugin.model.highestPSDDIndex == fieldIndex) {
		i2b2.GIRIXPlugin.createNewPSDDField();
	}
	// Save the info to our local data model
	sdxData = sdxData[0];
	i2b2.GIRIXPlugin.model.prsRecords[fieldIndex] = sdxData;
	// Change appearance of the drop field
	setTimeout(function() { $("girix-PRSDROP-" + fieldIndex).innerHTML = i2b2.h.Escape(sdxData.sdxInfo.sdxDisplayName);}, 0)
	setTimeout(function() { $("girix-PRSDROP-" + fieldIndex).style.background = "#CFB"},0); 
	i2b2.GIRIXPlugin.model.prsDirty = true;
};

// This function is called when a concept is dropped on an additional input drag&drop field
i2b2.GIRIXPlugin.aipatientsetDropped = function(sdxData, droppedOnID) {
	// Determine name of the additional input variable 
	var divNode = $(droppedOnID);
	var h3Node = $(droppedOnID + "-title");
	var aiName = h3Node.innerHTML;
	// Determine dimcode as value
	sdxData = sdxData[0];
	var psInfo = sdxData.sdxInfo.sdxKeyValue
	// Save in local data modal
	i2b2.GIRIXPlugin.model.aiPatientSets[i2b2.h.Escape(aiName)] = psInfo;
	// Change appearance of the drop field
	$(droppedOnID).innerHTML = i2b2.h.Escape(sdxData.sdxInfo.sdxDisplayName);
	$(droppedOnID).style.background = "#CFB"; 
};

// This function is called when a concept is dropped
i2b2.GIRIXPlugin.conceptDropped = function(sdxData, droppedOnID) {
	// Check if something was dropped on the lowest field (=field with highest id). If yes create a new field under it
	var fieldIndex = parseInt(droppedOnID.slice(17,19));
	//[DISABLED] Creation of new field
	if (false && i2b2.GIRIXPlugin.model.highestConcDDIndex == fieldIndex) {
		// Timeout to prevent a browser error that would occur when a new dd field is created too fast here
		// The error is harmless -> so this pseudo-fix is sufficient
		window.setTimeout(i2b2.GIRIXPlugin.createNewCONCDDField,200);
	}
	sdxData = sdxData[0];
	// Check for lab / modifier value, open popup etc. (see function)
	i2b2.GIRIXPlugin.bringPopup(sdxData, fieldIndex);
	// Save the info to our local data model
	i2b2.GIRIXPlugin.model.conceptRecords[fieldIndex] = sdxData;
	// Change appearance of the drop field
	$("girix-CONCPTDROP-" + fieldIndex).innerHTML = i2b2.h.Escape(sdxData.sdxInfo.sdxDisplayName);
	$("girix-CONCPTDROP-" + fieldIndex).style.background = "#CFB"; 
	i2b2.GIRIXPlugin.model.conceptDirty = true;
};

// This function is called when a concept is dropped on an additional input drag&drop field
i2b2.GIRIXPlugin.aiconceptDropped = function(sdxData, droppedOnID) {
	// Determine name of the additional input variable 
	var divNode = $(droppedOnID);
	var h3Node = $(droppedOnID + "-title");
	var aiName = h3Node.innerHTML;
	// Determine dimcode as value
	var concInfo = sdxData[0].origData.xmlOrig;
	var aiValue = i2b2.h.getXNodeVal(concInfo, "dimcode");
	// Save in local data modal
	i2b2.GIRIXPlugin.model.aiConcpts[i2b2.h.Escape(aiName)] = aiValue;
	// Change appearance of the drop field
	$(droppedOnID).innerHTML = i2b2.h.Escape(sdxData[0].sdxInfo.sdxDisplayName);
	$(droppedOnID).style.background = "#CFB"; 
};

// Helper function: It creates & registers a new drag&drop field for a patient set
i2b2.GIRIXPlugin.createNewPSDDField = function(container) {
        container = container || "girix-droptrgt-prs-fields";
	// Increment highest field counter
	var ind = ++i2b2.GIRIXPlugin.model.highestPSDDIndex;
	// Get handles and create a new visible field by cloning the prototype
	var psFieldProt = $("girix-PRSDROP-PROT");
	var psFieldContainer = $(container);
	var newNode = psFieldProt.cloneNode(true);
	newNode.className = "girix-droptrgt SDX-PRS";
	newNode.id = "girix-PRSDROP-" + ind;
	// newNode.innerHTML = "Patient Set " + (ind + 1);
	newNode.innerHTML = "Drop Patient Set " + (ind + 1) + " here";
	psFieldContainer.appendChild(newNode);
	Element.show(newNode);
	// Register as drag&drop target
	i2b2.sdx.Master._sysData["girix-PRSDROP-" + ind] = {}; // hack to get an old dd field unregistered as there's no function for it...
	var op_trgt = {dropTarget:true};
	i2b2.sdx.Master.AttachType("girix-PRSDROP-" + ind, "PRS", op_trgt);
	i2b2.sdx.Master.setHandlerCustom("girix-PRSDROP-" + ind, "PRS", "DropHandler", i2b2.GIRIXPlugin.prsDropped);
	console.log("Added new drag n drop field");
};

// Helper function: It creates & registers a new drag&drop field for a concept
i2b2.GIRIXPlugin.createNewCONCDDField = function(container) {
        container = container || $("girix-droptrgt-conc-fields")
	// Increment highest field counter
	var ind = ++i2b2.GIRIXPlugin.model.highestConcDDIndex;
	// Get handles and create a new visible field by cloning the prototype
	var concFieldProt = $("girix-CONCPTDROP-PROT");
	var concFieldContainer = container;
	var newNode = concFieldProt.cloneNode(true);
	newNode.className = "girix-droptrgt SDX-CONCPT";
	newNode.id = "girix-CONCPTDROP-" + ind;
	newNode.innerHTML = "Drop Concept " + (ind + 1) + " here";
	concFieldContainer.appendChild(newNode);
	Element.show(newNode);
	// Register as drag&drop target
	i2b2.sdx.Master._sysData["girix-CONCPTDROP-" + ind] = {}; // hack to get an old dd field unregistered as there's no function for it...
	var op_trgt = {dropTarget:true};
	i2b2.sdx.Master.AttachType("girix-CONCPTDROP-" + ind, "CONCPT", op_trgt);
	i2b2.sdx.Master.setHandlerCustom("girix-CONCPTDROP-" + ind, "CONCPT", "DropHandler", i2b2.GIRIXPlugin.conceptDropped);
};

// Helper function: It clears all drag&drop fields and shows one initial concept & patient set dd field
i2b2.GIRIXPlugin.clearDDFields = function() {
	// Remove all drag&drop fields
	var allOldDDFields = $$(".girix-droptrgt");
	for (var i = 0; i < allOldDDFields.length; i++) {
		allOldDDFields[i].parentElement.removeChild(allOldDDFields[i]);
	}
	// Reset counters, tokens and data
	i2b2.GIRIXPlugin.model.highestConcDDIndex = -1; // will be increment to 0 shortly after
	i2b2.GIRIXPlugin.model.highestPSDDIndex = -1; // will be increment to 0 shortly after
	i2b2.GIRIXPlugin.model.prsDirty = false;
	i2b2.GIRIXPlugin.model.conceptDirty = false;
	i2b2.GIRIXPlugin.model.conceptRecords = [];
	i2b2.GIRIXPlugin.model.prsRecords = [];

	// Create one patient set field
	i2b2.GIRIXPlugin.createNewPSDDField();
	// Create one concept field
	i2b2.GIRIXPlugin.createNewCONCDDField();
};


// Helper function: Initializes drag&drop fields
i2b2.GIRIXPlugin.initDDFields = function(scriptlet) {
	var numberOfConcepts = typeof scriptlet !== 'undefined' ? scriptlet.numberOfConcepts : $$(".girix-droptrgt.SDX-CONCPT").length;
	var numberOfPatientSets = typeof scriptlet !== 'undefined' ? scriptlet.numberOfPatientSets : $$(".girix-droptrgt.SDX-PRS").length;

	// Remove all drag&drop fields
	var allOldDDFields = $$(".girix-droptrgt");
	for (var i = 0; i < allOldDDFields.length; i++) {
		allOldDDFields[i].parentElement.removeChild(allOldDDFields[i]);
	}
	// Reset counters, tokens and data
	i2b2.GIRIXPlugin.model.highestConcDDIndex = -1; // will be increment to 0 shortly after
	i2b2.GIRIXPlugin.model.highestPSDDIndex = -1; // will be increment to 0 shortly after
	i2b2.GIRIXPlugin.model.prsDirty = false;
	i2b2.GIRIXPlugin.model.conceptDirty = false;
	i2b2.GIRIXPlugin.model.conceptRecords = [];
	i2b2.GIRIXPlugin.model.prsRecords = [];

	/*
	// Create patient set fields
	for(var i = 0; i < numberOfPatientSets; i++) {
		i2b2.GIRIXPlugin.createNewPSDDField();
	}
	// Create concept fields
	for(var i = 0; i < numberOfConcepts; i++) {
		i2b2.GIRIXPlugin.createNewCONCDDField();
	}
	*/
};
    
setParameter = function(parameter, value){
  document.getElementsByClassName("input-"+parameter)[0].value = value
}
 
// This function is used for asyncronous calls
i2b2.GIRIXPlugin.requestResults = function(diagram, params, callback) {

        setParameter("requestDiagram", diagram)
        setParameter("params", params)

        callbackFunction = function(result) { 
            result.parse(); 
            callback(result.model[0].value); 
            var arr = document.getElementsByClassName("girix-result-element")[0].getElementsByTagName('script')
            for (var n = 0; n < arr.length; n++)
              eval(arr[n].innerHTML)
          };
 
        i2b2.GIRIXPlugin.sendMessage(callbackFunction)
        
        setParameter("requestDiagram", "all")
        setParameter("params", "{}")

};

i2b2.GIRIXPlugin.sendMessage = function(callback) {

        // Get handles
	var piList = $("girix-pilist");
	var noResultsDiv = $("girix-no-results");
	var errorDivNoPI = $("girix-error-emptyPI");
	var errorDivNoPSCC = $("girix-error-emptyPSorCC");
	var allAIText = $$("DIV#girixplugin-mainDiv .girix-input-textfield");
	var allAIDate = $$("DIV#girixplugin-mainDiv .girix-input-date-select");
	var allAIDD = $$("DIV#girixplugin-mainDiv .girix-input-dropdown");
	var allAICO = $$("DIV#girixplugin-mainDiv .girix-input-concept");
	var allAIPS = $$("DIV#girixplugin-mainDiv .girix-input-patient-set");
	var allHiddenText = $$("DIV#girixplugin-mainDiv .girix-input-hidden");

	// Read out selected scriptlet
	var piTitle = piList.options[piList.selectedIndex].value;
	// Get subdirectory name
	var piDirName = i2b2.GIRIXPlugin.scriptlets[piTitle].subdir;

	// Get URL of the Query Tool Service
	var qtsUrl = i2b2["CRC"].cfg.cellURL;
	
	// Get patient set and concept information
	var patientSets = [];
	for (var i = 0; i < i2b2.GIRIXPlugin.model.prsRecords.length; i++) {
		patientSets[i] = i2b2.GIRIXPlugin.model.prsRecords[i].sdxInfo.sdxKeyValue;
	}

	var concepts = [];
	for (var i = 0; i < i2b2.GIRIXPlugin.model.conceptRecords.length; i++) {
		var t;
		var cdata;
		t = i2b2.GIRIXPlugin.model.conceptRecords[i].origData.xmlOrig;
		cdata = {};
		cdata.level = i2b2.h.getXNodeVal(t, "level");
		cdata.key = i2b2.h.getXNodeVal(t, "key");
		cdata.tablename = i2b2.h.getXNodeVal(t, "tablename");
		cdata.dimcode = i2b2.h.getXNodeVal(t, "dimcode");
		cdata.synonym = i2b2.h.getXNodeVal(t, "synonym_cd");
		cdata.constrainString = i2b2.GIRIXPlugin.buildConstrainString(i);
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

	// Get additional Inputs: Hidden
	for (var i = 0; i < allHiddenText.length; i++) {
		var name = Element.select(allHiddenText[i], 'h3')[0].innerHTML;
		var value = Element.select(allHiddenText[i], 'input')[0].value;
		addIns[j] = [name, value];
		j++;
	}

	// Get additional Inputs: Date
	for (var i = 0; i < allAIDate.length; i++) {
		var name = Element.select(allAIDate[i], 'h3')[0].innerHTML;
		var value = Element.select(allAIDate[i], 'input')[0].value;
		addIns[j] = [name, value];
		j++;
	}

	// Get additional inputs: Concept drag and drop fields
	for (var i = 0; i < allAICO.length; i++) {
		var name = Element.select(allAICO[i], 'h3')[0].innerHTML;
		var value = i2b2.GIRIXPlugin.model.aiConcpts[name];
		if (value == undefined) value = "";
		addIns[j] = [name, value];
		j++;
	}

	// Get additional inputs: Concept drag and drop fields
	for (var i = 0; i < allAIPS.length; i++) {
		var name = Element.select(allAIPS[i], 'h3')[0].innerHTML;
		var value = i2b2.GIRIXPlugin.model.aiPatientSets[name];
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
	i2b2.GIRIXPlugin.currentSessionKey = i2b2.GIRIXPlugin.generateSessionKey();
	messParams['r_scriptlet_name'] = i2b2.h.Escape(piDirName);
	messParams['session_key'] = i2b2.GIRIXPlugin.currentSessionKey;
	messParams['qts_url'] = i2b2.h.Escape(qtsUrl);
	messParams['patient_sets'] = psMessPart;
	messParams['concepts'] = conceptsMessPart;
	messParams['additional_input'] = aiMessPart;
	messParams['result_wait_time'] = i2b2.GIRIX.cfg.params.queryTimeout;

        // Send message (see above)
        var scoped_callback = new i2b2_scopedCallback;
        scoped_callback.scope = this;

        scoped_callback.callback = callback

        var commObjRef = eval("(i2b2.GIRIX.ajax)");
        commObjRef['getRResults']("GIRIXPlugin Client", messParams, scoped_callback);
 

}

// This function is called when a user clicks on the tab "View Results"
i2b2.GIRIXPlugin.buildAndSendMsg = function() {
	// Get handles
	var piList = $("girix-pilist");
	var noResultsDiv = $("girix-no-results");
	var errorDivNoPI = $("girix-error-emptyPI");
	var errorDivNoPSCC = $("girix-error-emptyPSorCC");
	var allAIText = $$("DIV#girixplugin-mainDiv .girix-input-textfield");
	var allAIDate = $$("DIV#girixplugin-mainDiv .girix-input-date-select");
	var allAIDD = $$("DIV#girixplugin-mainDiv .girix-input-dropdown");
	var allAICO = $$("DIV#girixplugin-mainDiv .girix-input-concept");
	var allAIPS = $$("DIV#girixplugin-mainDiv .girix-input-patient-set");
	var allHiddenText = $$("DIV#girixplugin-mainDiv .girix-input-hidden");

	noResultsDiv.hide()
	// Hide possibly visible error messages from the past
	noResultsDiv.hide()
	errorDivNoPI.hide();
	errorDivNoPSCC.hide();

	// Hide 'Download environment'
	var envLink = $("girix-envionment-div");
	envLink.hide();

	// Hide R output and errors
	var oStreamDiv = $("girix-ostream");
	Element.hide(oStreamDiv);
	var eStreamDiv = $("girix-estream");
	Element.hide(eStreamDiv);

	// Delete old results
	var allOldResults = $$("DIV#girixplugin-mainDiv .girix-result-element");
	for (var i = 0; i < allOldResults.length; i++) {
		allOldResults[i].parentElement.removeChild(allOldResults[i]);
	}

	// Hide old result headline and descriptions
	Element.hide($("girix-result"));

	// Hide old plots
	Element.hide($("girix-plots"));

       	// Display waiting message
	var resultsDiv = $("girix-result");
	resultsDiv.hide();
	var plotsDiv = $("girix-plots");
	plotsDiv.hide();
	var waitingDiv = $("girix-waiting");
	waitingDiv.show();

        var callback = i2b2.GIRIXPlugin.displayResults
        i2b2.GIRIXPlugin.sendMessage(callback)
};

i2b2.GIRIXPlugin.generateSessionKey = function() {
	return i2b2.h.parseXml(i2b2.h.getPass()).getElementsByTagName("password")[0].innerHTML.replace("SessionKey:", "") + Date.now();
}

i2b2.GIRIXPlugin.getSessionKey = function() {
	return i2b2.h.parseXml(i2b2.h.getPass()).getElementsByTagName("password")[0].innerHTML.replace("SessionKey:", "");
}

// This function processes and displays the results coming from the answer message
i2b2.GIRIXPlugin.displayResults = function(cbResults) {
	// Parse message
	cbResults.parse();

	if(cbResults.sessionKey == i2b2.GIRIXPlugin.currentSessionKey) {
		$("girix-stop-button").hide();
		$("girix-start-button").show();

		// Hide waiting screen
		var waitingDiv = $("girix-waiting");
		waitingDiv.hide();

		// Check for server side errors
		var tmpNode = i2b2.h.XPath(cbResults.refXML, "//status/@type");
		if(tmpNode[0].nodeValue == "ERROR") {
			tmpNode = i2b2.h.XPath(cbResults.refXML, "//status/text()");
			alert(tmpNode[0].nodeValue);
			return;
		}
		
		// Show result divs
		var plotsDiv = $("girix-plots");
		plotsDiv.show();
		var resultsDiv = $("girix-result");
		resultsDiv.show();

		// Show custom heading
		var heading = Element.select(resultsDiv, 'h1')[0];
		heading.innerHTML = "Results of scriptlet '" + i2b2.h.Escape(i2b2.GIRIXPlugin.scriptlets[i2b2.GIRIXPlugin.model.currentScriptlet].title) + "'"

		// Show results descriptions
		var resDescr = Element.select(resultsDiv, 'p')[0];
		resDescr.innerHTML = i2b2.h.Escape(i2b2.GIRIXPlugin.scriptlets[i2b2.GIRIXPlugin.model.currentScriptlet].resDescr);

		// Show result values
		var resultProt = $$("DIV#girixplugin-mainDiv .girix-result-prot")[0];
		var resultCont = $("girix-results-list");
		for (var i = 0; i < cbResults.model.length; i++) {
			var newNode = resultProt.cloneNode(true);
			var parName = Element.select(newNode, 'h3')[0];
			var parDescr = Element.select(newNode, '.girix-result-descr')[0];
			var parValue = Element.select(newNode, '.girix-result-value')[0];
			var parCSVLink = Element.select(newNode, 'a')[0];
			var parCSVDiv = Element.select(newNode, 'div')[0];
			parName.innerHTML = i2b2.h.Escape(cbResults.model[i].title);
			parDescr.innerHTML = i2b2.h.Escape(cbResults.model[i].description);
			// For security reasons the result values are escaped -> No HTML tags will be interpreted
			//parValue.innerHTML = i2b2.h.Escape(cbResults.model[i].value);
			parValue.innerHTML = cbResults.model[i].value;
	                exec_body_scripts(parValue)
			newNode.className = "girix-result-element";
			if (cbResults.model[i].type == "data.frame" || cbResults.model[i].type == "matrix") {
				// Do not escape here. Otherwise the table HTML tags will be escaped and therefore the table will not be properly dispayed
				// Note that this is NOT a security flaw here as the 'xtable' R-module is smart enough to output encode the table's content
				parValue.innerHTML = cbResults.model[i].value;
				// Add a link to download csv
				parCSVLink.href = i2b2.GIRIXPlugin.cfg.config.assetDir + "userfiles/" + i2b2.GIRIXPlugin.currentSessionKey + "/csv/" + cbResults.model[i].title + ".csv";
				Element.show(parCSVDiv);
			}
			resultCont.appendChild(newNode);
			Element.show(newNode);
		}
		
		// Delete old plots
		var allOldPlots = $$("DIV#girixplugin-mainDiv .girix-plot");
		for (var i = 0; i < allOldPlots.length; i++) {
			allOldPlots[i].parentElement.removeChild(allOldPlots[i]);
		}

		// Show plot description
		var plotHeading = Element.select(plotsDiv, 'p')[0];
		plotHeading.innerHTML = i2b2.h.Escape(i2b2.GIRIXPlugin.scriptlets[i2b2.GIRIXPlugin.model.currentScriptlet].plotDescr);	

		// Show plots if available
		var plotProt = $$("DIV#girixplugin-mainDiv .girix-plot-prot")[0];
		for (var i = 1; i <= cbResults.plotNumber; i++) {
			var newNode = plotProt.cloneNode(true);
			var plotIMG = Element.select(newNode, 'img')[0];
			var plotA = Element.select(newNode, 'a')[0];
			var d=new Date(); // This hack forces images with the same name to be reloaded every time. Src: http://jesin.tk/javascript-reload-image/
			plotIMG.src = i2b2.GIRIXPlugin.cfg.config.assetDir + "userfiles/" + i2b2.GIRIXPlugin.currentSessionKey + "/plots/plot00" + i + ".svg?a=" + d.getTime();
			plotA.href= i2b2.GIRIXPlugin.cfg.config.assetDir + "userfiles/" + i2b2.GIRIXPlugin.currentSessionKey + "/plots/plot00" + i + ".svg?a=" + d.getTime();
			newNode.className = "girix-plot";
			plotsDiv.appendChild(newNode);
			Element.show(newNode);
		}
		
		// Don't show plot area if no plots are available
		if (cbResults.plotNumber == 0) Element.hide(plotsDiv);
		
		// Show R output area if desired
		var oStreamDiv = $("girix-ostream");
		if(i2b2.GIRIXPlugin.scriptlets[i2b2.GIRIXPlugin.model.currentScriptlet].ostream == "true") {
			Element.show(oStreamDiv);
			var outputText = Element.select(oStreamDiv, 'p')[0];
			if (cbResults.Routput == "") {
				outputText.innerHTML = "(R didn't produce any output)";
			} else {
				outputText.innerHTML = i2b2.h.Escape(cbResults.Routput).replace("\n", "<br>");
			}
		}
		
		// Show R error area if desired
		var eStreamDiv = $("girix-estream");
		if(i2b2.GIRIXPlugin.scriptlets[i2b2.GIRIXPlugin.model.currentScriptlet].estream == "true") {
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
		$("girix-environment-link").href = i2b2.GIRIXPlugin.cfg.config.assetDir + "userfiles/" + i2b2.GIRIXPlugin.currentSessionKey + "/RImage/RImage";
		var envLink = $("girix-envionment-div");
		envLink.show();

	}

};

// This function brings a popup if a (lab) value or a modifier concept was dropped
i2b2.GIRIXPlugin.bringPopup = function(sdxData, fieldIndex) {
	
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
			i2b2.GIRIXPlugin.view.modalLabValues.show(this, sdxData.origData.key, sdxData, false, fieldIndex);			
		} else {
			// No values available
			return;
		}
	}
};

// This function builds the constrain string for (lab) values or modifiers
i2b2.GIRIXPlugin.buildConstrainString = function(index) {
	if ( ! Object.isUndefined(i2b2.GIRIXPlugin.model.conceptRecords[index].LabValues) ) {
		var lvd = i2b2.GIRIXPlugin.model.conceptRecords[index].LabValues;
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

	if ( ! Object.isUndefined(i2b2.GIRIXPlugin.model.conceptRecords[index].ModValues) ) {
		// Currently not supported
		return "";
	}

	return "";
};

// Reset model
i2b2.GIRIXPlugin.Unload = function() {
	i2b2.GIRIXPlugin.model.aiConcpts = {};
	i2b2.GIRIXPlugin.model.aiPatientSets = {};
	i2b2.GIRIXPlugin.scriptlets = {};
	i2b2.GIRIXPlugin.model.currentScriptlet = "";
	i2b2.GIRIXPlugin.model.highestConcDDIndex = 0;
	i2b2.GIRIXPlugin.model.highestPSDDIndex = 0;
	i2b2.GIRIXPlugin.model.prsDirty = false;
	i2b2.GIRIXPlugin.model.conceptDirty = false;
	i2b2.GIRIXPlugin.model.conceptRecords = [];
	i2b2.GIRIXPlugin.model.prsRecords = [];
	return true;
};

i2b2.GIRIXPlugin.doShowCalendar = function(dateInputId) {
	
	// create calendar if not already initialized
	dateConstrainCal = new YAHOO.widget.Calendar("DateContstrainCal","calendarDiv");
	dateConstrainCal.selectEvent.subscribe(function(eventName, selectedDate) {

		// function is event callback fired by YUI Calendar control 
		// (this function looses it's class scope)
		var cScope = i2b2.CRC.ctrlr.dateConstraint;
		var tn = $(dateInputId);
		var selectDate = selectedDate[0][0];
		tn.value = selectDate[1]+'/'+selectDate[2]+'/'+selectDate[0];
		$("calendarDiv").hide();
		$("calendarDivMask").hide();

	}, dateConstrainCal,true);
	dateConstrainCal.clear();
	// process click
	var apos = Position.positionedOffset($(dateInputId));
	var cx = apos[0] - $("calendarDiv").getWidth() + $(dateInputId).width + 3;
	var cy = apos[1] + $(dateInputId).height + 3 - 300;
	cx = 500;
	cy = 500;
	$("calendarDiv").style.top = cy+'px';
	$("calendarDiv").style.left = cx+'px';
	$(dateInputId).select();
	var sDateValue = $(dateInputId).value;
	var rxDate = /^\d{1,2}(\-|\/|\.)\d{1,2}\1\d{4}$/
	if (rxDate.test(sDateValue)) {
		var aDate = sDateValue.split(/\//);
		dateConstrainCal.setMonth(aDate[0]-1);
		dateConstrainCal.setYear(aDate[2]);
	} else {
		alert("Invalid Date Format, please use mm/dd/yyyy or select a date using the calendar.");
	}
	// display everything
	$("calendarDiv").show();
	var viewdim = document.viewport.getDimensions();
	$("calendarDivMask").style.top = "0px";
	$("calendarDivMask").style.left = "0px";
	$("calendarDivMask").style.width = (viewdim.width - 10) + "px";
	$("calendarDivMask").style.height = (viewdim.height - 10) + "px";
	$("calendarDivMask").show();
	dateConstrainCal.render(document.body);

};

exec_body_scripts = function(body_el) {
    // Finds and executes scripts in a newly added element's body.
    // Needed since innerHTML does not run scripts.
    //
    // Argument body_el is an element in the dom.

    function nodeName(elem, name) {
          return elem.nodeName && elem.nodeName.toUpperCase() ===
                          name.toUpperCase();
            };

      function evalScript(elem) {
            var data = (elem.text || elem.textContent || elem.innerHTML || "" ),
                        head = document.getElementsByTagName("head")[0] ||
                                            document.documentElement,
                                script = document.createElement("script");

                script.type = "text/javascript";
                    try {
                            // doesn't work on ie...
                            script.appendChild(document.createTextNode(data));      
                                } catch(e) {
                                        // IE has funky script nodes
                                        script.text = data;
                                            }

                        head.insertBefore(script, head.firstChild);
                            head.removeChild(script);
                              };

        // main section of function
        var scripts = [],
                  script,
                        children_nodes = body_el.childNodes,
                              child,
                                    i;

          for (i = 0; children_nodes[i]; i++) {
                child = children_nodes[i];
                    if (nodeName(child, "script" ) &&
                              (!child.type || child.type.toLowerCase() === "text/javascript")) {
                                          scripts.push(child);
                                                }
                      }

            for (i = 0; scripts[i]; i++) {
                  script = scripts[i];
                      if (script.parentNode) {script.parentNode.removeChild(script);}
                          evalScript(scripts[i]);
                            }
};
