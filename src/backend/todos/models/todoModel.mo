import Time "mo:core/Time";
import Result "mo:core/Result";
import Option "mo:core/Option";
import List "mo:core/List";
import Identifiers "../../shared/identifiers";

module {
    public type Todo = {
        identifier: Identifiers.WithID;
        bucket: Text;
        resume: Text;
        description: ?Text;
        scheduledDate: ?Time.Time;
        priority: TodoPriority;
        status: TodoStatus;
        createdAt: Time.Time;
        createdBy: Text;
    };

    public type TodoPriority    = { #high; #medium; #low; };
    public type TodoStatus      = { #pending; #done; };

    public func validateTodo(todo: Todo) : Result.Result<(), [Text]> {
        let errors = List.empty<Text>();

        if ( todo.createdAt == 0 )  { List.add(errors, "todo.createdAt cannot be empty") };
        if ( todo.resume.size() == 0 or todo.resume.size() > 100 )  { List.add(errors, "todo.resume cannot be empty and must be less than 101 characters") };
        if ( Option.get(todo.description, "").size() > 50000 )  { List.add(errors, "todo.description cannot be empty and must be less than 50001 characters") };

        if ( List.size(errors) == 0 ) { #ok } else { #err( List.toArray(errors) ) }
    };
};