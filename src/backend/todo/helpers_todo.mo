import Principal "mo:core/Principal";
import Order "mo:core/Order";
import Buffer "mo:base/Buffer";

let indexCanisterPrincipal = "2vxsx-fae";

module CheckAccess {
    public func principalIsTodoIndexCanister(principal: Principal) : Bool {
        principal == Principal.fromText(indexCanisterPrincipal)
    };
};

module ArrayHelpers {
    public func removeDuplicates<T>(array: [T], compare: (T,T) -> Order.Order) : [T] {
        let buf = Buffer.fromArray<T>(array);
        Buffer.removeDuplicates<T>(buf, compare);
        Buffer.toArray<T>(buf)
    };
};