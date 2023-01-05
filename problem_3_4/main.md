import ballerina/http;
import ballerina/io;

type step_data record {
    string date;
    int value;
};

type data_record record {
    step_data[] activities\-steps;
};

type age_data record {
    int age;
};

type user_data record {
    age_data user;
};

function findTheGift(string userID, string 'from, string to) returns Gift|error {
    // Write your answer here for Part B.
    // Two `http:Client`s are initialized for you. Please note that they do not include required security configurations.
    // A `Gift` record is initialized to make the given function compilable.
    final http:Client fifitEp = check new ("http://localhost:9091/activities", {
        timeout: 20,
        retryConfig: {
            interval: 3,
            count: 6,
            backOffFactor: 2.0,
            maxWaitInterval: 60,
            statusCodes: [500]
        }
    });
    final http:FailoverClient insureEveryoneEp = check new (
        {
        timeout: 10,
        interval: 3,
        retryConfig: {
            interval: 3,
            count: 3,
            backOffFactor: 2.0,
            maxWaitInterval: 40
        },
        failoverCodes: [500],
        targets: [
            {url: "http://localhost:9092/insurance1"},
            {url: "http://localhost:9092/insurance2"}
        ]
    });
    int total_score = 0;
    data_record records = check fifitEp->get("/steps/user/" + userID + "/from/" + 'from + "/to/" + to);
    io:println("error");
    io:println(records);
    foreach step_data data in records.activities\-steps {
        total_score += data.value;
    }
    user_data user_d = check insureEveryoneEp->get("/user/" + userID);
    int age = user_d.user.age;

    total_score = total_score / ((100 - age) / 10);
    Types t = SILVER;
    if total_score >= SILVER_BAR && total_score < GOLD_BAR {
        t = SILVER;
    } else if total_score >= GOLD_BAR && total_score < PLATINUM_BAR {
        t = GOLD;
    } else if total_score >= PLATINUM_BAR {
        t = PLATINUM;
    }
    Gift gift = {eligible: true, 'from, to, score: total_score, details: {'type: t, message: "Congratulations! You have won the " + t + " gift!"}};
    io:println(gift);
    return gift;
}

type Activities record {
    record {|
        string date;
        int value;
    |}[] activities\-steps;
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
        # message string: Congratulations! You have won the ${type} gift!;
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
