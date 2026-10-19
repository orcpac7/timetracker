component extends="Model" {

    function config() {
        table("timeEntries");

        belongsTo(name="task", foreignKey="task_id");
        belongsTo(name="projectCode", foreignKey="projectCode_id");

        validatesPresenceOf(properties="projectCode_id,startedAt");
        validate("validateEndAfterStart");

        beforeValidation("syncProjectCodeFromTask");
    }

    // When linked to a task, the billing code always follows the task's code.
    function syncProjectCodeFromTask() {
        if (StructKeyExists(this, "task_id") && Len(Trim(this.task_id))) {
            local.t = model("Task").findByKey(this.task_id);
            if (IsObject(local.t)) {
                this.projectCode_id = local.t.projectCode_id;
            }
        }
    }

    // endedAt (when present) must not be before startedAt.
    function validateEndAfterStart() {
        if (
            StructKeyExists(this, "endedAt") && Len(Trim(this.endedAt))
            && StructKeyExists(this, "startedAt") && Len(Trim(this.startedAt))
            && IsDate(this.startedAt) && IsDate(this.endedAt)
            && this.endedAt < this.startedAt
        ) {
            addError(property="endedAt", message="End time must be on or after the start time.");
        }
    }

    // Completed minutes on tasks flagged isReview, whatever their project code. The
    // range is by start time (matching the reports); omit both bounds for all-time.
    public numeric function reviewMinutesBetween(string rangeStart = "", string rangeEnd = "") {
        local.reviewTasks = model("Task").findAll(where="isReview = 1", select="id");
        if (!local.reviewTasks.recordCount) {
            return 0;
        }
        local.reviewTaskIds = {};
        for (local.t = 1; local.t <= local.reviewTasks.recordCount; local.t++) {
            local.reviewTaskIds[local.reviewTasks.id[local.t]] = true;
        }

        local.where = "endedAt IS NOT NULL AND task_id IS NOT NULL";
        if (Len(arguments.rangeStart)) {
            local.where &= " AND startedAt >= '#arguments.rangeStart#'";
        }
        if (Len(arguments.rangeEnd)) {
            local.where &= " AND startedAt < '#arguments.rangeEnd#'";
        }

        local.entries = findAll(where=local.where, select="task_id,startedAt,endedAt");
        local.total = 0;
        for (local.i = 1; local.i <= local.entries.recordCount; local.i++) {
            if (StructKeyExists(local.reviewTaskIds, local.entries.task_id[local.i])) {
                local.total += Max(0, DateDiff("n", local.entries.startedAt[local.i], local.entries.endedAt[local.i]));
            }
        }
        return local.total;
    }

    // True while the timer is still running (no end recorded yet).
    function isRunning() {
        return !StructKeyExists(this, "endedAt") || !Len(Trim(this.endedAt ?: ""));
    }

    // Elapsed whole minutes; measures against now() while still running.
    function durationMinutes() {
        if (!IsDate(this.startedAt ?: "")) {
            return 0;
        }
        local.finish = this.isRunning() ? now() : this.endedAt;
        return DateDiff("n", this.startedAt, local.finish);
    }

}
