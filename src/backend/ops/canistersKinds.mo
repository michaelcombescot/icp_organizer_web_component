import Text "mo:core/Text";
import Order "mo:core/Order";

module {
    // all canisters
    public type CanisterKind = {
        #indexes: IndexKind;
        #buckets: BucketKind;
        #registry: RegistryKind;
    };

    public func compareCanisterKinds(a: CanisterKind, b: CanisterKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };

    // registry
    public type RegistryKind = {
        #registry;
    };

    public let registryKindArray: [RegistryKind] = [#registry];

    public func compareRegistryKinds(a: RegistryKind, b: RegistryKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };

    // indexes
    public type IndexKind = {
        #todosIndex;
    };

    public let indexKindArray: [IndexKind] = [#todosIndex];

    public func compareIndexesKinds(a: IndexKind, b: IndexKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };

    // buckets
    public type BucketKind = {
        #todos: BucketTodoKind;
    };

    public let bucketKindArray: [BucketKind] = [#todos(#todosUsersDataBucket), #todos(#todosGroupsBucket)];

    public func compareBucketsKinds(a: BucketKind, b: BucketKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };

    public type BucketTodoKind = {
        #todosUsersDataBucket;
        #todosGroupsBucket;
    };

    public let bucketTodoKindArray: [BucketTodoKind] = [#todosUsersDataBucket, #todosGroupsBucket];

    public func compareBucketsTodoKinds(a: BucketTodoKind, b: BucketTodoKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };
}