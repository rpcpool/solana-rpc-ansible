Solana RPC role
=========

An Ansible role to deploy a Solana RPC node. This configures the validator software in RPC mode running under the user `solana`. The RPC service is installed as a user service running under this same user. 

Updates
------------

  - 16/02 - From Solana 1.8.15 (mainnet) and 1.9.6 (testnet) onwards you will need to specify `solana_full_rpc_api: true` for this role to actually create a fully exposed RPC API node.

Hardware Requirements
------------

An RPC server requires _at least_ the same specs as a Solana validator, but typically has higher requirements. In particular, we recommend using 256 GB of RAM in order to store indexes. For more information about hardware requirements, please see [https://docs.solana.com/running-validator/validator-reqs](https://docs.solana.com/running-validator/validator-reqs).

Before deploy you should prepare the host so that the directory that you use for your Accounts database and your Ledger location are properly configured. This can include setting up a tmpfs folder for accounts and a separate filesystem (ideally on an NVME drive) for the ledger. A common way to configure this might be:

```
/solana/tmpfs - a 100 GB tmpfs partition to hold accounts state
/solana/ledger - a 2 TB NVME drive to hold ledger
```

Software Requirements
------------

 * Ansible >= 2.7 (tested primarily on Ansible 2.8)
 * Ubuntu 18.04+ on the target deployment machine 

This role assumes some familiarity with the Solana validator software deployment process.

Role Variables
--------------

The deploy ensures that the checksum for the version of solana-installer that you are downloading matches one given in `vars/main.yml`. In case you want to insatll a solana version not listed there, it is good if you first download and check the sha256 checksum of the solana-installer script (https://raw.githubusercontent.com/solana-labs/solana/install/solana-install-init.sh).

There are a large number of configurable parameters for Solana. Many of these have workable defaults, and you can use this role to deploy a Solana RPC node without changing any of the default values and you should be able to have a decent experience. If you run this role without specifying any parameters, it'll configure a standard `mainnet` RPC node. 

### Basic variables

These are the basic variables that configure the setup of the validators. They have default values but you probably want to customise them based on your setup.

| Name                 | Default value        | Description                |
|----------------------|----------------------|----------------------------|
| `solana_version` | stable | The solana version to install. |
| `solana_full_rpc_api` | `true` | Whether to enable the full RPC API or not. That's typically what you want. |
| `solana_root`        | /solana              | Main directory for solana ledger and accounts |
| `solana_ledger_location` | /solana/ledger | Storage for solana ledger (should be on NVME) |
| `solana_accounts_location` | /solana/ledger/accounts | Storage for solana accounts information. In case you use tmpfs for accounts this should be a subdirectory of your tmpfs mount point (e.g. `/solana/tmpfs/accounts` in case tmpfs is mounted on `/solana/tmpfs` |
| `solana_snapshots_location` | <none> | Storage for solana snapshots. Can be useful to keep on a separate NVME from your ledger. |
| `solana_keypairs` | `[]` | List of keypairs to copy to the validator node. Each entry in the list should have a `key` and `name` entry. This will create `/home/solana/<name>.json` containing the value of `key`. |
| `solana_generate_keypair` | true | Whether or not to generate a keypair. If you haven't specified `solana_keypairs` and you set this to true, a new key will be generated and placed in /home/solana/identity.json |
| `solana_public_key` | `/home/solana/identity.json` | Location of the identity of the validator node. |
| `solana_network` | mainnet | The solana network that this node is supposed to be part of |
| `solana_environment` | see defaults/main.yml | Environment variables to specify for the validator node, most importantly `RUST_LOG` |
| `solana_enabled_services` | `[ solana-rpc ]`  | List of services to start automatically on boot |
| `solana_disabled_services` | `[ ]` | List of services to set as disabled |

### Ports

The following ports needs to be configured for your RPC server. 

| Name                 | Default value        | Description                |
|----------------------|----------------------|----------------------------|
| `solana_gossip_port` | 8001 | Port for gossip traffic (needs to be open publicly in firewall for both TCP and UDP) |
| `solana_rpc_port` | 8899 (+8900) | Ports for incoming RPC (and websocket). This is typically only open on localhost. Place a proxy like `haproxy` in front of these port(s) and don't expose them publicly. |
| `solana_rpc_bind_address` | 127.0.0.1 | Address to bind RPC on. This should typically be localhost. Place a proxy like `haproxy` in front of this to accept public traffic |
| `solana_dynamic_port_range` | 8002-8020 | Port for incoming solana traffic. May need to be open publicly in firewall for UDP. |

From this list, you can tell that you need at least 8001-8020 open in your firewall for incoming traffic in the default case.

For pure RPC nodes it may be possible to close down the TPU and TPU forward ports. These ports are dynamically allocated and you can see them by looking at your node in `solana gossip`. If you want to firewall them, you can use this utility: https://github.com/rpcpool/tpu-traffic-classifier. Using this tool you can block incoming TPU and TPU forward on a local node by running:

`./tpu-traffic-classifier -config-file config.yml -our-localhost -tpu-policy DROP -fwd-policy DROP -update=false`

Put this in a SystemD service and you can have it start at boot of node and leave it continuously running.

### Network specific variables

Default values for these variables are specified in `vars/{{ solana_network }}-default.yml` (e.g. `vars/mainnet-default.yml`). You can also specify your own by providing the file `{{ solana_network }}.yml`. You will need to specify all these variables unless you rely on the defaults.

| Name                 | Default value        | Description                |
|----------------------|----------------------|----------------------------|
| `solana_network` | mainnet | The solana network this node should join     |
| `solana_metrics_config` | see vars/mainnet-default.yml | The metrics endpoint |
| `solana_genesis_hash` | see vars/mainnet-default.yml | The genesis hash for this network |
| `solana_entrypoints` | see vars/mainnet-default.yml | Entrypoint hosts |
| `solana_known_validators` | see vars/mainnet-default.yml | Known validators from where to fetch snapshots and genesis bin on start up |
| `solana_expected_bank_hash` | see vars/mainnet-default.yml | Expected bank hash |
| `solana_expected_shred_version` | see vars/mainnet-default.yml | Expected shred version |
| `solana_index_exclude_keys` | see vars/mainnet-default.yml | Keys to exclude from indexes for performance reasons |

### RPC specific variables

| Name                 | Default value        | Description                |
|----------------------|----------------------|----------------------------|
| `solana_rpc_faucet_address` | | Specify an RPC faucet |
| `solana_rpc_history` | true | Whether to provide historical values over RPC |
| `solana_account_index` | program-id spl-token-owner spl-token-mint | Which indexes to enable. These greatly improve performance but slows down start up time and can increase memory requirements. |

### Performance variables

These are variables you can tweak to improve performance

| Name                 | Default value        | Description                |
|----------------------|----------------------|----------------------------|
| `solana_snapshot_compression` |  | Whether to compress snapshots or not. Specify none to improve performance.  |
| `solana_snapshot_interval_slots` | | How often to take snapshots. Increase to improve performance. Suggested value is 500. |
| `solana_pubsub_max_connections` | 1000 | Maximum number of pubsub connections to allow. |
| `solana_bpf_jit` | | Whether to enable BPF JIT . Default on for devnet. |
| `solana_banking_threads` | 16 | Number of banking threads. |
| `solana_rpc_threads` | | Number of RPC threads (default maximum threads/cores on system) |
| `solana_limit_ledger_size` | `solana default, 250 mio` | Size of the local ledger to store. For a full epoch set a value between 350 mio and 500 mio. For best performance set 50 (minimal value). |
| `solana_accounts_db_caching` | | Whether to enable accounts db caching |
| `solana_accounts_shrink_path` | | You may want to specify another location for the accounts shrinking process |

## Bigtable

You can specify Google Bigtable account credentials for querying blocks not present in local ledger.

| Name                 | Default value        | Description                |
|----------------------|----------------------|----------------------------|
| `solana_bigtable_enabled` | false | Enable bigtable access |
| `solana_bigtable_upload_enabled` | false | Enable bigtable uploading (the credentials you provide below needs write access) |
| `solana_bigtable_project_id` | | Bigtable project id |
| `solana_bigtable_private_key_id` | | Bigtable private key id |
| `solana_bigtable_private_key` | | Bigtable private key |
| `solana_bigtable_client_email` | | Bigtable client email |
| `solana_bigtable_client_id` | | Bigtable client id |
| `solana_bigtable_client_x509_cert_url` | | Bigtable cert url  |

For more information about BigTable see https://github.com/solana-labs/solana-bigtable .
	

## Handling forks

Occasionally devnet/testnet will experience forks. In these cases use the following parameters as instructed in Discord:

| Name                 | Default value        | Description                |
|----------------------|----------------------|----------------------------|
| `solana_hard_fork` |  | Hard fork |
| `solana_wait_for_supermajority` |  | Whether node should wait for supermajority or not |

## CPU governor & Sysctl settings

There are certain configurations that you need to do to get your RPC node running properly. This role can help you make some of these standard config changes. However, full optmisation depends greatly on your hardware so you need to take time to be familiar with how to configure your hardware right.

However, the most important element of optimisation is the CPU performance governor. This controls boost behaviour and energy usage. On many hosts in DCs they are configured for balance between performance and energy usage. In the case of Solana we really need them to perform at their fastest. To set the servers CPU governor there are three options:
	
 1. You have access to BIOS and you set the BIOS cpu setting to `max performance`. This seems to work well for HPE systems. In this case, specify the variable `cpu_governor: bios`. This is sometimes required for AMD EPYC systems too.
 2. You have acccess to BIOS and you set the BIOS cpu setting to `os control`. This should be the typical default. In this case you can leave the `cpu_governor` variable as default or set it explicitly to `cpu_governor: performance`.
 3. You don't have access to BIOS or CPU governor settings. If possible, try to set `cpu_governor: performance`. Otherwise, hopefully your provider has configured it for good performance!

The second config you need to do is to edit various kernel parameters to fit the Solana RPC use case.

One option is to deploy `solana-sys-tuner` together with this config to autotune some variables for you. 

A second option, especially if you are new to tuning performance is `tuned` and `tune-adm` from RedHat, where the `throughput-performance` profile is suitable. 

Finally, if you deploy through this role you can also specify a list of sysctl values for this playbook to automatically set up on your host. This allows full control and sets them so that they are permanently configured.
Here is a list of sysctl values that we have used on rpcpool:

```
sysctl_optimisations:
  vm.max_map_count: 700000
  kernel.nmi_watchdog: 0
# Minimal preemption granularity for CPU-bound tasks:
# (default: 1 msec#  (1 + ilog(ncpus)), units: nanoseconds)
  kernel.sched_min_granularity_ns: '10000000'
# SCHED_OTHER wake-up granularity.
# (default: 1 msec#  (1 + ilog(ncpus)), units: nanoseconds)
  kernel.sched_wakeup_granularity_ns:  '15000000' 
  vm.swappiness: '30'
  kernel.hung_task_timeout_secs: 600
# this means that virtual memory statistics is gathered less often but is a reasonable trade off for lower latency
  vm.stat_interval: 10
  vm.dirty_ratio: 40
  vm.dirty_background_ratio: 10
  vm.dirty_expire_centisecs: 36000
  vm.dirty_writeback_centisecs: 3000
  vm.dirtytime_expire_seconds: 43200
  kernel.timer_migration: 0
# A suggested value for pid_max is 1024 * <# of cpu cores/threads in system>
  kernel.pid_max: 65536
  net.ipv4.tcp_fastopen: 3
# From solana systuner
# Reference: https://medium.com/@CameronSparr/increase-os-udp-buffers-to-improve-performance-51d167bb1360
  net.core.rmem_max: 134217728
  net.core.rmem_default: 134217728
  net.core.wmem_max: 134217728
  net.core.wmem_default: 134217728
```

Example Playbooks
-----------------

Mainnet node:

```
    - hosts: rpc_nodes
      become: true
      become_method: sudo
      roles:
         - { role: rpcpool.solana-rpc, solana_network: mainnet }
```

Testnet node:

```
    - hosts: rpc_nodes
      become: true
      become_method: sudo
      roles:
         - { role: rpcpool.solana-rpc, solana_network: testnet }
```

Devnet node:

```
    - hosts: rpc_nodes
      become: true
      become_method: sudo
      roles:
         - { role: rpcpool.solana-rpc, solana_network: devnet }
```



Starting the RPC node
--------------------

After the deploy you can login to the machine and run `su -l solana` to become the solana user. 

To see the Solana validator command line generated for you during the deploy you can take a look at `/home/solana/bin/solana-rpc.sh`. Remember that any changes to this file will be overwritten next time you run this Ansible.

For the first start up, you should comment out `--no-genesis-fetch` and `--no-snapshot-fetch` in the file `/home/solana/bin/solana-rpc.sh`. This will allow solana to download the basic files it requires for first time start up. Remember to activate these lines again after you have started the validator for the first time.

Then start up the solana RPC process by running `systemctl --user start solana-rpc`. You can see status of the process by running `systemctl --user status solana-rpc`. The first start up will take some time. You can monitor start up by running `solana catchup --our-localhost`.

Finally, to see logs for your Solana RPC node run `journalctl --user -u solana-rpc -f`.

If this is your first time running a Solana node, you can find more details about how to operate the node on [https://docs.solana.com/running-validator/validator-start](https://docs.solana.com/running-validator/validator-start) and [https://github.com/agjell/sol-tutorials/](https://github.com/agjell/sol-tutorials/). 


Checking the RPC node
--------------------

The basic check after you've veriried that the node has started is to track catchup: 

```
solana catchup --our-localhost
```

After this you can continue to check that it is serving RPC calls correctly.

## Testing RPC access 
You can also try a few easy validation commands (thanks buffalu: https://gist.github.com/buffalu/db6458d4f6a0b70ac303027b61a636af):

```
curl http://localhost:8899 -X POST -H "Content-Type: application/json" -d '
  {"jsonrpc":"2.0","id":1, "method":"getSlot", "params": [
      {
        "commitment": "processed"
      }
    ]}
'

curl http://localhost:8899  -X POST -H "Content-Type: application/json" -d '
  {"jsonrpc":"2.0","id":1, "method":"getSlot"}
'
```

## Testing websocket access

The easiest way to test websockets is to install the utility `wscat`. To do so you'll need to install NodeJS and NPM and then run `npm install wscat`.

You can then connect to your websocket in the following way:

```
wscat -c localhost:8900
```

From there you'll get a command prompt where you can manually enter your websocket subscription requests:

```
> {"jsonrpc":"2.0", "id":1, "method":"slotSubscribe"}
```

You should now start receiving regular updates on the slots as they are confirmed by your RPC node. 

RPC node falling behind/not catching up
--------------------

The most typical performance issue that an RPC node can face is that it keeps falling behind the network and is not able to catch up.
	
If it can't catch up the first time you started it up, this would typically be due to a misconfiguration. The most common issue is your CPU boost frequencies (for more details on CPU config see above):

* Check that your CPU is recent enough (anything < EPYC 2nd gen on AMD or < Cascade Lake on Intel will struggle)
* Check that your CPU governor is not set to energy saving mode in BIOS and in your kernel settings
* Observe the CPU frequencies when running solana with `watch -n 1 grep MHz /proc/cpuinfo`, you'll need it to be > 3ghz on all cores typically (rule of thumb). You **do not** want to see any core going to 1.4-1.8 ever.
	
If it used to be able to catch up but is no longer (or if fixing the CPU didn't solve it):

* Check memory/cpu/network - do you have good CPU frequencies, are you dipping into swap (not enough memory) or is your provider throttling UDP packets?
	+ _CPU_: Fix performance governor/boost setting, get newer generation CPU or CPU with better all-cores turbo (check wikichip for details). Remember that MHz is not the same across different generations. Broadwell 3.0 ghz is not the same as Cascade Lake 3.0 ghz or EPYC 3rd gen 3.0 ghz.
	+ _Network_: Check UDP packet throttling and connectivity. You need at least a 500 mbps pipe without any throttling on UDP. Some providers like to block UDP or throttle it for DDoS protection. This is both on incoming and outgoing. If you are throttled on incoming your node will not receive shreds from the network in time. Check your firewalls that you are not 
	+ _Memory_: Download more RAM. Solana doesn't like to run on swap so if you are regularly dipping into swap you need to fix that. One temporary solution can be to disable `spl-token-owner` / `spl-token-mint` indexes. They have grown really big.
	+ _Disk_: Check that your NVME for holding ledger and/or accounts isn't dead or dieing. A simple `dmesg` or SMART status query should be able to tell you.
* There's a bug that after heavy getBlocks call over RPC the node stays permanently behind, try a restart of the node and if that helps that may be your issue
* Have you tried unplugging it and plugging it in again? Sometimes it can help to clean your ledger and restart.
* Check your traffic patterns. Certain RPC traffic patterns can **easily** push your node behind. Maybe you need to add another node and split your RPC traffic or you need to ratelimit your calls to problematic queries like `getProgramAccounts`.	

	
Access to historical data
--------------------

By default, when you start the RPC node it will being building its local ledger from the blocks that it receives over the Solana network. This local ledger starts from the point of the accounts snapshot that you downloaded when your node was starting. If you don't add `--no-snapshot-fetch` to your `solana-validator` command line, the validator will often pull a snapshot from the network when it is starting. This will leave holes or gaps in your ledger between the point where you stopped your RPC node and the point at which it downloaded the accounts snapshot. To avoid this, always specify `--no-snapshot-fetch` after the first time you started the node. Remember that any time you pull a snapshot you will create a hole in the local ledger.

The size of the local ledger is determined by the parameter `--limit-ledger-size`, which is measured in shreds. A shred is a fixed data unit. The conversion betweens shreds and blocks is not fixed, as blocks can be varying size. Therefore it is very difficult to say how much history measured in time or in number of blocks that your node will store. You will have to tune it according to your needs. A good starting point can be 250-350 million shreds which should cover approximately an epoch, which should in turn mean approximately 3 days.

The exact amount of data the RPC node will store also depends on the parameters `--enable-cpi-and-log-storage` and `--enable-rpc-transaction-history`. These are necessary for the node to retain and serve full block and transaction data.

Your node can only provide data which it has stored in its local ledger. This means that your history will always begin from the point at which you started the node (actually: the snapshot slot for which you started the node). If the network is currently at slot N and you pulled a snapshot at slot M, then your node will start to rebuild it's history between slot M and slot N. This is what is happening during `catchup`, the node is processing (replaying) everything that happened between M and N until it catches up with the network and can process all the current incoming data.

The node can (in theory) store as much history as you can fit on high speed storage (e.g. if you /don't/ specify `--limit-ledger-size` or you give it a huge value). However, this doesn't scale back to genesis. To get all history, you can use the built in Google BigTable support. You can both set your node to upload data to a Google BigTable instance, where it can be permanently available for historical querying. You can also configure your node to support queries to a BigTable instance. In this case, for any queries which the node does not have in its local ledger, it will make a request to Google BigTable and if it finds it in Google BigTable it can pull the data from there.

Some RPC providers and the Solana Foundation have copies of BigTable that go back to genesis. For more information about this, see https://github.com/solana-labs/solana-bigtable . 

Indexes and performance
--------------------

There are three indexes that the Solana validator generates `program-id`, `spl-token-mint`, `spl-token-owner`. The last two are used to support queries either via `getTokensByOwner` or via `getTokensByDelegate`. They are also used to suport queries of `getProgramAccounts` which employ specific filters. These indexes have started to grow huge. If you do not need these queries to be fast for your RPC node, then you should remove them as you will reduce memory usage of your node considerably as well as improve start up times. 


Security concerns
--------------------

Security is a big field and you cannot rely on a small guide in a GitHub repo. Typically, at the very least you **should** make sure that your RPC server does not expose port 8899 and 8900 directly without any kind of proxy and access control in front of it. An easy way to do this is to use nginx or HAproxy as a reverse proxy. You can add SSL support and authentication in this way through the built in tools of each of these.

To be safe, you can ensure that your rpc-bind-address is set to `127.0.0.1` (the default for this role) so that it will only respond to requests locally.
	
	


	

Other playbooks
--------------------

Usually you will want to deploy a reverse proxy in front of the Solana RPC. HAproxy is a great option and we have a playbook for configuring HAproxy for a solana rpc server [here](https://github.com/rpcpool/solana-rpc-haproxy-ansible).


Other guides and docs
--------------------
These are some other guides, resources and docs written about Solana RPC:
	
 - [Solana RPC setup with Traefik](https://github.com/CryptoManufaktur-io/solana-rpc)
 - [Solana Accounts DB plugin docs](https://docs.solana.com/developing/plugins/accountsdb_plugin)
 - [Solana Accounts DB zoo - list of plugins](https://github.com/rpcpool/solana-accountsdb-zoo)
 - [Solana RPC providers](https://solana.com/rpc)
 - [Solana AWS validator](https://github.com/solanium-io/aws-solana-validator)
 - [Solana RPC gist](https://gist.github.com/buffalu/db6458d4f6a0b70ac303027b61a636af)
 - [Solana JSON-RPC caching server by Zubr](https://github.com/zubr-exchange/cacherpc)
 - [RPC Cache server by Monadical](https://github.com/Monadical-SAS/rpc-cache-server)
 - [Solana RPC proxy](https://github.com/Blue-Terra/solana-rpc-proxy)

We make no claims as to the accuracy or quality of any of these docs. Please review and make your own mind for what docs to follow!
	
License
-------

MIT

Author Information
------------------

This role was originally developed by [Triton One](https://triton.one). Patches, suggestions and improvements are always welcome.
