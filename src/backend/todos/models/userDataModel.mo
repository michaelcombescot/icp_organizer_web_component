import Map "mo:core/Map";
import Identifiers "../../shared/identifiers";
import Time "mo:core/Time";

module {
    public type UserData = {
        identifiers: Identifiers.WithPrincipal;
        todoLists:  Map.Map<Identifiers.WithText, ()>;
        todos:      Map.Map<Identifiers.WithText, ()>;
        groups:     Map.Map<Identifiers.WithText, ()>;
        createdAt:  Time.Time;
    };
}