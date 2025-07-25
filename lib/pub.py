import time
from json import JSONDecodeError

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


def export(publication_name: str, ignore_board: str) -> None:
    notfound_publications = []
    for process in Process.select().where(Process.active):
        for corp in process.corps:
            for speciality in corp.specialities:
                for board in speciality.boards:
                    logger.info(f'Checking board: {board}')
                    if ignore_board and ignore_board in board.name:
                        logger.debug(f'Ignoring board: {board.name}')
                        continue
                    try:
                        publication = Publication.get(
                            (Publication.board == board) & (Publication.name == publication_name)
                        )
                    except Publication.DoesNotExist:
                        msg = f'Publication "{publication_name}" not found in board: {board}'
                        logger.warning(msg)
                        notfound_publications.append(msg)
                        continue
                    logger.info(f'Exporting results for: {publication}')
                    try:
                        publication.export_results()
                    except JSONDecodeError:
                        logger.error('Error decoding JSON for this publication')
                        continue
                    logger.success(f'Results exported to: {publication.results_path}')

    if notfound_publications:
        logger.warning('Some publications were not found ↓')
        for msg in notfound_publications:
            logger.warning(msg)
