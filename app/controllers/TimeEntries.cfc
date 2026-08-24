component extends="Controller" {

    function config() {
        super.config();
    }

    // Dashboard: the running timer (if any), the start form's code list, and recent
    // entries within a date range (defaults to the current week, Sunday–Saturday).
    function index() {
        running = model("TimeEntry").findOne(where="endedAt IS NULL", order="startedAt DESC");
        projectCodes = model("ProjectCode").findAll(where="active = 1", order="code");

        // Default range: this week, Sunday (day 1) through Saturday (day 7).
        local.dow = DayOfWeek(now());
        local.weekStart = DateAdd("d", -(local.dow - 1), now());
        local.weekEnd   = DateAdd("d", 7 - local.dow, now());

        local.rawFrom = Trim(params.from ?: "");
        local.rawTo   = Trim(params.to ?: "");
        fromStr = (Len(local.rawFrom) && IsDate(local.rawFrom)) ? DateFormat(local.rawFrom, "yyyy-mm-dd") : DateFormat(local.weekStart, "yyyy-mm-dd");
        toStr   = (Len(local.rawTo)   && IsDate(local.rawTo))   ? DateFormat(local.rawTo,   "yyyy-mm-dd") : DateFormat(local.weekEnd,   "yyyy-mm-dd");

        local.rangeStart = fromStr & " 00:00:00";
        local.rangeEnd   = DateFormat(DateAdd("d", 1, toStr), "yyyy-mm-dd") & " 00:00:00";

        recentEntries = model("TimeEntry").findAll(
            where = "endedAt IS NOT NULL AND startedAt >= '#local.rangeStart#' AND startedAt < '#local.rangeEnd#'",
            order = "startedAt DESC"
        );
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

    // Show the edit form for a stored entry.
    function edit() {
        timeEntry = model("TimeEntry").findByKey(params.key);
        projectCodes = model("ProjectCode").findAll(where="active = 1", order="code");
        if (!IsObject(timeEntry)) {
            flashInsert(error="That entry no longer exists.");
            redirectTo(action="index");
        }
    }

    // Persist edits to a stored entry's start/end times and notes.
    function update() {
        local.entry = model("TimeEntry").findByKey(params.key);
        if (!IsObject(local.entry)) {
            flashInsert(error="That entry no longer exists.");
            redirectTo(action="index");
            return;
        }

        projectCodes = model("ProjectCode").findAll(where="active = 1", order="code");

        // datetime-local posts "yyyy-MM-ddTHH:mm"; swap the T for a space so CFML/SQLite parse it.
        local.started = Replace(Trim(params.startedAt ?: ""), "T", " ");
        local.ended   = Replace(Trim(params.endedAt ?: ""), "T", " ");
        local.projectCodeId = Trim(params.projectCode_id ?: "");
        local.url = Trim(params.url ?: "");
        local.title = Trim(params.title ?: "");
        local.notes = Trim(params.notes ?: "");

        if (!Len(local.started) || !IsDate(local.started)) {
            flashInsert(error="Enter a valid start time.");
            timeEntry = local.entry;
            renderView(action="edit");
            return;
        }
        if (!Len(local.ended) || !IsDate(local.ended)) {
            flashInsert(error="Enter a valid end time.");
            timeEntry = local.entry;
            renderView(action="edit");
            return;
        }

        local.taskId = local.entry.task_id ?: "";

        if (Len(local.url)) {
            local.wid = extractWorkItemId(local.url);
            local.task = Len(local.wid) ? model("Task").findOne(where="workItemId = #Val(local.wid)#") : false;
            if (IsObject(local.task)) {
                local.taskId = local.task.id;
            } else {
                local.newTask = model("Task").create(
                    projectCode_id = Len(local.projectCodeId) ? local.projectCodeId : local.entry.projectCode_id,
                    title = local.title,
                    url = local.url,
                    status = "open"
                );
                if (local.newTask.hasErrors()) {
                    flashInsert(error="Couldn't update the task card — enter a title for a new card.");
                    timeEntry = local.entry;
                    renderView(action="edit");
                    return;
                }
                local.taskId = local.newTask.id;
            }
        }

        local.updateArgs = {
            startedAt = local.started,
            endedAt = local.ended,
            notes = local.notes
        };

        if (Len(local.projectCodeId)) {
            local.updateArgs.projectCode_id = local.projectCodeId;
        } else if (Len(local.entry.projectCode_id ?: "")) {
            local.updateArgs.projectCode_id = local.entry.projectCode_id;
        }

        if (Len(local.taskId)) {
            local.updateArgs.task_id = local.taskId;
        }

        // Model's validateEndAfterStart catches end-before-start.
        if (local.entry.update(argumentCollection=local.updateArgs)) {
            flashInsert(success="Entry updated.");
            redirectTo(action="index");
        } else {
            timeEntry = local.entry;
            renderView(action="edit");
        }
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

    // Delete a time entry.
    function delete() {
        local.entry = model("TimeEntry").findByKey(params.key);
        if (!IsObject(local.entry)) {
            flashInsert(error="That entry no longer exists.");
        } else if (local.entry.delete()) {
            flashInsert(success="Entry deleted.");
        } else {
            flashInsert(error="Couldn't delete the entry.");
        }
        redirectTo(action="index");
    }

    // Resume a past entry: start a new timer on the same task/code, copying its
    // notes. A separate row in Recent Entries; the report sums same-task sessions.
    function resume() {
        local.source = model("TimeEntry").findByKey(params.key);
        if (!IsObject(local.source)) {
            flashInsert(error="That entry no longer exists.");
            redirectTo(action="index");
            return;
        }

        stopRunningTimer();

        local.args = { startedAt = now(), notes = local.source.notes ?: "" };
        if (Len(local.source.task_id ?: "")) {
            // projectCode_id follows the task via the model's beforeValidation callback.
            local.args.task_id = local.source.task_id;
        } else {
            local.args.projectCode_id = local.source.projectCode_id;
        }

        local.entry = model("TimeEntry").create(argumentCollection=local.args);
        if (local.entry.hasErrors()) {
            flashInsert(error="Couldn't resume that entry.");
        } else {
            flashInsert(success="Resumed — timer started.");
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
