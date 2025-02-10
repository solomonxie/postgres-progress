# ==== DON'T EXECUTE THIS SCRIPT DIRECTLY, IT'S A WALKTHROUGH ====

#######################################################################
#                                DUMP                                 #
#######################################################################

# Dump the whole database from RDS.
# `-F d` dumps as a directory (allows parallel dump/restore).
# `-j N` runs N parallel jobs, scale to the number of CPUs available.
# Includes: table def+data, index def+data, sequences, constraints, functions.
time pg_dump -v -h my-source-db.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com -p 5432 -U postgres -d app_db \
    --no-owner --no-privileges -F d -j 8 -f app_db_dump_$(date +%Y%m%d)/ 2>&1 | tee -a /tmp/dump.log


#######################################################################
#                               RESTORE                               #
#######################################################################

export PGPASSWORD=changeme

# dropdb -U postgres app_db
# createdb -U postgres app_db

# Restore into the new self-hosted cluster (through pgbouncer, port 6432):
time pg_restore -v -h localhost -p 6432 -U postgres -d app_db \
    --clean --if-exists -F d app_db_dump_20250101/ 2>&1 | tee -a /tmp/restore.log


#######################################################################
#                           VERIFY                                    #
#######################################################################

# Compare row counts between source and target for a sanity check:
psql -h my-source-db.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com -p 5432 -U postgres -d app_db \
    -c "SELECT count(1) FROM some_table;"

psql -h localhost -p 6432 -U postgres -d app_db \
    -c "SELECT count(1) FROM some_table;"
