import Principal "mo:core/Principal";
import CanistersIDs "../../../helpers/canistersIds";

module {
    public func principalIsTodoIndexCanister(principal: Principal) : Bool {
        principal == Principal.fromText(CanistersIDs.todoIndexCanisterId)
    };
};