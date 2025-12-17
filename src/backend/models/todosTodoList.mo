import Time "mo:core/Time";

module {
    public type TodoList = {
        id: Nat;
        name: Text;
        color: Text;
        owner: Principal;
        createdAt: Time.Time;
        createdBy: Principal;
    };
};