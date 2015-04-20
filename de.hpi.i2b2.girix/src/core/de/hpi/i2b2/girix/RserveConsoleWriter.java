package de.hpi.i2b2.girix;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;


public class RserveConsoleWriter extends Thread {

	private InputStream is;
	private static Log log = LogFactory.getLog(RserveConsoleWriter.class);

	RserveConsoleWriter(InputStream is) {
		this.is = is;
		start();
	}

	public void run() {
		try {
			BufferedReader br = new BufferedReader(new InputStreamReader(is));
			String line = null;
			while ((line = br.readLine()) != null) {
				log.info(line);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

}

