import Map "mo:core/Map";
import Result "mo:core/Result";
import List "mo:core/List";
import Time "mo:core/Time";

module {
    public type TodoList = {
        id: Text;
        name: Text;
        color: Text;
        owner: Owner;
        createdAt: Time.Time;
        createdBy: Principal;
    };

    public type Owner = {
        #user: Text;
        #group: Text;
    };

    // create
    public type CreateTodoListData = {
        name: Text;
        color: Text;
    };

    public func validateTodoList(todoListData: CreateTodoListData) : Result.Result<(), [Text]> {
        let errors = List.empty<Text>();

        if ( todoListData.name.size() == 0 or todoListData.name.size() > 100 )  { List.add(errors, "todoList.name cannot be empty and must be less than 101 characters") };
        if ( todoListData.color.size() == 0 or todoListData.color.size() > 8 )  { List.add(errors, "todoList.color cannot be empty and must be less than 9 characters") };

        if ( List.size(errors) == 0 ) { #ok } else { #err( List.toArray(errors) ) }
    };

    //update
    public type UpdateTodoListData = CreateTodoListData and { id: Text; };
}