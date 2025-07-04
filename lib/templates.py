import hashlib
import inspect
from datetime import datetime

from jinja2 import Environment, FileSystemLoader

import settings

from . import filters

env = Environment(loader=FileSystemLoader(settings.TEMPLATES_DIR))

env.globals['hash'] = hashlib.sha256(datetime.now().isoformat().encode()).hexdigest()

for filter, func in inspect.getmembers(filters, inspect.isfunction):
    env.filters[filter] = func


def render_template(template_path, **context):
    """Render a template with the given context."""
    template = env.get_template(template_path)
    return template.render(**context)
