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
	
	import model.ModelLocator;
	
	import mx.collections.ArrayCollection;
	import mx.resources.ResourceManager;
	
	import objects.FoodItem;
	import objects.Unit;
	
	import views.FoodCounterView;
	
	
	/**
	 * Database class is a singleton
	 */ 
	public final class Database 
	{
		[ResourceBundle("general")]

		private static var instance:Database = new Database();
		
		public var aConn:SQLConnection;		

		private var sqlStatement:SQLStatement;
		
		private var globalDispatcher:EventDispatcher;
		
		/*private const MG_DL:String = "mg/dL";
		private const mmol:String = "mmol";*/
		private var sampleDbFileName:String;
		private const dbFileName:String = "foodfile.db";
		private  var dbFile:File  ;
		private var xmlFileName:String;
		private var foodFileName:String;
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
		/**
		 * CREATE TABLE IF NOT EXISTS settings (id INTEGER PRIMARY KEY, value TEXT)
		 */ 
		private const CREATE_TABLE_SETTINGS:String = "CREATE TABLE IF NOT EXISTS settings (id INTEGER PRIMARY KEY," +
														"value TEXT)";

		
		/**
		 * SELECT * FROM settings 
		 */
		private const GET_ALL_SETTINGS:String = "SELECT * FROM settings ";
		private const GET_FOODITEM:String = "SELECT * FROM fooditems WHERE itemid = :itemid";
		private const GET_SOURCE:String = "SELECT * FROM source";
		private const GET_ALLFOODITEMS:String = "SELECT * FROM fooditems";
		private const GET_UNITLIST:String = "SELECT * FROM units WHERE fooditems_itemid = :fooditemid";
		private const COUNT_ALLFOODITEMS:String = "SELECT itemid FROM fooditems";
		/**
		 * INSERT INTO settings (id,value) VALUES (:id,:value)
		 */
		private const INSERT_SETTING:String = "INSERT INTO settings (id,value) VALUES (:id,:value)";
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
			foodFileName = "foodfile-" + ResourceManager.getInstance().getString("general","TableLanguage");
			sampleDbFileName = foodFileName + "-sample.db";
			xmlFileName = foodFileName + ".xml";


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
		 * Create the asynchronous connection to the database
		 * In the complete flow first an attempt will be made to open the database in update mode. 
		 * If that fails, it means the database is not existing yet. Then an attempt is made to copy a sample from the assets, the database name searched will be
		 * language dependent. 
		 * 
		 * Independent of the result of the attempt to open the database and to copy from the assets, all tables will be created (if not existing yet).
		 * At the end, a check will be done to see if a source record exists in the source table, if no then the complete xml foodfile will be loaded into the database
		 * Otherwise no reloading is done. The foodfile name to be used is again language dependent.
		 * 
		 **/
		public function init(dispatcher:EventDispatcher):void
		{
			
			trace("HelpDiabetes-air : Database.init");
			this.globalDispatcher = dispatcher;
			dbFile  = File.applicationStorageDirectory.resolvePath(dbFileName);
			
			this.aConn = new SQLConnection();
			this.aConn.addEventListener(SQLEvent.OPEN, onConnOpen);
			this.aConn.addEventListener(SQLErrorEvent.ERROR, onConnError);
			this.aConn.openAsync(dbFile, SQLMode.UPDATE);
			
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
				reAttempt();
			}
			
			function reAttempt():void {
				//attempt to create dbFile based on a sample in assets directory, 
				//if that fails then dbFile will simply not exist and so will be created later on in openAsync 
				createDatabaseFromAssets(dbFile);
				this.aConn = new SQLStatement();
				aConn.addEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.addEventListener(SQLErrorEvent.ERROR, onConnError);
				aConn.openAsync(dbFile, SQLMode.CREATE);
			}
			
		}
		
		
		/**
		 * Will execute SQL that will either create the tables in a fresh database or return, if they're already creatd.
		 **/
		public function createTables():void
		{						
			sqlStatement = new SQLStatement();
			sqlStatement.sqlConnection = aConn;
			createSettingsTable();				
		}
		
		/**
		 * Creates the settings table
		 **/
		private function createSettingsTable():void
		{
			sqlStatement.text = CREATE_TABLE_SETTINGS;
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				getAllSettings();
			}

			function tableCreationError(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		
		private function getAllSettings():void {
			sqlStatement.text = GET_ALL_SETTINGS;
			sqlStatement.addEventListener(SQLEvent.RESULT,settingsRetrieved);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,settingsRetrievalFailed);
			sqlStatement.execute();
			var retrievalResult:Array = new Array(Settings.getInstance().getAmountOfSettings());
			
			function settingsRetrieved(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,settingsRetrieved);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,settingsRetrieved);
				var result:Object = sqlStatement.getResult().data;
				/* 
				 * Settings class now has default value 
				 * any setting which doesn't exist yet in the database needs to be stored in the database with value retrieved from Settings
				 * any setting which already exists in the database will be stored in Settings class
				 * so first store getresult.data values in an array of strings just a large as the Settings class, values that don't exist yet get null as value
				*/
				for (var i:int = 0;i < retrievalResult.length;i++)
					retrievalResult[i] = null;
				if (result != null & result is Array) {
					for each (var o:Object in result) {
						retrievalResult[(o.id as int)] = (o.value as String);
						Settings.getInstance().setSettingWithoutDatabaseUpdate((o.id as int),(o.value as String));
					}
				}
				//now add each missing element in the database, start with the first
				addMissingElement(0);
			}
			
			function addMissingElement(id:int):void {
				if (id == Settings.getInstance().getAmountOfSettings()) {
					//we went through all settings, continue with creating the fooditemstable
					createFoodItemsTable();
				} else {
					if (retrievalResult[id] == null) {
						sqlStatement.clearParameters();
						sqlStatement.addEventListener(SQLEvent.RESULT,settingAdded);
						sqlStatement.addEventListener(SQLErrorEvent.ERROR,addingSettingFailed);
						sqlStatement.text = INSERT_SETTING;
						sqlStatement.parameters[":id"] = id;
						sqlStatement.parameters[":value"] = Settings.getInstance().getSetting(id);
						sqlStatement.execute();
						
					} else {
						addMissingElement(id + 1);
					}
				}
			}
			
			function settingAdded (se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,settingAdded);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,addingSettingFailed);
				
			}
			
			function settingsRetrievalFailed(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,settingsRetrieved);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,settingsRetrieved);
				
			}
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
				checkSource();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		private function checkSource():void {
			var dispatcher:EventDispatcher = new EventDispatcher();

			dispatcher.addEventListener(DatabaseEvent.RESULT_EVENT, checkSourceResult);
			dispatcher.addEventListener(DatabaseEvent.ERROR_EVENT, checkSourceError);
			getSource(dispatcher);
			
			function checkSourceResult(se:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,checkSourceResult);	
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,checkSourceError);	
				if (se.data != null)
					finishedCreatingTables();
				else
					loadFoodTable();
			}
			
			function checkSourceError(se:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,checkSourceResult);	
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,checkSourceError);	
			}
			
		}
		
		/**
		 * stores a source name in the database
		 * if dispatcher != null then an event will be dispatches when finished
		 */
		private function insertSource(source:String, dispatcher:EventDispatcher):void {
			sqlStatement.text = INSERT_SOURCE;
			sqlStatement.parameters[":source"] = source;
			sqlStatement.addEventListener(SQLEvent.RESULT, sourceInserted);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR, sourceInsertionError);
			sqlStatement.execute();
			
			function sourceInserted(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,sourceInserted);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,sourceInsertionError);
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.RESULT_EVENT));
			}
			function sourceInsertionError(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,sourceInserted);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,sourceInsertionError);
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
			}
		}

		/**
		 * stores a food item in the database, obviously only the description, the dispatched databaseevent will have the inserted row id as lastInsertRowID
		 * if dispatcher != null then an event will be dispatches when finished
		 */
		private function insertFoodItem(foodItemDescription:String, dispatcher:EventDispatcher):void {
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
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					event.lastInsertRowID = localSqlStatement.getResult().lastInsertRowID;
					dispatcher.dispatchEvent(event);
				}
			}
			function foodItemInsertionError(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,foodItemInserted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,foodItemInsertionError);
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
			}
		}
		
		/**
		 * stores a unit in the database
		 * if dispatcher != null then an event will be dispatches when finished
		 */
		private function insertUnit(description:String,standardAmount:int,kcal:int,protein:Number,carbs:Number,fat:Number, fooditems_itemid:int,dispatcher:EventDispatcher):void {
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
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			function unitInsertionError(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,unitInserted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,unitInsertionError);
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
			}
		
		};
		

		/**
		 * msql query for getting source
		 * if dispathcer != null then a databaseevent will be dispatched with the result of the query in the data
		 */
		public function getSource(dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			localSqlStatement.sqlConnection = aConn;
			localSqlStatement.text = GET_SOURCE;
			localSqlStatement.addEventListener(SQLEvent.RESULT, sourceRetrieved);
			localSqlStatement.addEventListener(SQLErrorEvent.ERROR, sourceRetrievalError);
			localSqlStatement.execute();
			
			function sourceRetrieved(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,sourceRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,sourceRetrievalError);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					event.data = localSqlStatement.getResult().data;
					
					dispatcher.dispatchEvent(event);
				}
			}
			function sourceRetrievalError(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,sourceRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,sourceRetrievalError);
			}
			
		}
		
		
		
		
		/**
		 * loads the XML sourcefile and populates the database
		 */
		private function loadFoodTable():void {
			
			var sourceFile:File = File.applicationDirectory.resolvePath("assets/database/" + xmlFileName);
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

			trace("HelpDiabetes-air = loadFoodTable - before opening file");
			fileStream.open(sourceFile,FileMode.READ);
			foodtableXML = new XML(fileStream.readUTFBytes(fileStream.bytesAvailable));
			foodItemListSize = foodtableXML.fooditemlist.fooditem.length();
			foodItemListCounter = 0;
			
			foodItemDescriptionsXMLList = foodtableXML.fooditemlist.fooditem.description;
			
			dispatcher.addEventListener(DatabaseEvent.RESULT_EVENT, sourceInserted);
			dispatcher.addEventListener(DatabaseEvent.ERROR_EVENT, sourceInsertionError);
			insertSource(foodtableXML.source == null ? "" : foodtableXML.source,dispatcher);
			
			function sourceInserted(se:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,sourceInserted);
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,sourceInsertionError);
				goOnWithFoodItems();
			}
			function sourceInsertionError(see:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,sourceInserted);
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,sourceInsertionError);
			}
			
			function goOnWithFoodItems():void {
				
				if (foodItemListCounter == foodItemListSize) {
					finishedCreatingTables();					
				} else {
					dispatcher.addEventListener(DatabaseEvent.RESULT_EVENT, foodItemInserted);
					dispatcher.addEventListener(DatabaseEvent.ERROR_EVENT, foodItemInsertionError);
					//var test2:String = foodItemDescriptionsXMLList[foodItemCounter];
					insertFoodItem(foodItemDescriptionsXMLList[foodItemListCounter],dispatcher);
				}
			}
			
			function foodItemInserted(se:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,foodItemInserted);
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,foodItemInsertionError);
				unitListCounter = 0;
				unitListXMLList = foodtableXML.fooditemlist.fooditem[foodItemListCounter].unitlist.unit;
				unitListSize = unitListXMLList.length();
				actualFoodItemRowId = se.lastInsertRowID;
				foodItemListCounter++;
				goOnWithUnits();
			}
			
			function foodItemInsertionError(see:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,foodItemInserted);
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,foodItemInsertionError);
			}
			
			function goOnWithUnits():void {
				if (unitListCounter == unitListSize) {
					goOnWithFoodItems();					
				} else {
					dispatcher.addEventListener(DatabaseEvent.RESULT_EVENT, unitInserted);
					dispatcher.addEventListener(DatabaseEvent.ERROR_EVENT, unitInsertionError);
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
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT, unitInserted);
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT, unitInsertionError);
				goOnWithUnits();
			}
			
			function unitInsertionError(se:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT, unitInserted);
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT, unitInsertionError);
			}
		}
		
		
		/**
		 * if globalDispatcher not null then dispatches a result event
		 */
		private function finishedCreatingTables():void {
			//xml laden in fooditemxmllist
			//..source stockeren en verder gaan
			if (globalDispatcher != null)
				globalDispatcher.dispatchEvent(new Event(DatabaseEvent.RESULT_EVENT));
		}
		
		private  function createDatabaseFromAssets(targetFile:File):Boolean 			
		{
			var isSuccess:Boolean = true; 
			
			var sampleFile:File = File.applicationDirectory.resolvePath("assets/database/" + sampleDbFileName);
			if ( !sampleFile.exists )
			{
				isSuccess = false;
			}
			else
			{
				sampleFile.copyTo(targetFile);			
			}
			
			return isSuccess;			
		}
		
		/**
		 * msql query for all fooditems in fooditems table
		 * if dispathcer != null then a databaseevent will be dispatched with the result of the query in the data
		 */
		public function getAllFoodItemDescriptions(dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			localSqlStatement.sqlConnection = aConn;
			localSqlStatement.text = GET_ALLFOODITEMS;
			localSqlStatement.addEventListener(SQLEvent.RESULT, allFoodItemsRetrieved);
			localSqlStatement.addEventListener(SQLErrorEvent.ERROR, foodItemRetrievalError);
			localSqlStatement.execute();
			
			function allFoodItemsRetrieved(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,allFoodItemsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,foodItemRetrievalError);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					event.data = localSqlStatement.getResult().data;
					dispatcher.dispatchEvent(event);
				}
			}
			
			function foodItemRetrievalError(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,allFoodItemsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,foodItemRetrievalError);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}

		public function getFoodItem(fooditemid:int, dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			var foodItem:FoodItem;//the fooditem that will be returned by the dispatcher
			var foodItemDescription:String;//the fooditem description needs to be temporarily stored.
			var fooditemId:int;
			var unitList:ArrayCollection;

			localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
			localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);

				localSqlStatement.addEventListener(SQLEvent.RESULT,foodItemRetrieved);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,foodItemRetrievalError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = GET_FOODITEM;
				localSqlStatement.parameters[":itemid"] = fooditemid;
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function foodItemRetrieved (se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,foodItemRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,foodItemRetrievalError);
				if (dispatcher != null) {
					var tempObject:Object = localSqlStatement.getResult().data;
					if (tempObject != null) {
						foodItemDescription = 	tempObject[0].description;
						fooditemId = tempObject[0].itemid;
						localSqlStatement.addEventListener(SQLEvent.RESULT,unitListRetrieved);
						localSqlStatement.addEventListener(SQLErrorEvent.ERROR,unitListRetrievalError);
						localSqlStatement.sqlConnection = aConn;
						localSqlStatement.text = GET_UNITLIST;
						localSqlStatement.clearParameters();
						localSqlStatement.parameters[":fooditemid"] = fooditemid;
						localSqlStatement.execute();
					} else {
						var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
						unitList = new ArrayCollection();
						unitList.addItem(new Unit("dummy value",0,0,0,0,0));
						foodItem = new FoodItem("error while retrieving fooditem " + fooditemid + ".",unitList,0);
						event.data = foodItem;
						dispatcher.dispatchEvent(event);
					}
				}
			}
			
			function foodItemRetrievalError(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,foodItemRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,foodItemRetrievalError);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function unitListRetrieved(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,unitListRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,unitListRetrievalError);
				if (dispatcher != null) {
					unitList = new ArrayCollection();
					var tempObject:Object = localSqlStatement.getResult().data;
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					if (tempObject != null && tempObject is Array) {
						for each ( var o:Object in tempObject )
						{
							unitList.addItem(new Unit(o.description as String,o.standardamount as int,o.kcal as int,o.protein as Number,o.carbs as Number,o.fat as Number));
						}
						foodItem = new FoodItem(foodItemDescription,unitList,fooditemid);
						event.data = foodItem;
						dispatcher.dispatchEvent(event);
					} else {
						unitList.addItem(new Unit("error while retrieving unitlist for fooditem " + fooditemid + ".",0,0,0,0,0));
						foodItem = new FoodItem(foodItemDescription,unitList,0);
						event.data = foodItem;
						dispatcher.dispatchEvent(event);
					}
				}
			}
			
			function unitListRetrievalError(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,unitListRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,unitListRetrievalError);
				if (dispatcher != null) {
					var event3:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event3);
				}
			}
		}
		
		/**
		 * if aconn is not open then open aconn to dbFile , in asynchronous mode, in UPDATE mode
		 * returns true if aconn is open
		 * if aconn is closed then connection will be opened asynchronous mode and an event will be dispatched to the dispatcher after opening the connecion
		 * so that means if openSQLConnection returns true then there's no need to wait for the dispatcher event to trigger. 
		 */ 
		private function openSQLConnection(dispatcher:EventDispatcher):Boolean {
			// should I first check if there's still a connection open and close if necessary ?
			if (aConn != null && aConn.connected) { 
					return true;
			} else {
				aConn = new SQLConnection();
				aConn.addEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.addEventListener(SQLErrorEvent.ERROR, onConnError);
				aConn.openAsync(dbFile, SQLMode.UPDATE);
			}
			
			return false;
	
			function onConnOpen(se:SQLEvent):void
			{
				trace("SQL Connection successfully opened in method Database.openSQLConnection");
				aConn.removeEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.removeEventListener(SQLErrorEvent.ERROR, onConnError);	
				if (dispatcher != null) {
					var event2:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					//var event2:SQLEvent = new SQLEvent(SQLEvent.RESULT);
					dispatcher.dispatchEvent(event2);
				}
			}
			
			function onConnError(see:SQLErrorEvent):void
			{
				trace("SQL Error while attempting to open database in method Database.openSQLConnection");
				aConn.removeEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.removeEventListener(SQLErrorEvent.ERROR, onConnError);
				if (dispatcher != null) {
					var event2:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event2);
				}
			}
		}
	}		
}
