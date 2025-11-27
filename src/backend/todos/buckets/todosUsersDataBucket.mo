import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import UserData "../models/userDataModel";
import Iter "mo:core/Iter";
import Text "mo:core/Text";
import Time "mo:core/Time";
import Array "mo:core/Array";
import Nat64 "mo:core/Nat64";
import Interfaces "../../shared/interfaces";
import UserDataModel "../models/userDataModel";

shared ({ caller = owner }) persistent actor class TodosUsersDataBucket() = this {
    let thisPrincipalText = Principal.toText(Principal.fromActor(this));
    let coordinator = actor (Principal.toText(owner)) : Interfaces.Coordinator;

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

    var memoryIndexes        = Array.empty<Principal>();

    let memoryUsersData      = Map.empty<Nat, UserDataModel.UserData>();

    ////////////
    // SYSTEM //
    ////////////

     type Msg = {
        // #createTodo : () -> (todo : TodoModel.Todo);
        // #removeTodo : () -> (id : Nat);
        // #setCoordinator : () -> (principal : Principal);
        // #updateTodo : () -> (todo : TodoModel.Todo)
    };

    // system func inspect({ arg : Blob; caller : Principal; msg : Msg }) : Bool {
    //     // check if the user is connected
    //     if (Principal.isAnonymous(caller)) { return false; };
};