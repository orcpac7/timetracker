component extends="Controller" {

    function config() {
        super.config();
    }

    // Dashboard: the running timer (if any), the start form's code list, summary
    // stats/charts, and recent entries within a date range (defaults to the
    // current week, Sunday–Saturday).
    function index() {
        running = model("TimeEntry").findOne(where="endedAt IS NULL", order="startedAt DESC");
        projectCodes = model("ProjectCode").findAll(where="active = 1", order="code");
        defaultProjectCode = model("ProjectCode").findOne(where="active = 1 AND isDefault = 1");

        local.week = currentWeekBounds();

        local.rawFrom = Trim(params.from ?: "");
        local.rawTo   = Trim(params.to ?: "");
        fromStr = (Len(local.rawFrom) && IsDate(local.rawFrom)) ? DateFormat(local.rawFrom, "yyyy-mm-dd") : DateFormat(local.week.start, "yyyy-mm-dd");
        toStr   = (Len(local.rawTo)   && IsDate(local.rawTo))   ? DateFormat(local.rawTo,   "yyyy-mm-dd") : DateFormat(local.week.end,   "yyyy-mm-dd");

        local.rangeStart = fromStr & " 00:00:00";
        local.rangeEnd   = DateFormat(DateAdd("d", 1, toStr), "yyyy-mm-dd") & " 00:00:00";

        recentEntries = model("TimeEntry").findAll(
            where = "endedAt IS NOT NULL AND startedAt >= '#local.rangeStart#' AND startedAt < '#local.rangeEnd#'",
            order = "startedAt DESC"
        );

        loadDashboardStats();
    }

    // Start a timer. Creates/reuses a task on the fly when a URL is pasted.
    function start() {
        stopRunningTimer();

        local.projectCodeId = Trim(params.projectCode_id ?: "");
        local.url = Trim(params.url ?: "");
        local.title = Trim(params.title ?: "");
        local.notes = Trim(params.notes ?: "");
        local.taskId = "";

        if (Len(local.url) || Len(local.title)) {
            local.wid = Len(local.url) ? extractWorkItemId(local.url) : "";
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

        if (Len(local.url) || Len(local.title)) {
            local.wid = Len(local.url) ? extractWorkItemId(local.url) : "";
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

        // The model forces an entry's code to its task's code, so a code change must land on the task.
        if (Len(local.taskId) && Len(local.projectCodeId)) {
            local.linkedTask = model("Task").findByKey(local.taskId);
            if (IsObject(local.linkedTask) && local.linkedTask.projectCode_id != local.projectCodeId) {
                local.linkedTask.update(projectCode_id=local.projectCodeId);
                model("TimeEntry").updateAll(where="task_id = #Val(local.taskId)#", properties={projectCode_id=local.projectCodeId});
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

    // The current week, Sunday (day 1) through Saturday (day 7).
    private struct function currentWeekBounds() {
        local.dow = DayOfWeek(now());
        return {
            start = DateAdd("d", -(local.dow - 1), now()),
            end   = DateAdd("d", 7 - local.dow, now())
        };
    }

    // Builds the dashboard summary: today/week totals, hours-per-day this week,
    // and hours-by-code (this week and all-time). Sets request-scope vars for the view.
    private void function loadDashboardStats() {
        local.week = currentWeekBounds();
        local.todayStr = DateFormat(now(), "yyyy-mm-dd");

        local.weekStartStr = DateFormat(local.week.start, "yyyy-mm-dd");
        local.weekEndStr   = DateFormat(local.week.end, "yyyy-mm-dd");
        local.weekRangeStart = local.weekStartStr & " 00:00:00";
        local.weekRangeEnd   = DateFormat(DateAdd("d", 1, local.weekEndStr), "yyyy-mm-dd") & " 00:00:00";

        // Project-code lookup by id (plain structs, not model instances -- mirrors
        // the codeById pattern in Reports.loadDailyReport()).
        local.codeQuery = model("ProjectCode").findAll();
        local.codeById = {};
        for (local.r = 1; local.r <= local.codeQuery.recordCount; local.r++) {
            local.codeById[local.codeQuery.id[local.r]] = {
                code        = local.codeQuery.code[local.r],
                description = local.codeQuery.description[local.r],
                color       = local.codeQuery.color[local.r]
            };
        }

        // Seed 7 daily buckets, Sunday through Saturday.
        local.dailyBuckets = [];
        for (local.i = 0; local.i <= 6; local.i++) {
            ArrayAppend(local.dailyBuckets, { label = DateFormat(DateAdd("d", local.i, local.week.start), "ddd"), minutes = 0 });
        }

        local.weekByCodeMinutes = {};
        dashboardTodayMinutes = 0;

        local.weekEntries = model("TimeEntry").findAll(
            where = "endedAt IS NOT NULL AND startedAt >= '#local.weekRangeStart#' AND startedAt < '#local.weekRangeEnd#'",
            order = "startedAt"
        );

        for (local.i = 1; local.i <= local.weekEntries.recordCount; local.i++) {
            local.mins = DateDiff("n", local.weekEntries.startedAt[local.i], local.weekEntries.endedAt[local.i]);
            if (local.mins < 0) { local.mins = 0; }

            local.entryDateStr = DateFormat(local.weekEntries.startedAt[local.i], "yyyy-mm-dd");
            local.dayIndex = DateDiff("d", local.weekStartStr, local.entryDateStr);
            if (local.dayIndex >= 0 && local.dayIndex <= 6) {
                local.dailyBuckets[local.dayIndex + 1].minutes += local.mins;
            }

            local.codeId = local.weekEntries.projectCode_id[local.i];
            if (!StructKeyExists(local.weekByCodeMinutes, local.codeId)) {
                local.weekByCodeMinutes[local.codeId] = 0;
            }
            local.weekByCodeMinutes[local.codeId] += local.mins;

            if (local.entryDateStr == local.todayStr) {
                dashboardTodayMinutes += local.mins;
            }
        }

        dashboardWeekDaily = local.dailyBuckets;

        dashboardWeekMinutes = 0;
        dashboardWeekByCode = [];
        for (local.id in local.weekByCodeMinutes) {
            dashboardWeekMinutes += local.weekByCodeMinutes[local.id];
            if (StructKeyExists(local.codeById, local.id)) {
                local.c = local.codeById[local.id];
                ArrayAppend(dashboardWeekByCode, { label = "#local.c.code# - #local.c.description#", color = local.c.color, minutes = local.weekByCodeMinutes[local.id] });
            }
        }
        ArraySort(dashboardWeekByCode, function(a, b) { return b.minutes - a.minutes; });

        // All-time, by code.
        local.allByCodeMinutes = {};
        local.allEntries = model("TimeEntry").findAll(
            where = "endedAt IS NOT NULL",
            select = "projectCode_id, startedAt, endedAt"
        );
        for (local.i = 1; local.i <= local.allEntries.recordCount; local.i++) {
            local.mins = DateDiff("n", local.allEntries.startedAt[local.i], local.allEntries.endedAt[local.i]);
            if (local.mins < 0) { local.mins = 0; }

            local.codeId = local.allEntries.projectCode_id[local.i];
            if (!StructKeyExists(local.allByCodeMinutes, local.codeId)) {
                local.allByCodeMinutes[local.codeId] = 0;
            }
            local.allByCodeMinutes[local.codeId] += local.mins;
        }

        dashboardAllTimeByCode = [];
        for (local.id in local.allByCodeMinutes) {
            if (StructKeyExists(local.codeById, local.id)) {
                local.c = local.codeById[local.id];
                ArrayAppend(dashboardAllTimeByCode, { label = "#local.c.code# - #local.c.description#", color = local.c.color, minutes = local.allByCodeMinutes[local.id] });
            }
        }
        ArraySort(dashboardAllTimeByCode, function(a, b) { return b.minutes - a.minutes; });
    }

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
