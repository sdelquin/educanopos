run:
    uv run python main.py -v check-pub

reset-db file:
    uv run python main.py -v create-db -f
    uv run python main.py -v load-data {{file}}

db:
    open educanopos.db

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
