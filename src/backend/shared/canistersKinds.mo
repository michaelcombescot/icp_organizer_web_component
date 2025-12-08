import Text "mo:core/Text";
import Order "mo:core/Order";

module {
    // all canisters
    public type CanisterKind = {
        #indexes: IndexKind;
        #buckets: BucketKind;
        #registries: RegistryKind;
    };

    public func compareCanisterKinds(a: CanisterKind, b: CanisterKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };
    
    // registry
    public type RegistryKind = {
        #todosRegistry;
    };

    // indexes
    public type IndexKind = {
        #todosGroupsIndex;
        #todosUsersIndex;
    };

    public let indexKindArray: [IndexKind] = [#todosGroupsIndex, #todosUsersIndex];

    public func compareIndexesKinds(a: IndexKind, b: IndexKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };

    // buckets
    public type BucketKind = {
        #todos: BucketTodoKind;
    };

    public let bucketKindArray: [BucketKind] = [#todos(#todosUsersBucket), #todos(#todosGroupsBucket)];

    public func compareBucketsKinds(a: BucketKind, b: BucketKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };

    public type BucketTodoKind = {
        #todosUsersBucket;
        #todosGroupsBucket;
    };

    public let bucketTodoKindArray: [BucketTodoKind] = [#todosUsersBucket, #todosGroupsBucket];

    public func compareBucketsTodoKinds(a: BucketTodoKind, b: BucketTodoKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };
}