import Map "mo:core/Map";
import Result "mo:core/Result";
import Principal "mo:core/Principal";
import Nat "mo:core/Nat";
import Blob "mo:core/Blob";
import Time "mo:core/Time";
import Group "../../models/todosGroup";
import Todo "../../models/todosTodo";
import TodoList "../../models/todosTodoList";
import Identifier "../../../../shared/identifiers";
import CanistersKinds "../../../../shared/canistersKinds";
import CanistersMap "../../../../shared/canistersMap";

// This is the main bucket for todos.
// Each group belongs with all it's associated todos in a bucket.
// A user is a group with a single associated principal.
shared ({ caller = owner }) persistent actor class TodosGroupsBucket() = this {
    let thisPrincipal = Principal.fromActor(this);  

    /////////////
    // CONFIGS //
    /////////////

    let CONFIG_MAX_NUMBER_ENTRIES = 1000;
    let CONFIG_MAX_TODOS_PER_GROUP = 10000;

    ////////////
    // ERRORS //
    ////////////

    let ERR_BUCKET_FULL = "ERR_BUCKET_FULL";

    ////////////
    // STATES //
    ////////////

    let memoryCanisters = CanistersMap.newCanisterMap();

    var memoryGroups = Map.empty<Nat, Group.Group>();

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemAddCanisterToMap : () -> { canisterPrincipal: Principal; canisterKind: CanistersKinds.CanisterKind };

            #handlerCreateNewUserGroup : () -> {userPrincipal : Principal};
        };
    };

    system func inspect(params: InspectParams) : Bool {
        // check if the user is connected
        if (Principal.isAnonymous(params.caller)) { return false; };

        // check payload size
        if (Blob.size(params.arg) > 10000) { return false; };

        // check specific right for each route
        switch ( params.msg ) {
            case (#systemAddCanisterToMap(_))           params.caller == owner;
            case (#handlerCreateNewUserGroup(_))    Map.size(memoryGroups) <= CONFIG_MAX_NUMBER_ENTRIES;
        }
    };

    public shared func systemAddCanisterToMap({ canisterPrincipal: Principal; canisterKind: CanistersKinds.CanisterKind }) : async () {
        CanistersMap.addCanisterToMap({ map = memoryCanisters; canisterPrincipal = canisterPrincipal; canisterKind = canisterKind });
    };

    /////////
    // API //
    /////////

    // each user is it's own group. This handler create a specific group for a specific user
    public shared func handlerCreateNewUserGroup({ userPrincipal: Principal }) : async Result.Result<{ groupIdentifier: Identifier.Identifier; isFull: Bool }, Text> {
        if ( Map.size(memoryGroups) > CONFIG_MAX_NUMBER_ENTRIES ) { return #err(ERR_BUCKET_FULL); };

        let newGroup: Group.Group = {
                                        identifier = { id = Map.size(memoryGroups); bucket = thisPrincipal };
                                        name = "Personnal";
                                        todos = Map.empty<Nat, Todo.Todo>();
                                        todoLists = Map.empty<Nat, TodoList.TodoList>();
                                        users = Map.singleton<Principal, Group.UserGroupPermission>(userPrincipal, #owner);
                                        createdAt = Time.now();
                                        updatedAt = Time.now();
                                        createdBy = userPrincipal;
                                        kind = #personnal;
                                    };

        Map.add(memoryGroups, Nat.compare, newGroup.identifier.id, newGroup);

        #ok({ groupIdentifier = newGroup.identifier; isFull = newGroup.identifier.id >= CONFIG_MAX_NUMBER_ENTRIES; });
    };
}