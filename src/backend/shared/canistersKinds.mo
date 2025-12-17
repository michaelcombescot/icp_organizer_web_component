import Text "mo:core/Text";
import Order "mo:core/Order";

module {
    // all canisters
    public type CanisterKind = {
        #registries: Registries;
        #indexes: Indexes;
        #buckets: Buckets;
    };

    public type Registries = {
        #indexesRegistry;
    };

    public type Indexes = {
        #mainIndex;
    };

    public type Buckets = {
        #groupsBucket;
        #usersBucket;
    };

    public func compareCanisterKinds(a: CanisterKind, b: CanisterKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };
}