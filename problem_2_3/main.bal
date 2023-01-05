import ballerina/io;
import ballerina/sql;
import ballerinax/java.jdbc;

type HighPayment record {
    @sql:Column {name: "name"}
    string name;
    @sql:Column {name: "department"}
    string department;
    @sql:Column {name: "amount"}
    decimal amount;
    @sql:Column {name: "reason"}
    string reason;
};

function getHighPaymentDetails(string dbFilePath, decimal amount) returns HighPayment[]|error {
    jdbc:Client|sql:Error dbClient =
                            new ("jdbc:h2:file:" + dbFilePath,
                            "root", "root");

    if (dbClient is jdbc:Client) {
        // Query table with a condition.
        stream<HighPayment, error?> resultStream = dbClient->query(`SELECT e.name,e.department, p.amount, p.reason FROM Employee AS e LEFT JOIN Payment as p ON e.employee_id=p.employee_id WHERE p.amount>${amount} ORDER BY p.payment_id ASC;`);
        HighPayment[] result = [];
        // Iterates the result stream.
        check from HighPayment customer in resultStream
            do {
                result.push(customer);
            };

        // Closes the stream to release the resources.
        check resultStream.close();
        check dbClient.close();
        return result;

    }
        else {
        return dbClient;
    }
}

public function main() {
    io:println(getHighPaymentDetails("./db/gofigure", 3000));
}
