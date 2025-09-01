import Map "mo:core/Map";
import Result "mo:core/Result";
import List "mo:core/List";

module {
    public type TodoList = { 
        id: Nat;
        name: Text;
        color: Text;
    };

    public func validateTodoList(todoList: TodoList) : Result.Result<(), [Text]> {
        let errors = List.empty<Text>();

        if ( todoList.name.size() == 0 or todoList.name.size() > 100 )  { List.add(errors, "todoList.name cannot be empty and must be less than 101 characters") };
        if ( todoList.color.size() > 8 )  { List.add(errors, "todoList.color cannot be empty and must be less than 9 characters") };
        
        if ( List.size(errors) == 0 ) { #ok } else { #err( List.toArray(errors) ) }
    };
};