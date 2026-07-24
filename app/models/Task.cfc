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
     * Pull the Azure DevOps work item id out of a pasted URL. Handles both the
     * direct card link and a board/backlog deep link that has the card open:
     *   https://dev.azure.com/{org}/{project}/_workitems/edit/12345
     *   https://{org}.visualstudio.com/{project}/_workitems/edit/12345
     *   https://dev.azure.com/{org}/{project}/_boards/board/t/{team}/Stories?...&workitem=12345
     * Only sets workItemId when the URL matches; never clears a value.
     */
    function parseWorkItemId() {
        if (StructKeyExists(this, "url") && Len(Trim(this.url))) {
            local.m = reFindNoCase("_workitems/edit/([0-9]+)", this.url, 1, true);
            if (ArrayLen(local.m.pos) < 2 || local.m.pos[2] <= 0) {
                // Fall back to the board/backlog "?...&workitem=12345" form.
                local.m = reFindNoCase("[?&]workitem=([0-9]+)", this.url, 1, true);
            }
            if (ArrayLen(local.m.pos) >= 2 && local.m.pos[2] > 0) {
                this.workItemId = Mid(this.url, local.m.pos[2], local.m.len[2]);
            }
        }
    }

    /**
     * A link that opens the specific work item card. A board/backlog URL only
     * reopens the board (even when it carries a ?workitem= param), so when we
     * know the work item id we rebuild a direct .../_workitems/edit/{id} link
     * from the org/project base. URLs with no work item id (e.g. pull requests)
     * are already specific and are returned unchanged.
     */
    function cardUrl() {
        local.url = Trim(this.url ?: "");
        if (!Len(local.url)) {
            return "";
        }
        if (Len(Trim(this.workItemId ?: ""))) {
            // Everything before the first "/_" segment is the org/project base,
            // e.g. https://dev.azure.com/{org}/{project}
            local.idx = FindNoCase("/_", local.url);
            if (local.idx GT 0) {
                return Left(local.url, local.idx - 1) & "/_workitems/edit/" & Trim(this.workItemId);
            }
        }
        return local.url;
    }

}
