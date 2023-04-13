# EssentialFeed

## Cache Requirements
- Retrieve
    ✅ Empty Cache
    ✅ Empty Cache twice returns empty -- no side effects.
    ✅ Non-Empty Cache returns data
    ✅  Non-Empty Cache twice returns same data (no side effects)
    ✅ Error returns invalid data when applicable
    ✅ Error twice return same error

- Insert
    ✅ Insert to empty cache stores data
    ✅ Insert to non-empty cache stores data and overwrites old data
    ✅ Error (e.g. no write permissions)

- Delete
    ✅ does nothing to an empty cache and does not fail
    ✅ empties non-empty cache (wipeout)
    ✅ Error (if applicable, e.g. no delete permissions)
    
- Side-Effects must run **serially** to avoid race conditions (multi-threaded envrionment)
