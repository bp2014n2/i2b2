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
    aws s3 cp --region eu-central-1 s3://eha-hpcc/i2b2daten/12-01-2015/Datensatz.zip Datensatz.zip
    unzip Datensatz.zip
    sudo chmod 755 -R ./Datensatz
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Dropping Indexes... "
progress &
progPid=$!
{
    sudo chmod 755 ./i2b2/drop_indexes_and_constraints.sql
    sudo -u postgres psql -d i2b2 -f i2b2/drop_indexes_and_constraints.sql
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Loading data... "
progress &
progPid=$!
{
    sudo -u postgres psql -d i2b2 -c "TRUNCATE i2b2demodata.observation_fact;
    COPY i2b2demodata.observation_fact(ENCOUNTER_NUM, PATIENT_NUM, CONCEPT_CD, PROVIDER_ID, START_DATE, MODIFIER_CD, INSTANCE_NUM, VALTYPE_CD, TVAL_CHAR, NVAL_NUM, VALUEFLAG_CD, QUANTITY_NUM, UNITS_CD, END_DATE, LOCATION_CD, OBSERVATION_BLOB, CONFIDENCE_NUM, UPDATE_DATE, DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD, UPLOAD_ID) FROM '`pwd`/Datensatz/csv/observation_fact.csv' DELIMITER '|' CSV;
    TRUNCATE i2b2demodata.patient_mapping;
    COPY i2b2demodata.patient_mapping(PATIENT_IDE, PATIENT_IDE_SOURCE, PATIENT_NUM, PATIENT_IDE_STATUS, PROJECT_ID, UPLOAD_DATE, UPDATE_DATE, DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD, UPLOAD_ID) FROM '`pwd`/Datensatz/csv/patient_mapping.csv' DELIMITER '|' CSV;
    TRUNCATE i2b2demodata.provider_dimension;
    COPY i2b2demodata.provider_dimension(PROVIDER_ID, PROVIDER_PATH, NAME_CHAR, PROVIDER_BLOB, UPDATE_DATE, DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD, UPLOAD_ID) FROM '`pwd`/Datensatz/csv/provider_dimension.csv' DELIMITER '|' CSV;
    TRUNCATE i2b2demodata.patient_dimension;
    COPY i2b2demodata.patient_dimension(PATIENT_NUM, VITAL_STATUS_CD, BIRTH_DATE, DEATH_DATE, SEX_CD, AGE_IN_YEARS_NUM, LANGUAGE_CD, RACE_CD, MARITAL_STATUS_CD, RELIGION_CD, ZIP_CD, STATECITYZIP_PATH, INCOME_CD, PATIENT_BLOB, UPDATE_DATE, DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD, UPLOAD_ID) FROM '`pwd`/Datensatz/csv/patient_dimension.csv' DELIMITER '|' CSV;
    TRUNCATE i2b2demodata.visit_dimension;
    ALTER TABLE i2b2demodata.visit_dimension ADD COLUMN AGE_IN_YEARS INT NULL;
    ALTER TABLE i2b2demodata.visit_dimension ADD COLUMN TREATMENT INT NULL;
    COPY i2b2demodata.visit_dimension(ENCOUNTER_NUM, PATIENT_NUM, ACTIVE_STATUS_CD, START_DATE, END_DATE, INOUT_CD, LOCATION_CD, LOCATION_PATH, LENGTH_OF_STAY, VISIT_BLOB, UPDATE_DATE, DOWNLOAD_DATE, IMPORT_DATE, SOURCESYSTEM_CD, UPLOAD_ID, AGE_IN_YEARS, TREATMENT) FROM '`pwd`/Datensatz/csv/visit_dimension.csv' DELIMITER '|' CSV;"
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/atc-concept-dimension.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/icd-concept-dimension.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/ops-concept-dimension.sql
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Loading Ontologies... "
progress &
progPid=$!
{
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/ontology.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/atc-meta.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/icd-meta.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/modifier_dimension.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/modifier-meta.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/fg-meta.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/kh-meta.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/ops-meta.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/visit-meta.sql
    sudo -u postgres psql -d i2b2 -f i2b2/insert_basecodes.sql
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Loading Stammdaten... "
progress &
progPid=$!
{
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/stammdaten.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/alter-meta.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/region-meta.sql
    sudo -u postgres psql -d i2b2 -f Datensatz/sql/geschlecht-meta.sql
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Adding Indexes... "
progress &
progPid=$!
{
    sudo chmod 755 ./i2b2/create_indexes_and_constraints.sql
    sudo -u postgres psql -d i2b2 -f i2b2/create_indexes_and_constraints.sql
} >$LOG_FILE
echo "" ; kill -13 "$progPid";
