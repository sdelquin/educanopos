from flask import Flask, render_template_string

from .db import Publication

app = Flask(__name__)


@app.route('/screen/<int:publication_pk>/')
def display(publication_pk: int) -> str:
    publication = Publication.get(Publication.id == publication_pk)
    return render_template_string(publication.results_as_html)
