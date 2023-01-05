import ballerina/http;

import ballerina/io;

function findTheGift(string userID, string 'from, string to) returns Gift|error {
    string url = string `/steps/user/${userID}/from/${'from}/to/${to}`;
    final http:Client|error fifitEp = new ("http://localhost:9091/activities", {
            // Retry configuration options.
            retryConfig: {
                interval: 3,
                count: 3,
                backOffFactor: 1.0,
                maxWaitInterval: 30,
                statusCodes: [500]
            },
            timeout: 10
        });
    if (fifitEp is error) {
        return fifitEp;
    }
    Activities userActivities = check fifitEp->get(url);

    final http:FailoverClient insureEveryoneEp = check new ({
                                                            timeout: 10,
                                                            failoverCodes: [500],
                                                            interval: 3,
                                                            retryConfig: {
                                                                interval: 3,
                                                                count: 3,
                                                                backOffFactor: 1.0,
                                                                maxWaitInterval: 3
                                                            },
                                                            // Define a set of HTTP Clients that are targeted for failover.
                                                            targets: [
                                                                    {url: "http://localhost:9092/insurance1"},
                                                                    {url: "http://localhost:9092/insurance2"}
                                                                    ]
                                                });

    json userDetails = check insureEveryoneEp->get(string `/user/${userID}`);
    int age = check userDetails.user.age;
    int totalSteps = userActivities.activities\-steps.reduce(function(int total, Activity n) returns int {
        return total + n.value;
    }, 0);
    int score = totalSteps / ((100 - age) / 10);

    Types winningType = GOLD;
    if (score >= SILVER_BAR && score < GOLD_BAR) {
        winningType = SILVER;
    }
    else if (score >= GOLD_BAR && score < PLATINUM_BAR) {
        winningType = GOLD;
    }
    else if (score >= PLATINUM_BAR) {
        winningType = PLATINUM;
    }
    else {
        Gift noGift = {eligible: false, 'from, to, score: score};
        return noGift;
    }

    Gift gift = {eligible: true, 'from, to, score: score, details: {
        "type": winningType,
        "message": string `Congratulations! You have won the ${winningType} gift!`
    }};
    return gift;
}

type Activities record {
    record {|
        string date;
        int value;
    |}[] activities\-steps;
};

type Activity record {
    string date;
    int value;
};

type User record {
    map<record {
        string name;
        string display\-name;
        int age;
        string email;
        string state;
        string city;
        string address;
    }> user;
};

type UserResult record {
    record {
        int age;
    } user;
};

type Gift record {
    boolean eligible;
    int score;
    # format yyyy-mm-dd
    string 'from;
    # format yyyy-mm-dd
    string to;
    record {|
        Types 'type;
        # message string: Congradulations! You have won the ${type} gift!;
        string message;
    |} details?;
};

enum Types {
    SILVER,
    GOLD,
    PLATINUM
}

const int SILVER_BAR = 5000;
const int GOLD_BAR = 10000;
const int PLATINUM_BAR = 20000;

public function main() {
    io:println(findTheGift("1", "2022-01-01", "2022-03-31"));
}
