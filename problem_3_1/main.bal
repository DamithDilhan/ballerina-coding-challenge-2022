import ballerina/io;
import ballerina/http;

# The exchange rate API base URL
configurable string apiUrl = "http://localhost:8080";

type Rates record {|
    string base;
    map<decimal> rates;
|};

# Convert provided salary to local currency
#
# + salary - Salary in source currency
# + sourceCurrency - Soruce currency
# + localCurrency - Employee's local currency
# + return - Salary in local currency or error
public function convertSalary(decimal salary, string sourceCurrency, string localCurrency) returns decimal|error {

    if (sourceCurrency.length() != 3 || localCurrency.length() != 3) {
        return error("invalid country codes");
    }
    // Creates a new client with the backend URL.
    final http:Client clientEndpoint = check new (apiUrl);

    json resp = check clientEndpoint->get("/rates/" + sourceCurrency);
    Rates rates = check resp.fromJsonWithType(Rates);
    if (rates.rates.hasKey(localCurrency)) {

        decimal? convertionRate = rates.rates[localCurrency];
        decimal result = salary * <decimal>convertionRate;
        return result;
    }
    else {
        return error("Invalid localCurrency");
    }
}

public function main() {
    io:println(convertSalary(1350.25, "USD", "GBP"));
}
