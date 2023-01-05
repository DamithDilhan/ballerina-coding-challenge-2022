import ballerina/http;

configurable int port = 8080;

map<int> Menu = {
    "Butter Cake": 15,
    "Chocolate Cake": 20,
    "Tres Leches": 25
};

public type 'Order record {|
    string item;
    int quantity;
|};

public type Invoice record {
    string username;
    'Order[] order_items;
};

public type UpdateInvoice record {
    'Order[] order_items;
};

type InvoiceReply record {
    string order_id;
    int total;
};

function calculateInvoice(Order[] data, boolean updateRecord) returns InvoiceReply|error {
    if (data.length() == 0) {
        return error("empty order_items");
    }

    map<int> orderedCakes = {};
    int totalCost = 0;
    foreach Order item in data {
        if (orderedCakes[item.item] == ()) {
            orderedCakes[item.item] = 1;
        }
        else {
            return error("More than 1 order for same cake");
        }
        int? price = Menu[item.item];
        if (price is ()) {
            return error("Cake not in menu");
        }
        if (item.quantity < 1) {
            return error("Quantity less than 1");
        }
        totalCost += price * item.quantity;
    }
    if (updateRecord) {
        return {
            "order_id": "",
            "total": totalCost
        };
    }
    string orderId = currentKey.toString();
    currentKey += 1;
    orderStatus[orderId] = "pending";
    return {
        "order_id": orderId,
        "total": totalCost
    };
}

service http:Service / on new http:Listener(port) {
    // Retrive menu - GET /menu
    resource function get menu() returns json {
        return Menu.toJson();
    }

    // Place an order - POST /order 
    resource function post 'order(@http:Payload Invoice data) returns http:Created|http:BadRequest {
        string username = data.username;
        if (username.length() == 0) {
            http:BadRequest badReply = {"body": "Username is empty"};
            return badReply;
        }
        Order[] orderList = data.order_items;
        InvoiceReply|error reply = calculateInvoice(orderList, false);
        if (reply is error) {
            return <http:BadRequest>{
                "body": reply.message()
            };
        }
        http:Created ok = {body: reply.toJson()};
        return ok;
    }

    // Get order status - GET order/[orderId] 
    resource function get 'order/[string orderId]() returns http:Ok|http:NotFound {

        string? status = orderStatus[orderId];
        if (status == ()) {
            return <http:NotFound>{"body": "Order not found"};
        }
        return <http:Ok>{
            body: {
                "order_id": orderId,
                "status": status
                }
        };

    }

    // Update order - PUT order/[orderId]
    resource function put 'order/[string orderId](@http:Payload UpdateInvoice data) returns http:NotFound|http:BadRequest|http:Forbidden|http:Ok {
        string? currentStatus = orderStatus[orderId];
        if (currentStatus == ()) {
            return <http:NotFound>{"body": "Order not found"};
        }
        if (currentStatus == "in progress" || currentStatus == "completed") {
            return <http:Forbidden>{"body": "Order is not pending"};
        }
        InvoiceReply|error reply = calculateInvoice(data.order_items, false);
        if (reply is error) {
            return <http:BadRequest>{
                "body": reply.message()
            };
        }
        reply.order_id = orderId;
        http:Ok ok = {body: reply.toJson()};
        return ok;
    }

    // Delete order - order/[orderId]
    resource function delete 'order/[string orderId]() returns http:NotFound|http:Forbidden|http:Ok {

        string? currentStatus = orderStatus[orderId];
        if (currentStatus == ()) {
            return <http:NotFound>{"body": "Order not found"};
        }
        if (currentStatus == "in progress" || currentStatus == "completed") {
            return <http:Forbidden>{"body": "Order is not pending"};
        }
        string? result = orderStatus.removeIfHasKey(orderId);
        return <http:Ok>{body: result};

    }

}
