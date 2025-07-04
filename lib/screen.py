from flask import Flask

import settings

from .db import Publication

app = Flask(__name__, static_folder=settings.STATIC_DIR, template_folder=settings.TEMPLATES_DIR)


@app.route('/screen/<int:publication_pk>/')
def display(publication_pk: int) -> str:
    publication = Publication.get(Publication.id == publication_pk)
    return publication.render_as_html()
