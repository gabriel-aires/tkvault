CREATE TABLE IF NOT EXISTS "login" (
	"master_sha1"	TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS "credential" (
	"name"	        TEXT NOT NULL UNIQUE,
    "name_key"      TEXT,
	"identity"	    TEXT,
    "identity_key"  TEXT,    
	"password"	    TEXT,
    "password_key"  TEXT
);