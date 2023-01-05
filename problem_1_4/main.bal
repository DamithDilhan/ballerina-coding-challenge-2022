import ballerina/io;

xmlns "http://www.so2w.org" as s;

type FuelUsage record {
    readonly int employee_id;
    int gas_fill_up_count;
    decimal total_fuel_cost;
    decimal total_gallons;
    int min_odometer_reading;
    int max_odometer_reading;
};

function processFuelRecords(string inputFilePath, string outputFilePath) returns error? {
    // Write your code here
    xml readXml = check io:fileReadXml(inputFilePath);
    xml content = readXml.<s:FuelEvents>.children();
    xml fuelEvents = content.<s:FuelEvent>;
    table<FuelUsage> key(employee_id) fuelUsage = table [];

    foreach var item in fuelEvents {
        xml<xml:Element|xml:Comment|xml:ProcessingInstruction|xml:Text> child = item.children();

        string employeeIdS = check item.employeeId;
        int employeeId = check int:fromString(employeeIdS);
        int odometerReading = check int:fromString(child.<s:odometerReading>.data());
        decimal gallons = check decimal:fromString(child.<s:gallons>.data());
        decimal gasPrice = check decimal:fromString(child.<s:gasPrice>.data());

        FuelUsage? entry = fuelUsage[employeeId];
        if (entry == ()) {
            fuelUsage.add({
                employee_id: employeeId,
                gas_fill_up_count: 1,
                total_fuel_cost: gallons * gasPrice,
                total_gallons: gallons,
                min_odometer_reading: odometerReading,
                max_odometer_reading: odometerReading
            });
        }
        else {
            entry.gas_fill_up_count += 1;
            entry.total_fuel_cost += (gallons * gasPrice);
            entry.total_gallons += gallons;
            entry.max_odometer_reading = odometerReading;
        }
    }
    xml outputData = from FuelUsage r in fuelUsage
        order by r.employee_id ascending
        select xml `<s:employeeFuelRecord employeeId="${r.employee_id.toString()}"><s:gasFillUpCount>${r.gas_fill_up_count}</s:gasFillUpCount><s:totalFuelCost>${r.total_fuel_cost}</s:totalFuelCost><s:totalGallons>${r.total_gallons}</s:totalGallons><s:totalMilesAccrued>${r.max_odometer_reading - r.min_odometer_reading}</s:totalMilesAccrued></s:employeeFuelRecord>`;

    xml writeContent = xml `<s:employeeFuelRecords xmlns:s="http://www.so2w.org">${outputData}</s:employeeFuelRecords>`;
    check io:fileWriteXml(outputFilePath, writeContent);
}

public function main() {
    io:println(processFuelRecords("tests/resources/example01_input.xml", "target/example01_output.xml"));
}
