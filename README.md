Solana RPC role
=========

An Ansible role to deploy a Solana RPC node. This configures the validator software in RPC mode running under the user `solana`. The RPC service is installed as a user service running under this same user. 

Hardware Requirements
------------

Typically an RPC server requires _at least_ the same specs as a Solana validator, but typically has higher requirements. In particular, we recommend using 256 GB of RAM in order to store indexes.

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

There are a large number of configurable parameters for solana. Many of these have workable defaults, and you should be able to have a decent experience with the default values. If you run this role without specifying any parameters, it'll configure a standard `mainnet` RPC node. 

### Basic variables

These are the basic variables that configure the setup of the validators. They have default values but you probably want to customise them based on your setup.

| Name                 | Default value        | Description                |
|----------------------|----------------------|----------------------------|
| `solana_version` | stable | The solana version to install. |
| `solana_root`        | /solana              | Main directory for solana ledger and accounts |
| `solana_ledger_location` | /solana/ledger | Storage for solana ledger (should be on NVME) |
| `solana_accounts_location` | /solana/ledger/accounts | Storage for solana accounts information. In case you use tmpfs for accounts this should be a subdirectory of your tmpfs mount point (e.g. `/solana/tmpfs/accounts` in case tmpfs is mounted on `/solana/tmpfs` |
| `solana_keypairs` | `[]` | List of keypairs to copy to the validator node. Each entry in the list should have a `key` and `name` entry. This will create `/home/solana/<name>.json` containing the value of `key`. |
| `solana_generate_keypair` | true | Whether or not to generate a keypair. If you haven't specified `solana_keypairs` and you set this to true, a new key will be generated and placed in /home/solana/identity.json |
| `solana_public_key` | `/home/solana/identity.json` | Location of the identity of the validator node. |
| `solana_network` | mainnet | The solana network that this node is supposed to be part of |
| `solana_environment` | see defaults/main.yml | Environment variables to specify for the validator node, most importantly `RUST_LOG` |
| `solana_enabled_services` | `[ solana-rpc ]`  | List of services to start automatically on boot |
| `solana_disabled_services` | `[ ]` | List of services to set as disabled |
| `solana_gossip_port` | 8001 | Port for gossip traffic (needs to be open publicly in firewall) |
| `solana_rpc_port` | 8899 | Port for incoming RPC. This is typically only open on localhost. Place a proxy like `haproxy` in front of this port. |
| `solana_dynamic_port_range` | 8002-8012 | Port for incoming solana traffic. Needs to be open publicly in firewall. |

### Network specific variables

Default values for these variables are specified in `vars/{{ solana_network }}-default.yml` (e.g. `vars/mainnet-default.yml`). You can also specify your own by providing the file `{{ solana_network }}.yml`. You will need to specify all these variables unless you rely on the defaults.

| Name                 | Default value        | Description                |
|----------------------|----------------------|----------------------------|
| `solana_network` | mainnet | The solana network this node should join     |
| `solana_metrics_config` | see vars/mainnet-default.yml | The metrics endpoint |
| `solana_genesis_hash` | see vars/mainnet-default.yml | The genesis hash for this network |
| `solana_entrypoints` | see vars/mainnet-default.yml | Entrypoint hosts |
| `solana_trusted_validators` | see vars/mainnet-default.yml | Trusted validators from where to fetch snapshots and genesis bin on start up |
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
| `solana_pubsub_max_connections` | 1000 | maximum number of pubsub connections to allow. |
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
| `solana_bigtable_project_id` | | Bigtable project id |
| `solana_bigtable_private_key_id` | | Bigtable private key id |
| `solana_bigtable_private_key` | | Bigtable private key |
| `solana_bigtable_client_email` | | Bigtable client email |
| `solana_bigtable_client_id` | | Bigtable client id |
| `solana_bigtable_client_x509_cert_url` | | Bigtable cert url  |


## Handling forks

Occasionally devnet/testnet will experience forks. In these cases use the following parameters as instructed in Discord:

| Name                 | Default value        | Description                |
|----------------------|----------------------|----------------------------|
| `solana_hard_fork` |  | Hard fork |
| `solana_wait_for_supermajority` |  | Whether node should wait for supermajority or not |

## CPU governor & Sysctl settings

Typically you can deploy `solana-sys-tuner` together with this config to tune some variables. If you are new to tuning performance we also recommend looking at `tuned` from RedHat, where the `throughput-performance` profile is suitable. You can also specify a list of sysctl values for this playbook to add automatically. Here is a list of sysctl values that have been used:

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

Another important element is the CPU governor. There are three options:
	
	1. You have access to BIOS and you set the BIOS cpu setting to `max performance`. This seems to work well for HPE systems. In this case, specify the variable `cpu_governor: bios`. This is sometimes required for AMD EPYC systems too.
	2. You have acccess to BIOS and you set the BIOS cpu setting to `os control`. This should be the common default. In this case you can leave the `cpu_governor` variable as default or set it to `cpu_governor: perforamnce`.
	3. You don't have access to BIOS or CPU governor settings. If possible, try to set `cpu_governor: performance`. Otherwise, hopefully your provider has configured it for good performance!


Example Playbooks
-----------------

Mainnet node:

```
    - hosts: rpc_nodes
      roles:
         - { role: rpcpool.solana-rpc, solana_network: mainnet }
```

Testnet node:

```
    - hosts: rpc_nodes
      roles:
         - { role: rpcpool.solana-rpc, solana_network: testnet }
```

Devnet node:

```
    - hosts: rpc_nodes
      roles:
         - { role: rpcpool.solana-rpc, solana_network: devnetnet }
```



Running the RPC node
--------------------

After the deploy you can login to the machine and run `su -l solana` to become the solana user. 

To see the Solana validator command line generated for you during the deploy you can take a look at `/home/solana/bin/solana-rpc.sh`. Remember that any changes to this file will be overwritten next time you run this Ansible.

For the first start up, you should comment out `--no-snapshot-fetch` in the file `/home/solana/bin/solana-rpc.sh`. This will allow solana to download the basic files it requires. Remember to activate this line again before you run the validator the first time.

Then start up the solana RPC process by running `systemctl --user start solana-rpc`. You can see status of the process by running `systemctl --user status solana-rpc`. The first start up will take some time. You can monitor start up by running `solana catchup`.

Finally, to see logs for your Solana RPC node run `journalctl --user -u solana-rpc -f`.

If this is your first time running a Solana node, you can find more details on [https://github.com/agjell/sol-tutorials/](https://github.com/agjell/sol-tutorials/) about how to operate the node.


License
-------

MIT

Author Information
------------------

This role was originally developed by [rpcpool](https://rpcpool.com). Patches, suggestions and improvements are always welcome.
