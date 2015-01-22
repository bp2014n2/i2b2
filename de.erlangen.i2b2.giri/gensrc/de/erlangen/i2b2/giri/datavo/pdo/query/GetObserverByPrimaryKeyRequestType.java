//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.0.2-b01-fcs 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.04.28 at 11:05:30 PM MESZ 
//


package de.erlangen.i2b2.giri.datavo.pdo.query;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlType;


/**
 * <p>Java class for GetObserverByPrimaryKey_requestType complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="GetObserverByPrimaryKey_requestType">
 *   &lt;complexContent>
 *     &lt;extension base="{http://www.i2b2.org/xsd/cell/crc/pdo/1.1/}requestType">
 *       &lt;sequence>
 *         &lt;element name="observer_primary_key" type="{http://www.i2b2.org/xsd/cell/crc/pdo/1.1/}observer_primary_key_Type"/>
 *         &lt;element name="observer_output_option" type="{http://www.i2b2.org/xsd/cell/crc/pdo/1.1/}output_optionType"/>
 *       &lt;/sequence>
 *     &lt;/extension>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "GetObserverByPrimaryKey_requestType", propOrder = {
    "observerPrimaryKey",
    "observerOutputOption"
})
public class GetObserverByPrimaryKeyRequestType
    extends RequestType
{

    @XmlElement(name = "observer_primary_key", required = true)
    protected ObserverPrimaryKeyType observerPrimaryKey;
    @XmlElement(name = "observer_output_option", required = true)
    protected OutputOptionType observerOutputOption;

    /**
     * Gets the value of the observerPrimaryKey property.
     * 
     * @return
     *     possible object is
     *     {@link ObserverPrimaryKeyType }
     *     
     */
    public ObserverPrimaryKeyType getObserverPrimaryKey() {
        return observerPrimaryKey;
    }

    /**
     * Sets the value of the observerPrimaryKey property.
     * 
     * @param value
     *     allowed object is
     *     {@link ObserverPrimaryKeyType }
     *     
     */
    public void setObserverPrimaryKey(ObserverPrimaryKeyType value) {
        this.observerPrimaryKey = value;
    }

    /**
     * Gets the value of the observerOutputOption property.
     * 
     * @return
     *     possible object is
     *     {@link OutputOptionType }
     *     
     */
    public OutputOptionType getObserverOutputOption() {
        return observerOutputOption;
    }

    /**
     * Sets the value of the observerOutputOption property.
     * 
     * @param value
     *     allowed object is
     *     {@link OutputOptionType }
     *     
     */
    public void setObserverOutputOption(OutputOptionType value) {
        this.observerOutputOption = value;
    }

}
