Full exemple, frontend excluded, of a motoko multi indexes, multi buckets architecture, with a maintenance canister handling automatically the top up for cycles of everything.

When an index want to create a new bucket, it trigger a call to the maintenance canister. Both the index and the maintenance canister save the new bucket principal in stable memory.
Each bucket keep in stable memory the principal of the index which has triggered its creation.

When deploying, use the script deploy_local.sh, it will launch all canisters in local and generate the declarations for the buckets.

When updating code for a bucket, we need to call the maintenance index upgradeAllBuckets methods, while providing as parameter the bucket type and the wasm code as base64, here is an exemple;
dfx canister call organizerMaintenance upgradeAllBuckets \
  '(#buckettype, blob "'$(hexdump -ve '1/1 "\\\\%02x"' .dfx/local/canisters/organizerUsersDataBucket/organizerUsersDataBucket.wasm)'")'

Note for the dfx file => dependencies field will check if the canisters are already deployed, or it will try to deploy it, so don't put the buckets here.