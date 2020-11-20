#!/bin/bash

## Conventions:
##
## Working directory has the same name as the s3 bucket.
## Script is executed from the parent of this directory.
##

BUCKET=$1

if [ ! -d ${BUCKET} ]; then 
  echo "Directory '${BUCKET}' not found."
  exit
fi

inotifywait -m -qr -e modify,create,delete,moved_to,moved_from --format '%e %w%f' ${BUCKET} | while true 
do
   read -r op file;
   case $op in
   
    ## Simple case: creating or modifying a file, upload it.
    CREATE | MODIFY | MOVED_TO)
      aws s3 cp $file s3://$file
      ;;

    MOVED_TO,ISDIR) 
      aws s3 sync $file s3://$file
      ;;

    MOVED_FROM,ISDIR)
      aws s3 rm s3://$file --recursive
      ;;
      
    DELETE | MOVED_FROM)
      aws s3 rm s3://$file
      ;;

    DELETE,ISDIR | CREATE,ISDIR)
      echo Ignoring directories - S3 creates and destroys automatically
      ;;

    *)
      echo Unexpected op $op on file $file
      ;;
    esac
done
