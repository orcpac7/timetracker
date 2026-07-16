<cfscript>
// Place helper functions here that should be available for use in all view pages of your application.

// Turn a whole-minute count into "1h 25m" (or "25m" under an hour).
function formatMinutes(numeric minutes) {
    var m = Int(arguments.minutes);
    if (m < 0) {
        m = 0;
    }
    var h = Int(m / 60);
    var mm = m % 60;
    return (h > 0 ? h & "h " : "") & mm & "m";
}
</cfscript>
