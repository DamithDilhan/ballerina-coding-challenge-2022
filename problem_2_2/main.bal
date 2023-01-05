import ballerina/io;
import ballerina/sql;
import ballerinax/java.jdbc;

type Payment record {
    readonly int employee_id;
    decimal amount;
    string reason;
    string date;
};

function addPayments(string dbFilePath, string paymentFilePath) returns error|int[] {

    json|error jsonPayload = io:fileReadJson(paymentFilePath);
    if (jsonPayload is error) {
        return jsonPayload;
    }
    else {
        Payment[]|error entries = jsonPayload.cloneWithType();
        if (entries is error) {
            return entries;
        }
        jdbc:Client|sql:Error dbClient =
                            new ("jdbc:h2:" + dbFilePath,
                            "root", "root");

        if (dbClient is jdbc:Client) {
            // Creates a batch-parameterized query.
            sql:ParameterizedQuery[] insertQueries =
        from Payment data in entries
            select `INSERT INTO Payment (date, amount, employee_id, reason)
                VALUES (${data.date}, ${data.amount}, ${data.employee_id},
                ${data.reason})`;

            // Inserts the records with the auto-generated ID.
            sql:ExecutionResult[]|error result = dbClient->batchExecute(insertQueries);
            if (result is error) {
                return result;
            }
            int[] generatedIds = [];
            foreach var summary in result {
                generatedIds.push(<int>summary.lastInsertId);
            }
            return generatedIds;

        }
        else {
            return dbClient;
        }
    }
}

public function main() {
    io:println(addPayments("./db/gofigure", "tests/resources/payments.json"));
}
