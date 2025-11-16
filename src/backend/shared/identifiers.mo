import Principal "mo:core/Principal";
import Text "mo:core/Text";
import Nat "mo:core/Nat";

module {
    // with principal
    public type WithPrincipal = {
        bucket: Text;
        principal: Principal;
    };

    public func compareWithPrincipal(a: WithPrincipal, b: WithPrincipal) : {#less; #equal; #greater} {
        Principal.compare(a.principal, b.principal)
    };

    // with ID
    public type WithID = {
        bucket: Text;
        id: Nat;
    };

    public func compareWithID(a: WithID, b: WithID) : {#less; #equal; #greater} {
        Nat.compare(a.id, b.id)  
    };

    // with text
    public type WithText = {
        bucket: Text;
        text: Text;
    };

    public func compareWithText(a: WithText, b: WithText) : {#less; #equal; #greater} {
        Text.compare(a.text, b.text)
    };
};