#!/bin/bash

CONFIG=$1

source $CONFIG

echo ""
echo "************************************************"
echo "${SITENAME} Sync (Production -> Staging)"
echo "************************************************"
echo ""

HELPFILE=/home/johndoe/bin/.pull_help
BACKUP_DB_FIRST=0
DOWNLOAD_DB=0
INSTALL_DB=0
DOWNLOAD_FILES=1
DOWNLOAD_HTACCESS=0

DATE=$(date +%Y%m%d)
DBFILE="${DATE}_${DB_BASENAME}.sql"

if [ -z $RSYNC_EXCLUDE ]; then
  RSYNC_EXCLUDE=/dev/null
fi

if [ -z $REMOTESITEDIR ]; then
  REMOTESITEDIR="default"
fi

if [ -z $LOCALSITEDIR ]; then
  LOCALSITEDIR="default"
fi


# Configure command-line settings
if [ $# -eq 0 -o "$1" = "--help" ]; then
    cat $HELPFILE
    exit;
fi

for arg in $*
do
  if [ "$arg" = "--download-db" ]; then
    DOWNLOAD_DB=1
  elif [ "$arg" = "--download-files" ]; then
    DOWNLOAD_FILES=1
  elif [ "$arg" = "--skip-download-files" ]; then
    DOWNLOAD_FILES=0
  elif [ "$arg" = "--download-htaccess" ]; then
    DOWNLOAD_HTACCESS=0
  elif [ "$arg" = "--install-db" ]; then
    INSTALL_DB=1
    DOWNLOAD_DB=1
  elif [ "$arg" = "--install-db-only" ]; then
    INSTALL_DB=1
    DOWNLOAD_DB=0
    DOWNLOAD_FILES=0
  elif [ "$arg" = "--backup-local-db" ]; then
    BACKUP_DB_FIRST=1
  elif [ "$arg" = "--debug" ]; then
    set -x
  fi;
done

  if [ $BACKUP_DB_FIRST -eq 1 ]; then
    DB_BACKUP="$LOCALDBDIR/${DATE}_${DBNAME}_local.sql"
    echo "Backing up local database"
    cd $LOCALDIR/sites/$LOCALSITEDIR
    drush sql-dump > $DB_BACKUP
    cd $LOCALDBDIR
    gzip $DB_BACKUP
  fi

if [ $DOWNLOAD_DB -eq 1 ]; then
  echo "Triggering remote server to generate fresh database backup"
  ssh -p"$REMOTEPORT" $REMOTEUSER@$REMOTEHOST "${PREP_SCRIPT} ${PREP_SCRIPT_CONFIG}"
  echo "Downloading latest database"
  rsync -e"ssh -p${REMOTEPORT}" -azu $REMOTEUSER@$REMOTEHOST:$REMOTEDBDIR/$DBFILE.gz $LOCALDBDIR
else
  echo "Skipping database download"
fi

if [ $DOWNLOAD_FILES -eq 1 ]; then
  if [ $DOWNLOAD_HTACCESS -eq 1 ]; then
    echo "Downloading .htaccess file"
    rsync --exclude-from=$RSYNC_EXCLUDE -e"ssh -p${REMOTEPORT}" -azu $REMOTEUSER@$REMOTEHOST:$REMOTEDIR/.htaccess $LOCALDIR
  fi

  echo "Downloading files directory"
  rsync --exclude-from=$RSYNC_EXCLUDE -e"ssh -p${REMOTEPORT}" -azu $REMOTEUSER@$REMOTEHOST:$REMOTEDIR/sites/$REMOTESITEDIR/files/ $LOCALDIR/sites/$LOCALSITEDIR/files/
  
  echo "Downloading modules directory"
  rsync --exclude-from=$RSYNC_EXCLUDE -e"ssh -p${REMOTEPORT}" -azu $REMOTEUSER@$REMOTEHOST:$REMOTEDIR/sites/$REMOTESITEDIR/modules/ $LOCALDIR/sites/$LOCALSITEDIR/modules/

  echo "Downloading themes directory"
  rsync --exclude-from=$RSYNC_EXCLUDE -e"ssh -p${REMOTEPORT}" -azu $REMOTEUSER@$REMOTEHOST:$REMOTEDIR/sites/$REMOTESITEDIR/themes/ $LOCALDIR/sites/$LOCALSITEDIR/themes/

  echo "Downloading sites/all/modules directory"
  rsync --exclude-from=$RSYNC_EXCLUDE -e"ssh -p${REMOTEPORT}" -azu $REMOTEUSER@$REMOTEHOST:$REMOTEDIR/sites/all/modules/ $LOCALDIR/sites/all/modules/

  echo "Downloading sites/all/libraries directory"
  rsync --exclude-from=$RSYNC_EXCLUDE -e"ssh -p${REMOTEPORT}" -azu $REMOTEUSER@$REMOTEHOST:$REMOTEDIR/sites/all/libraries/ $LOCALDIR/sites/all/libraries/

  echo "Changing directories to $LOCALDIR"
  cd $LOCALDIR

  echo "Updating permissions"
  sudo fix-permissions.sh $LOCALDIR $LOCALUSER
else
  echo "Skipping file download"
fi

if [ $INSTALL_DB -eq 1 ]; then
  echo "Changing directories to $LOCALDBDIR"
  cd $LOCALDBDIR

  echo "Uncompressing database SQL file"
  gunzip $DBFILE.gz

  echo "Loading database SQL file"
  mysql -u $DBUSER -p$DBPASS -D$DBNAME -e "source $LOCALDBDIR/$DBFILE"
else
  echo "Skipping database install"
fi