import Principal "mo:core/Principal";
import Blob "mo:core/Blob";
import Map "mo:core/Map";
import Iter "mo:core/Iter";
import List "mo:core/List";
import CanistersKinds "../shared/canistersKinds";
import MixinAllowedCanisters "../shared/mixins/mixinAllowedCanisters";
import MixinOpsOperations "../shared/mixins/mixinOpsOperations";
import { setTimer; recurringTimer } = "mo:core/Timer";

// only goal of this canister is too keep track of all the indexes and serve their principal to the frontend.
// not dynamically created, if the need arise another instance will need to be declared in the dfx.json
shared ({ caller = owner }) persistent actor class IndexesRegistry(coordinatorPrincipal: Principal) = this {    
    ////////////
    // MIXINS //
    ////////////

    include MixinOpsOperations({
        coordinatorPrincipal    = coordinatorPrincipal;
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
        indexes = Map.empty<CanistersKinds.IndexesKind, List.List<Principal>>();
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
            #systemAddIndex : () -> (indexPrincipal : Principal, indexKind : CanistersKinds.IndexesKind);

            #handlerGetIndexes : () -> ();
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        if ( Blob.size(params.arg) > 50 ) { return false; };

        switch ( params.msg ) {
            case (#systemAddIndex(_))           params.caller == coordinatorPrincipal or params.caller == owner;
            case (#handlerGetIndexes(_))        true
        }
    };

    public shared func systemAddIndex(indexPrincipal: Principal, indexKind: CanistersKinds.IndexesKind) : async () {
        switch ( memory.indexes.get(CanistersKinds.compareIndexesKind, indexKind) ) {
            case (null) memory.indexes.add(CanistersKinds.compareIndexesKind, indexKind, List.singleton(indexPrincipal));
            case (?list) list.add(indexPrincipal);    
        };
    };

    /////////
    // API //
    /////////

    public query func handlerGetIndexes() : async [(CanistersKinds.IndexesKind, [Principal])] {
        let newMap = memory.indexes.map(func(k,v) = v.toArray());
        Iter.toArray(newMap.entries())
    };
};