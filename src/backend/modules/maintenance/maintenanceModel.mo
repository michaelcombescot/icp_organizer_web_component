import UsersDataBucket "../usersData/usersDataBucket";
import TodosBucket "../todos/todosBucket";

module {
    public type BucketType = {
        #usersData : () -> async UsersDataBucket.UsersDataBucket;
        #todos : () -> async TodosBucket.TodosBucket;
    };

    public type Nature = {
        #usersData;
        #todos;
    };
}