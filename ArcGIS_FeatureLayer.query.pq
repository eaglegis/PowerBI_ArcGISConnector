// Use this file to write queries to test your data connector
let
    result = ArcGIS_FeatureLayer.Query("https://services.arcgis.com/hMYNkrKaydBeWRXE/arcgis/rest/services/Addresses_geocoded/FeatureServer/0/query?f=html&outFields=""*""&where=1=1")
in
    result