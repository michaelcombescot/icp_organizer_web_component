import Text "mo:core/Text";
import Order "mo:core/Order";

module {
    public type CanisterKind = {
        // todos
        #todos;
        #todosTodosBucket;
        #todosUsersDataBucket;
        #todosListsBucket;
        #todosGroupsBucket;
    };

    public func compareCanisterKinds(a: CanisterKind, b: CanisterKind) : Order.Order {
        Text.compare(debug_show(a), debug_show(b))
    };

    public type IndexKind = {
        #todos;
    };

    public type BucketKind = {
        // todos
        #todosTodosBucket;
        #todosUsersDataBucket;
        #todosListsBucket;
        #todosGroupsBucket;
    };
}