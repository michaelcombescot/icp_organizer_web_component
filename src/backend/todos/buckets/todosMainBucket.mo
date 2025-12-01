import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import Blob "mo:core/Blob";
import Time "mo:core/Time";
import List "mo:core/List";
import TodoMainModels "../models/todosMainModels";
import Identifier "../../shared/identifiers";

shared ({ caller = owner }) persistent actor class TodosMainBucket() = this {
    let thisPrincipal = Principal.fromActor(this);  

    /////////////
    // CONFIGS //
    /////////////

    let CONFIG_MAX_NUMBER_ENTRIES = 1000;

    ////////////
    // ERRORS //
    ////////////

    let ERR_BUCKET_FULL = "ERR_BUCKET_FULL";

    ////////////
    // STATES //
    ////////////

    var memoryIndexes = List.empty<Principal>();

    var memoryGroups = Map.empty<Nat, TodoMainModels.Group.Memory>();

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #handlerCreateNewUserGroup : () -> {userPrincipal : Principal};
            #systemAddIndex : () -> {indexPrincipal : Principal}
        };
    };

    system func inspect(params: InspectParams) : Bool {
        // check if the user is connected
        if (Principal.isAnonymous(params.caller)) { return false; };

        // check payload size
        if (Blob.size(params.arg) > 500) { return false; };

        // check specific right for each route
        switch ( params.msg ) {
            case (#systemAddIndex(_))               params.caller == owner;
            case (#handlerCreateNewUserGroup(_)) {
                if ( Map.size(memoryGroups) >= CONFIG_MAX_NUMBER_ENTRIES ) { return false; };

                List.contains(memoryIndexes, Principal.equal, params.caller)
            };
        }        
    };

    // route called by the coordinator ONLY
    public shared func systemAddIndex({ indexPrincipal: Principal }) : async () {
        List.add(memoryIndexes, indexPrincipal);
    };

    /////////
    // API //
    /////////

    // each user is it's own group. This handler create a specific group for a specific user
    public shared func handlerCreateNewUserGroup({ userPrincipal: Principal }) : async Result.Result<{ groupIdentifier: Identifier.Identifier; isFull: Bool }, Text> {
        if ( Map.size(memoryGroups) > CONFIG_MAX_NUMBER_ENTRIES ) { return #err(ERR_BUCKET_FULL); };

        let newGroup: TodoMainModels.Group.Memory = {
                                                    identifier = { id = Map.size(memoryGroups); bucket = thisPrincipal };
                                                    name = "Personnal";
                                                    todos = Map.empty<Nat, TodoMainModels.Todo.Todo>();
                                                    todoLists = Map.empty<Nat, TodoMainModels.TodoList.TodoList>();
                                                    users = Map.singleton<Principal, TodoMainModels.Group.UserGroupPermission>(userPrincipal, #owner);
                                                    createdAt = Time.now();
                                                    updatedAt = Time.now();
                                                    createdBy = userPrincipal;
                                                    kind = #personnal;
                                                };

        Map.add(memoryGroups, Nat.compare, newGroup.identifier.id, newGroup);

        #ok({ groupIdentifier = newGroup.identifier; isFull = newGroup.identifier.id >= CONFIG_MAX_NUMBER_ENTRIES; });
    };
}