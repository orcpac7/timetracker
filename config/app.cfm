<cfscript>
	/*
		Use this file to set variables for the Application.cfc's "this" scope.

		Examples:
		this.name = "MyAppName";
		this.sessionTimeout = CreateTimeSpan(0,0,5,0);
	*/
	this.name = "timetracker";

	// SQLite zero-config database (configured by wheels new)
	this.datasources["blog"] = {
		class: "org.sqlite.JDBC",
		connectionString: "jdbc:sqlite:" & expandPath("../db/development.sqlite")
	};
	this.datasources["blog_test"] = {
		class: "org.sqlite.JDBC",
		connectionString: "jdbc:sqlite:" & expandPath("../db/test.sqlite")
	};

	// CLI-Appends-Here
</cfscript>
