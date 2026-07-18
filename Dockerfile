FROM ortussolutions/commandbox:latest

WORKDIR /app

# Copy the app into the image; runtime compose will typically mount the host folder for live development.
COPY . /app

# Install SQLite JDBC driver so Lucee can use the sqlite `org.sqlite.JDBC` class
RUN mkdir -p /usr/local/lib/CommandBox/server/serverHome/lucee-5.4.4.38/WEB-INF/lucee-server/context/lib \
 && curl -fsSL -o /usr/local/lib/CommandBox/server/serverHome/lucee-5.4.4.38/WEB-INF/lucee-server/context/lib/sqlite-jdbc.jar https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.39.3.0/sqlite-jdbc-3.39.3.0.jar \
 && chmod 644 /usr/local/lib/CommandBox/server/serverHome/lucee-5.4.4.38/WEB-INF/lucee-server/context/lib/sqlite-jdbc.jar

EXPOSE 8080

CMD ["box", "server", "start", "--config=lucee.json", "--background=false", "--host=0.0.0.0", "--port=8080"]
