import Map "mo:core/Map";
import Time "mo:core/Time";
import Text "mo:base/Text";
import Identifiers "../../../../shared/identifiers";

module {
    public type UserData = {
        name: Text;
        email: Text;
        groups: Map.Map<Identifiers.Identifier, ()>;
        createdAt: Time.Time;
    };

    public type SharableUserData = {
        name: Text;
        email: Text;
        groups: [Identifiers.Identifier];
        createdAt: Time.Time;
    }
};