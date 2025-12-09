import Map "mo:core/Map";
import Time "mo:core/Time";
import Identifiers "../../../shared/identifiers";

module {
    public type UserData = {
        groups: Map.Map<Identifiers.Identifier, ()>;
        createdAt: Time.Time;
    };
};