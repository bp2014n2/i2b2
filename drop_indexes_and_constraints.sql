ALTER TABLE i2b2demodata.observation_fact DROP CONSTRAINT observation_fact_pk;
ALTER TABLE i2b2demodata.patient_mapping DROP CONSTRAINT patient_mapping_pk;
ALTER TABLE i2b2demodata.provider_dimension DROP CONSTRAINT provider_dimension_pk;
ALTER TABLE i2b2demodata.patient_dimension DROP CONSTRAINT patient_dimension_pk;
ALTER TABLE i2b2demodata.visit_dimension DROP CONSTRAINT visit_dimension_pk;
DROP INDEX i2b2demodata.OF_IDX_ClusteredConcept;
DROP INDEX i2b2demodata.OF_IDX_ALLObservation_Fact;
DROP INDEX i2b2demodata.OF_IDX_Start_Date;
DROP INDEX i2b2demodata.OF_IDX_Modifier;
DROP INDEX i2b2demodata.OF_IDX_Encounter_Patient;
DROP INDEX i2b2demodata.OF_IDX_UPLOADID;
DROP INDEX i2b2demodata.OF_IDX_SOURCESYSTEM_CD;
DROP INDEX i2b2demodata.OF_TEXT_SEARCH_UNIQUE;