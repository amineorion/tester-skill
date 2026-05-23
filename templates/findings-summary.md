# QA findings — {{project_name}}

Run: `{{run_id}}` at {{finished_at}}.

## Top issues

{{#critical}}
### 🔴 Critical: {{title}}
- Route: `{{route_path}}`
- {{description}}
{{/critical}}

{{#high}}
### 🟠 High: {{title}}
- Route: `{{route_path}}`
- {{description}}
{{/high}}

{{#medium}}
### 🟡 Medium: {{title}}
- Route: `{{route_path}}`
{{/medium}}

## Performance

{{perf_table}}

## Full report

`{{report_path}}`
