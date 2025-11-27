import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Nat64 "mo:core/Nat64";
import Array "mo:core/Array";
import Blob "mo:core/Blob";
import Time "mo:base/Time";
import Group "../models/groupModel";
import GroupModel "../models/groupModel";
import Interfaces "../../shared/interfaces";

shared ({ caller = owner }) persistent actor class TodosGroupsBucket() = this {
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

    var memoryIndexes = Array.empty<Principal>();

    var memoryGroups = Map.empty<Nat, GroupModel.Group>();

    ////////////
    // SYSTEM //
    ////////////

    // type Msg = {
    //     // #createTodo : () -> (todo : TodoModel.Todo);
    //     // #removeTodo : () -> (id : Nat);
    //     // #setCoordinator : () -> (principal : Principal);
    //     // #updateTodo : () -> (todo : TodoModel.Todo)
    // };

    //  system func inspect({ arg : Blob; caller : Principal; msg : Msg }) : Bool {
    //     // check if the user is connected
    //     if (Principal.isAnonymous(caller)) { return false; };

    //     // check payload size
    //     if (Blob.size(arg) > 5000) { return false; };

    //     true
    // };

    /////////
    // API //
    /////////
}