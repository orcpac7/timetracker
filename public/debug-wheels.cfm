<cfscript>
try {
    writeOutput('<pre>');
    writeOutput('this.name: ' & (this.name ?: '<<not set>>') & '\n');
    writeOutput('application.wheels.dataSourceName: ' & (structKeyExists(application,'wheels') && structKeyExists(application.wheels,'dataSourceName') ? application.wheels.dataSourceName : '<<not set>>') & '\n');
    if (structKeyExists(this, 'datasources')) {
        writeOutput('this.datasources keys: ' & ArrayToList(structKeyArray(this.datasources)) & '\n');
    } else {
        writeOutput('this.datasources: <<not defined>>\n');
    }
    if (structKeyExists(application, 'wheels')) {
        writeOutput('application.wheels keys: ' & ArrayToList(structKeyArray(application.wheels)) & '\n');
    }
    writeOutput('expandPath("../db/development.sqlite"): ' & expandPath('../db/development.sqlite') & '\n');
    writeOutput('fileExists(expandPath("../db/development.sqlite")): ' & (fileExists(expandPath('../db/development.sqlite')) ? 'YES' : 'NO') & '\n');
    writeOutput('</pre>');
} catch (any e) {
    writeOutput('<pre>ERROR: ' & e.message & '</pre>');
}
</cfscript>