import Principal "mo:core/Principal";

let indexCanisterPrincipal = "2vxsx-fae";

module CheckAccess {
    public func principalIsTodoIndexCanister(principal: Principal) : Bool {
        principal == Principal.fromText(indexCanisterPrincipal)
    };
};