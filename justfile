# Check for new publications and save/notify if proceed
run:
    uv run python main.py -v check-pub --notify --save

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
deploy: && sync
    git pull
