import re
import sys

from loguru import logger

import settings


def remove_emojis_regex(text):
    emoji_pattern = re.compile(
        '['
        '\U0001f600-\U0001f64f'  # Emoticonos
        '\U0001f300-\U0001f5ff'  # Símbolos y pictogramas
        '\U0001f680-\U0001f6ff'  # Transporte y mapas
        '\U0001f700-\U0001f77f'  # Símbolos adicionales
        '\U0001f780-\U0001f7ff'
        '\U0001f800-\U0001f8ff'
        '\U0001f900-\U0001f9ff'
        '\U0001fa00-\U0001fa6f'
        '\U0001fa70-\U0001faff'
        '\U00002702-\U000027b0'  # Otros símbolos
        '\U000024c2-\U0001f251'
        r']+\s*',
        flags=re.UNICODE,
    )
    return emoji_pattern.sub(r'', text)


class CustomFilter:
    def __init__(self, sink_name: str):
        self.sink_name = sink_name

    def __call__(self, record):
        if self.sink_name == 'file':
            record['message'] = remove_emojis_regex(record['message'])
        return True


def lognamer(log_path: str):
    """Custom log file name function."""
    if m := re.search(r'.*\.\d{4}-\d{2}-\d{2}', log_path):
        return m.group(0) + '.log'
    return log_path


def build_logger(logfile: str = settings.LOGFILE, log_level: str = 'DEBUG'):
    logger.remove()
    logger.add(
        sys.stdout,
        format='<d>{time:HH:mm:ss.SSS}</d> <level>{level:8}</level> {message}',
        colorize=True,
        level=log_level,
        filter=CustomFilter('stdout'),
    )
    logger.add(
        logfile,
        format='{time:YYYY-MM-DD HH:mm:ss} {level:8} [{file}:{line}] {message}',
        level=log_level,
        rotation='00:00',
        retention='1 week',
        filter=CustomFilter('file'),
    )
