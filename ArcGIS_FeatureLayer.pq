section ArcGIS_FeatureLayer;

// First, we define the framework for the connector, 
//telling Power BI to Test the connection to the feature layer. 
// Should the connection fail due to the layer requiring authentication, 
//we tell it to use the methods StartLogin, FinishLogin and Refresh to 
//handle the different components of the authentication process, which will be defined later.
ArcGIS_FeatureLayer = [
    TestConnection = (dataSourcePath) => {"ArcGIS_FeatureLayer.Content", dataSourcePath},
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Refresh = Refresh
        ]
    ],
    Label = "ArcGIS Feature Layer Query"
];
[DataSource.Kind="ArcGIS_FeatureLayer", Publish="ArcGIS_FeatureLayer.Publish"]

// Next, we define the parameter name and help documentation 
// for the input that the user will see in Power BI when prompted to 
// enter the Feature Layer URL.
shared ArcGIS_FeatureLayer.Content = Value.ReplaceType(ArcGIS_FeatureLayer.Data, type function (
    url as (Uri.Type meta [
        Documentation.FieldCaption = "ArcGIS Feature Layer URL",
        Documentation.FieldDescription = "Provide an ArcGIS Feature Layer URL (including Layer ID e.g. /0). 
        Optionally, also include a query to filter the records using the spec defined at https://developers.arcgis.com/rest/services-reference/enterprise/query-feature-service-layer/. 
        If a query is not provided, the default query /query?f=json&outFields=*&where=1=1&returnGeometry=false will be used.
        If there is an error in your query, you will see a message saying that the field 'count' cannot be found. The query is case sensitive.
        If you don't provide a where clause or objectids in your query, the query will default to where=1=1.
        The connector is configured to never request the geometry, and will request records in batches of 1000."
])) as any meta [
    Documentation.Name = "ArcGIS Feature Layer Query"
]);

// Then we provide the metadata for the custom connector, 
// including the text that will be displayed in the 
// Get Data pane within Power BI, and the connector’s 
// icon (provided in different sizes to support different screen sizes).
ArcGIS_FeatureLayer.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Text.FromBinary(Extension.Contents("connector_name.config")), "Connect to ArcGIS Feature Layers" },
    LearnMoreUrl = "https://github.com/eaglegis/PowerBI_ArcGISConnector",
    SourceImage = ArcGIS_FeatureLayer.Icons,
    SourceTypeImage = ArcGIS_FeatureLayer.Icons
];

ArcGIS_FeatureLayer.Icons = [
    Icon16 = { Extension.Contents("ArcGIS_FeatureLayer16.png"), Extension.Contents("ArcGIS_FeatureLayer20.png"), Extension.Contents("ArcGIS_FeatureLayer24.png"), Extension.Contents("ArcGIS_FeatureLayer32.png") },
    Icon32 = { Extension.Contents("ArcGIS_FeatureLayer32.png"), Extension.Contents("ArcGIS_FeatureLayer40.png"), Extension.Contents("ArcGIS_FeatureLayer48.png"), Extension.Contents("ArcGIS_FeatureLayer64.png") }
];

// We then define the parameters for the OAuth2 connection which is used for authentication. 
//The actual values are pulled from the configuration files which are 
// modified when you compile the connector.
portal = Text.FromBinary(Extension.Contents("client_portal.config"));
client_id = Text.FromBinary(Extension.Contents("client_id.config"));
client_secret = Text.FromBinary(Extension.Contents("client_secret.config"));
redirect_uri = "https://oauth.powerbi.com/views/oauthredirect.html";
windowWidth = 800;
windowHeight = 800;

// The StartLogin step defines the first step of the login process. 
// This is the step that presents the login window to the user and 
// asks them to provide their credentials.
StartLogin = (resourceUrl, state, display) =>
        let
            AuthorizeUrl = portal & "/sharing/rest/oauth2/authorize/?" & Uri.BuildQueryString([
            client_id = client_id,
            response_type = "code",
            redirect_uri = redirect_uri])
        in
            [
                LoginUri = AuthorizeUrl,
                CallbackUri = redirect_uri,
                WindowHeight = windowHeight,
                WindowWidth = windowWidth,
                Context = null
            ];


// If the StartLogin step completes successfully and the user is authenticated, 
// the FinishLogin method gets the authorisation code returned in the response 
// and uses TokenMethod to convert the authentication code into an Access Token 
// (which is used to query a secure layer) and a Refresh Token 
// (which is used to keep the access token up-to-date).
FinishLogin = (context, callbackUri, state) =>
    let
        Parts = Uri.Parts(callbackUri)[Query]
    in
        TokenMethod(Parts[code]);

// Following successful authentication, exchange code for token
TokenMethod = (code) =>
    let
        Response = Web.Contents(portal & "/sharing/rest/oauth2/token/?", [
            Content = Text.ToBinary(Uri.BuildQueryString([
                client_id = client_id,
                client_secret = client_secret,
                code = code,
                redirect_uri = redirect_uri,
                grant_type = "authorization_code"])),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json"]]),
        Parts = Json.Document(Response)
    in
        Parts;

// The RefreshToken method will keep the Access Token up-to-date, 
// meaning that the user will only have to sign in again once the 
// maxTokenExpirationMinutes of the Portal is reached. 
Refresh = (redirectUri, refresh_token) =>
    let
        Response = Web.Contents(portal & "/sharing/rest/oauth2/token/?", [
            Content = Text.ToBinary(Uri.BuildQueryString([
                client_id = client_id,
                refresh_token = refresh_token,
                grant_type = "refresh_token"])),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json"]]),
        Refreshed = Json.Document(Response)
    in
        Refreshed;

//Finally, the ArcGIS_FeatureLayer.Data method is used to get and 
// parse the data from the feature layer.
// Main function for getting data from the feature layer and displaying it in Power BI.
ArcGIS_FeatureLayer.Data = (_url_ as text) =>
    // Clean up the input URL
    let
        // Function to remove resultRecordCount and resultOffset from the query
        removeQueryParams = (query as text) as text =>
            let
                // Remove resultRecordCount and resultOffset parameters
                cleanedQuery = Text.Replace(Text.Replace(query, "resultRecordCount=[0-9]+", ""), "resultOffset=[0-9]+", ""),
                // Remove any extra '&' and handle trailing '&'
                cleanedQuery2 = Text.Trim(Text.Replace(cleanedQuery, "&&", "&")),
                finalQuery = if Text.EndsWith(cleanedQuery2, "&") then Text.Start(cleanedQuery2, Text.Length(cleanedQuery2) - 1) else cleanedQuery2
            in
                finalQuery,

        // Add /query if not provided
        _url = if not Text.EndsWith(Text.BeforeDelimiter(_url_, "?"), "/query") then
                   Text.BeforeDelimiter(_url_, "?") & "/query?" & Text.AfterDelimiter(_url_, "?")
               else
                   _url_,

        url = 
            if Text.Contains(_url, "?") then
                let
                    // Make sure url is requesting json
                    urlWithJson = 
                        if Text.Contains(_url, "f=html") then 
                            Text.Replace(_url, "f=html", "f=json") 
                        else if Text.Contains(_url, "f=geojson") then 
                            Text.Replace(_url, "f=geojson", "f=json") 
                        else if Text.Contains(_url, "f=pbf") then 
                            Text.Replace(_url, "f=pbf", "f=json") 
                        else if Text.Contains(_url, "f=json") then
                            _url
                        else
                            _url & "&f=json",
                    // Make sure url is not requesting geometry
                    urlWithoutGeometry = 
                        if Text.Contains(urlWithJson, "returnGeometry=") then 
                            if Text.Contains(urlWithJson, "returnGeometry=true") then
                                Text.Replace(urlWithJson, "returnGeometry=true", "returnGeometry=false") 
                            else
                                urlWithJson
                        else
                            urlWithJson & "&returnGeometry=false",

                    // Make sure url specifies outFields
                    urlWithOutFields = 
                        if Text.Contains(Text.Lower(urlWithoutGeometry), "outfields=") then 
                            urlWithoutGeometry
                        else
                            urlWithoutGeometry & "&outFields=*",

                    // Make sure url provides a where clause or objectid
                    urlWithWhere = 
                        if Text.Contains(urlWithOutFields, "where=") or Text.Contains(Text.Lower(urlWithOutFields), "objectids=") then 
                            urlWithOutFields 
                        else
                            urlWithOutFields & "&where=1=1"
                in
                    urlWithWhere
            else 
                _url & "?f=json&outFields=*&where=1=1&returnGeometry=false",


        // First, get the count of all features matching the query
        c_url = url & "&returnCountOnly=true&token=" & Extension.CurrentCredential()[access_token],
        c_content = Web.Contents(c_url),
        c_json = Json.Document(c_content),
        count = c_json[count],

        // Generate the offset numbers for paginating the query
        startAtList = List.Generate(() => 0, each _ < count, each _ + 1000),

        // Remove unwanted parameters from the original URL
        cleanedQueryString = removeQueryParams(if Text.Contains(url, "?") then Text.AfterDelimiter(url, "?") else ""),
        requrl = if Text.Length(cleanedQueryString) = 0 then url else Text.BeforeDelimiter(url, "?") & "?" & cleanedQueryString,

        // Get data within each of the pages
        pages = List.Transform(startAtList, each Json.Document(Web.Contents(requrl & "&resultRecordCount=1000&resultOffset=" & Text.From(_)))[features]),

        // Explode the list of lists into a single list
        mainList = List.Combine(pages),

        // Convert the list to a table
        table = Table.FromList(mainList, Splitter.SplitByNothing()),

        // Expand attributes into separate columns
        MyTable = Table.ExpandRecordColumn(table, "Column1", {"attributes"}, {"attributes"}),

        output = Table.ExpandRecordColumn(
            MyTable, "attributes", Table.ColumnNames(
                Table.FromRecords(
                    List.Select(
                        Table.Column(MyTable, "attributes"), each _ <> "" and _ <> null
                    )
                )
            )      
        )
    in
        // Return the output to the user
        output;
