CREATE TABLE IF NOT EXISTS "login" (
	"master_sha1"	TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS "credential" (
    "name"	        TEXT NOT NULL UNIQUE,
    "name_key"      TEXT,
    "name_time"     INTEGER,
    "identity"	    TEXT,
    "identity_key"  TEXT,
    "identity_time" INTEGER,
    "password"	    TEXT,
    "password_key"  TEXT,
    "password_time" INTEGER
);