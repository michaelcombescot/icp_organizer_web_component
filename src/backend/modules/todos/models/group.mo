import Map "mo:core/Map";
import Todo "todo";
import TodoList "todoList";
import Text "mo:base/Text";
import Result "mo:base/Result";
import List "mo:core/List";
import Principal "mo:base/Principal";

module {
    public type GroupData = {
        name: Text;
        todos: Map.Map<Nat, Todo.Todo>;
        todoLists: Map.Map<Nat, TodoList.TodoList>;
        users: Map.Map<Principal, GroupPermission>;
    };

    public type GroupDataSharable = {
        name: Text;
        todoLists: [(Nat, TodoList.TodoList)];
        users: [(Principal, GroupPermission)];
    };

    public type GroupPermission = { #admin; #read; #write; };

    public func validateGroupData(name: Text) : Result.Result<(), [Text]> {
        let errors = List.empty<Text>();

        if ( name.size() == 0 or name.size() > 100 )  { List.add(errors, "name cannot be empty and must be less than 101 characters") };
        
        if ( List.size(errors) == 0 ) { #ok } else { #err( List.toArray(errors) ) }
    };
}