import Todo "../models/todo";
import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Blob "mo:core/Blob";
import Identifiers "../../../shared/identifiers";
import MixinAllowedCanisters "../../../shared/mixins/mixinAllowedCanisters";
import MixinOpsOperations "../../../shared/mixins/mixinOpsOperations";

shared ({ caller = owner }) persistent actor class TodosBucket() = this {
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
    // MEMORY //
    ////////////

    let memory = {
        groups = Map.empty<Nat, Todo.Todo>();
        var idGroupCounter = 0;
    };

    //////////
    // JOBS //
    //////////

    ignore setTimer<system>(
        #seconds(0),
        func () : async () {
            ignore recurringTimer<system>(#seconds(60_000_000_000), topCanisterRequest);
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
            #handlerCreateTodo : () -> (groupID : Nat, todo : Todo.Todo);
            #handlerDeleteTodo : () -> (groupID : Nat, todoID : Nat);
            #handlerUpdateTodo : () -> (groupID : Nat, todo : Todo.Todo);
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 5000 ) { return false; };

        switch ( params.msg ) {
            case (#handlerCreateTodo(_))   true;
            case (#handlerUpdateTodo(_))   true;
            case (#handlerDeleteTodo(_))   true;
        }
    };

    /////////
    // API //
    /////////
};