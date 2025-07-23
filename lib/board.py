from loguru import logger

import settings
from lib import templates
from lib.db import Process


def export(ignore_board: str) -> None:
    """Export all boards to CSV, ignoring specified board."""
    data = []
    for process in Process.select().where(Process.active):
        for corp in process.corps:
            for speciality in corp.specialities:
                for board in speciality.boards:
                    logger.info(f'Handling board: {board}')
                    if ignore_board in board.name:
                        logger.debug(f'Ignoring board: {board.name}')
                        continue
                    data.append(board.as_dict)
                    logger.info(f'Data included for board: {board}')
    export_path = settings.DATA_PATH / 'boards.csv'
    fields = list(data[0].keys()) if data else []
    render = templates.render_template('boards.csv', fields=fields, data=data)
    if not export_path.parent.exists():
        export_path.parent.mkdir(parents=True, exist_ok=True)
    with open(export_path, 'w') as file:
        file.write(render)
    logger.success(f'Boards data exported to: {export_path}')
