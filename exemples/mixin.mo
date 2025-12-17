mixin(incAmount : Nat) {
  var counter : Nat = 0;
  public func inc() : async () {
    counter += incAmount;
  };
};

// import CounterMixin "mo:mixins/CounterMixin"; => ex of synthax to import the mixin, mixin beeing here in CounterMixin.mo file
// persistent actor {
//   include CounterMixin(2);
//   public func incAndGet() : async Nat {
//     await inc();
//     counter
//   };
// }