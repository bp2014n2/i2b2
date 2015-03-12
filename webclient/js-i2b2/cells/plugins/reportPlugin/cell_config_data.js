// this file contains a list of all files that need to be loaded dynamically for this plugin
// every file in this list will be loaded after the plugin's Init function is called
{
	files:[ "reportpluginCtrl.js", "report_modLabRange.js" ],
	css:[ "reportplugin.css" ],
	config: {
		// additional configuration variables that are set by the system
		short_name: "ReportPlugin",
		name: "Report: Statistical functions",
		description: "This plugin provides several statistical functions based on the statistic program R.",
		category: ["plugin"],
		plugin: {
			isolateHtml: false,  	// this means do not use an IFRAME
			isolateComm: true,	// this means to expect the plugin to use AJAX communications provided by the framework
			standardTabs: true, // this means the plugin uses standard tabs at top
			html: {
				source: 'injected_screens.html',
				mainDivId: 'reportplugin-mainDiv'
			}
		}
	}
}