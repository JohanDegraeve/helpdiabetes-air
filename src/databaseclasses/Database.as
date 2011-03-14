/**
	Copyright (C) 2011  hippoandfriends
	
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
	
*/
package databaseclasses
{
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.EventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.Responder;
	import flash.xml.XMLDocument;
	
	import views.FoodCounterView;
	
	
	/**
	 * Database class is a singleton
	 */ 
	public final class Database 
	{
		private static var instance:Database = new Database();
		
		public var aConn:SQLConnection;		

		private var sqlStatement:SQLStatement;
		
		
		/*private const MG_DL:String = "mg/dL";
		private const mmol:String = "mmol";*/
		private  var dbFile:File  = File.applicationStorageDirectory.resolvePath("HelpDiabetes.db");
		private var fooditemList:XMLList;
		
		
		private const CREATE_TABLE_FOODITEMS:String = "CREATE TABLE IF NOT EXISTS fooditems (itemid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																							"description TEXT NOT NULL)";
		private const CREATE_TABLE_UNITS:String = "CREATE TABLE IF NOT EXISTS units (unitid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																					"fooditems_itemid INTEGER NOT NULL, " +
																					"description TEXT NOT NULL, " +
																					"standardamount INTEGER, " +
																					"weight INTEGER, " +
																					"kcal INTEGER, " +
																					"protein REAL, " +
																					"carbs REAL NOT NULL, " +
																					"fat REAL)";
		private const CREATE_TABLE_EVENTS:String = "CREATE TABLE IF NOT EXISTS events (eventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																					  "exerciseevents_exerciseeventid INTEGER," +
																					  "medicinevents_medicineventid INTEGER, " +
																					  "bloodglucoseevents_bloodglucoseeventid INTEGER, " +
																					  "mealevents_mealeventid INTEGER, " +
																					  "creationtimestamp TIMESTAMP " +
																					  ")";
		private const CREATE_TABLE_EXERCISE_EVENTS:String = "CREATE TABLE IF NOT EXISTS exerciseevents (exerciseeventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																									   "level TEXT, " +
																									   "comment_2 TEXT)";
		private const CREATE_TABLE_BLOODGLUCOSE_EVENTS:String = "CREATE TABLE IF NOT EXISTS bloodglucoseevents (bloodglucoseeventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																											   "unit TEXT NOT NULL, " +
																											   "value INTEGER NOT NULL)";
		private const CREATE_TABLE_MEDICIN_EVENTS:String = "CREATE TABLE IF NOT EXISTS medicinevents (medicineventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																									 "medicinname TEXT NOT NULL, " +
																									 "amount REAL NOT NULL)";		
		private const CREATE_TABLE_MEAL_EVENTS:String = "CREATE TABLE IF NOT EXISTS mealevents (mealeventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																							   "mealtype TEXT NOT NULL, " +
																							   "lastmodifiedtimestamp TIMESTAMP NOT NULL)";		
		private const CREATE_TABLE_SELECTED_FOODITEMS:String = "CREATE TABLE IF NOT EXISTS selectedfooditems (selectedfooditemid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																											 "mealevents_mealeventid INTEGER NOT NULL, " +
																											 "itemdescription TEXT NOT NULL, " +
																											 "unitdescription TEXT, " +
																											 "standardamount INTEGER, " +
						 	    																			 "weight INTEGER, " +
																					   					     "kcal INTEGER, " +
																											 "protein REAL, " +
																											 "carbs REAL NOT NULL, " +
																											 "fat REAL)";		
		private const CREATE_TABLE_TEMPLATE_FOODITEMS:String = "CREATE TABLE IF NOT EXISTS templatefooditems (templateitemid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																											 "templates_templateid INTEGER NOT NULL, " +
																											 "itemdescription TEXT NOT NULL, " +
																											 "unitdescription TEXT, " +
																											 "standardamount INTEGER, " +
																											 "weight INTEGER, " +
																											 "kcal INTEGER, " +
																											 "protein REAL, " +
																											 "carbs REAL NOT NULL, " +
																											 "fat REAL)";		
		private const CREATE_TABLE_TEMPLATES:String = "CREATE TABLE IF NOT EXISTS templates (templateid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																							"name TEXT NOT NULL)";
		private const CREATE_TABLE_SOURCE:String = "CREATE TABLE IF NOT EXISTS source (source TEXT)";

		
		private const GET_FOODITEM:String = "SELECT * FROM fooditems WHERE itemid = :itemid";
		private const GET_ALLFOODITEMS:String = "SELECT * FROM fooditems";
		private const COUNT_ALLFOODITEMS:String = "SELECT itemid FROM fooditems";
		private const INSERT_SOURCE:String = "INSERT INTO source (source) VALUES (:source)";
		private const INSERT_FOODITEM:String = "INSERT INTO fooditems (description) VALUES (:description)";
		private const INSERT_UNIT:String = "INSERT INTO units (fooditems_itemid," +
											"description," +
											"standardamount," +
											"weight," +
											"kcal," +
											"protein," +
											"carbs," +
											"fat) VALUES " +
											"(:description," +
											":standardamount," +
											":weight," +
											":kcal," +
											":protein," +
											":carbs," +
											":fat)";


		/**
		 * constructor, should not be used, use getInstance()
		 */
		public function Database()
		{
			if (instance != null) {
				throw new Error("Database class can only be accessed through Database.getInstance()");	
			}
			instance = this;
		}
		
		/**
		 * returns the Database Singleton
		 */
		public static function getInstance():Database {
			if (instance == null) instance = new Database();
			return instance;
		}
		
		/**
		 * gets the creation data of the database based on db file creation date
		 */
		public function getCreationDateOfDatabase():Date
		{
			var d:Date;
			if ( this.dbFile && this.dbFile.exists )
			{
				d = dbFile.creationDate;
			}
			return d;
		}
		
		/**
		 * deletes the database
		 */
		public function deleteDatabase():Boolean
		{
			var success:Boolean = false;
			if ( this.dbFile ) 
			{				
				if ( this.aConn && this.aConn.connected )
				{
					this.aConn.close(null);	
				}
				
				var fs:FileStream = new FileStream();
				try 
				{
					fs.open(this.dbFile,FileMode.UPDATE);
					while ( fs.bytesAvailable )	
					{
						fs.writeByte(Math.random() * Math.pow(2,32));						
					}
					trace("writing complete");
					fs.close();
					this.dbFile.deleteFile();
					trace("deletion complete");					
					success = true;
				}
				catch (e:Error)
				{
					trace(e.name + ", " + e.message );
					fs.close();
				}				
			}
			return success;
		}
		
		/**
		 * Create the asynchronous connection to the database, then create the tables
		 * 
		 * @param responder:DatabaseResponder Will dispatch result or error events when the tables are created. Dispatches an event with data TABLES_CREATED 
		 *  when all tables have been successfully created. 
		 **/
		public function init(responder:Responder):void
		{
			
			this.aConn = new SQLConnection();
			this.aConn.addEventListener(SQLEvent.OPEN, onConnOpen);
			this.aConn.addEventListener(SQLErrorEvent.ERROR, onConnError);
			this.aConn.openAsync(dbFile, SQLMode.CREATE);
			
			function onConnOpen(se:SQLEvent):void
			{
				trace("SQL Connection successfully opened. Database:0001");
				aConn.removeEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.removeEventListener(SQLErrorEvent.ERROR, onConnError);	
				createTables();
			}
			
			function onConnError(see:SQLErrorEvent):void
			{
				trace("SQL Error while attempting to open database. Database:0002");
				aConn.removeEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.removeEventListener(SQLErrorEvent.ERROR, onConnError);
			}
			
		}
		
		
		/**
		 * Will execute SQL that will either create the tables in a fresh database or return, if they're already creatd.
		 **/
		public function createTables():void
		{						
			sqlStatement = new SQLStatement();
			sqlStatement.sqlConnection = aConn;
			createFoodItemsTable();				
		}
		
		/**
		 * Creates the fooditems table
		 * 
		 **/
		private function createFoodItemsTable():void
		{
			sqlStatement.text = CREATE_TABLE_FOODITEMS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createUnitsTable();
			}

			function tableCreated(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		/**
		 * Creates the units table.
		 * 
		 **/
		private function createUnitsTable():void
		{
			sqlStatement.text = CREATE_TABLE_UNITS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createEventsTable();
			}
			
			function tableCreated(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		
		/**
		 * Creates the events table
		 * 
		 **/
		private function createEventsTable():void
		{
			sqlStatement.text = CREATE_TABLE_EVENTS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createExerciseEventsTable();
			}
			
			function tableCreated(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		/**
		 * Creates the create exerciseevents table table
		 * 
		 **/
		private function createExerciseEventsTable():void
		{
			sqlStatement.text = CREATE_TABLE_EXERCISE_EVENTS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createBloodglucoseEventsTable();
			}
			
			function tableCreated(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		/**
		 * Creates the bloodglucoseevents table
		 * 
		 **/
		private function createBloodglucoseEventsTable():void
		{
			sqlStatement.text = CREATE_TABLE_BLOODGLUCOSE_EVENTS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createMedicinEventsTable();
			}
			
			function tableCreated(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		/**
		 * Creates the medicinevents table
		 * 
		 **/
		private function createMedicinEventsTable():void
		{
			sqlStatement.text = CREATE_TABLE_MEDICIN_EVENTS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createTableMealEvents();
			}
			
			function tableCreated(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		/**
		 * Creates the mealevents table
		 * 
		 **/
		private function createTableMealEvents():void
		{
			sqlStatement.text = CREATE_TABLE_MEAL_EVENTS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createTableSelectedFoodItems();
			}
			
			function tableCreated(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		/**
		 * Creates the selectedfooditems table
		 * 
		 **/
		private function createTableSelectedFoodItems():void
		{
			sqlStatement.text = CREATE_TABLE_SELECTED_FOODITEMS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createTableTemplateFoodItems();
			}
			
			function tableCreated(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		/**
		 * Creates the templatefooditems table
		 * 
		 **/
		private function createTableTemplateFoodItems():void
		{
			sqlStatement.text = CREATE_TABLE_TEMPLATE_FOODITEMS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createTableTemplates();
			}
			
			function tableCreated(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		/**
		 * Creates the templates table
		 * 
		 **/
		private function createTableTemplates():void
		{
			sqlStatement.text = CREATE_TABLE_TEMPLATES;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				createTableSource();
			}
			
			function tableCreated(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		/**
		 * Creates the sourcre table
		 * The source table should only have one row with the source of the food composition table 
		 * 
		 **/
		private function createTableSource():void
		{
			sqlStatement.text = CREATE_TABLE_SOURCE;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				finishedCreatingTables();
			}
			
			function tableCreated(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		private function finishedCreatingTables():void {
			//xml laden in fooditemxmllist
			..source stockeren en verder gaan
		}
		
		/**
		 * stores a source name in the database
		 * Database responder can be null
		 */
		private function insertSource(dbResponder:DatabaseResponder, source:String):void {
			var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(dbResponder, INSERT_SOURCE, null);
			sqlWrapper.statement.parameters[":source"] = source;
			sqlWrapper.statement.execute();
		}
		
		/**
		 * Dispatches a complete event
		 * 
		 * @param args Expects element 0 to be a DatabaseResponder
		 **
		private function finishedCreatingTables(args:Array):void
		{
			if ( args[0] is DatabaseResponder )
			{
				var de:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
				de.data = Database.TABLES_CREATED;
				args[0].dispatchEvent(de);
			}
		}*/
		
		/** 
		 * loads the initial food table into the database
		 * args[0] should be databaseresponder
		 */
		private function loadData(args:Array):void {
			databaseResponder = args[0];
			var internalResponder:DatabaseResponder = new DatabaseResponder();
			
			var foodItemCounter:int = 0;
			var unitCounter:int;
			var lastInsertedRowId:int;
			var unitList:XMLList;
			var foodtableXML:XML;
			
			internalResponder.addEventListener(DatabaseEvent.RESULT_EVENT, allFoodItemsCounted);
			internalResponder.addEventListener(DatabaseEvent.ERROR_EVENT, onErrorFoodItemsCounted);		
			
			var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(internalResponder, COUNT_ALLFOODITEMS, null);
			sqlWrapper.statement.execute();
			
			function allFoodItemsCounted(de:DatabaseEvent):void
			{
				internalResponder.removeEventListener(DatabaseEvent.RESULT_EVENT, allFoodItemsCounted);
				internalResponder.removeEventListener(DatabaseEvent.ERROR_EVENT,onErrorFoodItemsCounted);
				if (!de.data) //NOT SURE IF THIS WORKS WHEN THERE ARE ACTUALLY RESULTS
				{	
					/*******should be done differently because multiple source could be added ***/
					var sourceFile:File = File.applicationStorageDirectory.resolvePath("foodfile-nl.xml");
					
					var fileStream:FileStream = new FileStream();
					fileStream.open(sourceFile,FileMode.READ);
					foodtableXML = new XML(fileStream.readUTFBytes(fileStream.bytesAvailable));
					insertSource(args[0], foodtableXML.source);
					
					fooditemList = foodtableXML.fooditemlist;
					foodItemCounter  = 0;
					if (fooditemList.fooditem.length() > 0) {
						insertNextFoodItem();
					}
					else {
						var de:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
						de.data = Database.TABLES_CREATED;
						args[0].dispatchEvent(de);
					}	
				}
				
			}
			
			function insertNextFoodItem():void {
				internalResponder.addEventListener(DatabaseEvent.RESULT_EVENT, fooditemInserted);
				internalResponder.addEventListener(DatabaseEvent.ERROR_EVENT, onErrorfooditemInserted);
				
				var sqlWrapper:SQLWrapper = sqlStatementFactory.newInstance(internalResponder, INSERT_FOODITEM, null );
				sqlWrapper.statement.parameters[":description"] = fooditemList.fooditem.description.text()[0].toString();
				//var test:Object = fooditemList.fooditem.description.text()[0].toString();
				sqlWrapper.statement.execute();
				
			}
			
			function fooditemInserted(de:DatabaseEvent):void {
				internalResponder.removeEventListener(DatabaseEvent.RESULT_EVENT, fooditemInserted);
				internalResponder.removeEventListener(DatabaseEvent.ERROR_EVENT, onErrorfooditemInserted);
				var unitList:XMLList = (fooditemList.fooditem[foodItemCounter]).unitlist;
				unitCounter = 0;
				if (unitList.unit.length() > 0) {
					//var test:int = unitList.unit.length();
					lastInsertedRowId = de.data.lastInsertRowID;
					var test2:int = lastInsertedRowId;
					insertNextUnit(internalResponder);
				}
				else {
					foodItemCounter++;

					if (foodItemCounter > fooditemList.fooditem.length() - 1) {
						var de:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
						de.data = Database.TABLES_CREATED;
						args[0].dispatchEvent(de);
					} else {
						insertNextFoodItem(databaseResponder);
					}
				}	
			}
			
			function unitInserted(de:DatabaseEvent):void {
				internalResponder.removeEventListener(DatabaseEvent.RESULT_EVENT,unitInserted);
				internalResponder.removeEventListener(DatabaseEvent.ERROR_EVENT, onErrorInsertNextUnit);
				unitCounter++;
				if (unitCounter > unitList.length - 1) {
					foodItemCounter++;
					if (foodItemCounter > fooditemList.fooditem.length() - 1) {
						internalResponder.removeEventListener(DatabaseEvent.ERROR_EVENT,onError);
						var de:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
						de.data = Database.TABLES_CREATED;
						databaseResponder.dispatchEvent(de);
					} else {
						insertNextFoodItem(internalResponder);
					}
				} else {
					insertNextUnit(unitCounter);
				}
			}

			function insertNextUnit(counter:int):void {
				internalResponder.addEventListener(DatabaseEvent.RESULT_EVENT,unitInserted);
				internalResponder.addEventListener(DatabaseEvent.ERROR_EVENT,onErrorInsertNextUnit);
				var sqlWrapper:SQLWrapper = this.sqlStatementFactory.newInstance(internalResponder, INSERT_UNIT, null);
				sqlWrapper.statement.parameters[":description"] = unitList[counter].description;
				sqlWrapper.statement.parameters[":standardamount"] = unitList[counter].standardamount;
				sqlWrapper.statement.parameters[":weight"] = unitList[counter].weight;
				sqlWrapper.statement.parameters[":kcal"] = unitList[counter].kcal;
				sqlWrapper.statement.parameters[":protein"] = unitList[counter].protein;
				sqlWrapper.statement.parameters[":carbs"] = unitList[counter].carbs;
				sqlWrapper.statement.parameters[":fat"] = unitList[counter].fat;
				sqlWrapper.statement.parameters[":fooditems_itemid"] = lastInsertedRowId;
				sqlWrapper.statement.execute();
			}
			
			function onErrorFoodItemsCounted(de:DatabaseEvent):void
			{				
				internalResponder.removeEventListener(DatabaseEvent.ERROR_EVENT, onErrorFoodItemsCounted);
				internalResponder.removeEventListener(DatabaseEvent.RESULT_EVENT, allFoodItemsCounted);
			}
			
			function onErrorfooditemInserted(de:DatabaseEvent):void
			{				
				internalResponder.removeEventListener(DatabaseEvent.ERROR_EVENT, onErrorfooditemInserted);
				internalResponder.removeEventListener(DatabaseEvent.RESULT_EVENT, fooditemInserted);
			}
			
			function onErrorInsertNextUnit(de:DatabaseEvent):void
			{				
				internalResponder.removeEventListener(DatabaseEvent.ERROR_EVENT, onErrorInsertNextUnit);
				internalResponder.removeEventListener(DatabaseEvent.RESULT_EVENT, unitInserted);
			}
			
			

		}		

		
}
