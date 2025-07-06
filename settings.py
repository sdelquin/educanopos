from pathlib import Path

import telegramtk
from prettyconf import config

PROJECT_DIR = Path(__file__).parent
PROJECT_NAME = PROJECT_DIR.name

DB_PATH = config('DB_PATH', default=PROJECT_DIR / (PROJECT_NAME + '.db'), cast=Path)
LOGFILE = config(
    'LOGFILE',
    default=PROJECT_DIR / 'logs' / (PROJECT_NAME + '_{time:YYYY-MM-DD}.log'),
    cast=Path,
)

API_PUBLICATIONS_URL = config(
    'API_PUBLICATIONS_URL',
    default='https://www.gobiernodecanarias.org/educacion/6/dgper/opoperdocprimweb/Scripts/publicaciones/apipublicaciones.asp?codtribunal={board_code}&op={process_code}&tipo=publicaciones&tipotribunal={board_kind}&especialidad={speciality_code}',
)
API_RESULTS_URL = config(
    'API_RESULTS_URL',
    default='https://www.gobiernodecanarias.org/educacion/6/dgper/opoperdocprimweb/Scripts/publicaciones/apipublicaciones.asp?codtribunal={board_code}&op={process_code}&tipo=resultado&idpublicacion={publication_code}&tipotribunal={board_kind}&especialidad={speciality_code}&cuerpo={corp_code}&idTipoPubPadre=0',
)
API_SCREEN_URL = config(
    'API_SCREEN_URL',
    default='https://educanopos.matraka.es/screen/{publication_pk}/',
)
REQ_SLEEP = config('REQ_SLEEP', default=0.5, cast=float)

TELEGRAM_BOT_TOKEN = config('TELEGRAM_BOT_TOKEN')
TELEGRAM_CHAT_ID = config('TELEGRAM_CHAT_ID')
telegramtk.init(TELEGRAM_BOT_TOKEN)

USER_AGENT = config(
    'USER_AGENT', default='Mozilla/5.0 (X11; Linux x86_64; rv:127.0) Gecko/20100101 Firefox/127.0'
)

TEMPLATES_DIR = config('TEMPLATES_DIR', default=PROJECT_DIR / 'templates', cast=Path)
STATIC_DIR = config('STATIC_DIR', default=PROJECT_DIR / 'static', cast=Path)

HERO_EMOJI_NEW = config('HERO_EMOJI_NEW', default='💫')
HERO_EMOJI_UPDATE = config('HERO_EMOJI_UPDATE', default='🔄')
NONE_REPR = config('NONE_REPR', default='-')

DROP_ROW_FIELD = config('DROP_ROW_FIELD', default='eliminacionpub_hide')
RESULTS_PATH = config('RESULTS_PATH', default=PROJECT_DIR / 'results', cast=Path)
if not RESULTS_PATH.exists():
    RESULTS_PATH.mkdir(parents=True, exist_ok=True)
