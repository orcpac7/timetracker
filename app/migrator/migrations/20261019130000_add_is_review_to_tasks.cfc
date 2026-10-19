component extends="wheels.migrator.Migration" hint="Add isReview flag to tasks (code review of someone else's PR) and backfill pull request URLs" {
    function up() {
        transaction {
            try {
                // NOT NULL DEFAULT 0 backfills existing tasks as "not a review".
                addColumn(table="tasks", columnType="boolean", columnNames="isReview", default=false, allowNull=false);
                execute("UPDATE tasks SET isReview = 1 WHERE LOWER(url) LIKE '%pullrequest%'");
            } catch (any e) {
                local.exception = e;
            }
            if (StructKeyExists(local, "exception")) {
                transaction action="rollback";
                Throw(errorCode="1", detail=local.exception.detail, message=local.exception.message, type="any");
            } else {
                transaction action="commit";
            }
        }
    }
    function down() {
        transaction {
            removeColumn(table="tasks", columnNames="isReview");
            transaction action="commit";
        }
    }
}
