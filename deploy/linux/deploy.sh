#!/bin/bash
#
#   Script to simplify uploading to rokus.
#   Set the roku credentials in ../rokus.txt.
#   Script will: 
#       - Create the zip file
#       - Upload to each roku specified
#   

ZIP_FILENAME="myvideobuzz.zip"
CODE_LOCATION="../.."
MAKE_ZIP=false

cd $CODE_LOCATION
if $MAKE_ZIP
then
    zip -r $ZIP_FILENAME --exclude=*.git* --exclude=*zip --exclude=deploy* *
else
    echo "not making zip file per settigs"
fi

while read cfgline; do 
    if [[ $cfgline != \;* ]]
    then
        IFS=' ' read -ra PARTS <<< "$cfgline"
        echo "Uploading to " ${PARTS[0]}
        STATUS=`curl --connect-timeout 10 --write-out %{http_code} --user ${PARTS[1]} -o /dev/null --digest -s -S -F "mysubmit=Install" -F "archive=@$ZIP_FILENAME" http://${PARTS[0]}/plugin_install`
        case ${STATUS} in
            200)
                echo "ok"
                ;;
            401)
                echo "authentication failed"
                ;;
              *)
                echo "i don't think that worked. status code:" $STATUS
        esac
    fi
done < deploy/rokus.txt
cd - 
