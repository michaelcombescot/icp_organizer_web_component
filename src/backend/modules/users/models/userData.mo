import Time "mo:core/Time";
import Map "mo:core/Map";
import Array "mo:core/Array";
import Text "mo:base/Text";
import Identifiers "../../../shared/identifiers";

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
    };

    public func newUserData() : UserData {
        {
            name = "";
            email = "";
            groups = Map.empty<Identifiers.Identifier, ()>();
            createdAt = Time.now();
        }
    };

    public func newSharableUserData(userData: UserData) : SharableUserData {
        {
            name = userData.name;
            email = userData.email;
            groups = Array.fromIter( Map.keys(userData.groups) );
        }
    };
};