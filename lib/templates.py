from jinja2 import Environment, FileSystemLoader

import settings

env = Environment(loader=FileSystemLoader(settings.TEMPLATES_DIR))


def render_template(template_path, **context):
    """Render a template with the given context."""
    template = env.get_template(template_path)
    return template.render(**context)
