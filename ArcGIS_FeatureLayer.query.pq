// Use this file to write queries to test your data connector
let
    result = ArcGIS_FeatureLayer.Query("https://services2.arcgis.com/28amRQMPTiEvaF1p/ArcGIS/rest/services/AGOL_AquacultureOffshoreInvestigation_Environment/FeatureServer/22/query?f=json&outFields=""*""&where=1=1")
in
    result