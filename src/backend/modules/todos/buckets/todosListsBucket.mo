import TodoList "../models/todoList";
import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Blob "mo:core/Blob";
import Identifiers "../../../shared/identifiers";
import Timer "mo:core/Timer";
import MixinAllowedCanisters "../../../shared/mixins/mixinAllowedCanisters";
import MixinOpsOperations "../../../shared/mixins/mixinOpsOperations";

shared ({ caller = owner }) persistent actor class TodosListsBucket() = this {
    /////////////
    // CONFIGS //
    /////////////

    let MAX_NUMBER_ENTRIES  = 100_000;

    ////////////
    // MIXINS //
    ////////////

    include MixinOpsOperations({
        coordinatorPrincipal    = owner;
        canisterPrincipal       = Principal.fromActor(this);
        toppingThreshold        = 2_000_000_000_000;
        toppingAmount           = 2_000_000_000_000;
        toppingIntervalNs       = 20_000_000_000;
    });
    include MixinAllowedCanisters(coordinatorActor); 

    ////////////
    // ERRORS //
    ////////////

    let ERR_INVALID_CALLER = "ERR_INVALID_CALLER";
    let ERR_TODOLIST_NOT_FOUND = "ERR_TODOLIST_NOT_FOUND";

    ////////////
    // MEMORY //
    ////////////

    let memory = {
        groups = Map.empty<Nat, TodoList.TodoList>();
        var idGroupCounter = 0;
    };

    //////////
    // JOBS //
    //////////

    ignore Timer.setTimer<system>(
        #seconds(0),
        func () : async () {
            ignore Timer.recurringTimer<system>(#seconds(60_000_000_000), topCanisterRequest);
            await topCanisterRequest();
        }
    );

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #handlerCreateTodoList : () -> (groupID : Nat, todoList : TodoList.TodoList);
            #handlerDeleteTodoList : () -> (groupID : Nat, todoListID : Nat);
            #handlerUpdateTodoList : () -> (groupID : Nat, todoList : TodoList.TodoList);
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 5000 ) { return false; };

        switch ( params.msg ) {
            case (#handlerCreateTodoList(_))   true;
            case (#handlerUpdateTodoList(_))   true;
            case (#handlerDeleteTodoList(_))   true;
        }
    };
}