section ArcGIS_FeatureLayer;

// Set out the framework for the connector
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

// Define the user parameters 
[DataSource.Kind="ArcGIS_FeatureLayer", Publish="ArcGIS_FeatureLayer.Publish"]
shared ArcGIS_FeatureLayer.Content = Value.ReplaceType(ArcGIS_FeatureLayer.Data, type function (
    url as (Uri.Type meta [
        Documentation.FieldCaption = "ArcGIS Feature Layer URL",
        Documentation.FieldDescription = "Provide an ArcGIS Feature Layer URL (including Layer ID e.g. /0). 
        Optionally, also include a query to filter the records using the spec defined at https://developers.arcgis.com/rest/services-reference/enterprise/query-feature-service-layer/. 
        If a query is not provided, the default query /query?f=json&outFields=""*""&where=1=1&returnGeometry=false will be used.
        If there is an error in your query, you will see a message saying that the field 'count' cannot be found. The query is case sensitive.
        If you don't provide a where clause or objectids in your query, the query will default to where=1=1.
        The connector is configured to never request the geometry, and will request records in batches of 1000."
])) as any meta [
    Documentation.Name = "ArcGIS Feature Layer Query"
]);

// Connection publishing description
ArcGIS_FeatureLayer.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Text.FromBinary(Extension.Contents("connector_name")), "Connect to ArcGIS Feature Layers" },
    LearnMoreUrl = "https://github.com/eaglegis/PowerBI_ArcGISConnector",
    SourceImage = ArcGIS_FeatureLayer.Icons,
    SourceTypeImage = ArcGIS_FeatureLayer.Icons
];

ArcGIS_FeatureLayer.Icons = [
    Icon16 = { Extension.Contents("ArcGIS_FeatureLayer16.png"), Extension.Contents("ArcGIS_FeatureLayer20.png"), Extension.Contents("ArcGIS_FeatureLayer24.png"), Extension.Contents("ArcGIS_FeatureLayer32.png") },
    Icon32 = { Extension.Contents("ArcGIS_FeatureLayer32.png"), Extension.Contents("ArcGIS_FeatureLayer40.png"), Extension.Contents("ArcGIS_FeatureLayer48.png"), Extension.Contents("ArcGIS_FeatureLayer64.png") }
];

// Define the oauth parameters for the connection
portal = Text.FromBinary(Extension.Contents("client_portal"));
client_id = Text.FromBinary(Extension.Contents("client_id"));
client_secret = Text.FromBinary(Extension.Contents("client_secret"));
redirect_uri = "https://oauth.powerbi.com/views/oauthredirect.html";
windowWidth = 800;
windowHeight = 800;

// Authentication - bring up oauth popup to user
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

// Refresh the token as required
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

// Main function for getting data from the feature layer and displaying it in Power BI.
ArcGIS_FeatureLayer.Data = (_url_ as text) =>
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
                            urlWithoutGeometry & "&outFields=""*""",

                    // Make sure url provides a where clause or objectid
                    urlWithWhere = 
                        if Text.Contains(urlWithOutFields, "where=") or Text.Contains(Text.Lower(urlWithOutFields), "objectids=") then 
                            urlWithOutFields 
                        else
                            urlWithOutFields & "&where=1=1"
                in
                    urlWithWhere
            else 
                _url & "?f=json&outFields=""*""&where=1=1&returnGeometry=false",


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
        output;
