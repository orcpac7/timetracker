<cfscript>

	// Use this file to add routes to your application and point the root route to a controller action.
	// Don't forget to issue a reload request (e.g. reload=true) after making changes.
	// See https://guides.wheels.dev/v4-0-0-snapshot/handling-requests-with-controllers/routing for more info.
mapper()
    .resources("projectCodes")
    .post(name="startTimer", pattern="timer/start", to="timeEntries##start")
    .post(name="stopTimer", pattern="timer/stop", to="timeEntries##stop")
    .get(name="timer", pattern="timer", to="timeEntries##index")
    .get(name="editTimeEntry", pattern="entry/[key]/edit", to="timeEntries##edit")
    .post(name="updateTimeEntry", pattern="entry/[key]/update", to="timeEntries##update")
    .post(name="deleteTimeEntry", pattern="entry/[key]/delete", to="timeEntries##delete")
    .post(name="resumeEntry", pattern="entry/[key]/resume", to="timeEntries##resume")
    .get(name="dailyReport", pattern="report/daily", to="reports##daily")
    .wildcard()
    .root(to="timeEntries##index", method="get")
.end();
</cfscript>
