import typer

from lib import cli, db, logger, pub

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
def check_pub():
    """Check if new publications exists and deliver if proceed."""
    pub.check()


if __name__ == '__main__':
    app()
