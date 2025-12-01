import Order "mo:core/Order";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";

module {
    public type Identifier = {
        id: Nat;
        bucket: Principal;
    };

    public func compare(a: Identifier, b: Identifier) : Order.Order {
        if ( Principal.compare(a.bucket, b.bucket) == #equal ) {
            switch ( Nat.compare(a.id, b.id) ) {
                case (#equal) #equal;
                case (#greater) #greater;
                case (#less) #less;
            }
        } else if (Principal.compare(a.bucket, b.bucket) == #greater ) {
            #greater
        } else {
            #less
        }
    };
};