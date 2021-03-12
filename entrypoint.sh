#!/bin/sh -l

set -e

if [ -z "$INPUT_API_HOST" ]; then
  echo "'api_host' was not provided"
  exit 1
fi

if [ -z "$INPUT_ORGANISATION_GROUP_ID" ]; then
  echo "'organisation_group_id' was not provided"
  exit 1
fi

if [ -z "$INPUT_USERNAME" ]; then
  echo "'username' was not provided"
  exit 1
fi

if [ -z "$INPUT_PASSWORD" ]; then
  echo "'password' was not provided"
  exit 1
fi

if [ -z "$INPUT_TENANT_CODE" ]; then
  echo "'tenant_code' was not provided"
  exit 1
fi

if [ -z "$INPUT_APPLICATION_NAME" ]
then
  echo "'application_name' was not provided"
  exit 1
fi

if [ -z "$INPUT_APPLICATION_IDENTIFIER" ]
then
  echo "'application_identifier' was not provided"
  exit 1
fi

if [ -z "$INPUT_APPLICATION_FILE_PATH" ]
then
  echo "'application_file_path' was not provided"
  exit 1
fi

if [ -z "$INPUT_DEVICE_TYPE" ]
then
  echo "'device_type' was not provided"
  exit 1
fi

if [ -z "$INPUT_DEVICE_MODEL_ID" ]
then
  echo "'device_model_id' was not provided"
  exit 1
fi

getFileSize() {
  echo $(wc -c < "$1")
}

SPLIT_SIZE="10m"
AIRWATCH_CREDS=$(echo -n "$INPUT_USERNAME:$INPUT_PASSWORD" | base64)
CHUNK_FILE_PREFIX=airwatch_chunk_

apkFileSize=$(getFileSize "$INPUT_APPLICATION_FILE_PATH")

# Split APK into 10mb chunks and upload to Airwatch
# The initial response to uploadchunk contains the TransactionId to be used in subsequent requests

TMP_APK_CHUNK_DIR=.airwatch
TRANSACTION_ID=""
FILES=$TMP_APK_CHUNK_DIR/$CHUNK_FILE_PREFIX*
COUNTER=1

mkdir -p $TMP_APK_CHUNK_DIR
cd $TMP_APK_CHUNK_DIR
split -b $SPLIT_SIZE "$GITHUB_WORKSPACE/$INPUT_APPLICATION_FILE_PATH" $CHUNK_FILE_PREFIX
cd -

for f in $FILES
do
  chunk_data=$(base64 "$f")
  chunk_size=$(getFileSize "$f")
  chunk_body='{
      "TransactionId":"'$TRANSACTION_ID'",
      "ChunkData":"'$chunk_data'",
      "ChunkSequenceNumber":'$COUNTER',
      "TotalApplicationSize":'$apkFileSize',
      "ChunkSize":'$chunk_size'
  }'

  echo "Sending request for chunk $COUNTER..."

  response=$(echo $chunk_body | curl -X POST \
      -H "Accept: application/json;version=1" \
      -H "Content-Type: application/json" \
      -H 'Authorization: Basic '$AIRWATCH_CREDS'' \
      -H "aw-tenant-code: ${INPUT_TENANT_CODE}" \
      -d @- "$INPUT_API_HOST"/api/mam/apps/internal/uploadchunk)

  TRANSACTION_ID=$(echo $response | jq -r '.TranscationId')

  if [ "$TRANSACTION_ID" == 'null' ]; then
      echo $response
      exit 1
  fi

  COUNTER=$(( COUNTER+1 ))
done
rm -rf $TMP_APK_CHUNK_DIR
echo "Chunks uploaded with Transaction ID: $TRANSACTION_ID"

# Using given TRANSACTION_ID from uploadchunk response
# begininstall creates an application with the given name and type and returns a new application_id

fileName="$(basename "$INPUT_APPLICATION_FILE_PATH")"

response=$(curl -X POST \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -H "aw-tenant-code: ${INPUT_TENANT_CODE}" \
    -H 'Authorization: Basic '$AIRWATCH_CREDS'' \
    -d '{
 	"ApplicationName": '"'$INPUT_APPLICATION_NAME'"',
  "LocationGroupId" : '"'$INPUT_ORGANISATION_GROUP_ID'"',
 	"TransactionId": '"'$TRANSACTION_ID'"',
 	"DeviceType": '"'$INPUT_DEVICE_TYPE'"',
 	"PushMode": "Auto",
 	"FileName": '"'$fileName'"',
 	"SupportedModels": {
 		"Model": [
 			{
 			  "ModelId": '"'$INPUT_DEVICE_MODEL_ID'"'
 			}
 		]
 	}
}' "${INPUT_API_HOST}/api/mam/apps/internal/begininstall")

application_id=$(echo $response | jq -r ".Id.Value")

if [ "$application_id" == 'null' ]; then
    echo "$response"
    exit 1
fi

echo "Application $application_id is uploaded successfully"
echo "::set-output name=application_id::$application_id"
