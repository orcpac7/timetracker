<cfscript>
try {
    // Run a simple query against the timetracker datasource
    local.sql = "SELECT name FROM sqlite_master WHERE type='table' LIMIT 5";
    local.rows = queryExecute(local.sql, [], {datasource="timetracker", result="qResult"});
    writeOutput('<h3>Query succeeded</h3>');
    writeOutput('<pre>');
    writeOutput('RowCount: ' & local.rows.recordCount & '\n');
    if (local.rows.recordCount) {
        for (r=1; r<=local.rows.recordCount; r++) {
            writeOutput(local.rows[r].name & '\n');
        }
    }
    writeOutput('</pre>');
} catch (any e) {
    writeOutput('<h3>Query failed</h3>');
    writeOutput('<pre>');
    writeOutput('Message: ' & e.message & '\n');
    // Include detail for diagnostics
    if (structKeyExists(e, 'detail')) writeOutput('Detail: ' & e.detail & '\n');
    writeOutput('Error Struct: ' & serializeJSON(e));
    writeOutput('</pre>');
}
</cfscript>