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


def drop_row(row) -> bool:
    return row.get(settings.DROP_ROW_FIELD, False) == 'S'


def hide_field(field: str) -> bool:
    return 'hide' in field
