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
