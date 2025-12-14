import Array "mo:core/Array";
import Principal "mo:core/Principal";
import Nat32 "mo:core/Nat32";

module {
    public type PrincipalsArray = [Principal];

    public func newPrincipalsArray(size: Nat, principal: Principal) : PrincipalsArray {
        Array.tabulate(size, func (i) = principal)
    };

    public func fetchUserBucket(array: PrincipalsArray, userPrincipal: Principal, ) : Principal {
        let userPrincipalHash = Principal.hash(userPrincipal);
        array[ Nat32.toNat(userPrincipalHash) % array.size()]
    };
};