component extends="Controller" {

    function config() {
        super.config();
    }

    // Dashboard: the running timer (if any), the start form's code list, and recent entries.
    function index() {
        running = model("TimeEntry").findOne(where="endedAt IS NULL", order="startedAt DESC");
        projectCodes = model("ProjectCode").findAll(where="active = 1", order="code");
        recentEntries = model("TimeEntry").findAll(where="endedAt IS NOT NULL", order="startedAt DESC", maxRows=25);
    }

    // Start a timer. Creates/reuses a task on the fly when a URL is pasted.
    function start() {
        stopRunningTimer();

        local.projectCodeId = Trim(params.projectCode_id ?: "");
        local.url = Trim(params.url ?: "");
        local.title = Trim(params.title ?: "");
        local.notes = Trim(params.notes ?: "");
        local.taskId = "";

        if (Len(local.url)) {
            local.wid = extractWorkItemId(local.url);
            local.task = Len(local.wid) ? model("Task").findOne(where="workItemId = #Val(local.wid)#") : false;
            if (IsObject(local.task)) {
                local.taskId = local.task.id;
            } else {
                local.newTask = model("Task").create(
                    projectCode_id = local.projectCodeId,
                    title = local.title,
                    url = local.url,
                    status = "open"
                );
                if (local.newTask.hasErrors()) {
                    flashInsert(error="Couldn't create the card — pick a project code and enter a title.");
                    redirectTo(action="index");
                    return;
                }
                local.taskId = local.newTask.id;
            }
        }

        if (Len(local.taskId)) {
            // projectCode_id is copied from the task by the model's beforeValidation callback.
            local.entry = model("TimeEntry").create(task_id=local.taskId, startedAt=now(), notes=local.notes);
        } else {
            local.entry = model("TimeEntry").create(projectCode_id=local.projectCodeId, startedAt=now(), notes=local.notes);
        }

        if (local.entry.hasErrors()) {
            flashInsert(error="Couldn't start the timer — please pick a project code.");
        } else {
            flashInsert(success="Timer started.");
        }
        redirectTo(action="index");
    }

    // Stop the running timer (if any).
    function stop() {
        if (stopRunningTimer()) {
            flashInsert(success="Timer stopped.");
        } else {
            flashInsert(error="No timer was running.");
        }
        redirectTo(action="index");
    }

    // --- helpers -------------------------------------------------------------

    // Stops the currently running entry, if one exists. Returns true if it stopped one.
    private boolean function stopRunningTimer() {
        local.running = model("TimeEntry").findOne(where="endedAt IS NULL");
        if (IsObject(local.running)) {
            local.running.update(endedAt=now());
            return true;
        }
        return false;
    }

    // Pull the Azure DevOps work item id from a card URL, or "" if none.
    private string function extractWorkItemId(required string url) {
        local.m = reFindNoCase("_workitems/edit/([0-9]+)", arguments.url, 1, true);
        if (ArrayLen(local.m.pos) >= 2 && local.m.pos[2] > 0) {
            return Mid(arguments.url, local.m.pos[2], local.m.len[2]);
        }
        return "";
    }

}
