import Principal "mo:core/Principal";
import Order "mo:core/Order";
import Buffer "mo:base/Buffer";

let indexCanisterPrincipal = "2vxsx-fae";

module CheckAccess {
    public func principalIsTodoIndexCanister(principal: Principal) : Bool {
        principal == Principal.fromText(indexCanisterPrincipal)
    };
};