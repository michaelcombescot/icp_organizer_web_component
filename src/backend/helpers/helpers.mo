import Order "mo:core/Order";
import Buffer "mo:base/Buffer";

module HelpersArray {
    public func removeDuplicates<T>(array: [T], compare: (T,T) -> Order.Order) : [T] {
        let buf = Buffer.fromArray<T>(array);
        Buffer.removeDuplicates<T>(buf, compare);
        Buffer.toArray<T>(buf)
    };
};

module Request {
    public type Status = {
        #ok;
        #err: Text;
        #notFound;
    };
}