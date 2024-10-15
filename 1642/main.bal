import ballerina/io;
import ballerinax/health.clients.fhir as fhirClient;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhirr4;

// Connection parameters to the  Cerner EMR
configurable string base = ?;
configurable string tokenUrl = ?;
configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string[] scopes = ?;

// Create a FHIR client configuration
fhirClient:FHIRConnectorConfig cernerConfig = {
    baseURL: base,
    mimeType: fhirClient:FHIR_JSON,
    authConfig: {
        tokenUrl: tokenUrl,
        clientId: clientId,
        clientSecret: clientSecret,
        scopes: scopes
    }
};

// Create a FHIR client
final fhirClient:FHIRConnector fhirConnectorObj = check new (cernerConfig);

service / on new fhirr4:Listener(7082, slotApiConfig) {
    isolated resource function get fhir/r4/Slot(r4:FHIRContext fhirContext) returns error|r4:Bundle {
        map<string[]> queryParams = {};

        r4:StringSearchParameter[]|r4:FHIRTypeError? practitionerArray = fhirContext.getStringSearchParameter("practitioner");

        if practitionerArray is r4:StringSearchParameter[] && practitionerArray.length() > 0 {
            queryParams["practitioner"] = [practitionerArray[0].value];
        }

        r4:StringSearchParameter[]|r4:FHIRTypeError? startDateArray = fhirContext.getStringSearchParameter("startDate");

        if startDateArray is r4:StringSearchParameter[] && startDateArray.length() > 0 {
            queryParams["start"] = [string `ge${startDateArray[0].value}T06:00:00Z`];
        }

        r4:StringSearchParameter[]|r4:FHIRTypeError? endDateArray = fhirContext.getStringSearchParameter("endDate");

        if endDateArray is r4:StringSearchParameter[] && endDateArray.length() > 0 {
            queryParams["start"] = [string `lt${endDateArray[0].value}T23:00:00Z`];
        }

        queryParams["service-type"] = ["https://fhir.cerner.com/ec2458f2-1e24-41c8-b71b-0e701af7583d/codeSet/14249|4047611"];
        queryParams["_count"] = ["15"];

        io:println("queryParams \n",queryParams,"\n");

        fhirClient:FHIRResponse searchResponse = check fhirConnectorObj->search("Slot", queryParams);     
        return searchResponse.'resource.cloneWithType();
    }
}
