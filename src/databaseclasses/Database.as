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
	import flash.events.Event;
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
		
		private var globalDispatcher:EventDispatcher;
		
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
																					   					     "kcal INTEGER, " +
																											 "protein REAL, " +
																											 "carbs REAL NOT NULL, " +
																											 "fat REAL)";		
		private const CREATE_TABLE_TEMPLATE_FOODITEMS:String = "CREATE TABLE IF NOT EXISTS templatefooditems (templateitemid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																											 "templates_templateid INTEGER NOT NULL, " +
																											 "itemdescription TEXT NOT NULL, " +
																											 "unitdescription TEXT, " +
																											 "standardamount INTEGER, " +
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
		private const INSERT_UNIT:String = "INSERT INTO units (fooditems_itemid,"+
											"description," +
											"standardamount," +
											"kcal," +
											"protein," +
											"carbs," +
											"fat) VALUES " +
											"(:fooditems_itemid," + 
											":description," +
											":standardamount," +
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
		 **/
		public function init(dispatcher:EventDispatcher):void
		{
			
			this.globalDispatcher = dispatcher;

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

			function tableCreationError(see:SQLErrorEvent):void {
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
			
			function tableCreationError(see:SQLErrorEvent):void {
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
			
			function tableCreationError(see:SQLErrorEvent):void {
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
			
			function tableCreationError(see:SQLErrorEvent):void {
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
			
			function tableCreationError(see:SQLErrorEvent):void {
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
			
			function tableCreationError(see:SQLErrorEvent):void {
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
			
			function tableCreationError(see:SQLErrorEvent):void {
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
			
			function tableCreationError(see:SQLErrorEvent):void {
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
			
			function tableCreationError(see:SQLErrorEvent):void {
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
			
			function tableCreationError(see:SQLErrorEvent):void {
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
				loadSourceXML("foodfile-nl.xml");
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		/**
		 * stores a source name in the database
		 * if dispatcher != null then an event will be dispatches when finished
		 */
		public function insertSource(source:String, dispatcher:EventDispatcher):void {
			sqlStatement.text = INSERT_SOURCE;
			sqlStatement.parameters[":source"] = source;
			sqlStatement.addEventListener(SQLEvent.RESULT, sourceInserted);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR, sourceInsertionError);
			sqlStatement.execute();
			
			function sourceInserted(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,sourceInserted);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,sourceInsertionError);
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.DATABASE_INITIALIZED_RESULT_EVENT));
			}
			function sourceInsertionError(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,sourceInserted);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,sourceInsertionError);
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.DATABASE_INITIALIZED_ERROR_EVENT));
			}
		}

		/**
		 * stores a food item in the database, obviously only the description, the dispatched databaseevent will have the inserted row id as lastInsertRowID
		 * if dispatcher != null then an event will be dispatches when finished
		 */
		public function insertFoodItem(foodItemDescription:String, dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			localSqlStatement.sqlConnection = aConn;
			localSqlStatement.text = INSERT_FOODITEM;
			localSqlStatement.parameters[":description"] = foodItemDescription;
			localSqlStatement.addEventListener(SQLEvent.RESULT, foodItemInserted);
			localSqlStatement.addEventListener(SQLErrorEvent.ERROR, foodItemInsertionError);
			localSqlStatement.execute();
			
			function foodItemInserted(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,foodItemInserted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,foodItemInsertionError);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.DATABASE_INITIALIZED_RESULT_EVENT);
					event.lastInsertRowID = localSqlStatement.getResult().lastInsertRowID;
					dispatcher.dispatchEvent(event);
				}
			}
			function foodItemInsertionError(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,foodItemInserted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,foodItemInsertionError);
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.DATABASE_INITIALIZED_ERROR_EVENT));
			}
		}
		
		/**
		 * stores a unit in the database
		 * if dispatcher != null then an event will be dispatches when finished
		 */
		public function insertUnit(description:String,standardAmount:int,kcal:int,protein:Number,carbs:Number,fat:Number, fooditems_itemid:int,dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			localSqlStatement.sqlConnection = aConn;
			localSqlStatement.text = INSERT_UNIT;
			localSqlStatement.parameters[":description"] = description;
			localSqlStatement.parameters[":standardamount"] = standardAmount; 
			localSqlStatement.parameters[":kcal"] = kcal;
			localSqlStatement.parameters[":protein"] = protein;
			localSqlStatement.parameters[":carbs"] = carbs;
			localSqlStatement.parameters[":fat"] = fat;
			localSqlStatement.parameters[":fooditems_itemid"] = fooditems_itemid;
			localSqlStatement.addEventListener(SQLEvent.RESULT, unitInserted);
			localSqlStatement.addEventListener(SQLErrorEvent.ERROR, unitInsertionError);
			localSqlStatement.execute();

			function unitInserted(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,unitInserted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,unitInsertionError);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.DATABASE_INITIALIZED_RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			function unitInsertionError(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,unitInserted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,unitInsertionError);
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.DATABASE_INITIALIZED_ERROR_EVENT));
			}
		
		};

		
		
		
		/**
		 * loads the XML sourcefile and populates the database
		 */
		private function loadSourceXML(sourceFileName:String):void {
			var sourceFile:File = File.applicationStorageDirectory.resolvePath(sourceFileName);
			var fileStream:FileStream = new FileStream();
			var dispatcher:EventDispatcher = new EventDispatcher();
			var foodtableXML:XML;
		    var unitListXMLList:XMLList;
			var foodItemDescriptionsXMLList:XMLList;
			var foodItemListCounter:int;
			var unitListCounter:int;
			var unitListSize:int;
			var foodItemListSize:int;
			var actualFoodItemRowId:int;

			fileStream.open(sourceFile,FileMode.READ);
			foodtableXML = new XML(fileStream.readUTFBytes(fileStream.bytesAvailable));
			foodItemListSize = foodtableXML.fooditemlist.fooditem.length();
			foodItemListCounter = 0;
			
			foodItemDescriptionsXMLList = foodtableXML.fooditemlist.fooditem.description;
			
			dispatcher.addEventListener(DatabaseEvent.DATABASE_INITIALIZED_RESULT_EVENT, sourceInserted);
			dispatcher.addEventListener(DatabaseEvent.DATABASE_INITIALIZED_ERROR_EVENT, sourceInsertionError);
			insertSource(foodtableXML.source == null ? "" : foodtableXML.source,dispatcher);
			
			function sourceInserted(se:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.DATABASE_INITIALIZED_RESULT_EVENT,sourceInserted);
				dispatcher.removeEventListener(DatabaseEvent.DATABASE_INITIALIZED_ERROR_EVENT,sourceInsertionError);
				goOnWithFoodItems();
			}
			function sourceInsertionError(see:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.DATABASE_INITIALIZED_RESULT_EVENT,sourceInserted);
				dispatcher.removeEventListener(DatabaseEvent.DATABASE_INITIALIZED_ERROR_EVENT,sourceInsertionError);
			}
			
			function goOnWithFoodItems():void {
				
				if (foodItemListCounter == foodItemListSize) {
					finishedCreatingTables();					
				} else {
					dispatcher.addEventListener(DatabaseEvent.DATABASE_INITIALIZED_RESULT_EVENT, foodItemInserted);
					dispatcher.addEventListener(DatabaseEvent.DATABASE_INITIALIZED_ERROR_EVENT, foodItemInsertionError);
					//var test2:String = foodItemDescriptionsXMLList[foodItemCounter];
					insertFoodItem(foodItemDescriptionsXMLList[foodItemListCounter],dispatcher);
				}
			}
			
			function foodItemInserted(se:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.DATABASE_INITIALIZED_RESULT_EVENT,foodItemInserted);
				dispatcher.removeEventListener(DatabaseEvent.DATABASE_INITIALIZED_ERROR_EVENT,foodItemInsertionError);
				unitListCounter = 0;
				unitListXMLList = foodtableXML.fooditemlist.fooditem[foodItemListCounter].unitlist.unit;
				unitListSize = unitListXMLList.length();
				actualFoodItemRowId = se.lastInsertRowID;
				foodItemListCounter++;
				goOnWithUnits();
			}
			
			function foodItemInsertionError(see:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.DATABASE_INITIALIZED_RESULT_EVENT,foodItemInserted);
				dispatcher.removeEventListener(DatabaseEvent.DATABASE_INITIALIZED_ERROR_EVENT,foodItemInsertionError);
			}
			
			function goOnWithUnits():void {
				if (unitListCounter == unitListSize) {
					goOnWithFoodItems();					
				} else {
					dispatcher.addEventListener(DatabaseEvent.DATABASE_INITIALIZED_RESULT_EVENT, unitInserted);
					dispatcher.addEventListener(DatabaseEvent.DATABASE_INITIALIZED_ERROR_EVENT, unitInsertionError);
					//var test2:String = foodItemDescriptionsXMLList[foodItemCounter];
					insertUnit(unitListXMLList[unitListCounter ].description,
						unitListXMLList[unitListCounter ].standardamount,
						unitListXMLList[unitListCounter ].kcal,
						unitListXMLList[unitListCounter ].protein,
						unitListXMLList[unitListCounter ].carbs,
						unitListXMLList[unitListCounter ].fat,
						actualFoodItemRowId,
						dispatcher);
					unitListCounter++;

				}
			}
			
			function unitInserted(see:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.DATABASE_INITIALIZED_RESULT_EVENT, unitInserted);
				dispatcher.removeEventListener(DatabaseEvent.DATABASE_INITIALIZED_ERROR_EVENT, unitInsertionError);
				goOnWithUnits();
			}
			
			function unitInsertionError(se:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.DATABASE_INITIALIZED_RESULT_EVENT, unitInserted);
				dispatcher.removeEventListener(DatabaseEvent.DATABASE_INITIALIZED_ERROR_EVENT, unitInsertionError);
			}
			
			
			
			
		}
		
		
		/**
		 * if globalDispatcher not null then dispatches a result event
		 */
		private function finishedCreatingTables():void {
			//xml laden in fooditemxmllist
			//..source stockeren en verder gaan
			if (globalDispatcher != null)
				globalDispatcher.dispatchEvent(new Event(DatabaseEvent.DATABASE_INITIALIZED_RESULT_EVENT));
		}
	}		
}
