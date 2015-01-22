//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.0.2-b01-fcs 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.04.28 at 11:05:30 PM MESZ 
//


package de.erlangen.i2b2.giri.datavo.pdo.query;

import javax.xml.bind.annotation.XmlEnum;
import javax.xml.bind.annotation.XmlEnumValue;


/**
 * <p>Java class for outputOptionSelectType.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * <p>
 * <pre>
 * &lt;simpleType name="outputOptionSelectType">
 *   &lt;restriction base="{http://www.i2b2.org/xsd/cell/crc/pdo/1.1/}tokenType">
 *     &lt;enumeration value="using_input_list"/>
 *     &lt;enumeration value="using_filter_list"/>
 *   &lt;/restriction>
 * &lt;/simpleType>
 * </pre>
 * 
 */
@XmlEnum
public enum OutputOptionSelectType {

    @XmlEnumValue("using_input_list")
    USING_INPUT_LIST("using_input_list"),
    @XmlEnumValue("using_filter_list")
    USING_FILTER_LIST("using_filter_list");
    private final String value;

    OutputOptionSelectType(String v) {
        value = v;
    }

    public String value() {
        return value;
    }

    public static OutputOptionSelectType fromValue(String v) {
        for (OutputOptionSelectType c: OutputOptionSelectType.values()) {
            if (c.value.equals(v)) {
                return c;
            }
        }
        throw new IllegalArgumentException(v.toString());
    }

}
