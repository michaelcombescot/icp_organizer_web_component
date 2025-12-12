import Text "mo:core/Text";
import Order "mo:core/Order";

module {
    // all canisters
    public type CanisterKind = {
        #todosRegistry;
        #todosIndex;

        // todosBucket and todosUserBucket are the same actor behind the scene, we just need a way to be able to easily route a principal to a specific bucket, it's easier this way.
        #todosBucket;
        #todosUsersBucket;
    };

    public let indexArray: [CanisterKind] = [#todosIndex];
    public let bucketArray: [CanisterKind] = [#todosBucket];

    public func compareCanisterKinds(a: CanisterKind, b: CanisterKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };
}