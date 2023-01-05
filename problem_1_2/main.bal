import ballerina/io;

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
    int min_odometer_reading;
    int max_odometer_reading;
};

function processFuelRecords(string inputFilePath, string outputFilePath) returns error? {

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
                min_odometer_reading: val.odometer_reading,
                max_odometer_reading: val.odometer_reading
});
        }
        else {
            entry.gas_fill_up_count += 1;
            entry.total_fuel_cost += (val.gallons * val.has_price);
            entry.total_gallons += val.gallons;
            entry.max_odometer_reading = val.odometer_reading;
        }
    });
    string[][] csvContent = from FuelUsage r in fuelUsage
        order by r.employee_id ascending
        select [
            r.employee_id.toString(),
            r.gas_fill_up_count.toString(),
            r.total_fuel_cost.toString(),
            r.total_gallons.toString(),
            (r.max_odometer_reading - r.min_odometer_reading).toString()
        ];
    check io:fileWriteCsv(outputFilePath, csvContent);
}
