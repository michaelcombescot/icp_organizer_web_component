module Errors {
    // permissions
    public let ERR_NOT_CONNECTED = "ERR_NOT_CONNECTED";
    public let ERR_NOT_AUTHORIZED = "ERR_NOT_AUTHORIZED";
    public let ERR_CAN_ONLY_BE_CALLED_BY_INDEX = "ERR_CAN_ONLY_BE_CALLED_BY_INDEX";

    // validation
    public let ERR_USER_DATA_ALREADY_EXISTS = "ERR_USER_DATA_ALREADY_EXISTS";

    // bad data
    public let ERR_INVALID_ID = "ERR_INVALID_ID";

    // maintenance
    public let ERR_UNKNOWN_NATURE = "ERR_UNKNOWN_NATURE";
    public let ERR_CAN_ONLY_BE_CALLED_BY_OWNER = "ERR_CAN_ONLY_BE_CALLED_BY_OWNER";

    // orchestration
    public let ERR_NO_BUCKET_FOUND = "ERR_NO_BUCKET_FOUND";
}