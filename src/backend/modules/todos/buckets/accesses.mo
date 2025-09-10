import Principal "mo:core/Principal";
import Debug "mo:core/Debug";
import CanistersIDs "../../helpers/canistersIDs";

module {
    public func principalIsTodoIndexCanister(principal: Principal) : Bool {
        principal == Principal.fromText(CanistersIDs.todoIndexCanisterId)
    };
};