# Microsoft Power BI - ArcGIS Feature Layer Connector

This connector allows Power BI users to use secured ArcGIS Feature Layers as data sources within their Power BI desktop models. Without it, users have to manually update their token string every 30 minutes. This method only forces users to re-authenticate when the OAuth2 refresh token expires for the Portal (2 weeks in AGOL)

Esri have provided an official approach to this, using Power Automate to update the flow. This solution is useful where this is not a possibility.
https://www.esri.com/arcgis-blog/products/power-bi/announcements/arcgis-connectors-in-power-automate/
https://powerbi.microsoft.com/en-us/blog/refresh-your-power-bi-dataset-using-microsoft-flow/

## Compiling the connector
1. Install Visual Studio Community 2019
2. Install the [Power Query SDK](https://www.aka.ms/powerquerysdk)
3. Clone this repository and open the solution (.sln) file
4. In ArcGIS Online or Enterprise, [register your App](https://doc.arcgis.com/en/arcgis-online/manage-data/add-items.htm#REG_APP). Name it `Power BI Desktop`.
> **Note** If you want users to access items in both of your ArcGIS sites, you will need to compile separate connectors, repeating these steps for each site.
5. In the App Settings, click **Update** and add `https://oauth.powerbi.com/views/oauthredirect.html` to the Redirect URI box. Click **Add**, then **Update**.
6. In the App Settings, click **Registered info* and copy the App ID and App Secret. Use these to populate the files client_id and client_secret in the cloned repository.
7. Rename Documentation.Name and Label on lines 13 and 25 to reflect the environment (ArcGIS Online or the name of your Portal) this will be used to connect to.
8. In the .sln Solution Explorer pane, go to the Properties of the client_id and client_secret files, and ensure that `Build Action` is set to `Compile`.
9. Click **Build** > **Build Solution**

## Power BI Desktop
### Install
1. Create the folder `C:\Users\<user>\Documents\Power BI Desktop\Custom Connectors` if it doesn't exist
2. Copy the .mez file from `C:\Users\<user>\source\repos\ArcGIS_FeatureLayer\bin\Debug` into the 'Custom Connectors' folder

### Usage
1. Click `Get data` and Search for `ArcGIS`
2. Enter the Query URL for the Feature Layer you want to add to to your Power BI model

> **Note** The Query URL should look like `https://services.arcgis.com/hMYNkrKaydBeWRXE/ArcGIS/rest/services/Addresses_geocoded/FeatureServer/0/query`

> **Note** The URL can include parameters to filter the query, as described in the [Query documentation](https://developers.arcgis.com/rest/services-reference/enterprise/query-feature-service-layer-.htm). 

> **Note** If you don't provide any query parameters, the default query `?f=json&outFields=""*""&where=1=1&returnGeometry=false` will be returned. Power BI will try to load all of the results matching the query. Take care if there are many features in your Feature Layer.

> **Note**  The geometry is not returned by the query. 

> **IMPORTANT** Remove resultRecordCount and resultOffset from your query string to allow the application to handle pagination. Also, the output format in your query string should be set to `f=json`.

3. Click OK, then click Sign in. This will prompt you to sign in with your ArcGIS credentials. Sign in and click OK. The data should load into PowerBI.


## Power BI Online
### Install
To use your custom connector in Power BI's online interface, you need to set up the On Premises Data Gateway. I found the 'personal mode' gateway did not work.
1. Download and install the gateway from https://powerbi.microsoft.com/en-us/gateway/
2. Configure the gateway to pick up your custom connector as described here: https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-custom-connectors
3. Navigate to https://app.powerbi.com/groups/me/gateways - you should see the gateway you have set up under 'On-premises data gateways'
4. Under the Data Sources tab on https://app.powerbi.com/groups/me/gateways, Click New
5. Select your gateway under Gateway Cluster name
6. Under Data Source name, type "ArcGIS Online" (or your Portal's name, if you have configured the connector's client application against a Portal)
7. Under Data source type, select "ArcGIS Feature Layer Query" (yours may have a different name, if you have compiled it with different Label)
8. Under URL, paste the query endpoint of a secure layer within your Portal. This will be used to generate and validate access tokens to the resources
9. Under Authentication method, select OAuth2 and click Edit credentials. Enter valid credentials for the service
> **Note** I believe this data source will have to be shared with all users who need to access the dataset, so you may want to consider creating multiple data sources which you can share to users based on role - i.e. if you use an admin/service account credentials when registering the data source, users may be able to access more ArcGIS data than they would normally be allowed to see.

![Data source configuration](https://github.com/eaglegis/PowerBI_ArcGISConnector/blob/master/docs/New_datasource.png)

### Usage

1. Publish a dashboard containing an ArcGIS Feature Layer as described in `Power BI Desktop - Usage`
2. In Power BI Online, navigate to Datasets>Settings https://app.powerbi.com/groups/me/settings/datasets/<dataset-id>?
3. Under Gateway Connection, select your gateway and the appropriate data source in the dropdown. This will tell the dataset to use the credentials of the registered data source when refreshing the dataset.

![Gateway configuration](https://github.com/eaglegis/PowerBI_ArcGISConnector/blob/master/docs/Gateway_connection.png)
  
You can then set up scheduled or manual refreshes, and the data will continue to update until the refresh_token expires. Once it does, you must navigate to https://app.powerbi.com/groups/me/gateways, select your data source and click "edit credentials". Re-authorise the data source and refresh will start working again.
