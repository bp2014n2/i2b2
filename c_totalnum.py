import psycopg2
from prov import provider_totalnum
from atc import atc_totalnum
from stammdaten import sd_totalnum


def generate_countquery(meta_entry):
	path = meta_entry[0]

	countquery=""
	if ("\\ATC" in path) or ("\\ICD" in path):
		countquery="SELECT COUNT(DISTINCT f.patient_num) FROM i2b2demodata.observation_fact f WHERE f.concept_cd IN (SELECT concept_cd FROM i2b2demodata.concept_dimension WHERE concept_path LIKE '" + path.replace('\\', '\\\\') + "%')"
	elif "\\Provider" in path:
		countquery="SELECT COUNT(DISTINCT f.patient_num) FROM i2b2demodata.observation_fact f WHERE f.provider_id IN (SELECT provider_id FROM i2b2demodata.provider_dimension WHERE provider_path LIKE '" + path.replace('\\', '\\\\') + "%')"
	elif "\\Stammdaten\\Alter" in path:
		# usually there are 2 conditions for age
		if meta_entry[1].find('AND') >= 0:
			countquery= "SELECT count(DISTINCT p.patient_num) FROM i2b2demodata.patient_dimension p WHERE birth_date BETWEEN " + meta_entry[1]
		else:
			countquery= "SELECT count(DISTINCT p.patient_num) FROM i2b2demodata.patient_dimension p WHERE birth_date > " + meta_entry[1]
	elif "\\Stammdaten\\Region" in path:
		countquery= "SELECT count(DISTINCT p.patient_num) FROM i2b2demodata.patient_dimension p WHERE STATECITYZIP_PATH LIKE '" + meta_entry[1].replace('\\', '\\\\') + "'"
	elif "\\Stammdaten\\Sex" in path:
		countquery= "SELECT count(DISTINCT p.patient_num) FROM i2b2demodata.patient_dimension p WHERE SEX_CD = '" + meta_entry[1] + "'"
	return countquery

def write_totalnum(meta_entry):
	print("Processing values for ", meta_entry[0])
	# calculate totalnum values
	cur2 = conn.cursor()
	countquery = generate_countquery(meta_entry)
	query= "UPDATE i2b2metadata.eva_meta SET c_totalnum = (" + countquery + ") WHERE c_fullname='" + meta_entry[0] + "'"


	print("executing query:\n ", query)
	try:
		cur2.execute(query)
	except:
		print("update query failed")

	conn.commit()
	cur2.close()


# Try to connect
try:
    conn=psycopg2.connect("dbname='i2b2' user='postgres' host='localhost' password=''")
except:
    print("Connection to database failed")

# get all paths
cur = conn.cursor()
try:
    cur.execute("SELECT c_fullname, c_dimcode FROM i2b2metadata.eva_meta WHERE NOT c_visualattributes='CA'")
except:
    print("query failed")

rows = cur.fetchall()
i=1
length = len(rows)
for row in rows:
	print("\n", i, "out of", length, "paths")
	write_totalnum(row[
	i=i+1

cur.close()