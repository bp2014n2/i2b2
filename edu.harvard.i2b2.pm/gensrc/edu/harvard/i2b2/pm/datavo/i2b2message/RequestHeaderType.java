//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, vhudson-jaxb-ri-2.1-558 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.04.22 at 03:11:24 PM EDT 
//


package edu.harvard.i2b2.pm.datavo.i2b2message;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlType;


/**
 * <p>Java class for request_headerType complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="request_headerType">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="result_waittime_ms" type="{http://www.w3.org/2001/XMLSchema}int"/>
 *       &lt;/sequence>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "request_headerType", propOrder = {
    "resultWaittimeMs"
})
public class RequestHeaderType {

    @XmlElement(name = "result_waittime_ms")
    protected int resultWaittimeMs;

    /**
     * Gets the value of the resultWaittimeMs property.
     * 
     */
    public int getResultWaittimeMs() {
        return resultWaittimeMs;
    }

    /**
     * Sets the value of the resultWaittimeMs property.
     * 
     */
    public void setResultWaittimeMs(int value) {
        this.resultWaittimeMs = value;
    }

}
