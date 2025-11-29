import Map "mo:core/Map";
import Time "mo:core/Time";

module {
    public type UserData = {
        id: Principal;
        bucket: Principal;
        groups: Map.Map<Nat, ()>;
        createdAt: Time.Time;
        updatedAt: Time.Time;
    };
}