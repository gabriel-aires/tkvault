CREATE TABLE IF NOT EXISTS "login" (
	"master_sha1"	TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS "credential" (
	"name"	    TEXT NOT NULL UNIQUE,
	"identity"	TEXT,
	"password"	TEXT
);

CREATE TABLE IF NOT EXISTS "crypt" (
	"init_vector"	TEXT NOT NULL
);