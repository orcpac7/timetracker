component extends="wheels.migrator.Migration" hint="Create timeEntries table (the time log)" {
    function up() {
        transaction {
            try {
                t = createTable(name="timeEntries");
                // foreignKey=false on both: SQLite's adapter emits invalid FK-constraint DDL, and
                // SQLite doesn't enforce FKs by default; integrity is handled at the model layer.
                // Optional link to a task/card -> task_id (nullable for ad-hoc work with no card).
                t.references(columnNames="task", allowNull=true, foreignKey=false);
                // Every entry is billed to a code -> projectCode_id (copied from the task, or set directly for ad-hoc).
                t.references(columnNames="projectCode", allowNull=false, foreignKey=false);
                // Exact timestamps are always stored; 15-minute rounding happens only at the report layer.
                t.datetime(columnNames="startedAt", allowNull=false);
                // endedAt NULL means the timer is still running.
                t.datetime(columnNames="endedAt", allowNull=true);
                t.text(columnNames="notes", allowNull=true);
                t.timestamps();
                t.create();
                addIndex(table="timeEntries", columnNames="projectCode_id");
                addIndex(table="timeEntries", columnNames="task_id");
                // startedAt drives every weekly/date-range report query.
                addIndex(table="timeEntries", columnNames="startedAt");
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
            dropTable("timeEntries");
            transaction action="commit";
        }
    }
}
