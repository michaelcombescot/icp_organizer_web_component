import Time "mo:core/Time";
import Random "mo:core/Random";
import Nat64 "mo:core/Nat64";

module {
    let rnd = await Random.blob();

    // uniq id are in two parts:
    // - timestamp in nanoseconds
    // - random bytes in case of collision
    public func generateUniqueId() : async Text {
        let now = Time.now();
        let rand = rnd.next();

        Nat.toText(now) # "-" # rand;
    };
};