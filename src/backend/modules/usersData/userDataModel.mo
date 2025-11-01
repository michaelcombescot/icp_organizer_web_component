import Map "mo:core/Map";

module {
    public type UserData = {
        id: Text;
        todoLists:  Map.Map<Text, ()>;
        todos:      Map.Map<Text, ()>;
    };
}