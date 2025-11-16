ARCHITECTURE:
- a single entry point as coordinator, this coordinator is responsible to create every other canisters dynamically topping buckets, and must not be accessible by anyone but the creator.
- indexes are dynamically created, but on demand by the admin, not automatically. One index of each type will must be created at first launch
- each index has no state at all, and will retrieve data (the accessible buckets) from the coordinator directly. Their only goal is to coordinate multi canister call (update or query)
- each bucket must be able to check if it is called by an index if needed, so each bucket will be responsible to retrieve the list of indexes from the coordinator once in a while.

DEPLOYEMENT:
- When deploying, use the script deploy_local.sh

UPDATING CODE FOR BUCKET:
When updating code for a bucket, we need to call the maintenance index upgradeAllBuckets methods, while providing as parameter the bucket type and the wasm code as base64, here is an exemple;
dfx canister call organizerMaintenance upgradeAllBuckets \
  '(#buckettype, blob "'$(hexdump -ve '1/1 "\\\\%02x"' .dfx/local/canisters/organizerUsersDataBucket/organizerUsersDataBucket.wasm)'")'


GOOD TO KNOW:
- Note for the dfx file => dependencies field will check if the canisters are already deployed, or it will try to deploy it, so don't put the buckets here.