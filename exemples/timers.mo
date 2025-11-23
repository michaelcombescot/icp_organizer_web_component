import Nat64 "mo:core/Nat64";
import Time "mo:core/Time";
import { setTimer; recurringTimer } = "mo:core/Timer";

// 2 ways to do it, with func time and timer

// 1) with system time
// the function will trigger when the canister is launched or upgraded, and then at the time defined in the setGlobalTimer
persistent actor class RemindSystemTime() = this {
    let DELAY_IN_NS: Nat64 = 60_000_000_000;

    system func timer(setGlobalTimer : (Nat64) -> ()) : async () {
        // do something
        setGlobalTimer(Nat64.fromIntWrap(Time.now()) + DELAY_IN_NS);
    };
};


// 2) with timer
// first param is the delay before the first tick
// second param is the function triggered
// here we want to start the recurring task as a specific time, so we use setTimer, and then trigger the recurring task with recurringTimer.
// for a simple recurring task, we can use recurringTimer directly (ignore recurringTimer<system>(#seconds, func() : async {});)
//
// WARNING: recuringTimer first tick is AFTER the delay, for a first tick when the canister start/restart use system time
persistent actor class RemindTimer() = this {
    let DELAY_IN_SECONDS = 10;

    func doSomething() : async () {};

    ignore setTimer<system>(
        #seconds(0),
        func () : async () {
            ignore recurringTimer<system>(#seconds(DELAY_IN_SECONDS), doSomething);
            await doSomething();
        }
    );
};