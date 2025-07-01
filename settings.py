from pathlib import Path

import telegramtk
from prettyconf import config

PROJECT_DIR = Path(__file__).parent
PROJECT_NAME = PROJECT_DIR.name

DB_PATH = config('DB_PATH', default=PROJECT_DIR / (PROJECT_NAME + '.db'), cast=Path)
LOGFILE = config('LOGFILE', default=PROJECT_DIR / (PROJECT_NAME + '.log'), cast=Path)

API_PUBLICATIONS_URL = config(
    'API_PUBLICATIONS_URL',
    default='https://www.gobiernodecanarias.org/educacion/6/dgper/opoperdocprimweb/Scripts/publicaciones/apipublicaciones.asp?codtribunal={board_code}&op={process_code}&tipo=publicaciones&tipotribunal={board_kind}&especialidad={speciality_code}',
)
API_RESULTS_URL = config(
    'API_RESULTS_URL',
    default='https://www.gobiernodecanarias.org/educacion/6/dgper/opoperdocprimweb/Scripts/publicaciones/apipublicaciones.asp?codtribunal={board_code}&op={process_code}&tipo=resultado&idpublicacion={publication_code}&tipotribunal={board_kind}&especialidad={speciality_code}&idTipoPubPadre=0',
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
