# Microsoft Power BI - ArcGIS Feature Layer Connector

This connector allows Power BI users to use secured ArcGIS Feature Layers as data sources within their Power BI desktop models.

## Compiling the connector
1. Install Visual Studio Community 2019
2. Install the [Power Query SDK](https://www.aka.ms/powerquerysdk)
3. Clone this repository and open the solution (.sln) file
4. In ArcGIS Online or Enterprise, [register your App](https://doc.arcgis.com/en/arcgis-online/manage-data/add-items.htm#REG_APP). Name it `Power BI Desktop`.
> **Note** If you want users to access items in both of your ArcGIS sites, you will need to compile separate connectors, repeating these steps for each site.
5. In the App Settings, click **Update** and add `https://oauth.powerbi.com/views/oauthredirect.html` to the Redirect URI box. Click **Add**, then **Update**.
6. In the App Settings, click **Registered info* and copy the App ID and App Secret. Use these to populate the files client_id and client_secret in the cloned repository.
7. In the .sln Solution Explorer pane, go to the Properties of the client_id and client_secret files, and ensure that `Build Action` is set to `Compile`.
8. Click **Build** > **Build Solution**

## Install
1. Create the folder `C:\Users\<user>\Documents\Power BI Desktop\Custom Connectors` if it doesn't exist
2. Copy the .mez file from `C:\Users\<user>\source\repos\ArcGIS_FeatureLayer\bin\Debug` into the 'Custom Connectors' folder

## Usage
1. Click `Get data` and Search for `ArcGIS`
2. Enter the Query URL for the Feature Layer you want to add to to your Power BI model

> **Note** The Query URL should look like `https://services.arcgis.com/hMYNkrKaydBeWRXE/ArcGIS/rest/services/Addresses_geocoded/FeatureServer/0/query`

> **Note** The URL can include parameters to filter the query, as described in the [Query documentation](https://developers.arcgis.com/rest/services-reference/enterprise/query-feature-service-layer-.htm). 

> **Note** If you don't provide any query parameters, the default query `?f=json&outFields=""*""&where=1=1&returnGeometry=false` will be returned. Power BI will try to load all of the results matching the query. Take care if there are many features in your Feature Layer.

> **Note**  The geometry is not returned by the query. 

> **IMPORTANT** Remove resultRecordCount and resultOffset from your query string to allow the application to handle pagination. Also, the output format in your query string should be set to `f=json`.

3. Click OK, then click Sign in. This will prompt you to sign in with your ArcGIS credentials. Sign in and click OK. The data should load into PowerBI.

The connector has not been tested for use with Power BI Service via on-premise gateway.
