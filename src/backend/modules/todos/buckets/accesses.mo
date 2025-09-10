import Principal "mo:core/Principal";
import Debug "mo:core/Debug";

module {
    public func principalIsTodoIndexCanister(principal: Principal) : Bool {
        Debug.print("principalIsTodoIndexCanister" # Principal.toText(principal) # "||" # indexCanisterPrincipal);
        principal == Principal.fromText(CanistersIDs.todoIndexCanisterId)
    };
};