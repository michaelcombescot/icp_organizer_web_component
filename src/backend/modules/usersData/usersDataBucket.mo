import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import UserData "./userDataModel";
import Errors "../../shared/errors";
import Iter "mo:core/Iter";
import Text "mo:core/Text";
import List "mo:core/List";
import Array "mo:core/Array";

shared ({ caller = owner }) persistent actor class UsersDataBucket(indexPrincipal: Principal) = this {
    let ERR_USER_DATA_NOT_FOUND = "ERR_USER_DATA_NOT_FOUND";

    var index = indexPrincipal;
    var usersData = Map.empty<Principal, UserData.UserData>();

    //
    // API
    //

    // create user data
    public shared ({ caller }) func createUserData(userPrincipal: Principal) : async Result.Result<Nat, Text> {
        if ( caller != index ) { return #err(Errors.ERR_CAN_ONLY_BE_CALLED_BY_INDEX); };

        let ?_ = Map.get(usersData, Principal.compare, userPrincipal) else return #err(Errors.ERR_USER_DATA_ALREADY_EXISTS);

        Map.add(usersData, Principal.compare, userPrincipal, {
                id = Principal.toText(Principal.fromActor(this)) # "/" # Principal.toText(userPrincipal);
                todos = Map.empty<Text, ()>();
                todoLists = Map.empty<Text, ()>();
        });

        #ok(usersData.size)
    };

    // get user data 
    type GetUserDataResponse = {
        todos: [Text];
        todoLists: [Text];
    };

    public shared ({ caller }) func getuserData() : async Result.Result<GetUserDataResponse, Text> {
        let ?data =  Map.get(usersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

        #ok({
            todos = Iter.toArray(Map.keys(data.todos));
            todoLists = Iter.toArray(Map.keys(data.todoLists));
        })
    };

    //
    // TODOS
    //

    public shared ({ caller }) func addTodos(todoId: Text) : async Result.Result<(), Text> {
        let ?data =  Map.get(usersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

        Map.add(data.todos, Text.compare, todoId, ());

        #ok()
    };

    public shared ({ caller }) func removeTodos(todoId: Text) : async Result.Result<(), Text> {
        let ?data =  Map.get(usersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

        Map.remove(data.todos, Text.compare, todoId);

        #ok()
    };

    public shared ({ caller }) func getAuthorizedTodos(ids: [Text]) : async Result.Result<[Text], [Text]> {
        let ?data =  Map.get(usersData, Principal.compare, caller) else return #err([ERR_USER_DATA_NOT_FOUND]);

        var errors = List.empty<Text>();
        var authorizedTodos = List.empty<Text>();
        
        for (testedId in Array.values(ids)) {
            switch (Map.get(data.todos, Text.compare, testedId)) {
                case null List.add(errors, "todo with id " # testedId # " not found");
                case (?_) List.add(authorizedTodos, testedId);
            };
        };

        if (List.size(errors) > 0) {
            return #err(List.toArray(errors));
        };

        #ok(List.toArray(authorizedTodos))
    };

    //
    // TODO LISTS
    //

    public shared ({ caller }) func addTodoLists(todoListId: Text) : async Result.Result<(), Text> {
        let ?data =  Map.get(usersData, Principal.compare, caller) else return #err(ERR_USER_DATA_NOT_FOUND);

        Map.add(data.todoLists, Text.compare, todoListId, ());

        #ok()
    };
};