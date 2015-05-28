R -e "library('devtools'); library(roxygen2); create('I2B2API')"
cp ~/i2b2/GIRIXScripts/lib/i2b2.crc.r ~/i2b2/I2B2API/R
cd I2B2API
touch i2b2.crc.config.r
sed -i "/Title/c\Title: API to i2b2 that is exposed to the R IDE" DESCRIPTION
sed -i "/Version/c\Version: 1.0" DESCRIPTION
sed -i '/License/c\License: Proprietary, ownership of Elsevier Health Analytics' DESCRIPTION
sed -i '/Authors/c\Authors@R: person("Carl", "Ambroselli", email = "i2b2@carl-ambroselli.de", role = c("aut", "cre"))' DESCRIPTION
sed -i "/Description/c\Description: This documentation describes the available functions that can be used in the R-IDE web interface." DESCRIPTION
R -e 'library(devtools);i2b2<-list();document()'
cd ../
R CMD Rd2pdf I2B2API
rm -rf I2B2API
mv I2B2API.pdf webclient/assets/db-doku.pdf
