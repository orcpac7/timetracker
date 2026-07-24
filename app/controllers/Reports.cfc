component extends="Controller" {

    function config() {
        super.config();
    }

    // Daily report: completed entries for one day, grouped by project code with
    // per-code subtotals and a grand total. Codes flagged excludeFromReport
    // (personal / breaks / meals) are omitted unless includeExcluded=1.
    function daily() {
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

        // Group by code, then collapse same-task sessions into one line
        // (durations summed, session count, latest note). Ad-hoc entries (no
        // task) never merge — each keeps its own line. Entries are ordered by
        // startedAt ascending, so the last note seen per task IS the latest.
        groups = [];
        grandTotalMinutes = 0;
        hiddenCount = 0;
        local.groupIndex = {};   // codeId -> position in groups
        local.lineIndex  = {};   // "codeId|taskKey" -> position in that group's lines

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
            // Same task merges; each ad-hoc entry is its own line (keyed by entry id).
            local.taskKey = Len(local.taskId) ? "t" & local.taskId : "a" & local.entries.id[local.i];

            // Ensure the code group exists.
            if (!StructKeyExists(local.groupIndex, local.codeId)) {
                ArrayAppend(groups, {code = local.code, lines = [], totalMinutes = 0, excluded = local.isExcluded});
                local.groupIndex[local.codeId] = ArrayLen(groups);
            }
            local.gpos = local.groupIndex[local.codeId];

            // Ensure the task line exists within the group.
            local.lkey = local.codeId & "|" & local.taskKey;
            if (!StructKeyExists(local.lineIndex, local.lkey)) {
                local.task = Len(local.taskId) ? model("Task").findByKey(local.taskId) : false;
                ArrayAppend(groups[local.gpos].lines, {
                    task     = local.task,
                    minutes  = 0,
                    sessions = 0,
                    notes    = ""
                });
                local.lineIndex[local.lkey] = ArrayLen(groups[local.gpos].lines);
            }
            local.lpos = local.lineIndex[local.lkey];

            groups[local.gpos].lines[local.lpos].minutes  += local.mins;
            groups[local.gpos].lines[local.lpos].sessions += 1;
            groups[local.gpos].lines[local.lpos].notes = local.entries.notes[local.i] ?: "";  // latest wins
            groups[local.gpos].totalMinutes += local.mins;
            grandTotalMinutes += local.mins;
        }
    }

}
