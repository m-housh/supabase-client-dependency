# ``SupabaseClientDependency``

@Metadata {
    @DocumentationExtension(mergeBehavior: append)
}

## Topics

### Initializers

- ``SupabaseClientDependency/init(client:auth:)``
- ``SupabaseClientDependency/init(configuration:auth:)``

### Deleting rows from the database.

Use one of these methods when you need to delete rows from the database.

- ``SupabaseClientDependency/delete(id:from:)-7land``
- ``SupabaseClientDependency/delete(id:from:)-1i4sk``
- ``SupabaseClientDependency/delete(from:where:)-4o786``
- ``SupabaseClientDependency/delete(from:where:)-8jdy4``
- ``SupabaseClientDependency/delete(from:filteredBy:)-45du5``
- ``SupabaseClientDependency/delete(from:filteredBy:)-4h2x1``

### Fetching rows from the database.

- ``SupabaseClientDependency/fetch(from:where:orderBy:as:)-1loo5``
- ``SupabaseClientDependency/fetch(from:where:orderBy:as:)-1xuvq``
- ``SupabaseClientDependency/fetch(from:filteredBy:orderBy:as:)-92mpq``
- ``SupabaseClientDependency/fetch(from:filteredBy:orderBy:as:)-798bs``

### Fetching single rows from the database.

- ``SupabaseClientDependency/fetchOne(id:from:as:)-4qe76``
- ``SupabaseClientDependency/fetchOne(id:from:as:)-6w380``
- ``SupabaseClientDependency/fetchOne(from:where:as:)-2mxtm``
- ``SupabaseClientDependency/fetchOne(from:where:as:)-21g28``
- ``SupabaseClientDependency/fetchOne(from:filteredBy:as:)-46dvt``
- ``SupabaseClientDependency/fetchOne(from:filteredBy:as:)-5j8gv``

### Inserting rows into the database.

- ``SupabaseClientDependency/insert(_:into:returning:as:)-493ty``
- ``SupabaseClientDependency/insert(_:into:returning:as:)-3pqxp``

### Updating rows in the database.

- ``SupabaseClientDependency/update(id:in:with:returning:as:)-5eoxi``
- ``SupabaseClientDependency/update(id:in:with:returning:as:)-6yo27``
- ``SupabaseClientDependency/update(table:where:values:returning:as:)``
- ``SupabaseClientDependency/update(table:filteredBy:values:returning:as:)-4b6dv``
- ``SupabaseClientDependency/update(table:filteredBy:values:returning:as:)-3xzmg``

### Working directly with the supabase database.

Use this method when you need to do advanced queries / operations on the database.

- ``SupabaseClientDependency/withDatabase(perform:)``

