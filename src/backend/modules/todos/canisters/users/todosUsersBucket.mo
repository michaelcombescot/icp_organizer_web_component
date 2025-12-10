import UserData "../../models/todosUserData";
import Map "mo:core/Map";
import CanistersKinds "../../../../shared/canistersKinds";
import CanistersMap "../../../../shared/canistersMap";
import Principal "mo:core/Principal";
import Result "mo:core/Result";
import Time "mo:core/Time";
import Identifiers "../../../../shared/identifiers";

shared ({ caller = owner }) persistent actor class TodosUsersBucket() = this {
    /////////////
    // CONFIGS //
    /////////////

    let MAX_NUMBER_ENTRIES = 30000;
    
    ////////////
    // ERRORS //
    ////////////

    let ERR_USER_ALREADY_EXISTS = "ERR_USER_ALREADY_EXISTS";
    
    ////////////
    // MEMORY //
    ////////////

    let memoryCanisters = CanistersMap.newCanisterMap();

    let memoryUsersData = Map.empty<Principal, UserData.UserData>();

    ////////////
    // SYSTEM //
    ////////////

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemAddCanisterToMap : () -> { canisterPrincipal: Principal; canisterKind: CanistersKinds.CanisterKind };

            #handlerCreateUserData : () -> {userPrincipal : Principal};
        };
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        switch ( params.msg ) {
            case (#systemAddCanisterToMap(_))       params.caller == owner;
            case (#handlerCreateUserData(_))    CanistersMap.isPrincipalInCanistersMap({ canistersMap = memoryCanisters; principal = params.caller; canisterKind = #indexes(#todosUsersIndex) });
        }
    };

    public shared func systemAddCanisterToMap({ canisterPrincipal: Principal; canisterKind: CanistersKinds.CanisterKind }) : async () {
        CanistersMap.addCanisterToMap({ map = memoryCanisters; canisterPrincipal = canisterPrincipal; canisterKind = canisterKind });
    };

    /////////
    // API //
    /////////

    public shared func handlerCreateUserData({ userPrincipal: Principal }) : async Result.Result<{ isFull: Bool }, Text> {
        let ?_ = Map.get(memoryUsersData, Principal.compare, userPrincipal) else return #err(ERR_USER_ALREADY_EXISTS);

        let userData: UserData.UserData = {
            groups = Map.empty<Identifiers.Identifier, ()>();
            createdAt = Time.now();
        };

        Map.add(memoryUsersData, Principal.compare, userPrincipal, userData);

        #ok({ isFull = Map.size(memoryUsersData) >= MAX_NUMBER_ENTRIES });
    };
};