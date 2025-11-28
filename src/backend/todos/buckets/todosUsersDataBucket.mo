import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import UserData "../models/userDataModel";
import Iter "mo:core/Iter";
import Text "mo:core/Text";
import Time "mo:core/Time";
import Array "mo:core/Array";
import List "mo:core/List";
import Nat64 "mo:core/Nat64";
import Interfaces "../../shared/interfaces";
import UserDataModel "../models/userDataModel";

shared ({ caller = owner }) persistent actor class TodosUsersDataBucket() = this {
    ////////////
    // CONFIG //
    ////////////

    let CONFIG_MAX_NUMBER_ENTRIES = 200_000;

    ////////////
    // ERRORS //
    ////////////

    ////////////
    // STATES //
    ////////////

    let coordinator = actor (Principal.toText(owner)) : Interfaces.Coordinator;

    var memoryIndexes        = List.empty<Principal>();

    let memoryUsersData      = Map.empty<Nat, UserDataModel.UserData>();

    ////////////
    // SYSTEM //
    ////////////

    type Msg = {
        #systemAddIndex: () -> { indexPrincipal : Principal};
    };

     system func inspect({ arg : Blob; caller : Principal; msg : Msg }) : Bool {
        if (Principal.isAnonymous(caller)) { return false; };

        // check payload size
        // if (Blob.size(arg) > 5000) { return false; };

        switch msg {
            case (#systemAddIndex(_)) caller == owner;
        }        
    };

    public shared func systemAddIndex({ indexPrincipal: Principal }) : async () {
        List.add(memoryIndexes, indexPrincipal);
    };
};