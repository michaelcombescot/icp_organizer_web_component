import Text "mo:core/Text";
import Order "mo:core/Order";

module {
    // all canisters
    public type CanisterKind = {
        #todosRegistry;
        #todosIndex;
        #todosBucket;
    };

    public let indexArray: [CanisterKind] = [#todosIndex];
    public let bucketArray: [CanisterKind] = [#todosBucket];

    public func compareCanisterKinds(a: CanisterKind, b: CanisterKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };
}