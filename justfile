# Check for new publications and save/notify if proceed
run:
    uv run python main.py -v check-pub --notify --save

# Launch screen server (to display publications)
screen:
    uv run python main.py -v screen --debug

# Reset database and load data from file
reset-db file:
    uv run python main.py -v create-db -f
    uv run python main.py -v load-data {{file}}

# Open database in browser
db:
    open educanopos.db

# Open database in terminal
dbsh:
    sqlite3 educanopos.db

# Sync uv
[macos]
sync:
    uv sync --no-group prod

# Sync uv
[linux]
sync:
    uv sync --no-dev --group prod

# Deploy
deploy:
    #!/usr/bin/env bash
    git pull
    just sync
    supervisorctl restart educanopos

# Clean logfiles
clean-logs:
    find . -type f -name '*.log*' -exec rm {} \;

# Open iPython shell
@sh:
    uv run ipython

# Clean all saved results for publications
clean-results:
    find results -type f -name '*.csv' -exec rm {} \;
