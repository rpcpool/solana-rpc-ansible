#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Remove empty snapshots
find "{{ solana_ledger_location }}" -name 'snapshot-*' -size 0 -print -exec rm {} \; || true

# Start solana rpc node, intended to be used with journalctl/systemctl. Logs will go to journalctl.
exec /home/solana/.local/share/solana/install/active_release/bin/solana-validator \
  --identity {{ solana_public_key }} \
{% if solana_gossip_host is defined and solana_gossip_host|length > 0 %}
  --gossip-host {{ solana_gossip_host }}
{% else %}
  {% for entrypoint in solana_entrypoints %}
  --entrypoint {{ entrypoint }} \
  {% endfor %}
{% endif %}
  --ledger {{ solana_ledger_location }} \
{% if solana_accounts_location is defined %}
  --accounts {{ solana_accounts_location }} \
{% endif %}
{% if solana_snapshots_location is defined %}
  --snapshots {{ solana_snapshots_location }} \
{% endif %}
{% if solana_snapshot_compression is defined %}
  --snapshot-compression {{ solana_snapshot_compression }} \
{% endif %}
  --log - \
  --gossip-port {{ solana_gossip_port }} \
  --rpc-port {{ solana_rpc_port }} \
  --rpc-bind-address {{ solana_rpc_bind_address }} \
  --dynamic-port-range {{ solana_dynamic_port_range }} \
  --wal-recovery-mode {{ solana_wal_recovery_mode }} \
  --limit-ledger-size {{ solana_limit_ledger_size }} \
  --private-rpc \
  --no-snapshot-fetch \
  --no-genesis-fetch \
  --no-port-check \
  --no-voting \
{% if solana_full_rpc_api %}
{%   if (solana_version == "stable" or (solana_version is version('1.9', '>=') and solana_version is version('1.9.6', '>=')) or (solana_version is version('1.9', '<') and solana_version is version('1.8.15', '>=')) %}
  --full-rpc-api \
{%  endif %}
{% endif %}
{% if solana_trusted_validators|length > 0 %}
  --no-untrusted-rpc \
  --halt-on-trusted-validators-accounts-hash-mismatch \
{% endif %}
{% if solana_rpc_history %}
  --enable-cpi-and-log-storage \
  --enable-rpc-transaction-history \
{% endif %}
  --account-index {{ solana_account_index }} \
  --expected-genesis-hash {{ solana_genesis_hash }} \
{% if solana_rpc_threads is defined and solana_rpc_threads > 0 %}
  --rpc-threads {{ solana_rpc_threads }} \
{% endif %}
{% if solana_bigtable_enabled is defined and solana_bigtable_enabled %}
  --enable-rpc-bigtable-ledger-storage \
{% endif %}
{% if solana_bigtable_upload_enabled is defined and solana_bigtable_upload_enabled %}
  --enable-bigtable-ledger-upload \
{% endif %}
{% if solana_rpc_faucet_address is defined and solana_rpc_faucet_address|length > 0 %}
  --rpc-faucet-address {{ solana_rpc_faucet_address }} \
{% endif %}
{% if solana_pubsub_max_connections is defined %}
  --rpc-pubsub-max-connections {{ solana_pubsub_max_connections }} \
{% endif %}
{% if solana_bpf_jit is defined and solana_bpf_jit %}
  --bpf-jit \
{% endif %}
{% if solana_accounts_db_caching is defined and solana_accounts_db_caching %}
  --no-accounts-db-caching \
{% endif %}
{% if solana_snapshot_interval_slots is defined %}
  --snapshot-interval-slots {{ solana_snapshot_interval_slots }} \
{% endif %}
{% if solana_expected_shred_version is defined and solana_expected_shred_version|length > 0 %}
  --expected-shred-version {{ solana_expected_shred_version }} \
{% endif %}
{% if solana_expected_bank_hash is defined and solana_expected_bank_hash|length > 0 %}
  --expected-bank-hash {{ solana_expected_bank_hash }} \
{% endif %}
{% if solana_wait_for_supermajority is defined and solana_wait_for_supermajority|length > 0 %}
  --wait-for-supermajority {{ solana_wait_for_supermajority }} \
{% endif %}
{% if solana_hard_fork is defined and solana_hard_fork|length > 0 %}
  --hard-fork {{ solana_hard_fork }} \
{% endif %}
{% if solana_accounts_shrink_path is defined and solana_accounts_shrink_path|length > 0%}
  --accounts-shrink-path {{ solana_accounts_shrink_path }} \
{% endif %}
{% for ac in solana_frozen_accounts %}
  --frozen-account {{ ac }} \
{% endfor %}
{% for key in solana_index_exclude_keys %}
  --account-index-exclude-key {{ key }} \
{% endfor %}
{% for voter in solana_authorized_voters %}
  --authorized-voter {{ voter }} \
{% endfor %}
{% for validator in solana_known_validators %}
  --known-validator {{ validator }} {% if not loop.last %}\
  {% endif %}
{% endfor %}

