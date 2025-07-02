import time

import telegramtk
from loguru import logger

import settings

from .db import Process, Publication


def check(save: bool = True, notify: bool = True) -> None:
    for process in Process.select().where(Process.active):
        for corp in process.corps:
            for speciality in corp.specialities:
                for board in speciality.boards:
                    logger.info(f'Checking board: {board}')
                    for publication_data in board.fetch_publications():
                        if (
                            not Publication.select()
                            .where(
                                Publication.board == board,
                                Publication.code == publication_data['code'],
                            )
                            .exists()
                        ):
                            publication = Publication(
                                code=publication_data['code'],
                                name=publication_data['description'],
                                description=publication_data['longdescription'],
                                date=publication_data['fechamodificado'],
                                board=board,
                            )
                            logger.debug(f'✨ New publication found: {publication}')
                            logger.debug('💾 Saving publication to database')
                            publication.save()
                            try:
                                if notify:
                                    logger.debug('📤 Notifying publication via Telegram')
                                    telegramtk.send_message(
                                        settings.TELEGRAM_CHAT_ID, publication.as_markdown
                                    )
                            except telegramtk.TelegramError as err:
                                logger.error(f'Error sending Telegram message: {err}')
                                logger.debug('🗑️ Deleting publication from database')
                                publication.delete_instance()
                            else:
                                if not save:
                                    logger.debug('🗑️ Deleting publication from database')
                                    publication.delete_instance()
                    time.sleep(settings.REQ_SLEEP)
