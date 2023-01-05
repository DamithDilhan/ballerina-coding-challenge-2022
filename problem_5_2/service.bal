import ballerina/graphql;
import ballerina/http;

type ActivityData record {
    readonly string date;
    int steps;
    Heart heart;
};

type Heart record {
    int min;
    int max;
    float caloriesOut;
    int minutes;
    string name;
};

type StepRespone record {
    string? date;
    int steps;
};

type StepResponseArray record {
    StepRespone[] activity;
};

type HeartResponse record {
    string? date;
    Heart heart;
};

type HeartResponseArray record {
    HeartResponse[] activity;
};

// Don't change the port number
service /graphql on new graphql:Listener(9090) {

    // Write your answer here. You must change the input and
    // the output of the below signature along with the logic.
    resource function get activity(string ID) returns ActivityDetails[] {
        http:Client|error fitfitEp = new ("http://localhost:9091");
        if (fitfitEp is error) {
            return [];
        }
        json|error stepResponse = fitfitEp->get("/activities/v2/steps/user/1");

        if (stepResponse is error) {
            return [];
        }
        json|error heartResponse = fitfitEp->get("/activities/v2/heart/user/1");
        if (heartResponse is error) {
            return [];
        }
        StepResponseArray|error stepData = stepResponse.cloneWithType(StepResponseArray);
        if (stepData is error) {
            return [];
        }
        HeartResponseArray|error heartData = heartResponse.cloneWithType(HeartResponseArray);
        if (heartData is error) {
            return [];
        }
        ActivityData[] dataTable = from StepRespone d1 in stepData.activity
            join HeartResponse d2 in heartData.activity
                                on d1.date equals d2.date
            where d1.date != () && d2.date != ()
            select {
                date: <string>d1.date,
                steps: d1.steps,
                heart: {min: d2.heart.min, max: d2.heart.max, caloriesOut: d2.heart.caloriesOut, minutes: d2.heart.minutes, name: d2.heart.name}
        };

        return dataTable.map(entry => new ActivityDetails(entry));
    }
}

service class ActivityDetails {
    private final readonly & ActivityData entryRecord;

    function init(ActivityData entryRecord) {
        self.entryRecord = entryRecord.cloneReadOnly();
    }

    resource function get date() returns string {
        return self.entryRecord.date;
    }

    resource function get steps() returns int {
        return self.entryRecord.steps;

    }

    resource function get heart() returns Heart {
        return self.entryRecord.heart;
    }
}
