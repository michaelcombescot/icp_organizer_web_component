import UserData "../models/todosUserData";
import Map "mo:core/Map";
import CanistersKinds "../../../shared/canistersKinds";
import CanistersMap "../../../shared/canistersMap";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Array "mo:core/Array";
import Identifiers "../../../shared/identifiers";
import Todo "../models/todosTodo";
import Group "../models/todosGroup";

shared ({ caller = owner }) persistent actor class TodosBucket() = this {
    let thisPrincipal = Principal.fromActor(this);

    /////////////
    // CONFIGS //
    /////////////

    let MAX_NUMBER_ENTRIES = 30000;
    
    ////////////
    // ERRORS //
    ////////////

    let ERR_USER_ALREADY_EXISTS = "ERR_USER_ALREADY_EXISTS";
    let ERR_GROUP_NOT_FOUND = "ERR_GROUP_NOT_FOUND";
    let ERR_USER_NOT_FOUND = "ERR_USER_NOT_FOUND";
    
    ////////////
    // MEMORY //
    ////////////

    let memoryCanisters = CanistersMap.newCanisterMap();

    let memoryUsers     = Map.empty<Principal, UserData.UserData>();
    let memoryGroups    = Map.empty<Nat, Group.Group>();

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemAddCanistersToMap : () -> { canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind };

            #handlerCreateUser : () -> {userPrincipal : Principal};
            #handlerGetUserData : () -> {userPrincipal : Principal};

            #handlerCreateTodo : () -> {userPrincipal : Principal; groupID : Nat; todo : Todo.Todo; };
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemAddCanistersToMap(_))       params.caller == owner;

            case (#handlerCreateUser(_))            CanistersMap.isPrincipalInKind(memoryCanisters, params.caller, #todosIndex);
            case (#handlerGetUserData(_))           CanistersMap.isPrincipalInKind(memoryCanisters, params.caller, #todosIndex);

            case (#handlerCreateTodo(_))            CanistersMap.isPrincipalInKind(memoryCanisters, params.caller, #todosIndex);
        }
    };

    public shared func systemAddCanistersToMap({ canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind }) : async () {
        CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
    };

    //////////////
    // API USER //
    //////////////

    public shared func handlerCreateUser({ userPrincipal: Principal }) : async Result.Result<{ isFull: Bool }, Text> {
        let ?_ = Map.get(memoryUsers, Principal.compare, userPrincipal) else return #err(ERR_USER_ALREADY_EXISTS);

        // create owned group for user
        let group = Group.createGroup({ name = "My group"; createdBy = userPrincipal; identifier = { id = Map.size(memoryGroups); bucket = thisPrincipal }; kind = #personnal; });

        Map.add(memoryGroups, Nat.compare, group.identifier.id, group);

        // create user data
        let userData: UserData.UserData = {
            name = "";
            email = "";
            groups = Map.singleton<Identifiers.Identifier, ()>(group.identifier, () );
            createdAt = Time.now();
        };

        Map.add(memoryUsers, Principal.compare, userPrincipal, userData);

        #ok({ isFull = Map.size(memoryGroups) >= MAX_NUMBER_ENTRIES });
    };

    public shared func handlerGetUserData({ userPrincipal: Principal }) : async Result.Result<UserData.SharableUserData, Text> {
        let ?userData = Map.get(memoryUsers, Principal.compare, userPrincipal) else return #err(ERR_USER_NOT_FOUND);

        #ok({
            name = userData.name;
            email = userData.email;
            groups = Array.fromIter( Map.keys(userData.groups) );
            createdAt = userData.createdAt;
        })
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