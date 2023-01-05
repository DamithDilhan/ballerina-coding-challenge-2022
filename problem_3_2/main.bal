import ims/billionairehub;
import ballerina/io;

# Client ID and Client Secret to connect to the billionaire API
configurable string clientId = "V5bhO97JalSWqUMcItOuKzhf1pca";
configurable string clientSecret = "eeXDwSQOfX_WZ2PMaD2rvOjyCTga";

type Billionaire record {
    string name;
    float netWorth;
    string country;
    string industry;
};

public function getTopXBillionaires(string[] countries, int x) returns string[]|error {
    // Create the client connector
    billionairehub:Client cl = check new ({auth: {clientId, clientSecret}});
    if (countries.length() == 0 || x < 0) {
        return error("Invalid input");
    }
    Billionaire[] totalRecords = [];
    foreach var item in countries {
        Billionaire[] result = check cl->getBillionaires(item);
        foreach var r in result {

            totalRecords.push(r);
        }
    }
    string[] nameofBillionare = from var b in totalRecords
        order by b.netWorth descending
        limit x
        select b.name;

    return nameofBillionare;
}

public function main() {
    io:println(getTopXBillionaires(["China", "India"],
            3));
}
