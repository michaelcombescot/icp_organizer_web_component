import Array "mo:core/Array";
import Principal "mo:core/Principal";
import Nat32 "mo:core/Nat32";

module {
    public type CanistersVirtualArray = [Principal];

    public func newCanistersVirtualArray(size: Nat, principal: Principal) : CanistersVirtualArray {
        Array.tabulate(size, func (i) = principal)
    };

    public func fetchUserBucket(canistersVirtualArray: CanistersVirtualArray, userPrincipal: Principal, ) : Principal {
        let userPrincipalHash = Principal.hash(userPrincipal);
        canistersVirtualArray[ Nat32.toNat(userPrincipalHash) % canistersVirtualArray.size()]
    };
};