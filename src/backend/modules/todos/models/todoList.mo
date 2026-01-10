import Time "mo:core/Time";
import Result "mo:core/Result";
import List "mo:core/List";

module {
    public type TodoList = {
        id: Nat;
        name: Text;
        color: Text;
        createdAt: Time.Time;
        createdBy: Principal;
    };

    public func validateTodoList(todoList: TodoList) : Result.Result<(), [Text]> {
        let errors = List.empty<Text>();

        if ( todoList.name.size() == 0 or todoList.name.size() > 100 )  { errors.add("todoList.name cannot be empty and must be less than 101 characters") };
        if ( todoList.color.size() > 10 )  { errors.add("todoList.color cannot be empty and must be less than 101 characters") };

        #ok
    };
};