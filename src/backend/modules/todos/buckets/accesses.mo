import Principal "mo:core/Principal";

module {
    let indexCanisterPrincipal = "2vxsx-fae";

    public func principalIsTodoIndexCanister(principal: Principal) : Bool {
        principal == Principal.fromText(indexCanisterPrincipal)
    };
};