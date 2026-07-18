# Containerization and Datasource Troubleshooting Summary

## Current State
- Docker Compose service is defined in `docker-compose.yml` and is running as `app`.
- Container image is built from `Dockerfile` using `ortussolutions/commandbox:latest`.
- The app serves from `/app/public` inside the container.
- `lucee.json` has been updated to use Linux container-compatible SQLite DSN paths:
  - `jdbc:sqlite:/app/db/development.sqlite`
  - `jdbc:sqlite:/app/db/test.sqlite`
- `config/app.cfm` has been updated to register `this.datasources["timetracker"]` and `this.datasources["timetracker_test"]` instead of `blog`.
- The `.env` file is used for environment values such as `WHEELS_ENV`, `WHEELS_DATASOURCE`, `WHEELS_RELOAD_PASSWORD`, and `WHEELS_LUCEE_ADMIN_PASSWORD`.

## Observed Behavior
- The container starts and Runwar reports `Web Root: /app/public`.
- Internal curl still returns a Wheels error page with `Wheels.DataSourceNotFound` / `The data source could not be reached.`
- No direct write permission issue exists on `/usr/local/lib/CommandBox/cfml/system/mdCache`; the container can write there.
- The SQLite files are present and mounted in `/app/db`.

## Key Files Changed
- `lucee.json`
- `config/app.cfm`
- `docker-compose.yml` (runtime command for `/app/public` and compose service config)

## Primary Remaining Issue
- The application is still not resolving the `timetracker` datasource at runtime. This suggests a configuration mismatch between Wheels datasource naming and the datasource actually being used by the request path.

## Notes
- The app uses Wheels 4.x with Lucee and CommandBox.
- `config/settings.cfm` sets `dataSourceName="timetracker"`.
- The error is occurring at the app request level, not at the container startup level.
- There may be a stale or alternate Application.cfc / include path in `public/` or a config loading order issue.
