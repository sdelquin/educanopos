import typer

from lib import cli, db, logger, pub
from lib.screen import app as screen_app

app = cli.build_typer('Evaluación de la práctica docente')


@app.callback()
def main(
    verbose: bool = typer.Option(False, '--verbose', '-v', help='Increase Log level to DEBUG'),
):
    log_level = 'DEBUG' if verbose else 'INFO'
    logger.build_logger(log_level=log_level)


@app.command()
def create_db(
    force: bool = typer.Option(
        False, '--force', '-f', help='Force database destroy and recreation'
    ),
):
    """Create database and corresponding tables."""
    if not force and not typer.confirm('All data will be destroyed. Continue?'):
        raise typer.Abort()
    db.drop_tables()
    db.create_tables()


@app.command()
def load_data(
    data_file: str = typer.Argument(help='Path to the data file (YAML format)'),
):
    """Load data into the database."""
    db.load_data(data_file)


@app.command()
def check_pub(
    save: bool = typer.Option(False, '--save', '-s', help='Save new publications to the database'),
    notify: bool = typer.Option(
        False, '--notify', '-n', help='Notify new publications via Telegram'
    ),
):
    """Check if new publications exists and save/notify if proceed."""
    pub.check(save, notify)


@app.command()
def screen(debug: bool = typer.Option(False, '--debug', '-d', help='Run screen app in debug mode')):
    """Display results (screen) for a specific publication."""
    screen_app.run(debug=debug)


@app.command()
def export(
    publication_name: str = typer.Argument(
        ..., help='Name of the publication to export results for'
    ),
):
    """Export publication results to CSV."""
    pub.export(publication_name)


if __name__ == '__main__':
    app()
