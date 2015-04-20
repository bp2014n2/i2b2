package de.hpi.i2b2.girix;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;


public class WindowsRLocator extends Thread {

	InputStream is;
	String installPath;

	public WindowsRLocator(InputStream is) {
		this.is = is;
		start();
	}

	public String getInstallPath() {
		return installPath;
	}

	public void run() {
		try {
			BufferedReader br = new BufferedReader(new InputStreamReader(is));
			String line = null;
			while ((line = br.readLine()) != null) {
				// we are supposed to capture the output from REG command
				int i = line.indexOf("InstallPath");
				if (i >= 0) {
					String s = line.substring(i + 11).trim();
					int j = s.indexOf("REG_SZ");
					if (j >= 0) {
						s = s.substring(j + 6).trim();
					}
					installPath = s;
				}
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

}

