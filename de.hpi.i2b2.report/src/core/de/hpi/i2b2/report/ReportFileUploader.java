package de.hpi.i2b2.report;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;



public class ReportFileUploader {
	
	private String requestUrl;
	private String username;
	
	public ReportFileUploader(String requestUrl, String username) {
		
		this.requestUrl = requestUrl;
		this.username = username;
		
	}
	
	private MultipartBuilder initializeMultipart() throws IOException {
		
		MultipartBuilder multipart = new MultipartBuilder(this.requestUrl);
		multipart.addFormField("user", this.username);
		return multipart;
		
	}
	
	public List<String> uploadFile(File file, String fileName, String type) {
 
		MultipartBuilder multipart;
		List<String> response = new ArrayList<String>();
		
		try {
			multipart = initializeMultipart();		
			
			multipart.addFormField("type", type);
	         
	        multipart.addFilePart("file", file);
	
	        response = multipart.send();
		} catch (IOException e) {
			
		}
        
        return response;
    }
	
}
