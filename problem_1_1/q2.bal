import ballerina/io;
import ballerina/file;

type Employee record {
    readonly int employee_id;
    int odometer_reading;
    decimal gallons;
    decimal has_price;
};

type FuelUsage record {
    readonly int employee_id;
    int gas_fill_up_count;
    decimal total_fuel_cost;
    decimal total_gallons;
    int total_miles_accrued;
    int last_odometer_reading;
};

function processFuelRecords(string inputFilePath, string outputFilePath) returns error? {
    // Write your code here
    boolean|file:Error fileExists = check file:test(inputFilePath, file:EXISTS);
    if (fileExists is file:Error) {
        return fileExists;
    }
    stream<Employee, io:Error?> csvStream = check
                                        io:fileReadCsvAsStream(inputFilePath);
    table<FuelUsage> key(employee_id) fuelUsage = table [];
    check csvStream.forEach(function(Employee val) {
        FuelUsage? entry = fuelUsage[val.employee_id];
        if (entry == ()) {
            fuelUsage.add({
                employee_id: val.employee_id,
                gas_fill_up_count: 1,
                total_fuel_cost: val.gallons * val.has_price,
                total_gallons: val.gallons,
                last_odometer_reading: val.odometer_reading,
                total_miles_accrued: 0
            });
        }
        else {
            entry.gas_fill_up_count += 1;
            entry.total_fuel_cost += (val.gallons * val.has_price);
            entry.total_gallons += val.gallons;
            entry.total_miles_accrued += val.odometer_reading - entry.last_odometer_reading;
            entry.last_odometer_reading = val.odometer_reading;
        }
    });
    string[][] csvContent = from FuelUsage r in fuelUsage
        select [
            r.employee_id.toString(),
            r.gas_fill_up_count.toString(),
            r.total_fuel_cost.toString(),
            r.total_gallons.toString(),
            r.total_miles_accrued == 0 ? r.last_odometer_reading.toString() : r.total_miles_accrued.toString()
        ];
    check io:fileWriteCsv(outputFilePath, csvContent);
}

public function main() returns error? {
    return processFuelRecords("example00_input.csv", "output01_.csv");
}
