from __future__ import annotations

from pathlib import Path
from typing import Generator

import peewee
import requests
import yaml
from loguru import logger
from slugify import slugify
from telegramtk.utils import escape_markdown as em

import settings
from lib import templates

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
        return settings.API_PUBLICATIONS_URL.format(
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

    @staticmethod
    def get_kind_code(board_name: str) -> str:
        norm_name = board_name.upper()
        if 'SISTEMA ACCESO' in norm_name:
            return 'A'
        if 'SISTEMA INGRESO' in norm_name:
            if 'ÚNICO' in norm_name:
                return 'L'
        return 'J'


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
    def api_url(self) -> str:
        return settings.API_RESULTS_URL.format(
            publication_code=self.code,
            board_code=self.board.code,
            process_code=self.board.speciality.corp.process.code,
            board_kind=self.board.kind,
            speciality_code=self.board.speciality.code,
            corp_code=self.board.speciality.corp.code,
            publication_kind=Publication.get_kind_code(self.name),
        )

    @property
    def api_screen_url(self) -> str:
        return settings.API_SCREEN_URL.format(publication_pk=self.id)

    def render_as_markdown(self, update: bool = False) -> str:
        return templates.render_template(
            'publication.md',
            process=em(str(self.board.speciality.corp.process)),
            corp=em(str(self.board.speciality.corp)),
            board=em(self.board.name),
            speciality=em(str(self.board.speciality)),
            publication_name=em(self.name),
            publication_date=em(self.date),
            marks_url=self.board.speciality.corp.process.marks_url,
            api_screen_url=self.api_screen_url,
            update=update,
            hero_emoji=settings.HERO_EMOJI_UPDATE if update else settings.HERO_EMOJI_NEW,
        )

    def render_as_html(self) -> str:
        results = self.fetch_results()
        return templates.render_template(
            'results.html',
            process=self.board.speciality.corp.process,
            corp=self.board.speciality.corp,
            board=self.board,
            publication=self,
            fields=results['fields'],
            data=results['data'],
            board_publications=self.board.get_publications(),
        )

    @property
    def as_name_date(self) -> str:
        """Return a string with the publication name and date."""
        return f'{self.name} ({self.date})'

    @property
    def slug(self) -> str:
        return slugify(self.name)

    @property
    def results_path(self) -> Path:
        """Return the path where results are stored."""
        return settings.DATA_PATH / f'{self.slug}/pub_{self.id}.csv'

    def fetch_results(self) -> dict:
        """Get (fetch) all results for this publication on API."""
        results = requests.get(self.api_url, headers={'User-Agent': settings.USER_AGENT}).json()
        return results

    def export_results(self, add_context: bool = True) -> None:
        results = self.fetch_results()
        if add_context:
            context = {
                'Proceso': self.board.speciality.corp.process,
                'Cuerpo': self.board.speciality.corp,
                'Especialidad': self.board.speciality,
                'Tribunal': self.board.name,
                'Publicación': self.name,
                'Fecha de publicación': self.date,
            }
            results['fields'] = list(context.keys()) + results['fields']
            for row in results['data']:
                row |= context
        render = templates.render_template(
            'results.csv',
            fields=results['fields'],
            data=results['data'],
        )
        if not self.results_path.parent.exists():
            self.results_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.results_path, 'w') as file:
            file.write(render)

    @staticmethod
    def get_kind_code(publication_name: str) -> str:
        norm_name = publication_name.upper()
        if 'DETALLE DE BAREMO' in norm_name:
            if 'PROVISIONAL' in norm_name:
                return '4'
            if 'DEFINITIVA' in norm_name:
                return '8'
        return '0'


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
                            kind=Board.get_kind_code(board_data['name']),
                            speciality=speciality,
                        )
