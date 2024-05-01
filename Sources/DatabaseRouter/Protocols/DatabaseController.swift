import CasePaths

/// Represents a controller for the database that is able to be wrapped in a ``DatabaseRouter``.
public protocol DatabaseController: CasePathable, RouteController { }
