import ballerina/http;
import ballerina/io;

configurable string USERNAME = "alice";
configurable string PASSWORD = "123";

http:OAuth2RefreshTokenGrantConfig fitfitEpConfig = {

        refreshUrl: tokenEndpoint,
        refreshToken: refreshToken,
        clientId: clientId,
        clientSecret: clientSecret,
        clientConfig: {
            secureSocket: {
                cert: "resources/public.crt"
            }
        }
};

function findTheGiftSimple(string userID, string 'from, string to) returns Gift|error {
    // Write your answer here for Part A.
    // An `http:Client` is initialized for you. Please note that it does not include required security configurations.
    // A `Gift` record is initialized to make the given function compilable.
    string url = string `/steps/user/${userID}/from/${'from}/to/${to}`;
    final http:Client|error fifitEp = new ("https://localhost:9091/activities",
    auth = fitfitEpConfig,
    secureSocket = {
        cert: "resources/public.crt"
        }
    );
    if (fifitEp is error) {
        return fifitEp;
    }
    Activities userActivities = check fifitEp->get(url);
    int totalSteps = userActivities.activities\-steps.reduce(function(int total, Activity n) returns int {
        return total + n.value;
    }, 0);
    int score = totalSteps;
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
        Gift noGift = {eligible: false, 'from, to, score: totalSteps};
        return noGift;
    }

    Gift gift = {eligible: true, 'from, to, score: totalSteps, details: {
        "type": winningType,
        "message": string `Congratulations! You have won the ${winningType} gift!`
    }};
    return gift;
}

function findTheGiftComplex(string userID, string 'from, string to) returns Gift|error {
    // Write your answer here for Part B.
    // Two `http:Client`s are initialized for you. Please note that they do not include required security configurations.
    // A `Gift` record is initialized to make the given function compilable.
    string url = string `/steps/user/${userID}/from/${'from}/to/${to}`;
    final http:Client|error fifitEp = new ("https://localhost:9091/activities",
    auth = fitfitEpConfig,
    secureSocket = {
        cert: "resources/public.crt"
        }
    );
    if (fifitEp is error) {
        return fifitEp;
    }
    Activities userActivities = check fifitEp->get(url);

    final http:Client insureEveryoneEp = check new ("https://localhost:9092/insurance", auth = {
        username: USERNAME,
        password: PASSWORD
    },
    secureSocket = {
        cert: "resources/public.crt"
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

public function main() {
    io:println(findTheGiftComplex("1", "2022-01-01", "2022-03-31"));
}
