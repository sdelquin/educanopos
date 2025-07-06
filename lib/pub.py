import time
from json import JSONDecodeError

import telegramtk
from loguru import logger
from peewee import fn

import settings

from .db import Process, Publication


def check(save: bool = True, notify: bool = True) -> None:
    for process in Process.select().where(Process.active):
        for corp in process.corps:
            for speciality in corp.specialities:
                for board in speciality.boards:
                    logger.info(f'Checking board: {board}')
                    for publication_data in board.fetch_publications():
                        try:
                            publication = Publication.get(
                                (Publication.board == board)
                                & (Publication.code == publication_data['code'])
                            )
                            if publication.date != publication_data['fechamodificado']:
                                publication.date = publication_data['fechamodificado']
                                logger.debug(f'🔄 Updated publication found: {publication}')
                                logger.debug('💾 Saving updated publication to database')
                                publication.save()
                                try:
                                    if notify:
                                        logger.debug(
                                            '📤 Notifying updated publication via Telegram'
                                        )
                                        telegramtk.send_message(
                                            settings.TELEGRAM_CHAT_ID,
                                            publication.render_as_markdown(update=True),
                                        )
                                except telegramtk.TelegramError as err:
                                    logger.error(f'Error sending Telegram message: {err}')
                                    logger.debug('🗑️ Deleting publication from database')
                                    publication.delete_instance()
                                    continue
                        except Publication.DoesNotExist:
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
                                        settings.TELEGRAM_CHAT_ID, publication.render_as_markdown()
                                    )
                            except telegramtk.TelegramError as err:
                                logger.error(f'Error sending Telegram message: {err}')
                                logger.debug('🗑️ Deleting publication from database')
                                publication.delete_instance()
                                continue
                        if not save:
                            logger.debug('🗑️ Deleting publication from database')
                            publication.delete_instance()
                    time.sleep(settings.REQ_SLEEP)


def export(publication_name: str) -> None:
    for publication in Publication.select().where(
        fn.UPPER(Publication.name) == publication_name.upper()
    ):
        logger.info(f'Exporting results for: {publication}')
        try:
            publication.export_results()
        except JSONDecodeError:
            logger.error('Error decoding JSON for this publication')
            continue
        logger.success(f'Results exported to: {publication.results_path}')
