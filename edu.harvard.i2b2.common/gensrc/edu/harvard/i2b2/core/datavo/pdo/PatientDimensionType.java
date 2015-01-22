//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v@@BUILD_VERSION@@ 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2014.04.28 at 11:05:15 PM MESZ 
//


package edu.harvard.i2b2.core.datavo.pdo;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlType;
import javax.xml.bind.annotation.adapters.CollapsedStringAdapter;
import javax.xml.bind.annotation.adapters.XmlJavaTypeAdapter;
import javax.xml.datatype.XMLGregorianCalendar;


/**
 * One row of data from the patient_dimension table.
 * 
 * <p>Java class for patient_dimensionType complex type.
 * 
 * <p>The following schema fragment specifies the expected content contained within this class.
 * 
 * <pre>
 * &lt;complexType name="patient_dimensionType">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;group ref="{http://www.i2b2.org/xsd/hive/pdo/}patient_idChoice"/>
 *         &lt;element name="vital_status_cd" type="{http://www.i2b2.org/xsd/hive/pdo/}Vital_Status_CdType" minOccurs="0"/>
 *         &lt;element name="birth_date" type="{http://www.i2b2.org/xsd/hive/pdo/}Birth_DateType" minOccurs="0"/>
 *         &lt;element name="death_date" type="{http://www.i2b2.org/xsd/hive/pdo/}Death_DateType" minOccurs="0"/>
 *         &lt;element name="sex_cd" type="{http://www.i2b2.org/xsd/hive/pdo/}Sex_CdType" minOccurs="0"/>
 *         &lt;element name="age_in_years_num" type="{http://www.i2b2.org/xsd/hive/pdo/}Age_In_Years_NumType" minOccurs="0"/>
 *         &lt;element name="language_cd" type="{http://www.i2b2.org/xsd/hive/pdo/}Language_CdType" minOccurs="0"/>
 *         &lt;element name="race_cd" type="{http://www.i2b2.org/xsd/hive/pdo/}Race_CdType" minOccurs="0"/>
 *         &lt;element name="marital_status_cd" type="{http://www.i2b2.org/xsd/hive/pdo/}Marital_Status_CdType" minOccurs="0"/>
 *         &lt;element name="religion_cd" type="{http://www.i2b2.org/xsd/hive/pdo/}Religion_CdType" minOccurs="0"/>
 *         &lt;element name="zip_cd" type="{http://www.i2b2.org/xsd/hive/pdo/}Zip_CdType" minOccurs="0"/>
 *         &lt;element name="statecityzip_path" type="{http://www.i2b2.org/xsd/hive/pdo/}StateCityZip_PathType" minOccurs="0"/>
 *         &lt;element name="patient_blob" type="{http://www.i2b2.org/xsd/hive/pdo/}Patient_BlobType" minOccurs="0"/>
 *         &lt;group ref="{http://www.i2b2.org/xsd/hive/pdo/}annotationGroup"/>
 *       &lt;/sequence>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "patient_dimensionType", propOrder = {
    "patientNum",
    "patientId",
    "patientIde",
    "vitalStatusCd",
    "birthDate",
    "deathDate",
    "sexCd",
    "ageInYearsNum",
    "languageCd",
    "raceCd",
    "maritalStatusCd",
    "religionCd",
    "zipCd",
    "statecityzipPath",
    "patientBlob",
    "updateDate",
    "downloadDate",
    "importDate",
    "sourcesystemCd",
    "uploadId"
})
public class PatientDimensionType {

    @XmlElement(name = "patient_num")
    protected Integer patientNum;
    @XmlElement(name = "patient_id")
    protected PatientIdType patientId;
    @XmlElement(name = "patient_ide")
    protected PatientIdeType patientIde;
    @XmlElement(name = "vital_status_cd")
    protected VitalStatusCdType vitalStatusCd;
    @XmlElement(name = "birth_date")
    protected XMLGregorianCalendar birthDate;
    @XmlElement(name = "death_date")
    protected XMLGregorianCalendar deathDate;
    @XmlElement(name = "sex_cd")
    protected String sexCd;
    @XmlElement(name = "age_in_years_num")
    protected Integer ageInYearsNum;
    @XmlElement(name = "language_cd")
    @XmlJavaTypeAdapter(CollapsedStringAdapter.class)
    protected String languageCd;
    @XmlElement(name = "race_cd")
    @XmlJavaTypeAdapter(CollapsedStringAdapter.class)
    protected String raceCd;
    @XmlElement(name = "marital_status_cd")
    @XmlJavaTypeAdapter(CollapsedStringAdapter.class)
    protected String maritalStatusCd;
    @XmlElement(name = "religion_cd")
    @XmlJavaTypeAdapter(CollapsedStringAdapter.class)
    protected String religionCd;
    @XmlElement(name = "zip_cd")
    @XmlJavaTypeAdapter(CollapsedStringAdapter.class)
    protected String zipCd;
    @XmlElement(name = "statecityzip_path")
    @XmlJavaTypeAdapter(CollapsedStringAdapter.class)
    protected String statecityzipPath;
    @XmlElement(name = "patient_blob")
    protected PatientBlobType patientBlob;
    @XmlElement(name = "update_date")
    protected XMLGregorianCalendar updateDate;
    @XmlElement(name = "download_date")
    protected XMLGregorianCalendar downloadDate;
    @XmlElement(name = "import_date")
    protected XMLGregorianCalendar importDate;
    @XmlElement(name = "sourcesystem_cd")
    @XmlJavaTypeAdapter(CollapsedStringAdapter.class)
    protected String sourcesystemCd;
    @XmlElement(name = "upload_id")
    protected Integer uploadId;

    /**
     * Gets the value of the patientNum property.
     * 
     * @return
     *     possible object is
     *     {@link Integer }
     *     
     */
    public Integer getPatientNum() {
        return patientNum;
    }

    /**
     * Sets the value of the patientNum property.
     * 
     * @param value
     *     allowed object is
     *     {@link Integer }
     *     
     */
    public void setPatientNum(Integer value) {
        this.patientNum = value;
    }

    /**
     * Gets the value of the patientId property.
     * 
     * @return
     *     possible object is
     *     {@link PatientIdType }
     *     
     */
    public PatientIdType getPatientId() {
        return patientId;
    }

    /**
     * Sets the value of the patientId property.
     * 
     * @param value
     *     allowed object is
     *     {@link PatientIdType }
     *     
     */
    public void setPatientId(PatientIdType value) {
        this.patientId = value;
    }

    /**
     * Gets the value of the patientIde property.
     * 
     * @return
     *     possible object is
     *     {@link PatientIdeType }
     *     
     */
    public PatientIdeType getPatientIde() {
        return patientIde;
    }

    /**
     * Sets the value of the patientIde property.
     * 
     * @param value
     *     allowed object is
     *     {@link PatientIdeType }
     *     
     */
    public void setPatientIde(PatientIdeType value) {
        this.patientIde = value;
    }

    /**
     * Gets the value of the vitalStatusCd property.
     * 
     * @return
     *     possible object is
     *     {@link VitalStatusCdType }
     *     
     */
    public VitalStatusCdType getVitalStatusCd() {
        return vitalStatusCd;
    }

    /**
     * Sets the value of the vitalStatusCd property.
     * 
     * @param value
     *     allowed object is
     *     {@link VitalStatusCdType }
     *     
     */
    public void setVitalStatusCd(VitalStatusCdType value) {
        this.vitalStatusCd = value;
    }

    /**
     * Gets the value of the birthDate property.
     * 
     * @return
     *     possible object is
     *     {@link XMLGregorianCalendar }
     *     
     */
    public XMLGregorianCalendar getBirthDate() {
        return birthDate;
    }

    /**
     * Sets the value of the birthDate property.
     * 
     * @param value
     *     allowed object is
     *     {@link XMLGregorianCalendar }
     *     
     */
    public void setBirthDate(XMLGregorianCalendar value) {
        this.birthDate = value;
    }

    /**
     * Gets the value of the deathDate property.
     * 
     * @return
     *     possible object is
     *     {@link XMLGregorianCalendar }
     *     
     */
    public XMLGregorianCalendar getDeathDate() {
        return deathDate;
    }

    /**
     * Sets the value of the deathDate property.
     * 
     * @param value
     *     allowed object is
     *     {@link XMLGregorianCalendar }
     *     
     */
    public void setDeathDate(XMLGregorianCalendar value) {
        this.deathDate = value;
    }

    /**
     * Gets the value of the sexCd property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getSexCd() {
        return sexCd;
    }

    /**
     * Sets the value of the sexCd property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setSexCd(String value) {
        this.sexCd = value;
    }

    /**
     * Gets the value of the ageInYearsNum property.
     * 
     * @return
     *     possible object is
     *     {@link Integer }
     *     
     */
    public Integer getAgeInYearsNum() {
        return ageInYearsNum;
    }

    /**
     * Sets the value of the ageInYearsNum property.
     * 
     * @param value
     *     allowed object is
     *     {@link Integer }
     *     
     */
    public void setAgeInYearsNum(Integer value) {
        this.ageInYearsNum = value;
    }

    /**
     * Gets the value of the languageCd property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getLanguageCd() {
        return languageCd;
    }

    /**
     * Sets the value of the languageCd property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setLanguageCd(String value) {
        this.languageCd = value;
    }

    /**
     * Gets the value of the raceCd property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getRaceCd() {
        return raceCd;
    }

    /**
     * Sets the value of the raceCd property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setRaceCd(String value) {
        this.raceCd = value;
    }

    /**
     * Gets the value of the maritalStatusCd property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getMaritalStatusCd() {
        return maritalStatusCd;
    }

    /**
     * Sets the value of the maritalStatusCd property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setMaritalStatusCd(String value) {
        this.maritalStatusCd = value;
    }

    /**
     * Gets the value of the religionCd property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getReligionCd() {
        return religionCd;
    }

    /**
     * Sets the value of the religionCd property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setReligionCd(String value) {
        this.religionCd = value;
    }

    /**
     * Gets the value of the zipCd property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getZipCd() {
        return zipCd;
    }

    /**
     * Sets the value of the zipCd property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setZipCd(String value) {
        this.zipCd = value;
    }

    /**
     * Gets the value of the statecityzipPath property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getStatecityzipPath() {
        return statecityzipPath;
    }

    /**
     * Sets the value of the statecityzipPath property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setStatecityzipPath(String value) {
        this.statecityzipPath = value;
    }

    /**
     * Gets the value of the patientBlob property.
     * 
     * @return
     *     possible object is
     *     {@link PatientBlobType }
     *     
     */
    public PatientBlobType getPatientBlob() {
        return patientBlob;
    }

    /**
     * Sets the value of the patientBlob property.
     * 
     * @param value
     *     allowed object is
     *     {@link PatientBlobType }
     *     
     */
    public void setPatientBlob(PatientBlobType value) {
        this.patientBlob = value;
    }

    /**
     * Gets the value of the updateDate property.
     * 
     * @return
     *     possible object is
     *     {@link XMLGregorianCalendar }
     *     
     */
    public XMLGregorianCalendar getUpdateDate() {
        return updateDate;
    }

    /**
     * Sets the value of the updateDate property.
     * 
     * @param value
     *     allowed object is
     *     {@link XMLGregorianCalendar }
     *     
     */
    public void setUpdateDate(XMLGregorianCalendar value) {
        this.updateDate = value;
    }

    /**
     * Gets the value of the downloadDate property.
     * 
     * @return
     *     possible object is
     *     {@link XMLGregorianCalendar }
     *     
     */
    public XMLGregorianCalendar getDownloadDate() {
        return downloadDate;
    }

    /**
     * Sets the value of the downloadDate property.
     * 
     * @param value
     *     allowed object is
     *     {@link XMLGregorianCalendar }
     *     
     */
    public void setDownloadDate(XMLGregorianCalendar value) {
        this.downloadDate = value;
    }

    /**
     * Gets the value of the importDate property.
     * 
     * @return
     *     possible object is
     *     {@link XMLGregorianCalendar }
     *     
     */
    public XMLGregorianCalendar getImportDate() {
        return importDate;
    }

    /**
     * Sets the value of the importDate property.
     * 
     * @param value
     *     allowed object is
     *     {@link XMLGregorianCalendar }
     *     
     */
    public void setImportDate(XMLGregorianCalendar value) {
        this.importDate = value;
    }

    /**
     * Gets the value of the sourcesystemCd property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getSourcesystemCd() {
        return sourcesystemCd;
    }

    /**
     * Sets the value of the sourcesystemCd property.
     * 
     * @param value
     *     allowed object is
     *     {@link String }
     *     
     */
    public void setSourcesystemCd(String value) {
        this.sourcesystemCd = value;
    }

    /**
     * Gets the value of the uploadId property.
     * 
     * @return
     *     possible object is
     *     {@link Integer }
     *     
     */
    public Integer getUploadId() {
        return uploadId;
    }

    /**
     * Sets the value of the uploadId property.
     * 
     * @param value
     *     allowed object is
     *     {@link Integer }
     *     
     */
    public void setUploadId(Integer value) {
        this.uploadId = value;
    }

}