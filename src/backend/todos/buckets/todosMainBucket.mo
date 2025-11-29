import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Nat64 "mo:core/Nat64";
import Array "mo:core/Array";
import Blob "mo:core/Blob";
import Time "mo:core/Time";
import List "mo:core/List";
import Interfaces "../../shared/interfaces";
import CanistersKinds "../../ops/canistersKinds";
import TodoModels "../models/todosModels";

shared ({ caller = owner }) persistent actor class TodosMainBucket() = this {
    let coordinator = actor (Principal.toText(owner)) : Interfaces.Coordinator;    

    ////////////
    // CONFIG //
    ////////////

    let CONFIG_MAX_NB_OF_GROUPS_PER_CANISTER = 1000;

    ////////////
    // ERRORS //
    ////////////

    // TODO IF NEEDED

    ////////////
    // STATES //
    ////////////

    var memoryIndexes = List.empty<Principal>();

    var memoryGroups = Map.empty<Nat, TodoModels.Group.Group>();

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemAddIndex: () -> { indexPrincipal : Principal};
        };
    };

    system func inspect(params: InspectParams) : Bool {
        // check if the user is connected
        if (Principal.isAnonymous(params.caller)) { return false; };

        // check payload size
        // if (Blob.size(arg) > 5000) { return false; };

        switch ( params.msg ) {
            case (#systemAddIndex(_)) params.caller == owner;
        }        
    };

    public shared func systemAddIndex({ indexPrincipal: Principal }) : async () {
        List.add(memoryIndexes, indexPrincipal);
    };

    /////////
    // API //
    /////////
}