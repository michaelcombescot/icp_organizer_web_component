import Text "mo:base/Text";
import Time "mo:base/Time";

module {
    // TODO
    public type Todo = {
        uuid: Text;
        resume: Text;
        description: Text;
        scheduledDate: Time.Time;
        priority: TodoPriority;
        status: TodoStatus;
        createdAt: Time.Time;
    };

    type TodoPriority = {
        #high;
        #medium;
        #low;
    };

    type TodoStatus = {
        #pending;
        #done;
    };

    // TODO LIST
    public type TodoList = {
        uuid: Text;
        name: Text;
        color: Text;
        todosUUIDs: [Text];
    } 
}