component extends="Model" {

    function config() {
        table("tasks");

        belongsTo(name="projectCode", foreignKey="projectCode_id");
        hasMany(name="timeEntries", foreignKey="task_id");

        validatesPresenceOf(properties="projectCode_id,title");
        validatesNumericalityOf(property="workItemId", onlyInteger=true, allowBlank=true);
        enum(property="status", values="open,done");

        beforeValidation("parseWorkItemId");
    }

    /**
     * Pull the Azure DevOps work item id out of a pasted card URL, e.g.
     *   https://dev.azure.com/{org}/{project}/_workitems/edit/12345
     *   https://{org}.visualstudio.com/{project}/_workitems/edit/12345
     * Only sets workItemId when the URL matches; never clears a value.
     */
    function parseWorkItemId() {
        if (StructKeyExists(this, "url") && Len(Trim(this.url))) {
            local.m = reFindNoCase("_workitems/edit/([0-9]+)", this.url, 1, true);
            if (ArrayLen(local.m.pos) >= 2 && local.m.pos[2] > 0) {
                this.workItemId = Mid(this.url, local.m.pos[2], local.m.len[2]);
            }
        }
    }

}
