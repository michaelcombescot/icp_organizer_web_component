import Map "mo:core/Map";
import CanistersKinds "../../../shared/canistersKinds";
import CanistersMap "../../../shared/canistersMap";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Identifiers "../../../shared/identifiers";
import Todo "../models/todosTodo";
import Group "../models/todosGroup";

shared ({ caller = owner }) persistent actor class TodosGroupsBucket() = this {
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

    let memoryCanisters = CanistersMap.newCanisterMap();

    let memoryGroups = Map.empty<Nat, Group.Group>();

    var idGroupCounter = 0;

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemAddCanistersToMap : () -> { canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind };

            #handlerCreateUser : () -> {userPrincipal : Principal};
            #handlerGetUserData : () -> (userPrincipal : Principal);

            #handlerCreateGroup : () -> (userPrincipal: Principal, params : Group.CreateGroupParams);
            #handlerDeleteGroup : () -> (id : Nat);

            #handlerCreateTodo : () -> {userPrincipal : Principal; groupID : Nat; todo : Todo.Todo; };
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemAddCanistersToMap(_))       params.caller == owner;

            case (#handlerCreateUser(_))            CanistersMap.isPrincipalInKind(memoryCanisters, params.caller, #todosIndex);
            case (#handlerGetUserData(_))           CanistersMap.isPrincipalInKind(memoryCanisters, params.caller, #todosIndex);

            case (#handlerCreateGroup(_))           CanistersMap.isPrincipalInKind(memoryCanisters, params.caller, #todosIndex);
            case (#handlerDeleteGroup(_))           CanistersMap.isPrincipalInKind(memoryCanisters, params.caller, #todosIndex);

            case (#handlerCreateTodo(_))            CanistersMap.isPrincipalInKind(memoryCanisters, params.caller, #todosIndex);
        }
    };

    public shared func systemAddCanistersToMap({ canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind }) : async () {
        CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
    };

    ////////////////
    // API GROUPS //
    ////////////////

    public shared func handlerCreateGroup(userPrincipal: Principal, params: Group.CreateGroupParams) : async Result.Result<{ isFull: Bool; identifier: Identifiers.Identifier }, Text> {
        let group = Group.createGroup({ name = params.name; createdBy = userPrincipal; identifier = { id = idGroupCounter; bucket = thisPrincipal }; kind = params.kind; });

        Map.add(memoryGroups, Nat.compare, Map.size(memoryGroups), group);
        idGroupCounter += 1;

        #ok({ isFull = Map.size(memoryGroups) >= MAX_NUMBER_ENTRIES; identifier = group.identifier; });
    };

    public shared func handlerDeleteGroup(id: Nat) : async Result.Result<(), Text> {
        Map.remove(memoryGroups, Nat.compare, id);

        #ok();
    };

    ///////////////
    // API TODOS //
    ///////////////

    public shared func handlerCreateTodo({ userPrincipal: Principal; groupID: Nat; todo: Todo.Todo}) : async Result.Result<(), [Text]> {
        let ?group = Map.get(memoryGroups, Nat.compare, groupID) else return #err([ERR_GROUP_NOT_FOUND]);

        switch ( Todo.validateTodo(todo) ) {
            case (#ok()) ();
            case (#err(e)) return #err(e)
        };      

        let fullTodo = { todo with id = Map.size(group.todos); owner = userPrincipal; createdAt = Time.now(); createdBy = userPrincipal; status = #pending; };

        Map.add(group.todos, Nat.compare, Map.size(group.todos), fullTodo);

        #ok();
    };
};