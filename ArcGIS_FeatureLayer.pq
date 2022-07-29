// This file contains your Data Connector logic
section ArcGIS_FeatureLayer;

client_id = Text.FromBinary(Extension.Contents("client_id"));
client_secret = Text.FromBinary(Extension.Contents("client_secret"));
redirect_uri = "https://oauth.powerbi.com/views/oauthredirect.html";
portal = "https://www.arcgis.com";
windowWidth = 800;
windowHeight = 800;

[DataSource.Kind="ArcGIS_FeatureLayer", Publish="ArcGIS_FeatureLayer.Publish"]
shared ArcGIS_FeatureLayer.Query = Value.ReplaceType(ArcGIS_FeatureLayer.Data, type function (url as Uri.Type) as any);

// Data Source Kind description
ArcGIS_FeatureLayer = [
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Refresh = Refresh
        ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
ArcGIS_FeatureLayer.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { "ArcGIS Feature Services", "Connect to ArcGIS Feature Services" },
    LearnMoreUrl = "https://arcgis.com",
    SourceImage = ArcGIS_FeatureLayer.Icons,
    SourceTypeImage = ArcGIS_FeatureLayer.Icons
];

ArcGIS_FeatureLayer.Icons = [
    Icon16 = { Extension.Contents("ArcGIS_FeatureLayer16.png"), Extension.Contents("ArcGIS_FeatureLayer20.png"), Extension.Contents("ArcGIS_FeatureLayer24.png"), Extension.Contents("ArcGIS_FeatureLayer32.png") },
    Icon32 = { Extension.Contents("ArcGIS_FeatureLayer32.png"), Extension.Contents("ArcGIS_FeatureLayer40.png"), Extension.Contents("ArcGIS_FeatureLayer48.png"), Extension.Contents("ArcGIS_FeatureLayer64.png") }
];

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

Refresh = () =>
    let
        Response = Web.Contents(portal & "/sharing/rest/oauth2/token/?", [
            Content = Text.ToBinary(Uri.BuildQueryString([
                client_id = client_id,
                refresh_token = Extension.CurrentCredential()[Properties][refresh_token],
                grant_type = "refresh_token"])),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json"]]),
        Refreshed = Json.Document(Response)
    in
        Refreshed;

ArcGIS_FeatureLayer.Data = (url as text) =>
    let

        // First, get the count of all features matching the query
        c_url =  url & "&returnCountOnly=true&token=" & Extension.CurrentCredential()[access_token],
        c_content = Web.Contents(c_url),
        c_json = Json.Document(c_content),
        count = c_json[count],

        // Get data within each of the pages https://stackoverflow.com/questions/69116913/rest-api-pagination-loop-power-query-m-language
        startAtList = List.Generate(()=>0, each _ < count, each _ +1000),
        url =  if Text.Contains(url, "?") 
            then url & "&resultRecordCount=1000&token="& Extension.CurrentCredential()[access_token] 
            else url & "?f=json&outFields=""*""&where=1=1&returnGeometry=false&resultRecordCount=1000&token="& Extension.CurrentCredential()[access_token],
        
        pages = List.Transform(startAtList, each Json.Document(Web.Contents(url & "&resultOffset=" & Text.From(_)))[features]),
        //lastPage = List.Last(pages),

        
        // Explode the list of lists into a single list

        mainList = List.Combine(pages),

        table = Table.FromList(mainList, Splitter.SplitByNothing()),

        MyTable = Table.ExpandRecordColumn(table, "Column1", {"attributes"}, {"attributes"}),

        table2 = Table.ExpandRecordColumn(
            MyTable, "attributes", Table.ColumnNames(
              Table.FromRecords(
                 List.Select(
                    Table.Column(MyTable, "attributes"), each _ <> "" and _ <> null
                 )
              )
           ),

           Table.ColumnNames(
              Table.FromRecords(
                  List.Select(
                      Table.Column(MyTable, "attributes"), each _ <> "" and _ <> null
                  )
              )
            )
        )
      

    in
        table2;
        //lastPage;