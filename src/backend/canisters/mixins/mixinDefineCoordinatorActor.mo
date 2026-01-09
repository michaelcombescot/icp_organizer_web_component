import Principal "mo:base/Principal";
import Interfaces "../../shared/interfaces";

mixin(coordinatorPrincipal: Principal) {
    let coordinatorActor = actor(Principal.toText(coordinatorPrincipal)) : Interfaces.Coordinator;
};