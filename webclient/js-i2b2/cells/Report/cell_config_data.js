// this file contains a list of all files that need to be loaded dynamically for this i2b2 Cell
// every file in this list will be loaded after the cell's Init function is called
{
	files: [
		"i2b2_msgs.js"
	],
	config: {
		// additional configuration variables that are set by the system
		name: "Report Messaging",
		category: ["core","cell"],
		paramTranslation: [
			{thinClientName:'queryTimeout', defaultValue:3600}
		]
	}
}
