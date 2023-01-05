import ballerina/io;

function allocateCubicles(int[] requests) returns int[] {
    int[] sorted = requests.sort();

    if (sorted.length() > 0) {
        int? prev = sorted[0];
        int[] result = [sorted[0]];
        foreach int i in 1 ..< sorted.length() {
            if (prev != sorted[i]) {
                result.push(sorted[i]);
                prev = sorted[i];
            }
        }
        return result;
    }

    return [];
}

public function main() {
    io:println(allocateCubicles([5, 6, 18, 56, 18, 8, 1]));
}
