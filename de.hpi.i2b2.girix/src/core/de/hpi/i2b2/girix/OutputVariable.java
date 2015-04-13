package de.hpi.i2b2.girix;

public class OutputVariable {
	
	private String name;
	private String description;
	private String value;
	private String type;
	
	public OutputVariable(String name, String description, String value, String type) {
		this.name = name;
		this.description = description;
		this.value = value;
		this.type = type;
	}
	
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getDescription() {
		return description;
	}
	public void setDescription(String description) {
		this.description = description;
	}
	public String getValue() {
		return value;
	}
	public void setValue(String value) {
		this.value = value;
	}
	public String getType() {
		return type;
	}
	public void setType(String type) {
		this.type = type;
	}
	
	
	
}
