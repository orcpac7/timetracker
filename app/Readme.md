# Readme

- Temporarily using for Dev Notes

Issue with datasource is Not fixed yet. Findings: server files show the site named timetracker and your updated lucee.json/config are present, and /app/db/development.sqlite exists — but the app still returns Wheels.DataSourceNotFound.

- Next step I suggest: create a temporary debug page in public that dumps application.wheels.dataSourceName, this.datasources and application.wheels at request start, then curl it from inside the container to see what Wheels actually sees at runtime. May I add that debug file and run the check?