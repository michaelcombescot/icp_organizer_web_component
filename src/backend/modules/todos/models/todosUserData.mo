import Map "mo:core/Map";
import Time "mo:core/Time";
import Identifier "../../shared/identifiers";

module {
    public type UserData = {
        groups: Map.Map<Identifier.Identifier, ()>;
        createdAt: Time.Time;
    };
};