//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.0.2-b01-fcs 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.04.28 at 11:05:30 PM MESZ 
//


package de.erlangen.i2b2.giri.datavo.giriconfig;

import javax.xml.bind.JAXBElement;
import javax.xml.bind.annotation.XmlElementDecl;
import javax.xml.bind.annotation.XmlRegistry;
import javax.xml.namespace.QName;


/**
 * This object contains factory methods for each 
 * Java content interface and Java element interface 
 * generated in the de.erlangen.i2b2.giri.datavo.giriconfig package. 
 * <p>An ObjectFactory allows you to programatically 
 * construct new instances of the Java representation 
 * for XML content. The Java representation of XML 
 * content can consist of schema derived interfaces 
 * and classes representing the binding of schema 
 * type definitions, element declarations and model 
 * groups.  Factory methods for each of these are 
 * provided in this class.
 * 
 */
@XmlRegistry
public class ObjectFactory {

    private final static QName _Rscriptlet_QNAME = new QName("http://www.i2b2.org/xsd/cell/giriconf/1.0/", "Rscriptlet");

    /**
     * Create a new ObjectFactory that can be used to create new instances of schema derived classes for package: de.erlangen.i2b2.giri.datavo.giriconfig
     * 
     */
    public ObjectFactory() {
    }

    /**
     * Create an instance of {@link OutputType }
     * 
     */
    public OutputType createOutputType() {
        return new OutputType();
    }

    /**
     * Create an instance of {@link CustomOutputsType }
     * 
     */
    public CustomOutputsType createCustomOutputsType() {
        return new CustomOutputsType();
    }

    /**
     * Create an instance of {@link SettingsType }
     * 
     */
    public SettingsType createSettingsType() {
        return new SettingsType();
    }

    /**
     * Create an instance of {@link ItemsType }
     * 
     */
    public ItemsType createItemsType() {
        return new ItemsType();
    }

    /**
     * Create an instance of {@link InputType }
     * 
     */
    public InputType createInputType() {
        return new InputType();
    }

    /**
     * Create an instance of {@link AdditionalInputsType }
     * 
     */
    public AdditionalInputsType createAdditionalInputsType() {
        return new AdditionalInputsType();
    }

    /**
     * Create an instance of {@link RscriptletType }
     * 
     */
    public RscriptletType createRscriptletType() {
        return new RscriptletType();
    }

    /**
     * Create an instance of {@link JAXBElement }{@code <}{@link RscriptletType }{@code >}}
     * 
     */
    @XmlElementDecl(namespace = "http://www.i2b2.org/xsd/cell/giriconf/1.0/", name = "Rscriptlet")
    public JAXBElement<RscriptletType> createRscriptlet(RscriptletType value) {
        return new JAXBElement<RscriptletType>(_Rscriptlet_QNAME, RscriptletType.class, null, value);
    }

}
