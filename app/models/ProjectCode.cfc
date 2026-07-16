component extends="Model" {

    function config() {
        table("projectCodes");

        hasMany(name="tasks", foreignKey="projectCode_id");
        hasMany(name="timeEntries", foreignKey="projectCode_id");

        validatesPresenceOf(properties="code,description");
        // includeSoftDeletes=false so a deleted code's hidden row doesn't block re-adding the same number.
        validatesUniquenessOf(property="code", includeSoftDeletes=false);
        validatesNumericalityOf(property="code", onlyInteger=true);
    }

    // e.g. "1001 - Internal Admin" — for dropdowns and report headings.
    function label() {
        return this.code & " - " & this.description;
    }

}
