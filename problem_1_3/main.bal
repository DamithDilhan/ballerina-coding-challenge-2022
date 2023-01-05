import ballerina/io;

type FillUpEntry record {
    readonly int employeeId;
    int odometerReading;
    decimal gallons;
    decimal gasPrice;
};

type OdemeterRecord record {
    readonly int employeeId;
    int prevReading;
    int curReading;
};

type EmployeeFillUpSummary record {
    readonly int employeeId;
    int gasFillUpCount;
    decimal totalFuelCost;
    decimal totalGallons;
    int totalMilesAccrued;
};

function processFuelRecords(string inputFilePath, string outputFilePath) returns error? {
    // Write your code here
    json jsonPayload = check io:fileReadJson(inputFilePath);
    FillUpEntry[] entries = check jsonPayload.cloneWithType();

    table<EmployeeFillUpSummary> key(employeeId) tbl = table [];
    table<OdemeterRecord> key(employeeId) odeTbl = table [];

    foreach FillUpEntry item in entries {

        EmployeeFillUpSummary? entry = tbl[item.employeeId];
        OdemeterRecord? odeEntry = odeTbl[item.employeeId];

        if ((entry == ()) || (odeEntry == ())) {
            tbl.add({
                employeeId: item.employeeId,
                gasFillUpCount: 1,
                totalFuelCost: item.gallons * item.gasPrice,
                totalGallons: item.gallons,
                totalMilesAccrued: 0
            });
            odeTbl.add({
                employeeId: item.employeeId,
                prevReading: item.odometerReading,
                curReading: item.odometerReading
            });

        }
        else {
            entry.gasFillUpCount += 1;
            entry.totalFuelCost += item.gallons * item.gasPrice;
            entry.totalGallons += item.gallons;
            odeEntry.curReading = item.odometerReading;
            entry.totalMilesAccrued = (odeEntry.curReading - odeEntry.prevReading);
        }
    }

    EmployeeFillUpSummary[] result = from EmployeeFillUpSummary r in tbl
        order by r.employeeId ascending
        select r;

    json newPayload = result.toJson();
    check io:fileWriteJson(outputFilePath, newPayload);
}

public function main() {
    string inputFilepath = "tests/resources/example02_input.json";
    string outputFilePath = "target/example01_output.json";

    io:println(processFuelRecords(inputFilepath, outputFilePath));
}

