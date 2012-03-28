#!/bin/bash

source $1

DATE=$(date +%Y%m%d);
FILENAME="${DATE}_${BASENAME}.sql"

echo $FILENAME
cd $WEBROOT
drush sql-dump > $OUTPUT_DIR/$FILENAME
cd $OUTPUT_DIR
gzip $FILENAME