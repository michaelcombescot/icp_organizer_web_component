import Text "mo:core/Text";
import Order "mo:core/Order";

module {
    public type CanisterKind = {
        // todos
        #todosIndex;
        #todosTodosBucket;
        #todosUsersDataBucket;
        #todosListsBucket;
        #todosGroupsBucket;
    };

    public let bucketKindArray: [BucketKind] = [#todosTodosBucket, #todosUsersDataBucket, #todosListsBucket, #todosGroupsBucket];

    public let indexKindArray: [IndexKind] = [#todosIndex];

    public func compareCanisterKinds(a: CanisterKind, b: CanisterKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };

    public type IndexKind = {
        #todosIndex;
    };

    public type BucketKind = {
        // todos
        #todosTodosBucket;
        #todosUsersDataBucket;
        #todosListsBucket;
        #todosGroupsBucket;
    };
}