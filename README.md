ARCHITECTURE:
- a coordinator is responsible to create buckets and indexes. It as a loop topping every canisters if needed
- indexes create new items, and handle the complex things (like multi step update on several buckets), otherwise the frontend can directly query relevant buckets

DEPLOYEMENT:
- When deploying locally, use the script deploy_local.sh, or see it to understand what is done.

UPDATING CODE FOR BUCKET:
When updating code for a bucket, we need to call the maintenance index upgradeAllBuckets methods, while providing as parameter the bucket type and the wasm code as base64, here is an exemple;
dfx canister call organizerMaintenance upgradeAllBuckets \
  '(#buckettype, blob "'$(hexdump -ve '1/1 "\\\\%02x"' .dfx/local/canisters/organizerUsersDataBucket/organizerUsersDataBucket.wasm)'")'


GOOD TO KNOW:
- Note for the dfx file => dependencies field will check if the canisters are already deployed, or it will try to deploy it, so don't put the buckets here. For the bucket we just need to generate the candid/js files if one day we need to be able to call a bucket directly.
- When a canister is deploy on the main network, a canister_ids file is generated, this is this file which make it possible for other canisters (especially the frontend) to know from the js file what the principals are.