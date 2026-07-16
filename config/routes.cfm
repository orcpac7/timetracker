<cfscript>

	// Use this file to add routes to your application and point the root route to a controller action.
	// Don't forget to issue a reload request (e.g. reload=true) after making changes.
	// See https://guides.wheels.dev/v4-0-0-snapshot/handling-requests-with-controllers/routing for more info.
mapper()
    .wildcard()
    .root(to="main##index", method="get")
.end();
</cfscript>
