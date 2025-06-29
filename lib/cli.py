import typer


def build_typer(app_name: str):
    return typer.Typer(
        add_completion=False,
        help=app_name,
        no_args_is_help=True,
        pretty_exceptions_enable=False,
    )
