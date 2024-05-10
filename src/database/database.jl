using SQLite
#define tables 





function create_db(path)

    # Create database connection
    db = SQLite.DB(path)

    SQLite.execute(db, "PRAGMA foreign_keys=ON;")
    create_Experiments = """
    CREATE TABLE Experiments (
        ExpID TEXT PRIMARY KEY, 
        Atmosphere TEXT,
        Temperature REAL,
        Unit TEXT
    );
    """
    
    create_Runs= """
    CREATE TABLE Runs ( 
        RunID TEXT PRIMARY KEY,
        ExpID TEXT, 
        LabwareID TEXT,
        Position INTEGER,
        Controls Text, 
        Blanks Text,
        FOREIGN KEY (ExpID) REFERENCES Experiments(ExpID) ON UPDATE CASCADE ON DELETE RESTRICT
        FOREIGN KEY (LabwareID) REFERENCES Labware(LabwareID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    
    """
    # SQL command to create Runs table
    
    
    
    
    create_Ingredients = """
        CREATE TABLE Ingredients ( 
            Name TEXT PRIMARY KEY,
            Molar_Mass REAL, 
            Class TEXT
        ); 
    
    
    
    """
    
        ### CompositionID needs to have a key to the Stocks table
        create_Compositions = """
        CREATE TABLE Compositions (
            CompositionID TEXT, 
            IngredientID TEXT,
            Concentration REAL,
            Unit TEXT,
            PRIMARY KEY (CompositionID, IngredientID),
            FOREIGN KEY(IngredientID) REFERENCES Ingredients(Name) ON UPDATE CASCADE ON DELETE RESTRICT 
        );
        """
    
    create_Stocks = """
    CREATE TABLE Stocks (
        StockID TEXT PRIMARY KEY,
        CompositionID TEXT,
        Quantity REAL,
        Unit TEXT,
        LabwareID TEXT,
        Position Integer,
        IsPrimary Integer, 
        FOREIGN KEY(CompositionID) REFERENCES Compositions(CompositionID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(LabwareID) REFERENCES Labware(LabwareID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """
    
    
    # In the abscense of a primary key, SQLite adds an implicit collumn called rowid that serves as the primary key. We don't need a primary key for this table other than to track how many dispense operations we have completed. 
    create_Dispenses= """
    CREATE TABLE Dispenses( 
        Source TEXT,
        Destination TEXT, 
        Quantity REAL,
        Unit TEXT,
        Instrument TEXT,
        Channel INTEGER,
        Time TEXT,
        FOREIGN KEY(Source) REFERENCES Stocks(StockID) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY(Destination) REFERENCES Stocks(STockID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """
    
    
    create_Containers="""
    CREATE TABLE Containers( 
        Name TEXT PRIMARY KEY,
        Volume REAL,
        Unit TEXT,
        Rows INTEGER,
        Cols INTEGER,
        Vendor TEXT,
        Catalog TEXT
    );
    """
    create_Labware="""
    CREATE TABLE Labware(
        LabwareID TEXT PRIMARY KEY,
        ContainerID TEXT,
        FOREIGN KEY(ContainerID) REFERENCES Containers(Name) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """

    create_Movements="""
    CREATE TABLE Movements(
        LabwareID TEXT,
        Location TEXT,
        Time TEXT,
        FOREIGN KEY(LabwareID) REFERENCES Labware(LabwareID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """

    create_Reads="""
    CREATE TABLE Reads(
        LabwareID TEXT,
        Position Integer,
        Instrument TEXT,
        Type TEXT,
        Value REAL,
        Unit TEXT,
        Time Text,
        FOREIGN KEY(LabwareID) REFERENCES Labware(LabwareID) ON UPDATE CASCADE ON DELETE RESTRICT
    );
    """

    SQLite.execute(db,create_Containers)
    SQLite.execute(db,create_Labware)
    SQLite.execute(db, create_Ingredients)
    SQLite.execute(db,create_Compositions)
    SQLite.execute(db,create_Stocks)
    SQLite.execute(db, create_Experiments)
    SQLite.execute(db, create_Runs)
    SQLite.execute(db, create_Dispenses)
    SQLite.execute(db, create_Movements)
    SQLite.execute(db, create_Reads)

end

function upload_db(db, container::Container)
    name=container.name
    volume=container.volume
    vol_val=ustrip(volume)
    vol_unit=string(unit(volume))
    rows,cols=container.shape
    vendor=container.vendor
    catalog=container.catalog
    SQLite.execute(db,"""
    INSERT OR IGNORE INTO Containers (Name, Volume, Unit, Rows, Cols, Vendor, Catalog)
    Values (?,?,?,?,?,?,?)
     """, (name,vol_val,vol_unit,rows,cols,vendor,catalog))
end 

function upload_db(db,labware::Labware)
    id=labware.id
    container=labware.container.name
    SQLite.execute(db,"""
    INSERT OR IGNORE INTO Labware (LabwareID,ContainerID)
    Values(?,?)""",(id,container))
    if labware.time ==missing
    SQLite.execute(db,"""
    INSERT OR IGNORE INTO Movements(LabwareID,Location,Time)
    Values(?,?,?)""",(id,container,labware.location,labware.time))
    else 
        SQLite.execute(db,"""
        INSERT OR IGNORE INTO Movements(LabwareID,Location,Time)
        Values(?,?,?)""",(id,container,labware.location,string(labware.time)))
    end 
end 

function upload_db(db,ingredient::Ingredient)
    name=ingredient.name
    class_val=string(ingredient.class)
    if typeof(ingredient.molecular_weight)==typeof(missing)
        SQLite.execute(db,"""
        INSERT OR IGNORE INTO Ingredients (Name, Molar_Mass, Class)
        Values(?, ?, ?)
        """, (name,ingredient.molecular_weight, class_val))
    else
        molar_mass=uconvert(u"g/mol",ingredient.molecular_weight)
        mm_val=AbstractFloat(ustrip(molar_mass))
        SQLite.execute(db,"""
        INSERT OR IGNORE INTO Ingredients (Name, Molar_Mass, Class)
        Values(?, ?, ?)
        """, (name,mm_val, class_val))
    end 
end 

function upload_db(db,composition::Composition)
    ings=collect(keys(composition.ingredients))
    for ing in ings 
        conc=composition.ingredients[ing]
        conc_val=AbstractFloat(ustrip(conc))
        conc_unit=string(unit(conc))
        SQLite.execute(db,"""
        INSERT OR IGNORE INTO Compositions (CompositionID,IngredientID,Concentration,Unit)
        Values(?,?,?,?)""",
        (composition.name,ing.name,conc_val,conc_unit))
    end 
end 

function upload_db(db,stock::Stock)
    id=stock.id
    comp_id=stock.composition.id
    upload_db(db,stock.composition) # upload if needed
    upload_db(db,stock.labware) # upload if needed 
    quantity=stock.quantity
    quant_val=AbstractFloat(ustrip(quantity))
    quant_unit=string(unit(quantity))
    labware=stock.labware.id
    position=stock.position
    isprimary=Int(stock.isprimary)
    SQLite.execute(db,"""
    INSERT OR IGNORE INTO Stocks (StockID,CompositionID,Quantity,Unit,LabwareID,Position,IsPrimary)
    Values(?,?,?,?,?,?,?)""",
    (id,comp_id,quant_val,quant_unit,labware,position,isprimary))
end 


function upload(db,experiment::Experiment)
    id=experiment.id 
    env=experiment.environment 
    temperature=env.temperature
    tempval=AbstractFloat(ustrip(temperature))
    tempunit=string(unit(temperature))
    SQLite.execute(db,"""
    INSERT OR IGNORE INTO Experiments(ExpID,Atmosphere,Temperature,Unit)
    Values(?,?,?)
    """,(id,string(env.atmosphere),tempval,tempunit))

    for run in experiment.runs 
        run_id=run.id 
        labware=run.labare.id
        position=run.position
        controls=join(run.controls,",") # parse string when querying 
        blanks=join(run.blanks,",")
        SQLite.execute(db,"""
        INSERT OR IGNORE INTO Runs(RunID, ExpID,LabwareID,Position,Controls,Blanks)
        Values(?,?,?,?,?,?)""",
        (run_id,id,labware,position,controls,blanks))
    end 
end 


function upload_db(db,dispense::Dispense)
    source=dipsnese.source.id
    destination=dispense.destination.id
    quantity=dispense.quantity
    quant_val=AbstractFloat(ustrip(quantity))
    quant_unit=string(unit(quantity))
    instrument=dispense.instrument
    channel=dispense.channel
    time=string(dispense.time)
    SQLite.execute(db,"""
    INSERT OR IGNRE INTO Dispenses(Source,Destination,Quantity,Unit,Instrument,Channel,Time)
    Values(?,?,?,?,?,?,?)
    """,(source,destination,quant_val,quant_unit,instrument,channel,time))
end 



