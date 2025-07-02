import hashlib
from datetime import datetime

from jinja2 import Environment, FileSystemLoader

import settings

env = Environment(loader=FileSystemLoader(settings.TEMPLATES_DIR))

env.globals['hash'] = hashlib.sha256(datetime.now().isoformat().encode()).hexdigest()
env.filters['none_to_empty'] = lambda value: value if value is not None else ''


def render_template(template_path, **context):
    """Render a template with the given context."""
    template = env.get_template(template_path)
    return template.render(**context)
