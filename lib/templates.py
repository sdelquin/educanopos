import hashlib
from datetime import datetime

from jinja2 import Environment, FileSystemLoader

import settings


def normalize(value):
    if value is None:
        return settings.NONE_REPR
    if not isinstance(value, str):
        return value
    value = value.strip()
    if value == 'APTO':
        return f'<span style="color: blue;">{value}</span>'
    try:
        grade = float(value)
    except (ValueError, TypeError):
        return value
    else:
        color = 'green' if grade >= 5 else 'red'
    return f'<span style="color: {color};">{grade}</span>'


env = Environment(loader=FileSystemLoader(settings.TEMPLATES_DIR))

env.globals['hash'] = hashlib.sha256(datetime.now().isoformat().encode()).hexdigest()
env.globals['hero_emoji'] = settings.HERO_EMOJI

env.filters['normalize'] = normalize


def render_template(template_path, **context):
    """Render a template with the given context."""
    template = env.get_template(template_path)
    return template.render(**context)
