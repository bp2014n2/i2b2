/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */
package de.erlangen.i2b2.giri;

import de.erlangen.i2b2.giri.datavo.i2b2message.RequestMessageType;
import edu.harvard.i2b2.common.exception.I2B2Exception;

public interface RequestHandler {
	public String handleRequest(RequestMessageType input) throws I2B2Exception;
}
