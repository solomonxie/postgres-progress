# common_conf

Config files and systemd units shared across all three nodes: etcd,
Patroni, pgbouncer, and the placeholder postgresql.conf / pg_hba.conf
used before Patroni takes over. Copied into place by the `setup_*.sh`
scripts one level up in `../`. See `../../README.md` for the setup
order.
