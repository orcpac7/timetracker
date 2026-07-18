# Session Continuation Notes

## Goal
Continue refining the Lucee/Wheels container so the app starts successfully and the `timetracker` SQLite datasource is reachable from inside the container.

## What We Know
- The Docker container is running and serving `/app/public`.
- `lucee.json` now points SQLite DSNs to `/app/db/…`.
- `config/app.cfm` now registers `this.datasources["timetracker"]`.
- The app still returns a Wings error page indicating `Wheels.DataSourceNotFound`.

## Next Investigation Steps
1. Confirm which `Application.cfc` file is actually used by the running app.
2. Confirm that Wheels is reading `config/settings.cfm` and not a different environment-specific override.
3. Confirm that the datasource name passed to Wheels is `timetracker`, not `blog`.
4. Check Lucee administrator datasource configuration or runtime datasource registry if possible.
5. If needed, add debug dump pages or temporary CFML logging to print `application.wheels.dataSourceName` and `this.datasources` at request startup.

## Possible Fix Areas
- `public/Application.cfc` include path / Application loading order
- `config/settings.cfm` vs environment overrides
- Wheels datasource registration name mismatch
- `lucee.json` datasource and/or `application.cfc` datasource config mismatch

## Useful Commands
- `docker compose exec app bash -lc "box server list"`
- `docker compose exec app bash -lc "curl -s http://127.0.0.1:8080"`
- `docker compose exec app bash -lc "cat /app/public/Application.cfc | sed -n '1,80p'"`
- `docker compose exec app bash -lc "find /app -name 'Application.cfc' -o -name 'settings.cfm' -o -name 'app.cfm'"`
- `docker compose exec app bash -lc "ls -lah /app/db && sqlite3 /app/db/development.sqlite '.tables'"`
- `docker compose exec app bash -lc "grep -RIn 'dataSourceName\|this\.datasources\|set\(dataSourceName\' /app"`

## Document History
- Created 2026-07-18
- Status: app container runs; data source not resolved
