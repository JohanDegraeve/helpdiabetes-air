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
	import flash.errors.SQLError;
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
	import mx.resources.ResourceBundle;
	import mx.resources.ResourceManager;
	
	import myComponents.DayLine;
	import myComponents.DayLineWithTotalAmount;
	
	import views.FoodCounterView;
	

	
	/**
	 * Database class is a singleton
	 */ 
	public final class Database 
	{
		import mx.core.FlexGlobals;
		import mx.resources.ResourceBundle;
	
		[ResourceBundle("general")]
		
		private static var instance:Database = new Database();
		
		public var aConn:SQLConnection;		

		private var sqlStatement:SQLStatement;
		
		private var globalDispatcher:EventDispatcher;
		
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
		private const CREATE_TABLE_EXERCISE_EVENTS:String = "CREATE TABLE IF NOT EXISTS exerciseevents (exerciseeventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																									   "level TEXT, " +
																									   "creationtimestamp TIMESTAMP NOT NULL," +
																									   "comment_2 TEXT)";
		private const CREATE_TABLE_BLOODGLUCOSE_EVENTS:String = "CREATE TABLE IF NOT EXISTS bloodglucoseevents (bloodglucoseeventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																											   "unit TEXT NOT NULL, " +
																											   "creationtimestamp TIMESTAMP NOT NULL," +
																											   "value INTEGER NOT NULL)";
		private const CREATE_TABLE_MEDICIN_EVENTS:String = "CREATE TABLE IF NOT EXISTS medicinevents (medicineventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
																									 "medicinname TEXT NOT NULL, " +
																									 "creationtimestamp TIMESTAMP NOT NULL," +
																									 "amount REAL NOT NULL)";		
		private const CREATE_TABLE_MEAL_EVENTS:String = "CREATE TABLE IF NOT EXISTS mealevents (mealeventid INTEGER PRIMARY KEY, " +
																							   "mealname TEXT NOT NULL, " +
																							   "lastmodifiedtimestamp TIMESTAMP NOT NULL, " +
																							   "insulinratio INTEGER," +
																							   "correctionfactor INTEGER," +
																							   "creationtimestamp TIMESTAMP NOT NULL," +
																							   "previousBGlevel INTEGER)";		
		private const CREATE_TABLE_SELECTED_FOODITEMS:String = "CREATE TABLE IF NOT EXISTS selectedfooditems (selectedfooditemid INTEGER PRIMARY KEY , " +
																											 "mealevents_mealeventid INTEGER NOT NULL, " +
																											 "itemdescription TEXT NOT NULL, " +
																											 "unitdescription TEXT, " +
																											 "standardamount INTEGER, " +
																					   					     "kcal INTEGER, " +
																											 "protein REAL, " +
																											 "carbs REAL NOT NULL, " +
																											 "fat REAL, " +
																											 "chosenamount REAL NOT NULL)";		
		private const CREATE_TABLE_TEMPLATE_FOODITEMS:String = "CREATE TABLE   IF NOT EXISTS  templatefooditems (templateitemid INTEGER PRIMARY KEY AUTOINCREMENT, " +
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
		private const GET_ALLMEALEVENTS:String = "SELECT * FROM mealevents";
		private const GET_UNITLIST:String = "SELECT * FROM units WHERE fooditems_itemid = :fooditemid";
		private const GET_ALLSELECTEDFOODITEMS:String="SELECT * FROM selectedfooditems";
		/**
		 * INSERT INTO settings (id,value) VALUES (:id,:value)
		 */
		private const INSERT_SETTING:String = "INSERT INTO settings (id,value) VALUES (:id,:value)";
		/**
		 * UPDATE settings set value = :value WHERE id = :id
		 */
		private const UPDATE_SETTING:String = "UPDATE settings set value = :value WHERE id = :id";
		private const UPDATE_MEALEVENT_LASTMODIFIEDTIMESTAMP:String = "UPDATE mealevents SET lastmodifiedtimestamp = :lastmodifiedtimestamp WHERE mealeventid = :mealeventid";
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
		private const UPDATE_INSULINRATIO_IN_MEAL_EVENT:String = "UPDATE mealevents set insulinratio = :=value WHERE mealeventid = :id";
		
		/**
		 * INSERT INTO mealevents (mealeventid , mealname , lastmodifiedtimestamp ) VALUES (:mealeventid,:mealname,:lastmodifiedtimestamp)
		 */ 
		private const INSERT_MEALEVENT:String = "INSERT INTO mealevents (mealeventid , mealname , lastmodifiedtimestamp, insulinratio, correctionfactor, previousBGlevel, creationtimestamp ) VALUES (:mealeventid,:mealname,:lastmodifiedtimestamp,:insulinratio,:correctionfactor,:previousBGlevel,:creationtimestamp)";

		private const INSERT_SELECTEDITEM:String = "INSERT INTO selectedfooditems (selectedfooditemid, mealevents_mealeventid,itemdescription ,unitdescription,standardamount,kcal,protein,carbs, fat, chosenamount ) VALUES (:selectedfooditemid,:mealevents_mealeventid,:itemdescription ,:unitdescription,:standardamount,:kcal,:protein,:carbs,:fat,:chosenamount)";

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
		 * deletes the database
		 */
		public function deleteDatabase():Boolean
		{
			var success:Boolean = false;
			dbFile  = File.applicationStorageDirectory.resolvePath(dbFileName);
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
		 * Create the asynchronous connection to the database<br>
		 * In the complete flow first an attempt will be made to open the database in update mode. <br>
		 * If that fails, it means the database is not existing yet. Then an attempt is made to copy a sample from the assets, the database name searched will be
		 * language dependent. 
		 * 
		 * Independent of the result of the attempt to open the database and to copy from the assets, all tables will be created (if not existing yet).<br>
		 * At the end, a check will be done to see if a source record exists in the source table, if no then the complete xml foodfile will be loaded into the database<br>
		 * Otherwise no reloading is done. The foodfile name to be used is again language dependent.<br>
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
			trace("Attempting to open database in update mode. Database:0004");
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
				var result:Boolean = createDatabaseFromAssets(dbFile);
				this.aConn = new SQLStatement();
				aConn.addEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.addEventListener(SQLErrorEvent.ERROR, onConnError);
				trace("Attempting to open database in creation mode. Database:0003");
				aConn.openAsync(dbFile, SQLMode.CREATE);
			}
		}
		
		/**
		 * Will execute SQL that will either create the tables in a fresh database or return, if they're already creatd.
		 **/
		private function createTables():void
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
				trace("Failed to create settings table. Database:0005");
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
			}
		}
		
		
		private function getAllSettings():void {
			sqlStatement.text = GET_ALL_SETTINGS;
			sqlStatement.addEventListener(SQLEvent.RESULT,settingsRetrieved);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,settingsRetrievalFailed);
			var retrievalResult:Array = new Array(Settings.getInstance().getNumberOfSettings());
			sqlStatement.execute();
			
			
			function settingsRetrieved(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,settingsRetrieved);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,settingsRetrievalFailed);
				var result:Object = sqlStatement.getResult().data;
				/* 
				 * Settings class now has default value 
				 * any setting which doesn't exist yet in the database needs to be stored in the database with value retrieved from Settings
				 * any setting which already exists in the database will be stored in Settings class
				 * so first store getresult.data values in an array of strings just a large as the Settings class, values that don't exist yet get null as value
				*/
				for (var i:int = 0;i < retrievalResult.length;i++) {
					retrievalResult[i] = null;
				}
					
				if (result != null && result is Array) {
					for each (var o:Object in result) {
						retrievalResult[(o.id as int)] = (o.value as String);
						Settings.getInstance().setSettingWithoutDatabaseUpdate((o.id as int),(o.value as String));
					}
				}
				//now add each missing element in the database, start with the first
				addMissingSetting(0);
			}
			
			function addMissingSetting(id:int):void {
				if (id == Settings.getInstance().getNumberOfSettings()) {
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
						addMissingSetting(id + 1);
					}
				}
			}
			
			function settingAdded (se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,settingAdded);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,addingSettingFailed);
				
				addMissingSetting((sqlStatement.parameters[":id"] as int)+1);
			}
			
			function addingSettingFailed (se:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,settingAdded);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,addingSettingFailed);
				trace("Failed to add setting. Database:0006");
			}
			
			function settingsRetrievalFailed(se:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,settingsRetrieved);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,settingsRetrievalFailed);
				trace("Failed to retrieve settings. Database:0007");
			}
		}
		
		/**
		 * Creates the fooditems table
		 * 
		 **/
		private function createFoodItemsTable():void
		{
			sqlStatement.text = CREATE_TABLE_FOODITEMS;
			sqlStatement.clearParameters();
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
				trace("Failed to create table :" + sqlStatement.text + ". Database0008");
			}
		}
		
		/**
		 * Creates the units table.
		 * 
		 **/
		private function createUnitsTable():void
		{
			sqlStatement.text = CREATE_TABLE_UNITS;
			sqlStatement.clearParameters();
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
				trace("Failed to create table :" + sqlStatement.text + ". Database0009");
			}
		}
		
		
		
		/**
		 * Creates the create exerciseevents table table
		 * 
		 **/
		private function createExerciseEventsTable():void
		{
			sqlStatement.text = CREATE_TABLE_EXERCISE_EVENTS;
			sqlStatement.clearParameters();
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
				trace("Failed to create table :" + sqlStatement.text + ". Database0011");
			}
		}
		
		/**
		 * Creates the bloodglucoseevents table
		 * 
		 **/
		private function createBloodglucoseEventsTable():void
		{
			sqlStatement.text = CREATE_TABLE_BLOODGLUCOSE_EVENTS;
			sqlStatement.clearParameters();
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
				trace("Failed to create table :" + sqlStatement.text + ". Database0012");
			}
		}
		
		/**
		 * Creates the medicinevents table
		 * 
		 **/
		private function createMedicinEventsTable():void
		{
			sqlStatement.text = CREATE_TABLE_MEDICIN_EVENTS;
			sqlStatement.clearParameters();
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
				trace("Failed to create table :" + sqlStatement.text + ". Database0013");
			}
		}
		
		/**
		 * Creates the mealevents table
		 * 
		 **/
		private function createTableMealEvents():void
		{
			sqlStatement.text = CREATE_TABLE_MEAL_EVENTS;
			sqlStatement.clearParameters();
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
				trace("Failed to create table :" + sqlStatement.text + ". Database0014");
			}
		}
		
		/**
		 * Creates the selectedfooditems table
		 * 
		 **/
		private function createTableSelectedFoodItems():void
		{
			sqlStatement.text = CREATE_TABLE_SELECTED_FOODITEMS;
			sqlStatement.clearParameters();
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
				trace("Failed to create table :" + sqlStatement.text + ". Database0015" + "error = " + see.toString());
			}
		}
		
		/**
		 * Creates the templatefooditems table
		 * 
		 **/
		private function createTableTemplateFoodItems():void
		{
			sqlStatement.text = CREATE_TABLE_TEMPLATE_FOODITEMS;
			sqlStatement.clearParameters();
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
				trace("Failed to create table :" + sqlStatement.text + ". Database0016" + "error = " + see.toString());
			}
		}
		
		/**
		 * Creates the templates table
		 * 
		 **/
		private function createTableTemplates():void
		{
			sqlStatement.text = CREATE_TABLE_TEMPLATES;
			sqlStatement.clearParameters();
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
				trace("Failed to create table :" + sqlStatement.text + ". Database0017");
			}
		}
		
		
		/**
		 * Creates the sourcre table<br>
		 * The source table should only have one row with the source of the food composition table 
		 * 
		 **/
		private function createTableSource():void
		{
			sqlStatement.text = CREATE_TABLE_SOURCE;
			sqlStatement.clearParameters();
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
				trace("Failed to create table :" + sqlStatement.text + ". Database0018");
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
				trace("Failed to get the source. Database0019");
			}
			
		}
		
		/**
		 * stores a source name in the database<br>
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
				trace("Failed to insert the source. Database0020");
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
			}
		}

		/**
		 * stores a food item in the database, obviously only the description, the dispatched databaseevent will have the inserted row id as lastInsertRowID<br>
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
				trace("Failed to insert a food item. Database0021");
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
			}
		}
		
		/**
		 * stores a unit in the database<br>
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
				trace("Failed to insert a unit. Database0022");
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
			}
		
		};
		

		/**
		 * msql query for getting source<br>
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
				trace("Failed to get the source. Database0023");
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
				trace("Failed to insert the source. Database0024");
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
				trace("Failed to insert a fooditem. Database0025");
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
				trace("Failed to insert a unit. Database0026");
			}
		}
		
		
		/**
		 * if globalDispatcher not null then dispatches a result event
		 */
		private function finishedCreatingTables():void {
			if (globalDispatcher != null)
				globalDispatcher.dispatchEvent(new Event(DatabaseEvent.RESULT_EVENT));
			//now continue prepopulating other stuff, like the tracking arraycollection, in the background
			getAllMealEventsAndFillUpMeals();
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
		 * msql query for all fooditems in fooditems table<br>
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
				trace("Failed to retrieve a fooditem. Database0027");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}

		/**
		 * gets the fooditem for the specified fooditemid<br>
		 * the fooditem will set in the data field of the event that will be dispatched to the specified dispatcher
		 */ 
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
				trace("Failed to open the database. Database0028");
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
				trace("Failed to retrieve the fooditem. Database0029");
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
				trace("Failed to retrieve the unitlist. Database0030");
				if (dispatcher != null) {
					var event3:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event3);
				}
			}
		}
		
		/**
		 * gets the list of units as an array collection, for the specified fooditem<br>
		 * the unitlist will be set in the data field of the event that will be dispatched to the specified dispatcher
		 */ 
		public function getUnitList(fooditem:FoodItem, dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			var unitList:ArrayCollection;
			
			localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
			localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
				
				localSqlStatement.addEventListener(SQLEvent.RESULT,unitListRetrieved);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,unitListRetrievalError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = GET_UNITLIST;
				localSqlStatement.clearParameters();
				localSqlStatement.parameters[":fooditemid"] = fooditem.itemid;
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
				trace("Failed to open the database. Database0032");
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
						event.data = unitList;
						dispatcher.dispatchEvent(event);
					} else {
						unitList.addItem(new Unit("error while retrieving unitlist for fooditem " + fooditem.itemid + ".",0,0,0,0,0));
						event.data = unitList;
						dispatcher.dispatchEvent(event);
					}
				}
			}
			
			function unitListRetrievalError(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,unitListRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,unitListRetrievalError);
				trace("Failed to retrieve the unitlist. Database0040");
				if (dispatcher != null) {
					var event3:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event3);
				}
			}
		}
		
		/**
		 * will update a mealevent in the database, updates the insulinratio<br>
		 * mealEventId = the mealevent to be updated<br>
		 * newInsulinRatioValue = the new insulinratio to be 	assigned<br>
		 * dispatcher = a DatabaseEvent will be dispatched when finished
		 */
		internal function updateInsulineRatio(mealEventId:Number, newInsulinRatioValue:Number, dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
			localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = UPDATE_INSULINRATIO_IN_MEAL_EVENT;
				localSqlStatement.parameters[":id"] = mealEventId;
				localSqlStatement.parameters[":value"] = newInsulinRatioValue;
				localSqlStatement.addEventListener(SQLEvent.RESULT, insulinRatioUpdated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, insulinRatioUpdateFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
				trace("Failed to open the database. Database0071");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			
			function insulinRatioUpdated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(DatabaseEvent.RESULT_EVENT,insulinRatioUpdated);
				localSqlStatement.removeEventListener(DatabaseEvent.ERROR_EVENT,insulinRatioUpdateFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function insulinRatioUpdateFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(DatabaseEvent.RESULT_EVENT,insulinRatioUpdated);
				localSqlStatement.removeEventListener(DatabaseEvent.ERROR_EVENT,insulinRatioUpdateFailed);
				trace("Failed to update a insulinratio. Database0070");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
		}
		
		/**
		 * if aconn is not open then open aconn to dbFile , in asynchronous mode, in UPDATE mode<br>
		 * returns true if aconn is open<br>
		 * if aconn is closed then connection will be opened asynchronous mode and an event will be dispatched to the dispatcher after opening the connecion<br>
		 * so that means if openSQLConnection returns true then there's no need to wait for the dispatcher event to trigger. <br>
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
		
		/**
		 * should only be used by settings class, therefore it's package private
		 * didn't test with the dispatcher
		 */
		internal function updateSetting(id:int,value:String, dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement()
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
			localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = UPDATE_SETTING;
				localSqlStatement.parameters[":id"] = id;
				localSqlStatement.parameters[":value"] = value;
				localSqlStatement.addEventListener(SQLEvent.RESULT, settingUpdated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, settingUpdateFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
				trace("Failed to open the database. Database0041");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}

			
			function settingUpdated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(DatabaseEvent.RESULT_EVENT,settingUpdated);
				localSqlStatement.removeEventListener(DatabaseEvent.ERROR_EVENT,settingUpdateFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function settingUpdateFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(DatabaseEvent.RESULT_EVENT,settingUpdated);
				localSqlStatement.removeEventListener(DatabaseEvent.ERROR_EVENT,settingUpdateFailed);
				trace("Failed to update a setting. Database0031");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
		}
		
		/**
		 * will add the mealevent to the database
		 */
		internal function createNewMealEvent(
				mealEventId:int,
				mealname:String,
				lastmodifiedtimestamp:String,
				insulinRatio:Number,
				correctionFactor:Number,
				previousBGlevel:int,
				creationtimestamp:Number,
				dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement()
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
			localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = INSERT_MEALEVENT;
				localSqlStatement.parameters[":mealeventid"] = mealEventId;
				localSqlStatement.parameters[":mealname"] = mealname;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = lastmodifiedtimestamp;
				localSqlStatement.parameters[":insulinratio"] = insulinRatio;
				localSqlStatement.parameters[":correctionfactor"] = correctionFactor;
				localSqlStatement.parameters[":previousBGlevel"] = previousBGlevel;
				localSqlStatement.parameters[":creationtimestamp"] = creationtimestamp;
				localSqlStatement.addEventListener(SQLEvent.RESULT, mealEventCreated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, mealEventCreationFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
				trace("Failed to open the database. Database0050");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			
			function mealEventCreated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(DatabaseEvent.RESULT_EVENT,mealEventCreated);
				localSqlStatement.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationFailed);
				
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					event.lastInsertRowID = localSqlStatement.getResult().lastInsertRowID;
					dispatcher.dispatchEvent(event);
				}
			}
			
			function mealEventCreationFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(DatabaseEvent.RESULT_EVENT,mealEventCreated);
				localSqlStatement.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationFailed);
				trace("Failed to create a mealEvent. Database0051");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
		}
		
		/**
		 * will add the Selected Item to the database
		 */
		internal function createNewSelectedItem(
			selectedItemId:int,
			mealEventId:int,
			itemDescription:String,
			unitDescription:String,
			standardAmount:int,
			kcal:int,
			protein:Number,
			carbs:Number,
			fat:Number,
			chosenAmount:Number,
			dispatcher:EventDispatcher):void {
			
			var localSqlStatement:SQLStatement = new SQLStatement()
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
			localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = INSERT_SELECTEDITEM;
				localSqlStatement.parameters[":selectedfooditemid"] = selectedItemId;
				localSqlStatement.parameters[":mealevents_mealeventid"] = mealEventId;
				localSqlStatement.parameters[":itemdescription"] = itemDescription;
				localSqlStatement.parameters[":unitdescription"] = unitDescription;
				localSqlStatement.parameters[":standardamount"] = standardAmount;
				localSqlStatement.parameters[":kcal"] = kcal;
				localSqlStatement.parameters[":protein"] = protein;
				localSqlStatement.parameters[":carbs"] = carbs;
				localSqlStatement.parameters[":fat"] = fat;
				localSqlStatement.parameters[":chosenamount"] = chosenAmount;
				localSqlStatement.addEventListener(SQLEvent.RESULT, selectedItemCreated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, selectedItemCreationFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
				trace("Failed to open the database. Database0050");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			
			function selectedItemCreated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(DatabaseEvent.RESULT_EVENT,selectedItemCreated);
				localSqlStatement.removeEventListener(DatabaseEvent.ERROR_EVENT,selectedItemCreationFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function selectedItemCreationFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(DatabaseEvent.RESULT_EVENT,selectedItemCreated);
				localSqlStatement.removeEventListener(DatabaseEvent.ERROR_EVENT,selectedItemCreationFailed);
				trace("Failed to create a selectedItem. Database0052");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
		}
		
	
		internal function updateMealEventLastModifiedTimeStamp(lastModifiedTimeStamp:Number,mealEventId:int,dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement()
			var localdispatcher:EventDispatcher = new EventDispatcher();

			localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
			localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);

			

			function onOpenError(e:SQLError):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
				
			}
			function onOpenResult(e:SQLError):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
				localSqlStatement.addEventListener(SQLEvent.RESULT,timeStampModified);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,timeStampModificationFailed);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = UPDATE_MEALEVENT_LASTMODIFIEDTIMESTAMP;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = lastModifiedTimeStamp;
				localSqlStatement.parameters[":mealeventid"] = mealEventId;
				localSqlStatement.execute();
				
			}

			function timeStampModified(result:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,timeStampModified);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,timeStampModificationFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}

			function timeStampModificationFailed(error:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,timeStampModified);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,timeStampModificationFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
				trace("Failed to create a selectedItem. Database0053");
			}

			
		}
		
		/**
		 * get all mealevents and store them in the arraycollection in the modellocator as MealEvent objects<br>
		 * The method also gets all selectedfooditems, which are stored in the correct MealEvent objects
		 */
		private function getAllMealEventsAndFillUpMeals():void {
			var localSqlStatement:SQLStatement = new SQLStatement()
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			var selectedFoodItems:ArrayCollection = new ArrayCollection();
			var currentMealEventID:int;//used in the filterfunction for the selectedfooditems
			
			selectedFoodItems.filterFunction = filterByMealEventId;
			
			localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
			localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			
			function onOpenError(e:SQLError):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);
			}
			function onOpenResult(e:SQLError):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,onOpenResult);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,onOpenError);

				localSqlStatement.addEventListener(SQLEvent.RESULT,selectedFoodItemsRetrieved);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,failedGettingSelectedFoodItems);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = GET_ALLSELECTEDFOODITEMS;
				localSqlStatement.execute();
			}

			function selectedFoodItemsRetrieved(result:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,selectedFoodItemsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,failedGettingSelectedFoodItems);
				var tempObject:Object = localSqlStatement.getResult().data;
				if (tempObject != null && tempObject is Array) {
					for each ( var o:Object in tempObject ) {
						var newSelectedFoodItem:SelectedFoodItem = new SelectedFoodItem(
							o.itemdescription as String,
							new Unit(o.unitdescription as String,o.standardamount as int,o.kcal as int,o.protein as Number,o.carbs as Number,o.fat as Number),
							o.chosenamount);
						newSelectedFoodItem.selectedItemId = o.selectedfooditemid as int;
						newSelectedFoodItem.mealEventId = o.mealevents_mealeventid as int;
						selectedFoodItems.addItem(newSelectedFoodItem);
					}
				}

				localSqlStatement.addEventListener(SQLEvent.RESULT,mealEventsRetrieved);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,mealEventRetrievalFailed);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = GET_ALLMEALEVENTS;
				localSqlStatement.execute();
			}
			
			function failedGettingSelectedFoodItems(error:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,mealEventsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,mealEventRetrievalFailed);
				trace("Failed to get all selectedFoodItems. Database0061");
			}
			
			/**
			 * adds all mealevents retrieved from the database to the trackinglist<br>
			 * at the same time will add daylines
			 */
			function mealEventsRetrieved(result:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,mealEventsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,mealEventRetrievalFailed);

				var tempObject:Object = localSqlStatement.getResult().data;
				
				if (tempObject != null && tempObject is Array) {
					for each ( var o:Object in tempObject ) {
						currentMealEventID = o.mealeventid as int;
						selectedFoodItems.refresh();
						var newMealEvent:MealEvent = new MealEvent(o.mealname as String,
							o.insulinratio as Number,
							o.correctionfactor as Number,
							o.prevousBGlevel as Number,
							o.creationtimestamp as Number,
							null,
							false,
							new ArrayCollection(selectedFoodItems.toArray()),
							o.mealeventid as Number,
							o.lastmodifiedtimestamp  as Number);
						ModelLocator.getInstance().trackingList.addItem(newMealEvent);
						var creationTimeStampAsDate:Date = new Date(newMealEvent.timeStamp);
						var creationTimeStampAtMidNight:Number = (new Date(creationTimeStampAsDate.fullYearUTC,creationTimeStampAsDate.monthUTC,creationTimeStampAsDate.dateUTC,0,0,0,0)).valueOf();
						if (creationTimeStampAtMidNight > ModelLocator.getInstance().oldestDayLineStoredInTrackingList) {
							ModelLocator.getInstance().oldestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
							if (ModelLocator.getInstance().youngestDayLineStoredInTrackingList == 5000000000000)
								ModelLocator.getInstance().youngestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
						} else if (creationTimeStampAtMidNight < ModelLocator.getInstance().youngestDayLineStoredInTrackingList) {
							ModelLocator.getInstance().youngestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
							if (ModelLocator.getInstance().oldestDayLineStoredInTrackingList == 0)
								ModelLocator.getInstance().oldestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
						}
					}
				}
				
				var oldest:Number = (new Date(ModelLocator.getInstance().oldestDayLineStoredInTrackingList)).valueOf();
				var youngest :Number = (new Date(ModelLocator.getInstance().youngestDayLineStoredInTrackingList)).valueOf();
				//Now add list of daylines
				for (var counter:Number = youngest;counter - 1 < oldest;counter = counter + 86400000)
					ModelLocator.getInstance().trackingList.addItem(new DayLineWithTotalAmount(counter));
				
				ModelLocator.getInstance().trackingList.refresh();
				
				// now populate ModelLocator.getInstance().meals
				ModelLocator.getInstance().refreshMeals();
				
			}
			
			function filterByMealEventId(item:Object):Boolean {
				return ((item  as SelectedFoodItem).mealEventId == currentMealEventID);
			}
			
			function mealEventRetrievalFailed(error:SQLErrorEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,mealEventsRetrieved);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventRetrievalFailed);
				trace("Failed to get all mealevents. Database0060");
			}
		}
		
			
		
		/**
		 * 
		 */
		internal function getPreviousGlucoseEvent(dispatcher:EventDispatcher):void {
			var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
			event.data = null;
			dispatcher.dispatchEvent(event);
		}
			
	} //class
	
} //package
