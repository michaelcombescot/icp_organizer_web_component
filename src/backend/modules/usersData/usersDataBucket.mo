import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import UserData "./userDataModel";
import Errors "../../shared/errors";
import Iter "mo:core/Iter";
import Text "mo:core/Text";

shared ({ caller = owner }) persistent actor class UsersDataBucket(indexPrincipal: Principal) = this {
    let ERR_USER_DATA_NOT_FOUND = "ERR_USER_DATA_NOT_FOUND";

    var index = indexPrincipal;
    var storeUsersData = Map.empty<Principal, UserData.UserData>();

    //
    // API
    //

    // create user data
    public shared ({ caller }) func createUserData(userPrincipal: Principal) : async Result.Result<Nat, Text> {
        if ( caller != index ) { return #err(Errors.ERR_CAN_ONLY_BE_CALLED_BY_INDEX); };

        let ?_ = Map.get(storeUsersData, Principal.compare, userPrincipal) else return #err(Errors.ERR_USER_DATA_ALREADY_EXISTS);

        Map.add(storeUsersData, Principal.compare, userPrincipal, {
                id = Principal.toText(Principal.fromActor(this)) # "/" # Principal.toText(userPrincipal);
                todos = Map.empty<Text, ()>();
                todoLists = Map.empty<Text, ()>();
        });

        #ok(storeUsersData.size)
    };

    // get user data 
    type GetUserDataResponse = {
        todos: [Text];
        todoLists: [Text];
    };

    public shared ({ caller }) func getuserData() : async Result.Result<GetUserDataResponse, Text> {
        let ?data =  Map.get(storeUsersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

        #ok({
            todos = Iter.toArray(Map.keys(data.todos));
            todoLists = Iter.toArray(Map.keys(data.todoLists));
        })
    };

    //
    // TODOS
    //

    public shared ({ caller }) func addTodos(todoId: Text) : async Result.Result<(), Text> {
        let ?data =  Map.get(storeUsersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

        Map.add(data.todos, Text.compare, todoId, ());

        #ok()
    };

    public shared ({ caller }) func removeTodos(todoId: Text) : async Result.Result<(), Text> {
        let ?data =  Map.get(storeUsersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

        Map.remove(data.todos, Text.compare, todoId);

        #ok()
    };

    public shared ({ caller }) func isTodoOwned(id: Text) : async Bool {
        let ?data =  Map.get(storeUsersData, Principal.compare, caller) else return false;

        let ?_ = Map.get(data.todos, Text.compare, id) else return false;

        return true
    };

    //
    // TODO LISTS
    //

    public shared ({ caller }) func addTodoLists(todoListId: Text) : async Result.Result<(), Text> {
        let ?data =  Map.get(storeUsersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

        Map.add(data.todoLists, Text.compare, todoListId, ());

        #ok()
    };

    public shared ({ caller }) func removeTodoLists(todoListId: Text) : async Result.Result<(), Text> {
        let ?data =  Map.get(storeUsersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

        Map.remove(data.todoLists, Text.compare, todoListId);

        #ok()
    };
};