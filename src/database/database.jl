using SQLite , DBInterface 


function create_db(path)
    # Create database connection
    db = SQLite.DB(path)
    DBInterface.execute(db, "PRAGMA foreign_keys = ON;")
    
    
    create_Experiments = """
    CREATE TABLE Experiments (
        ID INTEGER PRIMARY KEY NOT NULL ,
        Name Text, 
        User TEXT,
        IsPublic INTEGER,
        Time TEXT
    );
    """
    
    create_Runs= """
    CREATE TABLE Runs ( 
        ID INTEGER PRIMARY KEY NOT NULL ,
        ExperimentID INTEGER, 
        LocationID INTEGER,
        Controls Text, 
        Blanks Text,
        FOREIGN KEY (ExperimentID) REFERENCES Experiments(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY (LocationID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    
    """
    

    create_Components="""
        CREATE TABLE Components(
            Name TEXT Primary KEY
            );
    """


    create_CacheSets="""
    CREATE TABLE CacheSets(
        ID INTEGER PRIMARY KEY NOT NULL,
        ParentID INTEGER,
        ChildSetID INTEGER,
        AttributeSetID INTEGER,
        StockID INTEGER,
        IsLocked INTEGER,
        IsActive INTEGER,
        FOREIGN KEY(ChildSetID) REFERENCES CachedChildSets(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(ParentID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(AttributeSetID) REFERENCES CachedAttributeSets(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(StockID) REFERENCES CachedStocks(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
"""

    create_Caches="""
    Create Table Caches(
        ID INTEGER PRIMARY KEY NOT NULL,
        LocationID INTEGER,
        CacheSetID INTEGER,
        LedgerID, INTEGER,
        FOREIGN KEY(LocationID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(CacheSetID) REFERENCES CacheSets(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(LedgerID) REFERENCES Ledger(ID) ON UPDATE CASCADE ON DELETE RESTRICT

    );

"""

    create_CachedChildSets="""
    CREATE TABLE CachedChildSets(
        ID INTEGER PRIMARY KEY NOT NULL
    );
    """

    create_CachedChildren="""
    CREATE TABLE CachedParents(
        ID INTEGER PRIMARY KEY NOT NULL,
        CachedChildSetID INTEGER,
        ChildID INTEGER,
        FOREIGN KEY(CachedChildSetID) REFERENCES CachedChildSets(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(ChildID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """

    create_CachedAttributeSets="""
    CREATE TABLE CachedAttributeSets(
        ID INTEGER PRIMARY KEY NOT NULL
        );
    """
    create_CachedAttributes="""
    CREATE TABLE CachedAttributes(
        ID INTEGER PRIMARY KEY NOT NULL,
        AttributeSetID INTEGER,
        AttributeID TEXT,
        Value REAL,
        Unit TEXT,
        FOREIGN KEY(AttributeSetID) REFERENCES CachedAttributeSets(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(AttributeID) REFERENCES Attributes(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """

    create_CachedStocks="""
    CREATE TABLE CachedStocks(
        ID INTEGER PRIMARY KEY NOT NULL
    );
    """

    create_CachedComponents="""
    CREATE TABLE CachedComponents(
        ID INTEGER PRIMARY KEY NOT NULL,
        StockID INTEGER,
        ComponentID TEXT, 
        Quantity REAl,
        Unit TEXT,
        FOREIGN KEY(StockID) REFERENCES CachedStocks(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(ComponentID) REFERENCES Components(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
"""



    create_LocationTypes="""
    CREATE TABLE LocationTypes( 
        Name TEXT PRIMARY KEY
    );
    """
  
    create_Locations="""
    CREATE TABLE Locations(
        ID INTEGER PRIMARY KEY NOT NULL,
        Name TEXT,
        Type TEXT,
        FOREIGN KEY(Type) REFERENCES LocationTypes(Name) ON UPDATE CASCADE ON DELETE RESTRICT 
    )
    """

    create_Attributes="""
    CREATE TABLE Attributes(
        Attribute TEXT PRIMARY KEY
    );
    """

    create_EnvironmentAttributes="""
    CREATE TABLE EnvironmentAttributes(
        ID Integer PRIMARY KEY NOT NULL,
        LedgerID INTEGER,
        LocationID INTEGER,
        Attribute TEXT,
        Value Real,
        Unit,
        Time TEXT,
        FOREIGN KEY(LedgerID) REFERENCES Ledger(ID) ON UPDATE CASCADE ON DELETE RESTRICT, 
        FOREIGN KEY(Attribute) REFERENCES Attributes(Attribute) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY (LocationID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT 
    );
    """


    

    create_Configurations="""
    CREATE TABLE Configurations(
        ID TEXT PRIMARY KEY,
        Configuration TEXT,
        InstrumentID TEXT,
        FOREIGN KEY(InstrumentID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """
 
    create_Transfers= """
    CREATE TABLE Transfers(
        ID INTEGER PRIMARY KEY NOT NULL ,
        LedgerID INTEGER,
        Source INTEGER,
        Destination INTEGER, 
        Quantity REAL,
        Unit TEXT,
        Time TEXT,
        Configuration TEXT, 
        FOREIGN KEY(Source) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(Destination) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(LedgerID) REFERENCES Ledger(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(Configuration) REFERENCES Configurations(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        CHECK (Source != Destination)
    );
    """
    



    create_Movements="""
    CREATE TABLE Movements(
        ID INTEGER PRIMARY KEY NOT NULL ,
        LedgerID INTEGER,
        Child INTEGER,
        Parent INTEGER,
        Time TEXT, 
        FOREIGN KEY(Child) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(Parent) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(LedgerID) REFERENCES Ledger(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        CHECK (Parent != Child) 
    );
    """

    create_Locks="""
    CREATE TABLE Locks(
        ID INTEGER PRIMARY KEY NOT NULL,
        LedgerID INTEGER,
        LocationID INTEGER,
        IsLocked INTEGER,
        Time TEXT,
        FOREIGN KEY(LocationID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(LedgerID) REFERENCES Ledger(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """

    

    create_Reads="""
    CREATE TABLE Reads(
        ID INTEGER PRIMARY KEY NOT NULL ,
        LedgerID INTEGER,
        LocationID INTEGER,
        Type TEXT,
        Value REAL,
        Unit TEXT,
        Time Text,
        Configuration TEXT,
        FOREIGN KEY(LocationID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(LedgerID) REFERENCES Ledger(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(Configuration) REFERENCES Configurations(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """

    create_Ledger="""
    CREATE TABLE Ledger(
        ID INTEGER PRIMARY KEY NOT NULL ,
        Time TEXT
    );
    """

    create_Barcodes="""
    CREATE TABLE Barcodes(
        Barcode TEXT PRIMARY KEY,
        LocationID Integer,
        Name TEXT,
        FOREIGN KEY (LocationID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT  
    );
    """

    create_Tags="""
    CREATE TABLE Tags(
        ID INTEGER PRIMARY KEY NOT NULL ,
        LedgerID INTEGER,
        Comment TEXT,
        FOREIGN KEY(LedgerID) REFERENCES Ledger(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """

    create_Activity="""
    CREATE TABLE Activity(
        ID INTEGER PRIMARY KEY NOT NULL,
        LedgerID INTEGER,
        LocationID INTEGER,
        IsActive INTEGER,
        Time TEXT,
        FOREIGN KEY(LedgerID) REFERENCES Ledger(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(LocationID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """


    create_Protocols="""
    CREATE TABLE Protocols( 
        ID INTEGER PRIMARY KEY NOT NULL, 
        ExperimentID INTEGER,
        Name Text,
        EstimatedTime Real,
        FOREIGN KEY (ExperimentID) REFERENCES Experiments(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        Unique(ExperimentID,Name)
    );
    """

    create_Encumbrances="""
    CREATE TABLE Encumbrances( 
        ID INTEGER PRIMARY KEY NOT NULL,
        ProtocolID INTEGER,  
        FOREIGN KEY(ProtocolID) REFERENCES Protocols(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """

    create_EncumbranceEnforcement="""
    CREATE TABLE EncumbranceEnforcement(
        ID INTEGER PRIMARY KEY NOT NULL ,
        LedgerID INTEGER,
        EncumbranceID INTEGER,
        IsEnforced INTEGER,
        Time TEXT,
        FOREIGN KEY(EncumbranceID) REFERENCES Encumbrances(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(LedgerID) REFERENCES Ledger(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """



    create_EncumberedCaches="""
    CREATE TABLE EncumberedCaches(
        ID INTEGER PRIMARY KEY NOT NULL,
        EncumbranceID INTEGER,
        LocationID INTEGER,
        CacheSetID INTEGER,
        FOREIGN KEY(CacheSetID) REFERENCES CacheSets(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(EncumbranceID) REFERENCES Encumbrances(ID) ON UPDATE CASCADE ON DELETE RESTRICT
        FOREIGN KEY(LocationID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
        """







    create_EncumberedTransfers="""
    CREATE TABLE EncumberedTransfers( 
        ID INTEGER PRIMARY KEY NOT NULL,
        EncumbranceID INTEGER,
        Source INTEGER,
        Destination INTEGER, 
        Quantity REAL,
        Unit TEXT,
        Configuration TEXT,
        FOREIGN KEY(Source) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(Destination) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(EncumbranceID) REFERENCES Encumbrances(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(Configuration) REFERENCES Configuration(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        CHECK (Source != Destination)
    );
    """



    create_EncumberedEnvironments="""
    CREATE TABLE EncumberedEnvironments( 
        ID INTEGER PRIMARY KEY NOT NULL,
        EncumbranceID INTEGER,
        LocationID INTEGER,
        Attribute TEXT,
        Value Real,
        Unit,
        FOREIGN KEY(EncumbranceID) REFERENCES Encumbrances(ID) ON UPDATE CASCADE ON DELETE RESTRICT, 
        FOREIGN KEY(Attribute) REFERENCES Attributes(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY (LocationID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT 
    )
    """

    create_EncumberedMovements="""
    CREATE TABLE EncumberedMovements(
        ID INTEGER PRIMARY KEY NOT NULL,
        EncumbranceID INTEGER,
        Child INTEGER,
        Parent INTEGER,
        FOREIGN KEY(Child) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(Parent) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(EncumbranceID) REFERENCES Encumbrances(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        CHECK (Parent != Child) 
    )
    """ 

    create_EncumberedActivity="""
    CREATE TABLE EncumberedActivity(
        ID INTEGER PRIMARY KEY NOT NULL,
        EncumbranceID INTEGER,
        LocationID INTEGER,
        IsActive INTEGER,
        FOREIGN KEY(EncumbranceID) REFERENCES Encumbrances(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(LocationID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """

    create_EncumberedLocks="""
    CREATE TABLE EncumberedLocks(
        ID INTEGER PRIMARY KEY NOT NULL,
        EncumbranceID INTEGER,
        LocationID INTEGER,
        IsLocked INTEGER,
        FOREIGN KEY(EncumbranceID) REFERENCES Encumbrances(ID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(LocationID) REFERENCES Locations(ID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """

    #main 
    DBInterface.execute(db,create_Ledger)
    DBInterface.execute(db,create_Barcodes)
    DBInterface.execute(db,create_LocationTypes)
    DBInterface.execute(db,create_Locations)
    DBInterface.execute(db, create_Components)
    DBInterface.execute(db,create_Attributes)
    DBInterface.execute(db,create_EnvironmentAttributes)
    DBInterface.execute(db,create_Configurations)
    #operations
    DBInterface.execute(db, create_Transfers)
    DBInterface.execute(db,create_Movements)
    DBInterface.execute(db, create_Reads)
    DBInterface.execute(db, create_Activity)
    DBInterface.execute(db,create_Locks)
    DBInterface.execute(db,create_Tags)
    # caching 
    DBInterface.execute(db,create_CachedChildSets)
    DBInterface.execute(db,create_CachedChildren)
    DBInterface.execute(db,create_CachedAttributeSets)
    DBInterface.execute(db,create_CachedAttributes)
    DBInterface.execute(db,create_CachedStocks)
    DBInterface.execute(db,create_CachedComponents)
    DBInterface.execute(db,create_CacheSets)
    DBInterface.execute(db,create_Caches)

    # experiments and encumbrances
    DBInterface.execute(db, create_Experiments)
    DBInterface.execute(db, create_Runs)
    DBInterface.execute(db,create_Protocols)
    DBInterface.execute(db,create_Encumbrances)
    DBInterface.execute(db,create_EncumberedTransfers)
    DBInterface.execute(db,create_EncumberedCaches)
    DBInterface.execute(db,create_EncumberedLocks)
    DBInterface.execute(db,create_EncumberedMovements)
    DBInterface.execute(db,create_EncumberedEnvironments)
    DBInterface.execute(db,create_EncumberedActivity)
    DBInterface.execute(db,create_EncumbranceEnforcement)

    DBInterface.execute(db,"""INSERT INTO Ledger(Time) Values(datetime('now'))""")
    DBInterface.execute(db,"""INSERT INTO Tags(LedgerID,Comment) Values(1,'Big Bang')""")
end
file="./src/database/test_create_db.db"
rm(file)
create_db(file)