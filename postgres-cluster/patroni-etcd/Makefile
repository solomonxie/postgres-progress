# Convenience targets for the Patroni + etcd cluster.
#
# The scripts under manual/ are runbooks, not idempotent
# installers (see the "DON'T EXECUTE THIS SCRIPT DIRECTLY" header in
# each one): they're meant to be read and run command by command on
# the target node. This Makefile automates the parts that are safe to
# automate (Terraform, and copying this folder to each node) and
# otherwise opens each step in order so you can follow along.
#
# Usage:
#   make help
#   make terraform-apply KEY_PAIR_NAME=my-key
#   make sync-all SSH_USER=ec2-user
#   make step-etcd NODE=node1
#   make test-ha NODE=node1

SSH_USER      ?= ec2-user
NODE1_HOST    ?= node1.pg.internal
NODE2_HOST    ?= node2.pg.internal
NODE3_HOST    ?= node3.pg.internal
REMOTE_DIR    ?= ~/patroni_etcd
KEY_PAIR_NAME ?= your-key
NODE          ?= node1
PAGER         ?= less

node_host = $($(shell echo $(NODE) | tr a-z A-Z)_HOST)

.PHONY: help \
	terraform-init terraform-plan terraform-apply terraform-destroy terraform-output \
	sync-node1 sync-node2 sync-node3 sync-all ssh \
	step-ec2 step-etcd step-pg step-patroni step-pgbouncer step-haproxy step-pgadmin \
	test-etcd test-ha

help:
	@echo "Patroni + etcd cluster targets"
	@echo ""
	@echo "Infrastructure (real, runs Terraform in terraform/):"
	@echo "  terraform-init      terraform init"
	@echo "  terraform-plan      terraform plan -var key_pair_name=\$$(KEY_PAIR_NAME)"
	@echo "  terraform-apply     terraform apply -var key_pair_name=\$$(KEY_PAIR_NAME)"
	@echo "  terraform-output    print node private/public IPs"
	@echo "  terraform-destroy   tear the infrastructure down"
	@echo ""
	@echo "Sync this folder to a node over scp (needed before running any step-* target):"
	@echo "  sync-node1 / sync-node2 / sync-node3 / sync-all"
	@echo "  ssh NODE=node1           ssh into a node's \$$(REMOTE_DIR)"
	@echo ""
	@echo "Setup steps, in order (opens the script; run node-side over ssh):"
	@echo "  step-ec2 NODE=node1      base OS + venv + data disk   (all nodes)"
	@echo "  step-etcd NODE=node1     install and join etcd        (all nodes)"
	@echo "  step-pg NODE=node1       install PostgreSQL 17        (node1, node2)"
	@echo "  step-patroni NODE=node1  install and join Patroni     (node1, node2)"
	@echo "  step-pgbouncer NODE=node1  install pgbouncer          (node1, node2)"
	@echo "  step-haproxy NODE=node3  install HAProxy              (node3)"
	@echo "  step-pgadmin NODE=node3  install pgAdmin              (node3)"
	@echo ""
	@echo "Testing:"
	@echo "  test-etcd NODE=node1     open the etcd connectivity walkthrough"
	@echo "  test-ha NODE=node1       open the failure-scenario walkthrough"
	@echo ""
	@echo "Override SSH_USER, NODE1_HOST/NODE2_HOST/NODE3_HOST, REMOTE_DIR, KEY_PAIR_NAME as needed."

# ---- Terraform ----

terraform-init:
	cd terraform && terraform init

terraform-plan:
	cd terraform && terraform plan -var="key_pair_name=$(KEY_PAIR_NAME)"

terraform-apply:
	cd terraform && terraform apply -var="key_pair_name=$(KEY_PAIR_NAME)"

terraform-output:
	cd terraform && terraform output

terraform-destroy:
	cd terraform && terraform destroy -var="key_pair_name=$(KEY_PAIR_NAME)"

# ---- Sync this folder to a node ----

sync-node1:
	ssh $(SSH_USER)@$(NODE1_HOST) 'mkdir -p $(REMOTE_DIR)'
	scp -r manual $(SSH_USER)@$(NODE1_HOST):$(REMOTE_DIR)/

sync-node2:
	ssh $(SSH_USER)@$(NODE2_HOST) 'mkdir -p $(REMOTE_DIR)'
	scp -r manual $(SSH_USER)@$(NODE2_HOST):$(REMOTE_DIR)/

sync-node3:
	ssh $(SSH_USER)@$(NODE3_HOST) 'mkdir -p $(REMOTE_DIR)'
	scp -r manual $(SSH_USER)@$(NODE3_HOST):$(REMOTE_DIR)/

sync-all: sync-node1 sync-node2 sync-node3

ssh:
	ssh -t $(SSH_USER)@$(node_host) 'cd $(REMOTE_DIR) && exec $$SHELL -l'

# ---- Setup steps: open the runbook for that node to follow along ----

step-ec2:
	ssh -t $(SSH_USER)@$(node_host) 'cd $(REMOTE_DIR)/manual && $(PAGER) setup_ec2.sh'

step-etcd:
	ssh -t $(SSH_USER)@$(node_host) 'cd $(REMOTE_DIR)/manual && $(PAGER) setup_etcd.sh'

step-pg:
	ssh -t $(SSH_USER)@$(node_host) 'cd $(REMOTE_DIR)/manual && $(PAGER) setup_pg.sh'

step-patroni:
	ssh -t $(SSH_USER)@$(node_host) 'cd $(REMOTE_DIR)/manual && $(PAGER) setup_patroni.sh'

step-pgbouncer:
	ssh -t $(SSH_USER)@$(node_host) 'cd $(REMOTE_DIR)/manual && $(PAGER) setup_pgbouncer.sh'

step-haproxy:
	ssh -t $(SSH_USER)@$(node_host) 'cd $(REMOTE_DIR)/manual && $(PAGER) setup_haproxy.sh'

step-pgadmin:
	ssh -t $(SSH_USER)@$(node_host) 'cd $(REMOTE_DIR)/manual/node3_conf && $(PAGER) setup_pgadmin.sh'

# ---- Testing ----

test-etcd:
	ssh -t $(SSH_USER)@$(node_host) 'cd $(REMOTE_DIR)/manual && $(PAGER) test_etcd.sh'

test-ha:
	ssh -t $(SSH_USER)@$(node_host) 'cd $(REMOTE_DIR)/manual && $(PAGER) test_ha.sh'
