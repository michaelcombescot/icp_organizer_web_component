import List "mo:core/List";

module {
    public type UserData = {
        todoLists:  List.List<Text>;
        todos:      List.List<Text>;
    };
}