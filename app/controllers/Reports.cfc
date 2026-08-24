component extends="Controller" {

    function config() {
        super.config();
    }

    // Daily report: completed entries for one day, grouped by project code with
    // per-code subtotals and a grand total. Codes flagged excludeFromReport
    // (personal / breaks / meals) are omitted unless includeExcluded=1.
    function daily() {
        loadDailyReport();
    }

    // Email-safe render of the same data: table-based, inline-styled, literal
    // spacing so the formatting survives a copy/paste into Outlook. A copy button
    // in the view writes just the report region to the clipboard as rich HTML.
    function emailReport() {
        loadDailyReport();
    }

    // Email-safe render of just the notes text as a flat bullet list for the whole
    // day -- no code headings, no task titles. Entries without notes contribute
    // nothing. Same copy-to-Outlook mechanics as emailReport().
    function notesReport() {
        loadDailyReport();
    }

    // Shared data prep for both the on-screen and email renders. Sets the
    // report vars (groups, totals, date navigation) into the request scope.
    private function loadDailyReport() {
        // Resolve the report day (default today).
        local.raw = Trim(params.date ?: "");
        local.reportDate = (Len(local.raw) && IsDate(local.raw)) ? local.raw : DateFormat(now(), "yyyy-mm-dd");
        reportDateStr = DateFormat(local.reportDate, "yyyy-mm-dd");
        prevDateStr = DateFormat(DateAdd("d", -1, local.reportDate), "yyyy-mm-dd");
        nextDateStr = DateFormat(DateAdd("d",  1, local.reportDate), "yyyy-mm-dd");
        todayStr = DateFormat(now(), "yyyy-mm-dd");

        includeExcluded = (params.includeExcluded ?: "") == "1";
        showTimes = (params.showTimes ?: "") == "1";

        local.dayStart = reportDateStr & " 00:00:00";
        local.dayEnd   = nextDateStr  & " 00:00:00";

        // Completed entries that STARTED on the report day, ordered by code then time.
        local.entries = model("TimeEntry").findAll(
            where = "startedAt >= '#local.dayStart#' AND startedAt < '#local.dayEnd#' AND endedAt IS NOT NULL",
            order = "projectCode_id, startedAt"
        );

        // Project-code lookup by id.
        local.codeQuery = model("ProjectCode").findAll();
        local.codeById = {};
        for (local.r = 1; local.r <= local.codeQuery.recordCount; local.r++) {
            local.codeById[local.codeQuery.id[local.r]] = {
                id                = local.codeQuery.id[local.r],
                code              = local.codeQuery.code[local.r],
                description       = local.codeQuery.description[local.r],
                color             = local.codeQuery.color[local.r],
                excludeFromReport = local.codeQuery.excludeFromReport[local.r]
            };
        }

        // Task lookup by id (loaded once per distinct task referenced today).
        // We need each entry's url field BEFORE choosing its line, so lines can
        // merge by url rather than by task identity. Objects are kept so the
        // view can still call cardUrl().
        local.taskById = {};
        for (local.i = 1; local.i <= local.entries.recordCount; local.i++) {
            local.tid = local.entries.task_id[local.i] ?: "";
            if (Len(local.tid) && !StructKeyExists(local.taskById, local.tid)) {
                local.taskById[local.tid] = model("Task").findByKey(local.tid);
            }
        }

        // Group by code, then collapse entries that share the same title into one
        // line (durations summed, session count, all distinct notes coalesced).
        // Task entries merge by task (a task has a stable title); ad-hoc entries
        // (no task) merge by their notes text, so repeats of the same description
        // combine instead of each keeping its own line.
        // The notes-only report needs a second, flatter view of the same entries:
        // one row per task for the WHOLE day (not per code), each carrying its
        // distinct notes. Minutes accumulate per entry, both on the task row and on
        // the individual note, so nothing is double counted. Task-less entries all
        // collapse into a single "Ad-hoc" row rather than one row per note.
        groups = [];
        taskNoteLines = [];
        notedMinutes = 0;
        unnotedMinutes = 0;
        grandTotalMinutes = 0;
        hiddenCount = 0;
        local.groupIndex = {};   // codeId -> position in groups
        local.lineIndex  = {};   // "codeId|taskKey" -> position in that group's lines
        local.dayTaskIndex = {}; // day-wide task key -> position in taskNoteLines

        for (local.i = 1; local.i <= local.entries.recordCount; local.i++) {
            local.codeId = local.entries.projectCode_id[local.i];
            local.code = StructKeyExists(local.codeById, local.codeId) ? local.codeById[local.codeId] : {code="?", description="(deleted code)", color="##9ca3af", excludeFromReport=false};
            local.isExcluded = local.code.excludeFromReport ?: false;

            if (local.isExcluded && !includeExcluded) {
                hiddenCount++;
                continue;
            }

            local.mins = DateDiff("n", local.entries.startedAt[local.i], local.entries.endedAt[local.i]);
            if (local.mins < 0) { local.mins = 0; }

            local.taskId = local.entries.task_id[local.i] ?: "";
            local.task = (Len(local.taskId) && StructKeyExists(local.taskById, local.taskId)) ? local.taskById[local.taskId] : false;
            local.taskUrl = IsObject(local.task) ? Trim(local.task.url ?: "") : "";
            local.entryNote = Trim(local.entries.notes[local.i] ?: "");
            // Merge lines by the task url field so different task rows pointing at
            // the same card/PR collapse together. Fall back to task identity when a
            // task has no url, and to notes text for ad-hoc (task-less) entries.
            if (Len(local.taskUrl)) {
                local.taskKey = "u" & LCase(local.taskUrl);
            } else if (Len(local.taskId)) {
                local.taskKey = "t" & local.taskId;
            } else {
                local.taskKey = "a" & LCase(local.entryNote);
            }

            // Ensure the code group exists.
            if (!StructKeyExists(local.groupIndex, local.codeId)) {
                ArrayAppend(groups, {code = local.code, lines = [], totalMinutes = 0, excluded = local.isExcluded});
                local.groupIndex[local.codeId] = ArrayLen(groups);
            }
            local.gpos = local.groupIndex[local.codeId];

            // Ensure the task line exists within the group.
            local.lkey = local.codeId & "|" & local.taskKey;
            if (!StructKeyExists(local.lineIndex, local.lkey)) {
                ArrayAppend(groups[local.gpos].lines, {
                    task     = local.task,
                    minutes  = 0,
                    sessions = 0,
                    notes    = [],   // distinct notes, in first-seen order
                    noteSeen = {}    // lowercased note -> true, for dedup
                });
                local.lineIndex[local.lkey] = ArrayLen(groups[local.gpos].lines);
            }
            local.lpos = local.lineIndex[local.lkey];

            groups[local.gpos].lines[local.lpos].minutes  += local.mins;
            groups[local.gpos].lines[local.lpos].sessions += 1;
            // Coalesce notes: keep each distinct note once (case-insensitive).
            if (Len(local.entryNote)) {
                local.noteKey = LCase(local.entryNote);
                if (!StructKeyExists(groups[local.gpos].lines[local.lpos].noteSeen, local.noteKey)) {
                    groups[local.gpos].lines[local.lpos].noteSeen[local.noteKey] = true;
                    ArrayAppend(groups[local.gpos].lines[local.lpos].notes, local.entryNote);
                }
            }
            groups[local.gpos].totalMinutes += local.mins;
            grandTotalMinutes += local.mins;

            // Day-wide task roll-up for the notes-only report: title on top, its
            // notes underneath. Entries with no note are skipped, but their minutes
            // are tracked so the view can say how much of the day the bullets don't
            // account for. Ad-hoc entries share one row keyed "adhoc"; task entries
            // merge by url then task id, mirroring the per-code merge above but
            // without the code prefix, so one task spanning two codes stays a
            // single row.
            if (Len(local.entryNote)) {
                if (Len(local.taskUrl)) {
                    local.dkey = "u" & LCase(local.taskUrl);
                } else if (Len(local.taskId)) {
                    local.dkey = "t" & local.taskId;
                } else {
                    local.dkey = "adhoc";
                }

                if (!StructKeyExists(local.dayTaskIndex, local.dkey)) {
                    ArrayAppend(taskNoteLines, {
                        title    = (IsObject(local.task) AND Len(local.task.title ?: "")) ? local.task.title : "Ad-hoc",
                        minutes  = 0,
                        sessions = 0,
                        notes    = [],   // {text, minutes, sessions}, first-seen order
                        noteSeen = {}    // lowercased note -> position in notes
                    });
                    local.dayTaskIndex[local.dkey] = ArrayLen(taskNoteLines);
                }
                local.dpos = local.dayTaskIndex[local.dkey];
                taskNoteLines[local.dpos].minutes  += local.mins;
                taskNoteLines[local.dpos].sessions += 1;

                local.nkey = LCase(local.entryNote);
                if (!StructKeyExists(taskNoteLines[local.dpos].noteSeen, local.nkey)) {
                    ArrayAppend(taskNoteLines[local.dpos].notes, {text = local.entryNote, minutes = 0, sessions = 0});
                    taskNoteLines[local.dpos].noteSeen[local.nkey] = ArrayLen(taskNoteLines[local.dpos].notes);
                }
                local.npos = taskNoteLines[local.dpos].noteSeen[local.nkey];
                taskNoteLines[local.dpos].notes[local.npos].minutes  += local.mins;
                taskNoteLines[local.dpos].notes[local.npos].sessions += 1;

                notedMinutes += local.mins;
            } else {
                unnotedMinutes += local.mins;
            }
        }
    }

}
