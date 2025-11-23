ARCHITECTURE:
- a coordinator responsible to create buckets dynamically topping every canister (indexes included), and must not be accessible by anyone but the creator and the canisters directly
- one or several indexes by module, all defined in the dfx.json and used by the frontend.
- data are stored in buckets, and buckets are created dynamically when needed -> the coordinator keep a pool of new buckets available, and indexes grab them when needed. The pool of new buckets is automatically refilled by the coordinator. 

DEPLOYEMENT:
- When deploying, use the script deploy_local.sh, or see it to understand what is done.

UPDATING CODE FOR BUCKET:
When updating code for a bucket, we need to call the maintenance index upgradeAllBuckets methods, while providing as parameter the bucket type and the wasm code as base64, here is an exemple;
dfx canister call organizerMaintenance upgradeAllBuckets \
  '(#buckettype, blob "'$(hexdump -ve '1/1 "\\\\%02x"' .dfx/local/canisters/organizerUsersDataBucket/organizerUsersDataBucket.wasm)'")'


GOOD TO KNOW:
- Note for the dfx file => dependencies field will check if the canisters are already deployed, or it will try to deploy it, so don't put the buckets here. For the bucket we just need to generate the candid/js files if one day we need to be able to call a bucket directly.