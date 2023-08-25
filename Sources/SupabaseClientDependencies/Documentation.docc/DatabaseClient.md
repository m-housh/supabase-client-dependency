# ``SupabaseClientDependencies/SupabaseClientDependency/DatabaseClient``

@Metadata {
  @DocumentationExtension(mergeBehavior: append)
}

## Topics

### Deleting Items

The following methods are convenience methods for deleting items from the database.

- ``delete(id:from:)``
- ``delete(from:where:)``
- ``delete(from:filteredBy:)``

### Fetching Items

The following methods are convenience methods for fetching items from the database.

- ``fetch(from:where:orderBy:decoding:)``
- ``fetch(from:filteredBy:orderBy:decoding:)``

### Fetching Single Items

The following methods are convenience methods for fetching single items from the database.

- ``fetchOne(id:from:decoding:)``
- ``fetchOne(from:where:decoding:)``
- ``fetchOne(from:filteredBy:decoding:)``

### Inserting Single Items

The following methods are convenience methods for inserting single items into the database.

- ``insert(_:into:returning:decoding:)-731w6``

### Inserting Mutliple Items

The following methods are convenience methods for inserting multiple items into the database.

- ``insert(_:into:returning:decoding:)-630da``

### Updating Items

The following methods are convenience methods for updating items in the database.

- ``update(id:in:with:returning:decoding:)``
- ``update(table:where:values:returning:decoding:)``
- ``update(table:filteredBy:values:returning:decoding:)``

### Remote Functions

The following methods are convenience methods for calling a remote function on the database.

``rpc(_:params:count:decoding:perform:)``

### Build Custom Queries

The following methods allow you to build a custom query for the database.

``from(_:decoding:perform:)``
