/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */
package de.erlangen.i2b2.giri;

// This class just holds a csv string and a boolean value indicating that the csv String has data rows
public class GIRICSVContainer {
	
	private String csvString;
	private boolean hasData;
	
	public GIRICSVContainer(String csvString, boolean hasData) {
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
