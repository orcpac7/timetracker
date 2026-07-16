<cfscript>

	// Use this file to add routes to your application and point the root route to a controller action.
	// Don't forget to issue a reload request (e.g. reload=true) after making changes.
	// See https://guides.wheels.dev/v4-0-0-snapshot/handling-requests-with-controllers/routing for more info.
mapper()
    .resources("projectCodes")
    .post(name="startTimer", pattern="timer/start", to="timeEntries##start")
    .post(name="stopTimer", pattern="timer/stop", to="timeEntries##stop")
    .get(name="timer", pattern="timer", to="timeEntries##index")
    .wildcard()
    .root(to="timeEntries##index", method="get")
.end();
</cfscript>
