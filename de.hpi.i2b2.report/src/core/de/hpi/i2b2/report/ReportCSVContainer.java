/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */
package de.hpi.i2b2.report;

// This class just holds a csv string and a boolean value indicating that the csv String has data rows
public class ReportCSVContainer {
	
	private String csvString;
	private boolean hasData;
	
	public ReportCSVContainer(String csvString, boolean hasData) {
		this.csvString = csvString;
		this.hasData = hasData;
	}
	
	public String getString() {
		return this.csvString;
	}
	
	public boolean hasData() {
		return this.hasData;
	}
	
}
