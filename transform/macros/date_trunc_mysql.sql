{% macro date_trunc_mysql(datepart, col) %}
    {% if datepart == 'day' %}
        DATE({{ col }})
    {% elif datepart == 'month' %}
        DATE_FORMAT({{ col }}, '%Y-%m-01')
    {% elif datepart == 'year' %}
        DATE_FORMAT({{ col }}, '%Y-01-01')
    {% else %}
        {{ exceptions.raise_compiler_error("unsupported datepart") }}
    {% endif %}
{% endmacro %}