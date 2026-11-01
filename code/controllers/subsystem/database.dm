/datum/controller/subsystem/database
    name = "Eciv13 External Database"
    var/database/db = null
    var/connected = FALSE
    
    // Connection config (adjust to your external SQL server details)
    var/host = "localhost"
    var/port = 3306
    var/dbname = "eciv13"
    var/user = "eciv13_user"
    var/pass = "your_secure_password"

/datum/controller/subsystem/database/Initialize()
    connect_to_db()
    return ..()

/datum/controller/subsystem/database/proc/connect_to_db()
    // Open connection to external SQL database
    db = new()
    var/connection_string = "dbi:mysql:[dbname]:[host]:[port]"
    
    if (db.Connect(connection_string, user, pass))
        connected = TRUE
        log_world("DATABASE: Successfully connected to external SQL server at [host]:[port].")
        setup_tables()
    else
        connected = FALSE
        log_world("DATABASE ERROR: Failed to connect to external SQL server: [db.ErrorMsg()]")

/datum/controller/subsystem/database/proc/setup_tables()
    if (!connected) return
    
    // Create tables if they don't exist yet
    var/query_admins = "CREATE TABLE IF NOT EXISTS eciv13_admins (ckey VARCHAR(32) PRIMARY KEY, rank VARCHAR(64));"
    var/query_bans = "CREATE TABLE IF NOT EXISTS eciv13_bans (ckey VARCHAR(32) PRIMARY KEY, reason TEXT, banner VARCHAR(32), date TIMESTAMP);"
    
    db.Execute(query_admins)
    db.Execute(query_bans)

// --- ADMIN DATABASE QUERIES ---
/datum/controller/subsystem/database/proc/get_admin_rank(var/ckey)
    if (!connected) return null
    ckey = lowertext(ckey)
    
    var/dbi_query/query = db.NewQuery("SELECT rank FROM eciv13_admins WHERE ckey = '[sql_sanitize_text(ckey)]'")
    if (query.Execute())
        while (query.NextRow())
            var/list/row = query.GetRowData()
            return row["rank"]
    return null

/datum/controller/subsystem/database/proc/save_admin(var/ckey, var/rank)
    if (!connected) return
    ckey = lowertext(ckey)
    
    var/dbi_query/query = db.NewQuery("REPLACE INTO eciv13_admins (ckey, rank) VALUES ('[sql_sanitize_text(ckey)]', '[sql_sanitize_text(rank)]')")
    query.Execute()

// --- BAN DATABASE QUERIES ---
/datum/controller/subsystem/database/proc/is_banned(var/ckey)
    if (!connected) return null
    ckey = lowertext(ckey)
    
    var/dbi_query/query = db.NewQuery("SELECT reason FROM eciv13_bans WHERE ckey = '[sql_sanitize_text(ckey)]'")
    if (query.Execute())
        while (query.NextRow())
            var/list/row = query.GetRowData()
            return row["reason"]
    return null

/datum/controller/subsystem/database/proc/add_ban(var/ckey, var/reason, var/banner)
    if (!connected) return
    ckey = lowertext(ckey)
    
    var/dbi_query/query = db.NewQuery("REPLACE INTO eciv13_bans (ckey, reason, banner, date) VALUES ('[sql_sanitize_text(ckey)]', '[sql_sanitize_text(reason)]', '[sql_sanitize_text(banner)]', NOW())")
    query.Execute()

/datum/controller/subsystem/database/proc/remove_ban(var/ckey)
    if (!connected) return
    ckey = lowertext(ckey)
    
    var/dbi_query/query = db.NewQuery("DELETE FROM eciv13_bans WHERE ckey = '[sql_sanitize_text(ckey)]'")
    query.Execute()