import Time "mo:core/Time";
import Map "mo:core/Map";

module {
    public type Group = {
        id: Text;
        name: Text;
        todos: Map.Map<Text, ()>;
        todoLists: Map.Map<Text, ()>;
        users: Map.Map<Principal, ()>;
        createdAt: Time.Time;
        updatedAt: Time.Time;
    };

    //
    // API
    //

    public type CreateGroupParam = {
        name: Text;
    };
}