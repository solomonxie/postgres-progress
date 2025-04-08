# manual

The original, hand-run version of this cluster: config files and
setup/test scripts together, in one folder, the way they were used
while first building it. Everything here is meant to be read and
copy-pasted step by step, not executed as-is.

- `setup_*.sh`, `test_*.sh`: install and test steps, one script per
  component, typed by hand while first working through building the
  cluster. Run a command, see what happened, note it down, move to
  the next one, that's why they read as annotated command history
  rather than clean scripts, and why they say not to execute them
  directly.
- `common_conf/`: config files and systemd units shared across all
  three nodes: etcd, Patroni, pgbouncer, and the placeholder
  postgresql.conf / pg_hba.conf used before Patroni takes over.
- `node1_conf/`, `node2_conf/`, `node3_conf/`: per-node config, etcd
  and Patroni identity for each node, plus HAProxy and pgAdmin setup
  for node3.
- `render_template.py`: small helper to render a Jinja2 template
  (e.g. a roles file) against a `.env` file of variables.

## Why this is kept around

Reading these is the fastest way to understand what each step
actually does and why, they're closer to a lab notebook than an
installer. But this isn't how the cluster gets built anymore:

- The infrastructure they assume (three nodes, a data disk, the
  networking between them) is now `../terraform/`.
- The install/configure steps themselves are now `../ansible/`, which
  targets these same `common_conf/` and `node*_conf/` files, just run
  automatically instead of by hand.

Start with `../README.md` for the setup order and the design diagram;
come back here for the detail behind any individual step, or to
follow along by hand instead of running `../ansible/`.
