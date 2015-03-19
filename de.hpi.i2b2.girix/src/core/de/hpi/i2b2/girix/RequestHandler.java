/* 
 * Created on : 07-11-2013 
 * Author     : Bastian Weinlich
 */
package de.hpi.i2b2.girix;

import de.hpi.i2b2.girix.datavo.i2b2message.RequestMessageType;
import edu.harvard.i2b2.common.exception.I2B2Exception;

public interface RequestHandler {
	public String handleRequest(RequestMessageType input) throws I2B2Exception;
}
