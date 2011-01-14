------------------------------------------------------------------------------
-- Topo programs result cache
------------------------------------------------------------------------------

CREATE TABLE topo.cache (
        key         TEXT,               -- hash key
        command     TEXT,               -- command called with arguments
        file        TEXT,               -- file containing cached command output
        hit         INTEGER,            -- number of calls for this entry
        runtime     INTEGER,            -- time taken for last command execution
        lastread    TIMESTAMP           -- last time the entry was read
                    WITHOUT TIME ZONE,
        lastrun     TIMESTAMP           -- last time the entry was written
                    WITHOUT TIME ZONE,
        PRIMARY KEY (key)
) ;

GRANT ALL ON topo.cache TO dns ;
