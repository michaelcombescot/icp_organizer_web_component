import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Identifiers "../shared/identifiers";
import Todo "../models/todosTodo";
import TodoList "../models/todosTodoList";
import Group "../models/todosGroup";
import MixinAllowedCanisters "mixins/mixinAllowedCanisters";
import Blob "mo:core/Blob";
import Iter "mo:core/Iter";
import Errors "../shared/errors";

shared ({ caller = owner }) persistent actor class GroupsBucket() = this {
    include MixinAllowedCanisters(owner);

    let thisPrincipal = Principal.fromActor(this);

    /////////////
    // CONFIGS //
    /////////////

    let MAX_NUMBER_ENTRIES = 30_000;  
    
    ////////////
    // MEMORY //
    ////////////

    let memoryGroups = Map.empty<Nat, Group.Group>();

    var idGroupCounter = 0;

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #handlerCreateGroup : () -> (userPrincipal : Principal, params : Group.CreateGroupParams);
            #handlerDeleteGroup : () -> (groupID : Nat);

            #handlerGetGroupDisplayData : () -> (groupID : Nat);
            #handlerCreateTodo : () -> (groupID : Nat, todo : Todo.Todo);
            #handlerDeleteTodo : () -> (groupID : Nat, todoID : Nat);
            #handlerUpdateTodo : () -> (groupID : Nat, todo : Todo.Todo);

            #handlerCreateTodosList : () -> (groupID : Nat, todoList : TodoList.TodoList);
            #handlerUpdateTodosList : () -> (groupID : Nat, todoList : TodoList.TodoList);
            #handlerDeleteTodosList : () -> (groupID : Nat, todoListID : Nat);
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 5000 ) { return false; };

        switch ( params.msg ) {
            case (#handlerGetGroupDisplayData(_)) true;
            case (#handlerCreateGroup(_))  true;
            case (#handlerDeleteGroup(_))  true;

            case (#handlerCreateTodo(_))   true;
            case (#handlerUpdateTodo(_))   true;
            case (#handlerDeleteTodo(_))   true;

            case (#handlerCreateTodosList(_)) true;
            case (#handlerUpdateTodosList(_)) true;
            case (#handlerDeleteTodosList(_)) true;
        }
    };

    ////////////////
    // API GROUPS //
    ////////////////

    public shared ({ caller }) func handlerGetGroupDisplayData(groupID: Nat) : async Result.Result<Group.RespGetGroupDisplayData, Text> {
        let ?group = memoryGroups.get(groupID) else return #err(Errors.ERR_GROUP_NOT_FOUND);
        
        switch ( group.users.get(caller) ) {
            case null return #err(Errors.ERR_GROUP_ACTION_FORBIDDEN);
            case (?permission) if ( permission == #archived ) return #err(Errors.ERR_GROUP_ACTION_FORBIDDEN);
        };

        let resp = {
            identifier = group.identifier;
            name = group.name;
            todos = Iter.toArray(group.todos.values());
            todoLists = Iter.toArray(group.todoLists.values());
            users = Iter.toArray(group.users.entries());
            kind = group.kind;
        };

        #ok(resp);
    };

    public shared ({ caller }) func handlerCreateGroup(userPrincipal: Principal, params: Group.CreateGroupParams) : async Result.Result<{ isFull: Bool; identifier: Identifiers.Identifier }, Text> {
        if (await systemHelperIsCanisterAllowed(caller)) return #err(Errors.ERR_INVALID_CALLER);

        let group = Group.createGroup({ name = params.name; createdBy = userPrincipal; identifier = { id = idGroupCounter; bucket = thisPrincipal }; kind = params.kind; });

        memoryGroups.add(Map.size(memoryGroups), group);
        idGroupCounter += 1;

        #ok({ isFull = memoryGroups.size() >= MAX_NUMBER_ENTRIES; identifier = group.identifier; });
    };

    public shared ({ caller }) func handlerDeleteGroup(groupID: Nat) : async Result.Result<(), Text> {
        let ?group = memoryGroups.get(groupID) else return #err(Errors.ERR_GROUP_NOT_FOUND);

        switch ( group.users.get(caller) ) {
            case null return #err(Errors.ERR_GROUP_ACTION_FORBIDDEN);
            case (?permission) if ( permission != #owner ) return #err(Errors.ERR_GROUP_ACTION_FORBIDDEN);
        };

        memoryGroups.remove(groupID);

        #ok();
    };

    ///////////////
    // API TODOS //
    ///////////////

    public shared ({ caller }) func handlerCreateTodo(groupID: Nat, todo: Todo.Todo) : async Result.Result<Nat, [Text]> {
        let ?group = memoryGroups.get(groupID) else return #err([Errors.ERR_GROUP_NOT_FOUND]);

        switch ( group.users.get(caller) ) {
            case null return #err([Errors.ERR_GROUP_ACTION_FORBIDDEN]);
            case (?permission) if ( permission == #visitor or permission == #archived ) return #err([Errors.ERR_GROUP_ACTION_FORBIDDEN]);
        };

        switch ( Todo.validateTodo(todo) ) {
            case (#ok()) ();
            case (#err(e)) return #err(e)
        };      

        let fullTodo = { todo with id = Map.size(group.todos); createdAt = Time.now(); createdBy = caller; status = #pending; };

        group.todos.add(Map.size(group.todos), fullTodo);

        #ok(fullTodo.id);
    };

    public shared ({ caller }) func handlerUpdateTodo(groupID: Nat, todo: Todo.Todo) : async Result.Result<(), [Text]> {
        let ?group = memoryGroups.get(groupID) else return #err([Errors.ERR_GROUP_NOT_FOUND]);
        let ?_ = group.todos.get(todo.id) else return #err([Errors.ERR_TODO_NOT_FOUND]);

        switch ( group.users.get(caller) ) {
            case null return #err([Errors.ERR_GROUP_ACTION_FORBIDDEN]);
            case (?permission) if ( permission == #visitor or permission == #archived ) return #err([Errors.ERR_GROUP_ACTION_FORBIDDEN]);
        };

        switch ( Todo.validateTodo(todo) ) {
            case (#ok()) ();
            case (#err(e)) return #err(e)
        };  

        group.todos.add(todo.id, todo);

        #ok()
    };

    public shared ({ caller }) func handlerDeleteTodo(groupID: Nat, todoID: Nat) : async Result.Result<(), [Text]> {
        let ?group = memoryGroups.get(groupID) else return #err([Errors.ERR_GROUP_NOT_FOUND]);

        switch ( group.users.get(caller) ) {
            case null return #err([Errors.ERR_GROUP_ACTION_FORBIDDEN]);
            case (?permission) if ( permission == #visitor or permission == #archived ) return #err([Errors.ERR_GROUP_ACTION_FORBIDDEN]);
        };

        group.todos.remove(todoID);
        #ok()
    };

    /////////////////////
    // API TODOS LISTS //
    /////////////////////

    public shared ({ caller }) func handlerCreateTodosList(groupID: Nat, todoList: TodoList.TodoList) : async Result.Result<Nat, [Text]> {
        let ?group = memoryGroups.get(groupID) else return #err([Errors.ERR_GROUP_NOT_FOUND]);

        switch ( group.users.get(caller) ) {
            case null return #err([Errors.ERR_GROUP_ACTION_FORBIDDEN]);
            case (?permission) if ( permission == #visitor or permission == #archived ) return #err([Errors.ERR_GROUP_ACTION_FORBIDDEN]);
        };

        switch ( TodoList.validateTodoList(todoList) ) {
            case (#ok()) ();
            case (#err(e)) return #err(e)
        };

        let fullTodoList = { todoList with id = Map.size(group.todoLists); createdAt = Time.now(); createdBy = caller; };

        group.todoLists.add(fullTodoList.id, fullTodoList);

        #ok(fullTodoList.id);
    };

    public shared ({ caller }) func handlerUpdateTodosList(groupID: Nat, todoList: TodoList.TodoList) : async Result.Result<(), [Text]> {
        let ?group = memoryGroups.get(groupID) else return #err([Errors.ERR_GROUP_NOT_FOUND]);
        let ?_ = group.todoLists.get(todoList.id) else return #err([Errors.ERR_TODOLIST_NOT_FOUND]);

        switch ( group.users.get(caller) ) {
            case null return #err([Errors.ERR_GROUP_ACTION_FORBIDDEN]);
            case (?permission) if ( permission == #visitor or permission == #archived ) return #err([Errors.ERR_GROUP_ACTION_FORBIDDEN]);
        };

        switch ( TodoList.validateTodoList(todoList) ) {
            case (#ok()) ();
            case (#err(e)) return #err(e)
        };

        group.todoLists.add(todoList.id, todoList);

        #ok
    };

    public shared ({ caller }) func handlerDeleteTodosList(groupID: Nat, todoListID: Nat) : async Result.Result<(), [Text]> {
        let ?group = memoryGroups.get(groupID) else return #err([Errors.ERR_GROUP_NOT_FOUND]);
        let ?_ = group.todoLists.get(todoListID) else return #err([Errors.ERR_TODOLIST_NOT_FOUND]);

        switch ( group.users.get(caller) ) {
            case null return #err([Errors.ERR_GROUP_ACTION_FORBIDDEN]);
            case (?permission) if ( permission == #visitor or permission == #archived ) return #err([Errors.ERR_GROUP_ACTION_FORBIDDEN]);
        };

        group.todoLists.remove(todoListID);
        #ok()
    };
};