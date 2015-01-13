ALTER TABLE i2b2demodata.observation_fact ADD CONSTRAINT observation_fact_pk PRIMARY KEY (PATIENT_NUM, CONCEPT_CD, MODIFIER_CD, START_DATE, ENCOUNTER_NUM, INSTANCE_NUM, PROVIDER_ID);
ALTER TABLE i2b2demodata.patient_mapping ADD CONSTRAINT patient_mapping_pk PRIMARY KEY(PATIENT_IDE, PATIENT_IDE_SOURCE, PROJECT_ID);
ALTER TABLE i2b2demodata.provider_dimension ADD CONSTRAINT provider_dimension_pk PRIMARY KEY(PROVIDER_PATH, PROVIDER_ID);
ALTER TABLE i2b2demodata.patient_dimension ADD CONSTRAINT patient_dimension_pk PRIMARY KEY(PATIENT_NUM);
ALTER TABLE i2b2demodata.visit_dimension ADD CONSTRAINT visit_dimension_pk PRIMARY KEY(encounter_num, patient_num);
CREATE  INDEX OF_IDX_ClusteredConcept ON i2b2demodata.OBSERVATION_FACT( CONCEPT_CD );
CREATE INDEX OF_IDX_ALLObservation_Fact ON i2b2demodata.OBSERVATION_FACT( PATIENT_NUM , ENCOUNTER_NUM , CONCEPT_CD , START_DATE , PROVIDER_ID , MODIFIER_CD , INSTANCE_NUM, VALTYPE_CD , TVAL_CHAR , NVAL_NUM , VALUEFLAG_CD , QUANTITY_NUM , UNITS_CD , END_DATE , LOCATION_CD , CONFIDENCE_NUM);
CREATE INDEX OF_IDX_Start_Date ON i2b2demodata.OBSERVATION_FACT(START_DATE, PATIENT_NUM);
CREATE INDEX OF_IDX_Modifier ON i2b2demodata.OBSERVATION_FACT(MODIFIER_CD);
CREATE INDEX OF_IDX_Encounter_Patient ON i2b2demodata.OBSERVATION_FACT(ENCOUNTER_NUM, PATIENT_NUM, INSTANCE_NUM);
CREATE INDEX OF_IDX_UPLOADID ON i2b2demodata.OBSERVATION_FACT(UPLOAD_ID);
CREATE INDEX OF_IDX_SOURCESYSTEM_CD ON i2b2demodata.OBSERVATION_FACT(SOURCESYSTEM_CD);
CREATE UNIQUE INDEX OF_TEXT_SEARCH_UNIQUE ON i2b2demodata.OBSERVATION_FACT(TEXT_SEARCH_INDEX);
CREATE  INDEX VD_IDX_AGE_IN_YEARS ON i2b2demodata.VISIT_DIMENSION (AGE_IN_YEARS);
CREATE  INDEX VD_IDX_TREATMENT ON i2b2demodata.VISIT_DIMENSION (TREATMENT);