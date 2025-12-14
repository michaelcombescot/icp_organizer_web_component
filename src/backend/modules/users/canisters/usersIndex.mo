import PrincipalsArray "../../../shared/principalsArray";
import CanistersMap "../../../shared/canistersMap";
import Principal "mo:core/Principal";
import Timer "mo:core/Timer";
import UsersBucket "usersBucket";
import CanistersKinds "../../../shared/canistersKinds";

shared ({ caller = owner }) persistent actor class UsersIndex() = this {
    ////////////
    // MEMORY //
    ////////////

    let memoryCanisters = CanistersMap.newCanisterMap();

    let memoryUsers: PrincipalsArray.PrincipalsArray = [];

    ////////////
    // SYSTEM //
    ////////////

    ignore Timer.setTimer<system>(
        #seconds(0),
        func() : async () {
            if ( memoryUsers.size() == 0 ) {
                
            };
        }
    );

    type InspectParams = {
        arg: Blob;
        caller : Principal;
        msg : {
            #systemAddCanistersToMap : () -> { canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind };
        }
    };

    system func inspect(params: InspectParams) : Bool {
        if ( params.caller == Principal.anonymous() ) { return false; };

        true
    };

    public shared func systemAddCanistersToMap({ canistersPrincipals: [Principal]; canisterKind: CanistersKinds.CanisterKind }) : async () {
        CanistersMap.addCanistersToMap({ map = memoryCanisters; canistersPrincipals = canistersPrincipals; canisterKind = canisterKind });
    };
};