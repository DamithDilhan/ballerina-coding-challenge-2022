import ballerina/graphql;
import ballerina/http;

public enum TimeUnit {
    SECONDS,
    MINUTES
}

type Levels record {
    int deep;
    int wake;
    int light;
};

type Summary record {
    int minutes;
    int thirtyDayAvgMinutes;
};

type Sleep record {
    string date;
    int duration;
    record {
        map<Summary> summary;
    } levels;
};

type SleepResponse record {
    Sleep[] sleep;
};

// Don't change the port number
service /graphql on new graphql:Listener(9090) {

    // Write your answer here. You must change the input and
    // the output of the below signature along with the logic.
    resource function get sleepSummary(string ID, TimeUnit timeunit) returns SleepSummary[] {
        http:Client|error fitfitEp = new ("http://localhost:9091");
        if (fitfitEp is error) {
            return [];
        }
        json|error response = fitfitEp->get("/activities/summary/sleep/user/1");

        if (response is error) {
            return [];
        }

        SleepResponse|error arr = response.cloneWithType(SleepResponse);
        if (arr is error) {
            return [];
        }
        return arr.sleep.map(entry => new SleepSummary(entry, timeunit));
    }
}

service class SleepSummary {

    private final readonly & Sleep entryRecord;
    private final TimeUnit timeunit;

    function init(Sleep entryRecord, TimeUnit timeunit) {
        self.entryRecord = entryRecord.cloneReadOnly();
        self.timeunit = timeunit;
    }

    resource function get date() returns string {
        return self.entryRecord.date;
    }

    resource function get duration() returns int {
        return self.timeunit == SECONDS ? self.entryRecord.duration * 60 : self.entryRecord.duration;
    }

    resource function get levels() returns Levels {
        Summary deep = self.entryRecord.levels.summary.get("deep");
        Summary wake = self.entryRecord.levels.summary.get("wake");
        Summary light = self.entryRecord.levels.summary.get("light");
        if (self.timeunit == SECONDS) {
            return {
            "deep": deep.minutes * 60,
            "wake": wake.minutes * 60,
            "light": light.minutes * 60
            };
        }
        else {
            return {
            "deep": deep.minutes,
            "wake": wake.minutes,
            "light": light.minutes
            };
        }

    }

}
