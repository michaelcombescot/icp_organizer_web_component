import Text "mo:core/Text";
import Order "mo:core/Order";

module {
    public type CanistersKind = {
        #dynamic: DynamicsKind;
        #static: StaticsKind;
    };

    public type StaticsKind = {
        #registries: RegistriesKind;
    };

    public type DynamicsKind = {
        #indexes: IndexesKind;
        #buckets: BucketsKind;
    };

    public type RegistriesKind = {
        #indexesRegistry;
    };

    public type IndexesKind = {
        #mainIndex;
    };

    public type BucketsKind = {
        #groupsBucket;
        #usersBucket;
    };

    public func compareCanistersKinds(a: CanistersKind, b: CanistersKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };
}