from typing import Generator

import peewee
import requests
import yaml
from loguru import logger
from telegramtk.utils import escape_markdown

import settings

db = peewee.SqliteDatabase(settings.DB_PATH)


class BaseModel(peewee.Model):
    class Meta:
        database = db


class Process(BaseModel):
    """Oposición"""

    code = peewee.SmallIntegerField(primary_key=True)
    name = peewee.CharField(max_length=255, unique=True)
    marks_url = peewee.CharField(max_length=255)
    active = peewee.BooleanField(default=True)

    def __str__(self):
        return self.name


class Corp(BaseModel):
    """Cuerpo"""

    code = peewee.SmallIntegerField(primary_key=True)
    name = peewee.CharField(max_length=255, unique=True)
    process = peewee.ForeignKeyField(Process, backref='corps')

    def __str__(self):
        return self.name


class Speciality(BaseModel):
    """Especialidad"""

    code = peewee.SmallIntegerField(primary_key=True)
    name = peewee.CharField(max_length=255)
    corp = peewee.ForeignKeyField(Corp, backref='specialities')

    def __str__(self):
        return self.name


class Board(BaseModel):
    """Tribunal"""

    code = peewee.SmallIntegerField()
    name = peewee.CharField(max_length=255)
    kind = peewee.CharField(max_length=8)  # L: Tribunal Único / J: Tribunal Conjunto
    speciality = peewee.ForeignKeyField(Speciality, backref='boards')

    # https://docs.peewee-orm.com/en/latest/peewee/models.html#composite-primary-keys
    # class Meta:
    #     primary_key = peewee.CompositeKey('code', 'speciality')

    def __str__(self):
        return f'{self.speciality} @ {self.name}'

    @property
    def api_url(self) -> str:
        return settings.API_URL.format(
            board_code=self.code,
            process_code=self.speciality.corp.process.code,
            board_kind=self.kind,
            speciality_code=self.speciality.code,
        )

    def get_publications(self) -> peewee.SelectQuery:
        """Get all publications for this board on database."""
        return Publication.select().where(Publication.board == self)

    def fetch_publications(self) -> Generator:
        """Get (fetch) all publications for this board on API."""
        yield from requests.get(self.api_url, headers={'User-Agent': settings.USER_AGENT}).json()


class Publication(BaseModel):
    """Publicación"""

    code = peewee.SmallIntegerField()
    name = peewee.CharField(max_length=255)
    description = peewee.CharField(max_length=1024, null=True)
    date = peewee.CharField(max_length=255)
    board = peewee.ForeignKeyField(Board, backref='publications')

    def __str__(self):
        return f'{self.board} → {self.name}'

    @property
    def as_markdown(self) -> str:
        """Return publication as Markdown formatted string."""
        return rf"""
ℹ️ Nueva publicación de procedimiento selectivo \#Personal

{escape_markdown(str(self.board.speciality.corp.process))} \| {escape_markdown(str(self.board.speciality.corp))}

*{escape_markdown(str(self.board))}*
_{escape_markdown(self.name)} \({escape_markdown(self.date)}\)_
[Consultar publicación]({self.board.speciality.corp.process.marks_url})
"""


def create_tables() -> None:
    """Create all tables in the database."""
    logger.info('Creating database tables')
    with db:
        db.create_tables([Process, Corp, Speciality, Board, Publication])


def drop_tables() -> None:
    """Drop all tables in the database."""
    logger.info('Dropping database tables')
    with db:
        db.drop_tables([Process, Corp, Speciality, Board, Publication])


def load_data(data_file: str) -> None:
    """Load initial data into the database."""
    logger.info(f'Loading data from {data_file}')
    with open(data_file) as file:
        data = yaml.safe_load(file)
        for process_data in data['processes']:
            logger.debug(f'Loading process: {process_data["name"]}')
            process = Process.create(
                code=process_data['code'],
                name=process_data['name'],
                marks_url=process_data['marks_url'],
            )
            for corp_data in process_data['corps']:
                logger.debug(f'Loading corp: {corp_data["name"]}')
                corp = Corp.create(
                    code=corp_data['code'],
                    name=corp_data['name'],
                    process=process,
                )
                for speciality_data in corp_data['specialities']:
                    logger.debug(f'Loading speciality: {speciality_data["name"]}')
                    speciality = Speciality.create(
                        code=speciality_data['code'],
                        name=speciality_data['name'],
                        corp=corp,
                    )
                    for board_data in speciality_data['boards']:
                        logger.debug(f'Loading board: {board_data["name"]}')
                        Board.create(
                            code=board_data['code'],
                            name=board_data['name'],
                            kind='L' if 'ÚNICO' in board_data['name'].upper() else 'J',
                            speciality=speciality,
                        )
