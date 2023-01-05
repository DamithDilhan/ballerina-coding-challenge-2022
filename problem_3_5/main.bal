import ballerina/http;
// import ballerina/io;

import problem_3_5.customers;
import problem_3_5.sales;

type Q "Q1"|"Q2"|"Q3"|"Q4";

type Quarter [int, Q];

type SaleRecord record {
    readonly string customerId;
    decimal amount;
};

function findTopXCustomers(Quarter[] quarters, int x) returns customers:Customer[]|error {
    // final http:Client customerEp = check new ("http://localhost:8080/customers");
    // json customersJson = check customerEp->get("/");
    table<SaleRecord> key(customerId) salesTable = table [];

    final http:Client salesEp = check new ("http://localhost:8080/sales");
    foreach Quarter item in quarters {
        sales:SalesArr salesList = check salesEp->get(string `?year=${item[0]}&quarter=${item[1]}`);
        foreach sales:Sales sale in salesList {
            SaleRecord? entry = salesTable[sale.customerId];
            if (entry == ()) {
                salesTable.add({
                    "customerId": sale.customerId,
                    "amount": sale.amount.clone()
                });
            }
            else {
                entry.amount += sale.amount;
            }
        }
    }
    // customers:Customer[] customerList = check customersJson.cloneWithType(customers:CustomerArr);
    string[] customerIds = from SaleRecord data in salesTable
        order by data.amount descending
        limit x
        select data.customerId;
    customers:Customer[] results = [];
    final http:Client customerEp = check new ("http://localhost:8080/customers");
    foreach string customer in customerIds {
        customers:Customer customerData = check customerEp->get(string `/${customer}`);
        results.push(customerData);
    }
    return results;
}

// public function main() {
//     io:println(findTopXCustomers([[2022, "Q1"], [2021, "Q3"]], 3));
// }
