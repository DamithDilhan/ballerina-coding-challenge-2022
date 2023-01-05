// function getHighPaymentEmployees(string dbFilePath, decimal amount) returns string[]|error {
//     //Add your logic here
//     return [];
// }
import ballerina/io;
import ballerina/sql;
import ballerinax/java.jdbc;

type HighPayment record {
    @sql:Column {name: "payment_id"}
    readonly int payment_id;
    @sql:Column {name: "name"}
    string employee_name;
    @sql:Column {name: "amount"}
    decimal amount;
};

function getHighPaymentEmployees(string dbFilePath, decimal amount) returns string[]|error {
    jdbc:Client|sql:Error dbClient =
                            new ("jdbc:h2:file:" + dbFilePath,
                            "root", "root");

    if (dbClient is jdbc:Client) {
        // Query table with a condition.
        stream<HighPayment, error?> resultStream = dbClient->query(`SELECT e.name, p.payment_id, p.amount FROM Employee AS e LEFT JOIN Payment as p ON e.employee_id=p.employee_id WHERE p.amount> -1;`);
        table<HighPayment> key(payment_id) highPaymentTable = table [];
        // Iterates the result stream.
        check from HighPayment customer in resultStream
            do {
                highPaymentTable.add(customer);
            };

        // Closes the stream to release the resources.
        check resultStream.close();
        check dbClient.close();
        string[] unprocessEmployees = from HighPayment data in highPaymentTable
            where data.amount > amount
            order by data.employee_name ascending
            select data.employee_name;
        map<int> processEmployees = {};
        foreach string name in unprocessEmployees {
            processEmployees[name] = 1;
        }
        return processEmployees.keys();

    }
        else {
        return dbClient;
    }
}

public function main() {
    io:println(getHighPaymentEmployees("./db/gofigure", 3000));
}
