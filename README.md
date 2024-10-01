# Microsoft Power BI - ArcGIS Feature Layer Connector

This connector allows Power BI users to use secured ArcGIS Feature Layers as data sources within their Power BI desktop models. Without it, users have to manually update their token string every 30 minutes. This method only forces users to re-authenticate when the OAuth2 refresh token expires for the Portal (2 weeks in AGOL)

Esri have provided an official approach to this, using Power Automate to update the flow. This solution is useful where this is not a possibility.
https://www.esri.com/arcgis-blog/products/power-bi/announcements/arcgis-connectors-in-power-automate/
https://powerbi.microsoft.com/en-us/blog/refresh-your-power-bi-dataset-using-microsoft-flow/

## Compiling the connector
1. Install Visual Studio Code
2. Install the [Power Query SDK](https://marketplace.visualstudio.com/items?itemName=PowerQuery.vscode-powerquery-sdk)
3. Clone this repository and open the folder in VS Code
4. In ArcGIS Online or Enterprise, [register your App](https://doc.arcgis.com/en/arcgis-online/manage-data/add-items.htm#REG_APP). Name it `Power BI Desktop`.
> **Note** If you want users to access items in both of your ArcGIS sites, you will need to compile separate connectors, repeating these steps for each site.
5. In the App Settings, click **Update** and add `https://oauth.powerbi.com/views/oauthredirect.html` to the Redirect URI box. Click **Add**, then **Update**.
6. In the App Settings, click **Registered info* and copy the App ID and App Secret. Use these to populate the files client_id and client_secret in the cloned repository.
7. Change the `Button Text` within the `ArcGIS_FeatureLayer.Publish` object (ArcGIS_FeatureLayer.pq, line 33) to reflect the name of the environment (ArcGIS Online or the name of your Portal) this will be used to connect to.
8. Press F1 and type "Build Task". Select the `Tasks: Run Build Task` option.
9. Select "Build project using MakePQX"
10. The Connector will build and get stored in the `[project]/bin/AnyCPU/Debug` folder

## Power BI Desktop
### Install
1. Create the folder `C:\Users\<user>\Documents\Power BI Desktop\Custom Connectors` if it doesn't exist
2. Copy the .mez file from `[project]/bin/AnyCPU/Debug` into the new 'Custom Connectors' folder

### Usage
1. Click `Get data` and Search for `ArcGIS`
2. Enter the Query URL for the Feature Layer you want to add to to your Power BI model

> **Note** The Query URL should look like `https://services.arcgis.com/hMYNkrKaydBeWRXE/ArcGIS/rest/services/Addresses_geocoded/FeatureServer/0/query`

> **Note** The URL can include parameters to filter the query, as described in the [Query documentation](https://developers.arcgis.com/rest/services-reference/enterprise/query-feature-service-layer-.htm). 

> **Note** If you don't provide any query parameters, the default query `?f=json&outFields=""*""&where=1=1&returnGeometry=false` will be returned. Power BI will try to load all of the results matching the query. Take care if there are many features in your Feature Layer.

> **Note**  The geometry is not returned by the query. 

> **IMPORTANT** Remove resultRecordCount and resultOffset from your query string to allow the application to handle pagination. Also, the output format in your query string should be set to `f=json`.

3. Click OK, then click Sign in. This will prompt you to sign in with your ArcGIS credentials. Sign in and click OK. The data should load into PowerBI.