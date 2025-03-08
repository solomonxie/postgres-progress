# ==== DON'T EXECUTE THIS SCRIPT DIRECTLY ====

#######################################################################
#            pg_activity (like htop, install on each node)            #
#######################################################################
sudo apt install pg-activity -y
which pg_activity
# >> /usr/bin/pg_activity

# Test activity:
export PGPASSWORD=changeme
pg_activity -h localhost -p 5432 -U postgres
pg_activity -h node1.pg.internal -p 5432 -U postgres
pg_activity -h node2.pg.internal -p 5432 -U postgres



#######################################################################
#           Log exporter for Grafana(install on each node)            #
#######################################################################

# TBD
# ...
