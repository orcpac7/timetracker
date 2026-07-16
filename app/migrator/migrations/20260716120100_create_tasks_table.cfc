component extends="wheels.migrator.Migration" hint="Create tasks table (work items / cards)" {
    function up() {
        transaction {
            try {
                t = createTable(name="tasks");
                // Every task belongs to exactly one billing code -> projectCode_id (NOT NULL).
                // foreignKey=false: SQLite's adapter emits invalid FK-constraint DDL, and SQLite
                // doesn't enforce FKs by default anyway; integrity is handled at the model layer.
                t.references(columnNames="projectCode", allowNull=false, foreignKey=false);
                t.string(columnNames="title", default="", allowNull=false, limit=255);
                // Azure DevOps card URLs can be long -> use text.
                t.text(columnNames="url", allowNull=true);
                // Work item id parsed from the pasted URL (e.g. .../_workitems/edit/12345).
                t.integer(columnNames="workItemId", allowNull=true);
                t.string(columnNames="status", default="open", allowNull=false, limit=20);
                t.timestamps();
                t.create();
                addIndex(table="tasks", columnNames="projectCode_id");
                addIndex(table="tasks", columnNames="workItemId");
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
            dropTable("tasks");
            transaction action="commit";
        }
    }
}
