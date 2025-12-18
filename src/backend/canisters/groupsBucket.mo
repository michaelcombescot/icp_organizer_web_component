import Map "mo:core/Map";
import CanistersKinds "../shared/canistersKinds";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Identifiers "../shared/identifiers";
import Todo "../models/todosTodo";
import Group "../models/todosGroup";
import UserData "../models/todosUserData";
import Interfaces "../shared/interfaces";

shared ({ caller = owner }) persistent actor class GroupsBucket() = this {
    let thisPrincipal = Principal.fromActor(this);

    /////////////
    // CONFIGS //
    /////////////

    let MAX_NUMBER_ENTRIES = 30_000;
    
    ////////////
    // ERRORS //
    ////////////

    let ERR_GROUP_NOT_FOUND = "ERR_GROUP_NOT_FOUND";
    
    ////////////
    // MEMORY //
    ////////////

    let coordinatorActor = actor(Principal.toText(owner)) : Interfaces.Coordinator;

    let allowedCanisters = Map.empty<Principal, ()>();

    let memoryGroups = Map.empty<Nat, Group.Group>();

    var memoryUsersMapping: [Principal] = [];

    var idGroupCounter = 0;

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemUpdateUsersMapping : () -> (usersMapping: [Principal]);

            #handlerCreateGroup : () -> (userPrincipal: Principal, params : Group.CreateGroupParams);
            #handlerDeleteGroup : () -> (id : Nat);

            #handlerCreateTodo : () -> {userPrincipal : Principal; groupID : Nat; todo : Todo.Todo; };
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemUpdateUsersMapping(_))      params.caller == owner;

            case (#handlerCreateGroup(_))           true;
            case (#handlerDeleteGroup(_))           true;

            case (#handlerCreateTodo(_))            true;
        }
    };

    public shared func systemUpdateUsersMapping(usersMapping: [Principal]) : async () {
        memoryUsersMapping := usersMapping;
    };

    ////////////////
    // API GROUPS //
    ////////////////

    public shared func handlerCreateGroup(userPrincipal: Principal, params: Group.CreateGroupParams) : async Result.Result<{ isFull: Bool; identifier: Identifiers.Identifier }, Text> {
        let group = Group.createGroup({ name = params.name; createdBy = userPrincipal; identifier = { id = idGroupCounter; bucket = thisPrincipal }; kind = params.kind; });

        memoryGroups.add(Map.size(memoryGroups), group);
        idGroupCounter += 1;

        #ok({ isFull = memoryGroups.size() >= MAX_NUMBER_ENTRIES; identifier = group.identifier; });
    };

    public shared func handlerDeleteGroup(id: Nat) : async Result.Result<(), Text> {
        memoryGroups.remove(id);

        #ok();
    };

    ///////////////
    // API TODOS //
    ///////////////

    public shared func handlerCreateTodo({ userPrincipal: Principal; groupID: Nat; todo: Todo.Todo}) : async Result.Result<(), [Text]> {
        let ?group = memoryGroups.get(groupID) else return #err([ERR_GROUP_NOT_FOUND]);

        switch ( Todo.validateTodo(todo) ) {
            case (#ok()) ();
            case (#err(e)) return #err(e)
        };      

        let fullTodo = { todo with id = Map.size(group.todos); owner = userPrincipal; createdAt = Time.now(); createdBy = userPrincipal; status = #pending; };

        group.todos.add(Map.size(group.todos), fullTodo);

        #ok();
    };
};