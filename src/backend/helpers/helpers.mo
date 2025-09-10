import Order "mo:core/Order";
import Principal "mo:core/Principal";
import BucketGroups "../modules/todos/buckets/bucketGroups";

module {
    public func compareBuckets(b1: BucketGroups.BucketGroups, b2: BucketGroups.BucketGroups) : Order.Order {
        Principal.compare(Principal.fromActor(b1), Principal.fromActor(b2))
    };
};