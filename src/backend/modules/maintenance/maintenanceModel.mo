import UsersDataBucket "../usersData/usersDataBucket";
import TodosBucket "../todos/todosBucket";
import Map "mo:core/Map";
import Iter "mo:core/Iter";
import Principal "mo:core/Principal";
import Configs "../../shared/configs";

module {
    public type BucketType = {
        #usersData : () -> async UsersDataBucket.UsersDataBucket;
        #todos : () -> async TodosBucket.TodosBucket;
    };

    public type Nature = {
        #usersData;
        #todos;
    };

    public func makeAllowedCallers() : Map.Map<Principal, (Nature, BucketType)> {
        Map.fromIter<Principal, (Nature, BucketType)>(
            Iter.fromArray([
                ( Principal.fromText(Configs.CanisterIds.INDEX_USERS_DATA), (#usersData, #usersData(UsersDataBucket.UsersDataBucket)) ),
                ( Principal.fromText(Configs.CanisterIds.INDEX_TODOS), (#todos, #todos(TodosBucket.TodosBucket)) )
            ]),
            Principal.compare
        )
    };
}