import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import UserData "../models/userDataModel";
import Iter "mo:core/Iter";
import Text "mo:core/Text";
import Identifiers "../../shared/identifiers";
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

    let CONFIG_INTERVAL_FETCH_INDEXES: Nat64    = 60_000_000_000;
    let CONFIG_MAX_NUMBER_ENTRIES: Nat          = 50_000;

    ////////////
    // ERRORS //
    ////////////

    let ERR_CAN_ONLY_BE_CALLED_BY_INDEX = "ERR_CAN_ONLY_BE_CALLED_BY_INDEX";

    ////////////
    // STORES //
    ////////////

    var storeIndexes        = Map.empty<Principal, ()>();
    let storeUsersData      = Map.empty<Nat, UserDataModel.UserData>();

    ////////////
    // SYSTEM //
    ////////////

    // system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
    //     storeIndexes := Map.fromIter(Array.map(await coordinator.getIndexes(), func(x) = (x, ())).values(), Principal.compare);
    //     setGlobalTimer(Nat64.fromIntWrap(Time.now()) + CONFIG_INTERVAL_FETCH_INDEXES);
    // };

    // //
    // // ERRORS
    // //

    // let ERR_USER_DATA_NOT_FOUND = "ERR_USER_DATA_NOT_FOUND";
    // let ERR_USER_DATA_ALREADY_EXISTS = "ERR_USER_DATA_ALREADY_EXISTS";
    // let ERR_CAN_ONLY_BE_CALLED_BY_INDEX = "ERR_CAN_ONLY_BE_CALLED_BY_INDEX";

    // //
    // // STORES
    // //

    // var storeUsersData = Map.empty<Principal, UserData.UserData>();

    // //
    // // API
    // //

    // // create user data
    // public shared ({ caller }) func createUserData({userPrincipal: Principal}) : async Result.Result<Identifiers.WithPrincipal, Text> {
    //     if ( caller != index ) { return #err(ERR_CAN_ONLY_BE_CALLED_BY_INDEX); };

    //     let ?_ = Map.get(storeUsersData, Principal.compare, userPrincipal) else return #err(ERR_USER_DATA_ALREADY_EXISTS);

    //     let data =  {
    //                     identifiers = { principal = userPrincipal; bucket = thisPrincipalText; };
    //                     todos       = Map.empty<Identifiers.WithText, ()>();
    //                     todoLists   = Map.empty<Identifiers.WithText, ()>();
    //                     groups      = Map.empty<Identifiers.WithText, ()>();
    //                     createdAt   = Time.now();
    //                 };

    //     Map.add(storeUsersData, Principal.compare, userPrincipal, data);

    //     #ok(data.identifiers)
    // };

    // // get user data 
    // type GetUserDataResponse = {
    //     todos: [Identifiers.WithText];
    //     todoLists: [Identifiers.WithText];
    //     groups: [Identifiers.WithText];
    // };

    // public shared ({ caller }) func getuserData() : async Result.Result<GetUserDataResponse, Text> {
    //     let ?data =  Map.get(storeUsersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

    //     #ok({
    //         todos = Iter.toArray(Map.keys(data.todos));
    //         todoLists = Iter.toArray(Map.keys(data.todoLists));
    //         groups = Iter.toArray(Map.keys(data.groups));
    //     })
    // };

    // //
    // // TODOS
    // //

    // public shared ({ caller }) func addTodosToUser(todoId: Identifiers.WithText) : async Result.Result<(), Text> {
    //     let ?data =  Map.get(storeUsersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

    //     Map.add(data.todos, Identifiers.compareWithText, todoId, ());

    //     #ok()
    // };

    // public shared ({ caller }) func removeTodosFromUser(todoId: Identifiers.WithText) : async Result.Result<(), Text> {
    //     let ?data =  Map.get(storeUsersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

    //     Map.remove(data.todos, Identifiers.compareWithText, todoId);

    //     #ok()
    // };

    // public shared ({ caller }) func isTodoOwnedByUser(id: Identifiers.WithText) : async Bool {
    //     let ?data =  Map.get(storeUsersData, Principal.compare, caller) else return false;

    //     let ?_ = Map.get(data.todos, Identifiers.compareWithText, id) else return false;

    //     return true
    // };

    // //
    // // TODO LISTS
    // //

    // public shared ({ caller }) func addTodoLists(todoListId: Identifiers.WithText) : async Result.Result<(), Text> {
    //     let ?data =  Map.get(storeUsersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

    //     Map.add(data.todoLists, Identifiers.compareWithText, todoListId, ());

    //     #ok()
    // };

    // public shared ({ caller }) func removeTodoLists(todoListId: Identifiers.WithText) : async Result.Result<(), Text> {
    //     let ?data =  Map.get(storeUsersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

    //     Map.remove(data.todoLists, Identifiers.compareWithText, todoListId);

    //     #ok()
    // };
};