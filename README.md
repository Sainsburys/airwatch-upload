# AirWatch Upload Action

This action uploads an .apk or .ipa to AirWatch returning the application ID in case of a
successful upload.

## Inputs

##### `api_host`

**Required** The base AirWatch URL to be used when uploading the application.
 
##### `organisation_group_id`

**Required** The AirWatch organisation group ID to be used when uploading the application.

##### `username`

**Required** The AirWatch username used for credentials.

##### `password`

**Required** The AirWatch password used for credentials.

##### `tenant_code`

**Required** The AirWatch tenant code used for credentials.

##### `application_name`

**Required** The application name used on AirWatch list of apps.

##### `application_identifier`

**Required** The application identifier of the .apk or .ipa being uploaded.

##### `application_file_path`

**Required** The file path to the .apk or .ipa to be uploaded.

##### `device_model_id`

**Required** The device model of the application to be uploaded.

| Model      | Value |
| ---------- | ----- |
| iOS        |   1   |
| Android    |   5   |

##### `device_type`

**Required** The device type of the application to be uploaded.

| Device type   | Value |
| ------------- | ----- |
| iOS phone     |   2   |
| Android phone |   5   |

## Outputs

##### `application_id`

The ID given to the application by AirWatch upon a successful upload.

## Example usage

```
upload-to-airwatch:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Run tests
        run: echo 'Do your testing...'
      - name: Upload action step
        uses: edisonspencer/airwatch-upload@1.0.0
        id: upload
        with:
          api_host: ${{ secrets.API_HOST }}
          organisation_group_id: ${{ secrets.ORGANISATION_GROUP_ID }}
          username: ${{ secrets.USERNAME }}
          password: ${{ secrets.PASSWORD }}
          tenant_code: ${{ secrets.TENANT_CODE }}
          application_name: ${{ secrets.APPLICATION_NAME }}
          application_identifier: ${{ secrets.APPLICATION_IDENTIFIER }}
          application_file_path: 'app/build/outputs/apk/acceptance/app-acceptance.apk'
          device_type: '5'
          device_model_id: '5'
```