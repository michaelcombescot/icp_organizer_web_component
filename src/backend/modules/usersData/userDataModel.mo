import Map "mo:core/Map";
import Types "../../shared/types";

module {
    public type UserData = {
        identifiers: Types.UserIdentifiers;
        todoLists:  Map.Map<Text, ()>;
        todos:      Map.Map<Text, ()>;
    };
}