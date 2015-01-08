#!/bin/bash

progress() {
  pc=0;
  while true
    do
      echo -n -e "[$pc sec]\033[0K\r"
      sleep 1
      ((pc++))
    done
}

clear;
echo "######################"
echo "Running DB Setup"
echo "######################"


# setup environment
cd ~
mkdir log
export LOG_FILE=`pwd`/log/db_setup_log.txt
touch $LOG_FILE

echo "Installing software"
progress &
progPid=$!
{
    sudo apt-get install -y ant unzip postgresql python-pip bc;
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Creating Database... "
progress &
progPid=$!
{
    sudo -u postgres psql -c "CREATE DATABASE i2b2;"
    wget -q http://54.93.194.56/setup_postgres.sql
    sudo -u postgres psql -d i2b2 -f "setup_postgres.sql"
    wget -q http://54.93.194.56/i2b2createdb-1704.zip
    unzip i2b2createdb-1704.zip
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Building i2b2... "
progress &
progPid=$!
{
    cd edu.harvard.i2b2.data/Release_1-7/NewInstall
    cd Crcdata
    ant -f data_build.xml create_crcdata_tables_release_1-7
    ant -f data_build.xml create_procedures_release_1-7
    ant -f data_build.xml db_demodata_load_data
    cd ../Hivedata
    ant -f data_build.xml create_hivedata_tables_release_1-7
    ant -f data_build.xml db_hivedata_load_data
    cd ../Imdata
    ant -f data_build.xml create_imdata_tables_release_1-7
    ant -f data_build.xml db_imdata_load_data
    cd ../Metadata
    ant -f data_build.xml create_metadata_tables_release_1-7
    ant -f data_build.xml db_metadata_load_data
    cd ../Pmdata
    ant -f data_build.xml create_pmdata_tables_release_1-7
    ant -f data_build.xml create_triggers_release_1-7
    ant -f data_build.xml db_pmdata_load_data
    cd ../Workdata
    ant -f data_build.xml create_workdata_tables_release_1-7
    ant -f data_build.xml db_workdata_load_data
    cd
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Downloading data... "
progress &
progPid=$!
{
    sudo pip install six==1.8.0
    sudo pip install awscli
    #mkdir ~/.aws
    #echo -e "[default]\naws_access_key_id=$aws_access_key_id\naws_secret_access_key=$aws_secret_access_key" >> ~/.aws/credentials
    aws s3 cp --region eu-central-1 s3://eha-hpcc/i2b2daten/26-11-2014/Datensatz.zip Datensatz.zip
    unzip Datensatz.zip
    sudo chmod 755 -R ./Datensatz
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Dropping Indexes... "
progress &
progPid=$!
{
    sudo -u postgres psql -d i2b2 -c "ALTER TABLE i2b2demodata.observation_fact DROP CONSTRAINT observation_fact_pk;
    ALTER TABLE i2b2demodata.patient_mapping DROP CONSTRAINT patient_mapping_pk;
    ALTER TABLE i2b2demodata.provider_dimension DROP CONSTRAINT provider_dimension_pk;
    ALTER TABLE i2b2demodata.patient_dimension DROP CONSTRAINT patient_dimension_pk;
    DROP INDEX i2b2demodata.OF_IDX_ClusteredConcept;
    DROP INDEX i2b2demodata.OF_IDX_ALLObservation_Fact;
    DROP INDEX i2b2demodata.OF_IDX_Start_Date;
    DROP INDEX i2b2demodata.OF_IDX_Modifier;
    DROP INDEX i2b2demodata.OF_IDX_Encounter_Patient;
    DROP INDEX i2b2demodata.OF_IDX_UPLOADID;
    DROP INDEX i2b2demodata.OF_IDX_SOURCESYSTEM_CD;
    DROP INDEX i2b2demodata.OF_TEXT_SEARCH_UNIQUE;"
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Loading data... "
progress &
progPid=$!
{
    sudo -u postgres psql -d i2b2 -c "TRUNCATE i2b2demodata.observation_fact;
    COPY i2b2demodata.observation_fact(ENCOUNTER_NUM, PATIENT_NUM, CONCEPT_CD, PROVIDER_ID, START_DATE, MODIFIER_CD, INSTANCE_NUM, VALTYPE_CD, TVAL_CHAR, NVAL_NUM, VALUEFLAG_CD, QUANTITY_NUM, UNITS_CD, END_DATE, LOCATION_CD, OBSERVATION_BLOB, CONFIDENCE_NUM, UPDATE_DATE, DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD, UPLOAD_ID) FROM '`pwd`/Datensatz/datamart/observation_fact.csv' DELIMITER '|' CSV;
    TRUNCATE i2b2demodata.patient_mapping;
    COPY i2b2demodata.patient_mapping(PATIENT_IDE, PATIENT_IDE_SOURCE, PATIENT_NUM, PATIENT_IDE_STATUS, PROJECT_ID, UPLOAD_DATE, UPDATE_DATE, DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD, UPLOAD_ID) FROM '`pwd`/Datensatz/datamart/patient_mapping.csv' DELIMITER '|' CSV;
    TRUNCATE i2b2demodata.provider_dimension;
    COPY i2b2demodata.provider_dimension(PROVIDER_ID, PROVIDER_PATH, NAME_CHAR, PROVIDER_BLOB, UPDATE_DATE, DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD, UPLOAD_ID) FROM '`pwd`/Datensatz/datamart/provider_dimension.csv' DELIMITER '|' CSV;
    TRUNCATE i2b2demodata.patient_dimension;
    COPY i2b2demodata.patient_dimension(PATIENT_NUM, VITAL_STATUS_CD, BIRTH_DATE, DEATH_DATE, SEX_CD, AGE_IN_YEARS_NUM, LANGUAGE_CD, RACE_CD, MARITAL_STATUS_CD, RELIGION_CD, ZIP_CD, STATECITYZIP_PATH, INCOME_CD, PATIENT_BLOB, UPDATE_DATE, DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD, UPLOAD_ID) FROM '`pwd`/Datensatz/stammdaten/patient_dimension.csv' DELIMITER '|' CSV;"
    sudo -u postgres psql -d i2b2 -f Datensatz/datamart/concept_dimension.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/datamart/modifier_dimension.sql
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Loading Ontologies... "
progress &
progPid=$!
{
    sudo -u postgres psql -d i2b2 -f Datensatz/ontology/ontology.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/ontology/atc-meta.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/ontology/icd-meta.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/ontology/modifier-meta.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/ontology/fg-meta.sql
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Loading Stammdaten... "
progress &
progPid=$!
{
    sudo -u postgres psql -d i2b2 -f Datensatz/stammdaten/stammdaten.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/stammdaten/alter-meta.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/stammdaten/region-meta.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/stammdaten/geschlecht-meta.sql
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Adding Indexes... "
progress &
progPid=$!
{
    sudo -u postgres psql -d i2b2 -c "ALTER TABLE i2b2demodata.observation_fact ADD CONSTRAINT observation_fact_pk PRIMARY KEY (PATIENT_NUM, CONCEPT_CD, MODIFIER_CD, START_DATE, ENCOUNTER_NUM, INSTANCE_NUM, PROVIDER_ID);
    ALTER TABLE i2b2demodata.patient_mapping ADD CONSTRAINT patient_mapping_pk PRIMARY KEY(PATIENT_IDE, PATIENT_IDE_SOURCE, PROJECT_ID);
    ALTER TABLE i2b2demodata.provider_dimension ADD CONSTRAINT provider_dimension_pk PRIMARY KEY(PROVIDER_PATH, PROVIDER_ID);
    ALTER TABLE i2b2demodata.patient_dimension ADD CONSTRAINT patient_dimension_pk PRIMARY KEY(PATIENT_NUM);
    CREATE  INDEX OF_IDX_ClusteredConcept ON i2b2demodata.OBSERVATION_FACT( CONCEPT_CD );
    CREATE INDEX OF_IDX_ALLObservation_Fact ON i2b2demodata.OBSERVATION_FACT( PATIENT_NUM , ENCOUNTER_NUM , CONCEPT_CD , START_DATE , PROVIDER_ID , MODIFIER_CD , INSTANCE_NUM, VALTYPE_CD , TVAL_CHAR , NVAL_NUM , VALUEFLAG_CD , QUANTITY_NUM , UNITS_CD , END_DATE , LOCATION_CD , CONFIDENCE_NUM);
    CREATE INDEX OF_IDX_Start_Date ON i2b2demodata.OBSERVATION_FACT(START_DATE, PATIENT_NUM);
    CREATE INDEX OF_IDX_Modifier ON i2b2demodata.OBSERVATION_FACT(MODIFIER_CD);
    CREATE INDEX OF_IDX_Encounter_Patient ON i2b2demodata.OBSERVATION_FACT(ENCOUNTER_NUM, PATIENT_NUM, INSTANCE_NUM);
    CREATE INDEX OF_IDX_UPLOADID ON i2b2demodata.OBSERVATION_FACT(UPLOAD_ID);
    CREATE INDEX OF_IDX_SOURCESYSTEM_CD ON i2b2demodata.OBSERVATION_FACT(SOURCESYSTEM_CD);
    CREATE UNIQUE INDEX OF_TEXT_SEARCH_UNIQUE ON i2b2demodata.OBSERVATION_FACT(TEXT_SEARCH_INDEX);"
} >$LOG_FILE
echo "" ; kill -13 "$progPid";