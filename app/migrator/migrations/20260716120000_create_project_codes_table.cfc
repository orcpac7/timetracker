component extends="wheels.migrator.Migration" hint="Create projectCodes table (billing codes)" {
    function up() {
        transaction {
            try {
                t = createTable(name="projectCodes");
                t.integer(columnNames="code", allowNull=false);
                t.string(columnNames="description", default="", allowNull=false, limit=255);
                t.string(columnNames="color", default="##6b7280", allowNull=false, limit=20);
                t.boolean(columnNames="active", default=true, allowNull=false);
                t.timestamps();
                t.create();
                // Each billing code is unique.
                addIndex(table="projectCodes", columnNames="code", unique=true);
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
            dropTable("projectCodes");
            transaction action="commit";
        }
    }
}
