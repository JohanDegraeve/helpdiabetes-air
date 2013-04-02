/**
 Copyright (C) 2013  hippoandfriends
 
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
	
	import myComponents.DayLineWithTotalAmount;
	
	import views.FoodCounterView;
	
	
	
	/**
	 * Database class is a singleton
	 */ 
	public final class Database extends EventDispatcher
	{
		import mx.core.FlexGlobals;
		import mx.resources.ResourceBundle;
		
		[ResourceBundle("general")]
		
		private static var instance:Database = new Database();
		
		public var aConn:SQLConnection;		
		
		private var sqlStatement:SQLStatement;
		
		private var globalDispatcher:EventDispatcher;
		
		private var sampleDbFileName:String;
		private static const dbFileName:String = "foodfile.db";
		private  static var dbFile:File  ;
		private var xmlFileName:String;
		
		private const DATABASE_VERSION_1 = "version1";
		private const DATABASE_VERSION_2 = "version2";
		
		private const CREATE_TABLE_VERSIONINFO:String = "CREATE TABLE IF NOT EXISTS versioninfo (info TEXT NOT NULL, lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		private const CREATE_TABLE_FOODITEMS:String = "CREATE TABLE IF NOT EXISTS fooditems (itemid INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"description TEXT NOT NULL, lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		private const CREATE_TABLE_UNITS:String = "CREATE TABLE IF NOT EXISTS units (unitid INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"fooditems_itemid INTEGER NOT NULL, " +
			"description TEXT NOT NULL, " +
			"standardamount INTEGER, " +
			"kcal INTEGER, " +
			"protein REAL, " +
			"carbs REAL NOT NULL, " +
			"fat REAL, lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		private const CREATE_TABLE_EXERCISE_EVENTS:String = "CREATE TABLE IF NOT EXISTS exerciseevents (exerciseeventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"level TEXT, " +
			"creationtimestamp TIMESTAMP NOT NULL," +
			"comment_2 TEXT, lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		private const CREATE_TABLE_BLOODGLUCOSE_EVENTS:String = "CREATE TABLE IF NOT EXISTS bloodglucoseevents (bloodglucoseeventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"unit TEXT NOT NULL, " +
			"creationtimestamp TIMESTAMP NOT NULL," +
			"value INTEGER NOT NULL, lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		private const CREATE_TABLE_MEDICIN_EVENTS:String = "CREATE TABLE IF NOT EXISTS medicinevents (medicineventid INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"medicinname TEXT NOT NULL, " +
			"creationtimestamp TIMESTAMP NOT NULL," +
			"amount REAL NOT NULL, lastmodifiedtimestamp TIMESTAMP NOT NULL)";		
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
			"chosenamount REAL NOT NULL, lastmodifiedtimestamp TIMESTAMP NOT NULL)";		
		private const CREATE_TABLE_TEMPLATE_FOODITEMS:String = "CREATE TABLE   IF NOT EXISTS  templatefooditems (templateitemid INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"templates_templateid INTEGER NOT NULL, " +
			"itemdescription TEXT NOT NULL, " +
			"unitdescription TEXT, " +
			"standardamount INTEGER, " +
			"kcal INTEGER, " +
			"protein REAL, " +
			"carbs REAL NOT NULL, " +
			"fat REAL, lastmodifiedtimestamp TIMESTAMP NOT NULL)";		
		private const CREATE_TABLE_TEMPLATES:String = "CREATE TABLE IF NOT EXISTS templates (templateid INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"name TEXT NOT NULL, lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		private const CREATE_TABLE_SOURCE:String = "CREATE TABLE IF NOT EXISTS source (source TEXT)";
		/**
		 * CREATE TABLE IF NOT EXISTS settings (id INTEGER PRIMARY KEY, value TEXT)
		 */ 
		private const CREATE_TABLE_SETTINGS:String = "CREATE TABLE IF NOT EXISTS settings (id INTEGER PRIMARY KEY," +
			"value TEXT, lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		
		private const DELETE_ROW_IN_TABLE_SELECTED_FOODITEMS_MATCHING_MEALEVENTID:String = 
			"DELETE FROM selectedfooditems where mealevents_mealeventid = :mealevents_mealeventid";
		private const DELETE_ROW_IN_TABLE_EXERCISEEVENTS:String = 
			"DELETE FROM exerciseevents where exerciseeventid = :exerciseeventid";
		private const DELETE_ROW_IN_TABLE_BLOODGLUCOSEEVENTS:String = 
			"DELETE FROM bloodglucoseevents where bloodglucoseeventid = :bloodglucoseeventid";
		private const DELETE_ROW_IN_TABLE_MEDICINEVENTS:String = 
			"DELETE FROM medicinevents where medicineventid = :medicineventid";
		private const DELETE_ROW_IN_TABLE_MEALEVENTS:String = 
			"DELETE FROM mealevents where mealeventid = :mealeventid";
		private const DELETE_ROW_IN_TABLE_SELECTED_FOODITEMS_MATCHING_SELECTEDFOODITEMID:String = 
			"DELETE FROM selectedfooditems where selectedfooditemid = :selectedfooditemid";
		private const DELETE_ALL_FOODITEMS:String = "DELETE FROM fooditems";
		private const DELETE_ALL_UNITS:String = "DELETE FROM units";
		/**
		 * SELECT * FROM settings 
		 */
		private const GET_ALL_SETTINGS:String = "SELECT * FROM settings ";
		private const GET_FOODITEM:String = "SELECT * FROM fooditems WHERE itemid = :itemid";
		private const GET_SOURCE:String = "SELECT * FROM source";
		private const GET_ALLFOODITEMS:String = "SELECT * FROM fooditems";
		private const GET_ALLMEALEVENTS:String = "SELECT * FROM mealevents";
		private const GET_ALLBLOODGLUCOSEEVENTS:String = "SELECT * FROM bloodglucoseevents";
		private const GET_ALLMEDICINEVENTS:String = "SELECT * FROM medicinevents";
		private const GET_ALLEXERCISEEVENTS:String = "SELECT * FROM exerciseevents";
		private const GET_UNITLIST:String = "SELECT * FROM units WHERE fooditems_itemid = :fooditemid";
		private const GET_ALLSELECTEDFOODITEMS:String="SELECT * FROM selectedfooditems";
		private const GET_VERSIONINFO:String = "SELECT * FROM versioninfo";
		/**
		 * INSERT INTO settings (id,value) VALUES (:id,:value)
		 */
		private const INSERT_SETTING:String = "INSERT INTO settings (id,value,lastmodifiedtimestamp) VALUES (:id,:value,:lastmodifiedtimestamp)";
		/**
		 * UPDATE settings set value = :value WHERE id = :id
		 */
		private const UPDATE_SETTING:String = "UPDATE settings set value = :value, lastmodifiedtimestamp = :lastmodifiedtimestamp WHERE id = :id";
		private const UPDATE_MEALEVENT_LASTMODIFIEDTIMESTAMP:String = "UPDATE mealevents SET lastmodifiedtimestamp = :lastmodifiedtimestamp WHERE mealeventid = :mealeventid";
		private const INSERT_SOURCE:String = "INSERT INTO source (source) VALUES (:source)";
		private const INSERT_FOODITEM:String = "INSERT INTO fooditems (description,lastmodifiedtimestamp) VALUES (:description,:lastmodifiedtimestamp)";
		private const INSERT_UNIT:String = "INSERT INTO units (fooditems_itemid," +
			"description," +
			"standardamount," +
			"kcal," +
			"protein," +
			"carbs," +
			"fat, lastmodifiedtimestamp) VALUES " +
			"(:fooditems_itemid," + 
			":description," +
			":standardamount," +
			":kcal," +
			":protein," +
			":carbs," +
			":fat, :lastmodifiedtimestamp)";
		private const UPDATE_MEAL_EVENT:String = "UPDATE mealevents set comment_2 = :comment_2, mealname = :mealname, insulinratio = :insulinratio, previousBGlevel = :previousBGlevel, creationtimestamp = :creationtimestamp, lastmodifiedtimestamp = :lastmodifiedtimestamp,correctionfactor = :correctionfactor WHERE mealeventid = :id";
		private const UPDATE_SELECTED_FOOD_ITEM:String="UPDATE selectedfooditems set mealevents_mealeventid = :mealevents_mealeventid,itemdescription = :itemdescription, standardamount = :standardamount,unitdescription = :unitdescription,kcal = :kcal,protein = :protein,carbs = :carbs,fat = :fat,chosenamount = :chosenamount,lastmodifiedtimestamp = :lastmodifiedtimestamp WHERE selectedfooditemid = :selectedfooditemid";
		private const UPDATE_MEDICINEVENT:String="UPDATE medicinevents set comment_2 = :comment_2, amount = :amount, medicinname = :medicinname, lastmodifiedtimestamp = :lastmodifiedtimestamp, creationtimestamp = :creationtimestamp WHERE medicineventid = :id";
		private const UPDATE_EXERCISEEVENT:String="UPDATE exerciseevents set comment_2 = :comment_2, level = :level, comment_2 = :comment_2, lastmodifiedtimestamp = :lastmodifiedtimestamp, creationtimestamp = :creationtimestamp WHERE exerciseeventid = :id";
		private const UPDATE_BLOODGLUCOSEEVENT:String="UPDATE bloodglucoseevents set comment_2 = :comment_2, unit = :unit, value = :value, lastmodifiedtimestamp = :lastmodifiedtimestamp, creationtimestamp = :creationtimestamp WHERE bloodglucoseeventid = :id";
		
		/**
		 * INSERT INTO mealevents (mealeventid , mealname , lastmodifiedtimestamp ) VALUES (:mealeventid,:mealname,:lastmodifiedtimestamp)
		 */ 
		private const INSERT_MEALEVENT:String = "INSERT INTO mealevents (mealeventid , mealname , lastmodifiedtimestamp, insulinratio, correctionfactor, previousBGlevel, creationtimestamp, comment_2 ) VALUES (:mealeventid,:mealname,:lastmodifiedtimestamp,:insulinratio,:correctionfactor,:previousBGlevel,:creationtimestamp,:comment_2)";
		
		private const INSERT_SELECTED_FOOD_ITEM:String = "INSERT INTO selectedfooditems (selectedfooditemid, mealevents_mealeventid,itemdescription ,unitdescription,standardamount,kcal,protein,carbs, fat, chosenamount,lastmodifiedtimestamp ) VALUES (:selectedfooditemid,:mealevents_mealeventid,:itemdescription ,:unitdescription,:standardamount,:kcal,:protein,:carbs,:fat,:chosenamount, :lastmodifiedtimestamp)";
		
		private const INSERT_BLOODGLUCOSEEVENT:String = "INSERT INTO bloodglucoseevents (bloodglucoseeventid, unit, creationtimestamp, value, lastmodifiedtimestamp, comment_2) VALUES (:bloodglucoseeventid, :unit,:creationtimestamp, :value, :lastmodifiedtimestamp,:comment_2)";
		
		private const INSERT_MEDICINEVENT:String = "INSERT INTO medicinevents (medicineventid, medicinname, amount, creationtimestamp, lastmodifiedtimestamp, comment_2) VALUES (:medicineventid, :medicinname,  :amount, :creationtimestamp, :lastmodifiedtimestamp,:comment_2)";
		
		private const INSERT_EXERCISEEVENT:String = "INSERT INTO exerciseevents (exerciseeventid, level, creationtimestamp, comment_2, lastmodifiedtimestamp, comment_2) VALUES (:exerciseeventid, :level, :creationtimestamp, :comment_2, :lastmodifiedtimestamp,:comment_2)";
		
		private const INSERT_COMMENT_COLUMN_IN_MEALEVENTS:String = "ALTER TABLE mealevents ADD comment_2 TEXT";
		private const INSERT_COMMENT_COLUMN_IN_MEDICINEVENTS:String = "ALTER TABLE medicinevents ADD comment_2 TEXT";
		private const INSERT_COMMENT_COLUMN_IN_BLOODGLUCOSEEVENTS:String = "ALTER TABLE bloodglucoseevents ADD comment_2 TEXT";
		private const INSERT_VERSIONINFO:String = "INSERT INTO versioninfo (info,lastmodifiedtimestamp) VALUES (:info, :lastmodifiedtimestamp)";
		//later on a UPDATE_VERSIONINFO
		
		//exerciseevents already has the comment_2 column		
		private var databaseWasCopiedFromSampleFile:Boolean = false;
		
		/**
		 * used for event dispatching, when dispatched, it means there's a new fooddatabase in the database stored successfully
		 */
		public static const NEW_FOOD_DATABASE_STORED_SUCCESS:String = "new_food_database_stored_success";
		/**
		 * used for event dispatching, when dispatched, storing new database failed
		 */
		public static const NEW_FOOD_DATABASE_STORED_FAILED:String = "new_food_database_stored_failure";
		/**
		 * process of installing new foodtable in database is sending status update
		 */
		public static const NEW_FOOD_DATABASE_STATUS_UPDATE:String = "new_food_database_status_update";
		/**
		 * text to use in downloadfoodtableview, for showing status 
		 */
		private var _newFoodDatabaseStatus:String = "";
		
		public function get newFoodDatabaseStatus():String

		{
			return _newFoodDatabaseStatus;
		}

		
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
		 * deletes the database
		 */
		public function deleteDatabase():Boolean
		{
			var success:Boolean = false;
			dbFile  = File.applicationStorageDirectory.resolvePath(dbFileName);
			if ( dbFile ) 
			{				
				if ( this.aConn && this.aConn.connected )
				{
					this.aConn.close(null);	
				}
				
				var fs:FileStream = new FileStream();
				try 
				{
					fs.open(dbFile,FileMode.UPDATE);
					while ( fs.bytesAvailable )	
					{
						fs.writeByte(Math.random() * Math.pow(2,32));						
					}
					trace("writing complete");
					fs.close();
					dbFile.deleteFile();
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
				databaseWasCopiedFromSampleFile = createDatabaseFromAssets(dbFile);
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
			trace("in method createtables");
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
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create settings table. Database:0005";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
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
				*
				* exception for SettingsFirstStartUp, in case the database was created by copying the sample file, then we'll use the SettingsFirstStartUp from the class and not from the database
				*/
				for (var i:int = 0;i < retrievalResult.length;i++) {
					retrievalResult[i] = null;
				}
				
				if (result != null && result is Array) {
					for each (var o:Object in result) {
						if  ((o.id as int) != Settings.SettingsFirstStartUp || !databaseWasCopiedFromSampleFile) {
							//retrievalresult[Settings.SettingsFirstStartUp] will remain null so it will get the value from the class later on
							retrievalResult[(o.id as int)] = (o.value as String);
							Settings.getInstance().setSettingWithoutDatabaseUpdate((o.id as int),(o.value as String), o.lastmodifiedtimestamp);
						}
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
						sqlStatement.text = 
							(id != Settings.SettingsFirstStartUp || !databaseWasCopiedFromSampleFile)
							?
							INSERT_SETTING
							:
							UPDATE_SETTING;
						sqlStatement.parameters[":id"] = id;
						sqlStatement.parameters[":value"] = Settings.getInstance().getSetting(id);
						sqlStatement.parameters[":lastmodifiedtimestamp"] = Settings.getInstance().getSettingLastModifiedTimeStamp(id);
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
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to add setting. Database:0006";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
			}
			
			function settingsRetrievalFailed(se:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,settingsRetrieved);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,settingsRetrievalFailed);
				trace("Failed to retrieve settings. Database:0007");
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to retrieve settings. Database:0007";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
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
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0008";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
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
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0009";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
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
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0011";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
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
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0012";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
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
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0013";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
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
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0014";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
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
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0015" + "error = " + see.toString();
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
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
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0016" + "error = " + see.toString();
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
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
				createTableVersionInfo();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				trace("Failed to create table :" + sqlStatement.text + ". Database0017");
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0017";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
			}
		}
		
		private function createTableVersionInfo():void {
			sqlStatement.text = CREATE_TABLE_VERSIONINFO;
			sqlStatement.clearParameters();
			sqlStatement.addEventListener(SQLEvent.RESULT,tableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function tableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				checkVersionInfo();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				trace("Failed to create table :" + sqlStatement.text + ". Database0120");
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0120";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
			}
		}
		
		private function checkVersionInfo():void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			localSqlStatement.sqlConnection = aConn;
			localSqlStatement.text = GET_VERSIONINFO;
			localSqlStatement.addEventListener(SQLEvent.RESULT, checkVersionInfoResult);
			localSqlStatement.addEventListener(SQLErrorEvent.ERROR, checkVersionInfoError);
			localSqlStatement.execute();
			
			function checkVersionInfoResult(se:SQLEvent):void {
				localSqlStatement.removeEventListener(DatabaseEvent.RESULT_EVENT,checkVersionInfoResult);	
				localSqlStatement.removeEventListener(DatabaseEvent.ERROR_EVENT,checkVersionInfoError);	
				var tempObject:Object = localSqlStatement.getResult().data;
				if (tempObject != null && tempObject is Array) {
					for each ( var o:Object in tempObject)
					{
						var version:String = (o.info as String);
						if (version == DATABASE_VERSION_1)//in fact will never happen, because we don't insert this string during creation of version 1
							upgradeToVersion2();
						else {
							//we should already be on version 2, later on, if there's a version 3, will check on version 2
							createTableSource();
						}
					}
				} else {
					upgradeToVersion2();
				}
			}
			
			function checkVersionInfoError(se:SQLError):void {
				localSqlStatement.removeEventListener(DatabaseEvent.RESULT_EVENT,checkVersionInfoResult);	
				localSqlStatement.removeEventListener(DatabaseEvent.ERROR_EVENT,checkVersionInfoError);	
				trace("Failed to get the versioninfo. Database0121");
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to get the source. Database0121";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
			}
		}
		
		/**
		 *  version 2 is about adding a comment column in all events
		 */
		private function upgradeToVersion2():void {
			sqlStatement.text = INSERT_COMMENT_COLUMN_IN_MEALEVENTS;
			sqlStatement.clearParameters();
			sqlStatement.addEventListener(SQLEvent.RESULT,step1Finished);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,upgradeToVersion2Failed);
			sqlStatement.execute();
			
			function step1Finished(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,step1Finished);
				sqlStatement.addEventListener(SQLEvent.RESULT,step2Finished);
				sqlStatement.text = INSERT_COMMENT_COLUMN_IN_MEDICINEVENTS;
				sqlStatement.clearParameters();
				sqlStatement.execute();
			}
			
			function step2Finished(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,step2Finished);
				sqlStatement.addEventListener(SQLEvent.RESULT,step3Finished);
				sqlStatement.text = INSERT_COMMENT_COLUMN_IN_BLOODGLUCOSEEVENTS;
				sqlStatement.clearParameters();
				sqlStatement.execute();
			}
			
			function step3Finished(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,step3Finished);
				sqlStatement.addEventListener(SQLEvent.RESULT,step4Finished);
				sqlStatement.text = INSERT_VERSIONINFO;
				sqlStatement.clearParameters();
				sqlStatement.parameters[":info"] = DATABASE_VERSION_2;
				sqlStatement.parameters[":lastmodifiedtimestamp"] = (new Date()).valueOf();
				sqlStatement.execute();
			}
			
			function step4Finished(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,step4Finished);
				sqlStatement.removeEventListener(SQLEvent.RESULT,upgradeToVersion2Failed);
				checkVersionInfo();
			}
			
			function upgradeToVersion2Failed(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,step1Finished);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,upgradeToVersion2Failed);
				trace("Failed to upgrade to version 2 :" + sqlStatement.text + ". Database0121. see.error.details = " + see.error.details);
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0121";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
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
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0018";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
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
					loadFoodTableInternal(finishedCreatingTables);
			}
			
			function checkSourceError(se:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,checkSourceResult);	
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,checkSourceError);	
				trace("Failed to get the source. Database0019");
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to get the source. Database0019";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
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
			localSqlStatement.parameters[":lastmodifiedtimestamp"] = (new Date()).valueOf();
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
		 * deletes all fooditems from the database and also the units
		 */
		private function deleteFoodDatabase(dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			localSqlStatement.sqlConnection = aConn;
			localSqlStatement.text = DELETE_ALL_FOODITEMS;
			localSqlStatement.addEventListener(SQLEvent.RESULT, foodItemsDeleted);
			localSqlStatement.addEventListener(SQLErrorEvent.ERROR, foodItemDeletionFailed);
			localSqlStatement.execute();
			
			function foodItemDeletionFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,foodItemsDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,foodItemDeletionFailed);
				trace("Failed to delete fooditems from database");
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
			}
			
			function foodItemsDeleted(se:SQLEvent):void  {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,foodItemsDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,foodItemDeletionFailed);
				trace("fooditems deleted from database");
				localSqlStatement = new SQLStatement();
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = DELETE_ALL_UNITS;
				localSqlStatement.addEventListener(SQLEvent.RESULT, unitsDeleted);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, unitDeletionFailed);
				localSqlStatement.execute();
			}

			function unitDeletionFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,unitsDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,unitDeletionFailed);
				trace("Failed to delete units from database");
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
			}
			
			function unitsDeleted(se:SQLEvent):void  {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,unitsDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,unitDeletionFailed);
				trace("units deleted from database");
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.RESULT_EVENT));
			}
		}
		
		/**
		 * stores a unit in the database<br>
		 * if dispatcher != null then an event will be dispatches when finished
		 */
		private function insertUnit(description:String,standardAmount:int,kcal:int,protein:Number,carbs:Number,fat:Number, fooditems_itemid:Number,dispatcher:EventDispatcher):void {
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
			localSqlStatement.parameters[":lastmodifiedtimestamp"] = (new Date()).valueOf();
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
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
		}
		
		
		
		/**
		 * deletes fooddatabase<br>
		 * stores data in xml into database<br>
		 * if overWriteDatabase then existing database will first be deleted<br>
		 * lots of dispatching, better look in the code 
		 */
		public function loadFoodTable(overWriteDatabase:Boolean,foodtable:XML = null,dispatcher:EventDispatcher = null):void {
			var localDispatcher:EventDispatcher = new EventDispatcher();
			
			if (overWriteDatabase) {
				localDispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,fooddatabaseDeleted);
				localDispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,foodDatabaseDeletionFailed);
				deleteFoodDatabase(localDispatcher);
			} else  {
				fooddatabaseDeleted();				
			}

			function fooddatabaseDeleted(se:DatabaseEvent = null):void {
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,fooddatabaseDeleted);
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,foodDatabaseDeletionFailed);
				loadFoodTableInternal(externalXMLLoaded,foodtable,dispatcher);
			}
			
			function foodDatabaseDeletionFailed(see:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,fooddatabaseDeleted);
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,foodDatabaseDeletionFailed);
				trace("Failed to delete the fooddatabase");
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
				externalXMLLoaded(false);
			}
		}
		
		/**
		 * 
		 * if success then xml download was ok<br>
		 * dispatches NEW_FOOD_DATABASE_STORED_SUCCESS or NEW_FOOD_DATABASE_STORED_FAILED depending on success
		 */
		private function externalXMLLoaded(success:Boolean = true):void {
			if (success)
				this.dispatchEvent(new Event(NEW_FOOD_DATABASE_STORED_SUCCESS));
			else
				this.dispatchEvent(new Event(NEW_FOOD_DATABASE_STORED_FAILED));
		}
		
		/**
		 * loads the XML sourcefile and populates the database<br>
		 * if foodtable == null then foodtable from xml file stored in application is used<br>
		 * functionToCallWhenFinished is obviously function to call when finished
		 */
		private function loadFoodTableInternal(functionToCallWhenFinished:Function,foodtable:XML = null,dispatcher:EventDispatcher  = null):void {
			
			var foodtableXML:XML;

			if (foodtable != null)
				foodtableXML = foodtable;
			else {
				var sourceFile:File = File.applicationDirectory.resolvePath("assets/database/" + xmlFileName);
				var fileStream:FileStream = new FileStream();
				fileStream.open(sourceFile,FileMode.READ);
				foodtableXML = new XML(fileStream.readUTFBytes(fileStream.bytesAvailable));
			}
			
			var localDispatcher:EventDispatcher = new EventDispatcher();
			var unitListXMLList:XMLList;
			var foodItemDescriptionsXMLList:XMLList;
			var foodItemListCounter:int;
			var unitListCounter:int;
			var unitListSize:int;
			var foodItemListSize:int;
			var actualFoodItemRowId:int;
			
			foodItemListSize = foodtableXML.fooditemlist.fooditem.length();
			foodItemListCounter = 0;
			
			foodItemDescriptionsXMLList = foodtableXML.fooditemlist.fooditem.description;
			
			localDispatcher.addEventListener(DatabaseEvent.RESULT_EVENT, sourceInserted);
			localDispatcher.addEventListener(DatabaseEvent.ERROR_EVENT, sourceInsertionError);
			insertSource(foodtableXML.source == null ? "" : foodtableXML.source,localDispatcher);
			
			function sourceInserted(se:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,sourceInserted);
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,sourceInsertionError);
				goOnWithFoodItems();
			}
			function sourceInsertionError(see:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,sourceInserted);
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,sourceInsertionError);
				trace("Failed to insert the source. Database0024");
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to insert the source. Database0024";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
			}
			
			function goOnWithFoodItems():void {
				if (foodItemListCounter == foodItemListSize) {
					functionToCallWhenFinished();					
				} else {
					//send status update
					if ((foodItemListSize - foodItemListCounter)%10 == 0) {
						_newFoodDatabaseStatus = foodItemListCounter + " {outof} " + foodItemListSize + " {elementsloaded} ";
						(instance as EventDispatcher).dispatchEvent(new Event(NEW_FOOD_DATABASE_STATUS_UPDATE));
					}
						
					localDispatcher.addEventListener(DatabaseEvent.RESULT_EVENT, foodItemInserted);
					localDispatcher.addEventListener(DatabaseEvent.ERROR_EVENT, foodItemInsertionError);
					//var test2:String = foodItemDescriptionsXMLList[foodItemCounter];
					insertFoodItem(foodItemDescriptionsXMLList[foodItemListCounter],localDispatcher);
				}
			}
			
			function foodItemInserted(se:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,foodItemInserted);
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,foodItemInsertionError);
				unitListCounter = 0;
				unitListXMLList = foodtableXML.fooditemlist.fooditem[foodItemListCounter].unitlist.unit;
				unitListSize = unitListXMLList.length();
				actualFoodItemRowId = se.lastInsertRowID;
				foodItemListCounter++;
				goOnWithUnits();
			}
			
			function foodItemInsertionError(see:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,foodItemInserted);
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,foodItemInsertionError);
				trace("Failed to insert a fooditem. Database0025");
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to insert a fooditem. Database0025";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
			}
			
			function goOnWithUnits():void {
				if (unitListCounter == unitListSize) {
					goOnWithFoodItems();					
				} else {
					localDispatcher.addEventListener(DatabaseEvent.RESULT_EVENT, unitInserted);
					localDispatcher.addEventListener(DatabaseEvent.ERROR_EVENT, unitInsertionError);
					var unit:XML = unitListXMLList[unitListCounter];
					
					//the following piece of code is the same functionality as in synchronize.as
					//probably this here will never be used, it would only be the case if the tests in synchronize.as haven't been executed yet
					//which is only the case for the xml file which is built into the app, which should never contain errors.
					
					//check if mandatory fields exist
					//unit description is already checked in synchronize.as
					if (unit.carbs ==  undefined)  {dispatchFunction("Unit must have a carb value",foodItemListCounter,unitListCounter + 1);return;}
					if (unit.standardamount ==  undefined)  {dispatchFunction("Unit must have a standardamount",foodItemListCounter,unitListCounter + 1);return;}
					//replace , by . and check if parseable to number
					
					var standardamount:Number;
					var carb:Number;
					var kcal:Number = -1;
					var protein:Number = -1;
					var fat:Number = -1;
					
					if (isNaN(carb = new Number((unit.carbs).toString().replace(",",".")))) {dispatchFunction("Carb value must  be numeric",foodItemListCounter,unitListCounter + 1,unit.carbs.toString());return;}
					if (isNaN(standardamount = new Number((unit.standardamount).toString().replace(",",".")))) {dispatchFunction("standardamount value must be integer",foodItemListCounter,unitListCounter + 1,unit.standardamount.toString());return;}
					if (unit.kcal != undefined) if (isNaN(kcal = new Number((unit.kcal).toString().replace(",",".")))) {dispatchFunction("kcal value must  be integer",foodItemListCounter,unitListCounter + 1,unit.kcal.toString());return;}
					if (unit.protein != undefined) if (isNaN(protein = new Number((unit.protein).toString().replace(",",".")))) {dispatchFunction("protein value must  be numeric",foodItemListCounter,unitListCounter + 1,unit.protein.toString());return;}
					if (unit.fat != undefined) if (isNaN(fat = new Number((unit.fat).toString().replace(",",".")))) {dispatchFunction("fat value must  be numeric",foodItemListCounter,unitListCounter + 1,unit.fat.toString());return;}
					
					//check integers if necessary
					if (standardamount % 1 != 0)  {dispatchFunction("standardamount must be an integer number",foodItemListCounter,unitListCounter + 1);return}
					if (kcal != -1) if (kcal % 1 != 0)  {dispatchFunction("kcal must be an integer number",foodItemListCounter,unitListCounter + 1);return}
					
					
					insertUnit(unitListXMLList[unitListCounter ].description,
						standardamount,
						kcal,
						protein,
						carb,
						fat,
						actualFoodItemRowId,
						localDispatcher);
					unitListCounter++;
				}
			}
			
			function unitInserted(see:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT, unitInserted);
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT, unitInsertionError);
				goOnWithUnits();
			}
			
			function unitInsertionError(se:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT, unitInserted);
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT, unitInsertionError);
				trace("Failed to insert a unit. Database0026");
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to insert a unit. Database0026";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
			}
			
			function dispatchFunction(message:String, fooditemctr:int,unitcntr:int = 0,found:String=null):void  {
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					event.data = message + ", check the foodtable, row " + foodItemListCounter ;
					if (unitcntr != 0) event.data += ", unit " + (unitListCounter + 1) + ".";
					if (found != null) event.data += " Found \"" + found + "\"";
					dispatcher.dispatchEvent(event);
				}
				functionToCallWhenFinished();
			}
		}
		
		
		/**
		 * if globalDispatcher not null then dispatches a result event
		 */
		private function finishedCreatingTables():void {
			if (globalDispatcher != null) {
				globalDispatcher.dispatchEvent(new Event(DatabaseEvent.RESULT_EVENT));
				globalDispatcher = null;
			}
			//now continue prepopulating other stuff, like the tracking arraycollection, in the background
			getAllEventsAndFillUpMeals(globalDispatcher);
		}
		
		
		private  function createDatabaseFromAssets(targetFile:File):Boolean 			
		{
			var isSuccess:Boolean = true; 

			var foodFileName:String;
			foodFileName = "foodfile-" + ResourceManager.getInstance().getString("general","TableLanguage");
			sampleDbFileName = foodFileName + "-sample.db";
			xmlFileName = foodFileName + ".xml";
			

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
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				
				localSqlStatement.addEventListener(SQLEvent.RESULT,foodItemRetrieved);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,foodItemRetrievalError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = GET_FOODITEM;
				localSqlStatement.parameters[":itemid"] = fooditemid;
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
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
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				
				localSqlStatement.addEventListener(SQLEvent.RESULT,unitListRetrieved);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,unitListRetrievalError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = GET_UNITLIST;
				localSqlStatement.clearParameters();
				localSqlStatement.parameters[":fooditemid"] = fooditem.itemid;
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
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
		 * updates a mealevent in the database<br>
		 * mealEventId = the mealevent to be updated<br>
		 * newInsulinRatioValue = the new insulinratio to be 	assigned<br>
		 * newLastModifiedTimeStamp = <br>
		 * dispatcher = a DatabaseEvent will be dispatched when finished
		 */
		internal function updateMealEvent(mealEventId:Number, newMealName:String,newInsulinRatio:Number,newCorrectionFactor:Number,newPreviousBGLevel:int,newLastModifiedTimeStamp:Number,newCreationTimeStamp:Number, comment:String, dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = UPDATE_MEAL_EVENT;
				localSqlStatement.parameters[":id"] = mealEventId;
				localSqlStatement.parameters[":insulinratio"] = newInsulinRatio;
				localSqlStatement.parameters[":previousBGlevel"] = newPreviousBGLevel;
				localSqlStatement.parameters[":correctionfactor"] = newCorrectionFactor;
				localSqlStatement.parameters[":mealname"] = newMealName;
				localSqlStatement.parameters[":creationtimestamp"] = newCreationTimeStamp;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = newLastModifiedTimeStamp;
				localSqlStatement.parameters[":comment_2"] = comment;
				localSqlStatement.addEventListener(SQLEvent.RESULT, mealEventUpdated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, mealEventUpdateFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database. Database0071");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			
			function mealEventUpdated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,mealEventUpdated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,mealEventUpdateFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function mealEventUpdateFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,mealEventUpdated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,mealEventUpdateFailed);
				trace("Failed to update a mealevent. Database0070");
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
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.RESULT_EVENT));
				}
			}
			
			function onConnError(see:SQLErrorEvent):void
			{
				trace("SQL Error while attempting to open database in method Database.openSQLConnection");
				aConn.removeEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.removeEventListener(SQLErrorEvent.ERROR, onConnError);
				if (dispatcher != null) {
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
				}
			}
		}
		
		/**
		 * should only be used by settings class, therefore it's package private<br>
		 * didn't test with the dispatcher<br>
		 * if lastmodifedtimestamp = NaN then current date and time is stored
		 */
		internal function updateSetting(id:int,value:String, lastModifiedTimeStamp:Number, dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement()
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = UPDATE_SETTING;
				localSqlStatement.parameters[":id"] = id;
				localSqlStatement.parameters[":value"] = value;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = (isNaN(lastModifiedTimeStamp) ? (new Date()).valueOf() : lastModifiedTimeStamp);
				localSqlStatement.addEventListener(SQLEvent.RESULT, settingUpdated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, settingUpdateFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database. Database0041");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			
			function settingUpdated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,settingUpdated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,settingUpdateFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function settingUpdateFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,settingUpdated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,settingUpdateFailed);
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
			mealEventId:Number,
			mealname:String,
			lastmodifiedtimestamp:Number,
			insulinRatio:Number,
			correctionFactor:Number,
			previousBGlevel:int,
			creationtimestamp:Number,
			comment:String,
			dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement()
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = INSERT_MEALEVENT;
				localSqlStatement.parameters[":mealeventid"] = mealEventId;
				localSqlStatement.parameters[":mealname"] = mealname;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = lastmodifiedtimestamp;
				localSqlStatement.parameters[":insulinratio"] = insulinRatio;
				localSqlStatement.parameters[":correctionfactor"] = correctionFactor;
				localSqlStatement.parameters[":previousBGlevel"] = previousBGlevel;
				localSqlStatement.parameters[":creationtimestamp"] = creationtimestamp;
				localSqlStatement.parameters[":comment_2"] = comment;
				localSqlStatement.addEventListener(SQLEvent.RESULT, mealEventCreated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, mealEventCreationFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database. Database0050");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			
			function mealEventCreated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,mealEventCreated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,mealEventCreationFailed);
				
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					event.lastInsertRowID = localSqlStatement.getResult().lastInsertRowID;
					dispatcher.dispatchEvent(event);
				}
			}
			
			function mealEventCreationFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,mealEventCreated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,mealEventCreationFailed);
				trace("Failed to create a mealEvent. Database0051");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
		}
		
		/**
		 * new bloodglucoselevel event will be added to the database<br>
		 */
		internal function createNewBloodGlucoseEvent(level:Number,timeStamp:Number,newLastModifiedTimeStamp:Number,unit:String,bloodglucoseeventid:Number, comment:String,dispatcher:EventDispatcher = null ):void {
			var localSqlStatement:SQLStatement = new SQLStatement()
			var localdispatcher:EventDispatcher = new EventDispatcher();
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = INSERT_BLOODGLUCOSEEVENT;
				//(bloodglucoseeventid, unit, creationtimestamp, value)
				localSqlStatement.parameters[":bloodglucoseeventid"] =  bloodglucoseeventid;
				localSqlStatement.parameters[":unit"] = unit;
				localSqlStatement.parameters[":creationtimestamp"] = timeStamp;
				if (unit  == ResourceManager.getInstance().getString('general','mmoll'))
					level = level * 10;
				localSqlStatement.parameters[":value"] = level;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = isNaN(newLastModifiedTimeStamp) ? (new Date()).valueOf() : newLastModifiedTimeStamp;
				localSqlStatement.parameters[":comment_2"] = comment;
				localSqlStatement.addEventListener(SQLEvent.RESULT, bloodGlucoseLevelCreated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, bloodGlucoseLevelCreationFailed);
				localSqlStatement.execute();
			}
			
			function bloodGlucoseLevelCreated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bloodGlucoseLevelCreated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bloodGlucoseLevelCreationFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function bloodGlucoseLevelCreationFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bloodGlucoseLevelCreated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bloodGlucoseLevelCreationFailed);
				trace("Failed to create a bloodglucseevent. Database0081");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database. Database0080");
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
			selectedItemId:Number,
			mealEventId:Number,
			itemDescription:String,
			unitDescription:String,
			standardAmount:int,
			kcal:int,
			protein:Number,
			carbs:Number,
			fat:Number,
			chosenAmount:Number,
			lastmodifiedtimestamp:Number,
			dispatcher:EventDispatcher):void {
			
			var localSqlStatement:SQLStatement = new SQLStatement()
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = INSERT_SELECTED_FOOD_ITEM;
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
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = lastmodifiedtimestamp;
				localSqlStatement.addEventListener(SQLEvent.RESULT, selectedItemCreated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, selectedItemCreationFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database. Database0050");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
						
			function selectedItemCreated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,selectedItemCreated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,selectedItemCreationFailed);
				trace("newSelectedItem successfully stored");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function selectedItemCreationFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,selectedItemCreated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,selectedItemCreationFailed);
				trace("Failed to create a selectedItem. Database0052");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
				
		/**
		 * get all mealevents, bloodglucoseevents, medicinevents and exerciseevents and store them in the arraycollection in the modellocator as MealEvent objects<br>
		 * The method also gets all selectedfooditems, which are stored in the correct MealEvent objects<br>
		 * if dispatcher is not null, then the result will be dispatched
		 */
		public function getAllEventsAndFillUpMeals(dispatcher:EventDispatcher):void {
			globalDispatcher = dispatcher;
			var localSqlStatement:SQLStatement = new SQLStatement()
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			var selectedFoodItems:ArrayCollection = new ArrayCollection();
			var currentMealEventID:Number;//used in the filterfunction for the selectedfooditems
			
			selectedFoodItems.filterFunction = filterByMealEventId;
			
			//we will delete from the database any element that is older than Settings.SETTINGSMAXTRACKINGSIZE
			//later on that should be moved to an archive database or archive table.
			//so start with calculating the minimumTimeStamp
			var minimumTimeStamp:Number = (new Date()).valueOf() - (new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE))) * 24 * 3600 * 1000;
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			
			function onOpenError(e:SQLError):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				if (globalDispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					event.data = "failed to open sql connection";
					globalDispatcher.dispatchEvent(event);
					globalDispatcher =  null;
				}
			}
			
			function onOpenResult(e:SQLError):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				
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
					for each (var o:Object in tempObject ) {
						var newSelectedFoodItem:SelectedFoodItem = new SelectedFoodItem(
							o.selectedfooditemid as Number,
							o.itemdescription as String,
							new Unit(o.unitdescription as String,o.standardamount as int,o.kcal as int,o.protein as Number,o.carbs as Number,o.fat as Number),
							o.chosenamount,
							o.lastmodifiedtimestamp);
						newSelectedFoodItem.mealEventId = o.mealevents_mealeventid as Number;
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
				if (globalDispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					event.data = "Failed to get all selectedFoodItems. Database0061";
					globalDispatcher.dispatchEvent(event);
					globalDispatcher =  null;
				}
			}
			
			function mealEventsRetrieved(result:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,mealEventsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,mealEventRetrievalFailed);
				
				var tempObject:Object = localSqlStatement.getResult().data;
				
				if (tempObject != null && tempObject is Array) {
					for each ( var o:Object in tempObject ) {
						if ((o.lastmodifiedtimestamp as Number) < minimumTimeStamp) {
							deleteMealEvent(o.mealeventid as Number);
						} else {
							currentMealEventID = o.mealeventid as Number;
							selectedFoodItems.refresh();
							var newMealEvent:MealEvent = new MealEvent(o.mealname as String,
								o.insulinratio as Number,
								o.correctionfactor as Number,
								o.prevousBGlevel as Number,
								o.creationtimestamp as Number,
								null,
								o.mealeventid as Number,
								o.comment_2 as String,
								o.lastmodifiedtimestamp  as Number,
								false,
								new ArrayCollection(selectedFoodItems.toArray()));
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
				}
				
				localSqlStatement.addEventListener(SQLEvent.RESULT,bloodGlucoseEventsRetrieved);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,bloodGlucoseRetrievalFailed);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = GET_ALLBLOODGLUCOSEEVENTS;
				localSqlStatement.execute();
				
			}
			
			function bloodGlucoseEventsRetrieved(result:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bloodGlucoseEventsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bloodGlucoseRetrievalFailed);
				
				var tempObject:Object = localSqlStatement.getResult().data;
				
				if (tempObject != null && tempObject is Array) {
					for each ( var o:Object in tempObject ) {
						if ((o.lastmodifiedtimestamp as Number) < minimumTimeStamp) {
							deleteBloodGlucoseEvent(o.bloodglucoseeventid as Number);
						} else {
							var tempLevel:Number = o.value as Number;
							if (o.unit as String  == ResourceManager.getInstance().getString('general','mmoll'))
								tempLevel = tempLevel/10;
							var newBloodGlucoseEvent:BloodGlucoseEvent = new BloodGlucoseEvent(tempLevel as Number,o.unit as String, o.bloodglucoseeventid as Number, o.comment_2 as String, o.creationtimestamp as Number,o.lastmodifiedtimestamp as Number,false);
							ModelLocator.getInstance().trackingList.addItem(newBloodGlucoseEvent);
							var creationTimeStampAsDate:Date = new Date(newBloodGlucoseEvent.timeStamp);
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
				}
				localSqlStatement.addEventListener(SQLEvent.RESULT,medicinEventsRetrieved);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,medicinEventsRetrievalFailed);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = GET_ALLMEDICINEVENTS;
				localSqlStatement.execute();
			}
			
			function medicinEventsRetrieved(result:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,medicinEventsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,medicinEventsRetrievalFailed);
				
				var tempObject:Object = localSqlStatement.getResult().data;
				
				if (tempObject != null && tempObject is Array) {
					for each ( var o:Object in tempObject ) {
						if ((o.lastmodifiedtimestamp as Number) < minimumTimeStamp) {
							deleteMedicinEvent(o.medicineventid as Number);
						} else {
							var newMedicinEvent:MedicinEvent = new MedicinEvent( o.amount as Number,o.medicinname as String,o.medicineventid as Number, o.comment_2 as String, o.creationtimestamp as Number,o.lastmodifiedtimestamp as Number,false);
							ModelLocator.getInstance().trackingList.addItem(newMedicinEvent);
							var creationTimeStampAsDate:Date = new Date(newMedicinEvent.timeStamp);
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
				}
				
				localSqlStatement.addEventListener(SQLEvent.RESULT,exerciseEventsRetrieved);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,exerciseEventsRetrievalFailed);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = GET_ALLEXERCISEEVENTS;
				localSqlStatement.execute();
			}
			
			function exerciseEventsRetrieved(result:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,exerciseEventsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,exerciseEventsRetrievalFailed);
				
				var tempObject:Object = localSqlStatement.getResult().data;
				var creationTimeStampAtMidNight:Number ;
				
				if (tempObject != null && tempObject is Array) {
					for each ( var o:Object in tempObject ) {
						if ((o.lastmodifiedtimestamp as Number) < minimumTimeStamp) {
							deleteExerciseEvent(o.exerciseeventid as Number);
						} else {
							var newExerciseEvent:ExerciseEvent = new ExerciseEvent(o.level as String,o.comment_2 as String,o.exerciseeventid as Number,o.creationtimestamp as Number,o.lastmodifiedtimestamp as Number,false);
							ModelLocator.getInstance().trackingList.addItem(newExerciseEvent);
							var creationTimeStampAsDate:Date = new Date(newExerciseEvent.timeStamp);
							creationTimeStampAtMidNight = (new Date(creationTimeStampAsDate.fullYearUTC,creationTimeStampAsDate.monthUTC,creationTimeStampAsDate.dateUTC,0,0,0,0)).valueOf();
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
				}
				
				var oldest:Number = (new Date(ModelLocator.getInstance().oldestDayLineStoredInTrackingList)).valueOf();
				var youngest :Number = (new Date(ModelLocator.getInstance().youngestDayLineStoredInTrackingList)).valueOf();
				
				//Now add list of daylines 
				for (var counter:Number = youngest;counter - 1 < oldest;counter = counter + 86400000) {
					ModelLocator.getInstance().trackingList.addItem(new DayLineWithTotalAmount(counter));
				}
				
				ModelLocator.getInstance().trackingList.refresh();
				
				// now populate ModelLocator.getInstance().meals
				ModelLocator.getInstance().refreshMeals();
				if (globalDispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					globalDispatcher.dispatchEvent(event);
					globalDispatcher =  null;
				}
			}
			
			function exerciseEventsRetrievalFailed(error:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,exerciseEventsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,exerciseEventsRetrievalFailed);
				trace("Failed to get all mealevents. Database0095");
				if (globalDispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					event.data = "Failed to get all mealevents. Database0095";
					globalDispatcher.dispatchEvent(event);
					globalDispatcher =  null;
				}
			}
			
			function medicinEventsRetrievalFailed(error:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,medicinEventsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,medicinEventsRetrievalFailed);
				trace("Failed to get all mealevents. Database0094");
				if (globalDispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					event.data = "Failed to get all mealevents. Database0094";
					globalDispatcher.dispatchEvent(event);
					globalDispatcher =  null;
				}
			}
			
			function filterByMealEventId(item:Object):Boolean {
				return ((item  as SelectedFoodItem).mealEventId == currentMealEventID);
			}
			
			function mealEventRetrievalFailed(error:SQLErrorEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,mealEventsRetrieved);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventRetrievalFailed);
				trace("Failed to get all mealevents. Database0060");
				if (globalDispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					event.data = "Failed to get all mealevents. Database0060";
					globalDispatcher.dispatchEvent(event);
					globalDispatcher =  null;
				}
			}
			
			function bloodGlucoseRetrievalFailed(error:SQLErrorEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,bloodGlucoseEventsRetrieved);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,bloodGlucoseRetrievalFailed);
				trace("Failed to get all mealevents. Database0090");
				if (globalDispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					event.data = "Failed to get all mealevents. Database0090";
					globalDispatcher.dispatchEvent(event);
					globalDispatcher =  null;
				}
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
		
		internal function updateSelectedFoodItem(selectedFoodItemId:Number, newMealEventId:Number,newDescription:String,newChosenAmount:Number, newUnit:Unit, newLastModifiedTimeStamp:Number, dispatcher:EventDispatcher):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);

			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = UPDATE_SELECTED_FOOD_ITEM;
				localSqlStatement.parameters[":selectedfooditemid"] = selectedFoodItemId;
				localSqlStatement.parameters[":itemdescription"] = newDescription;
				localSqlStatement.parameters[":standardamount"] = newUnit.standardAmount;
				localSqlStatement.parameters[":chosenamount"] = newChosenAmount;
				localSqlStatement.parameters[":unitdescription"] = newUnit.unitDescription;
				localSqlStatement.parameters[":kcal"] = newUnit.kcal;
				localSqlStatement.parameters[":carbs"] = newUnit.carbs;
				localSqlStatement.parameters[":fat"] = newUnit.fat;
				localSqlStatement.parameters[":protein"] = newUnit.protein;
				localSqlStatement.parameters[":mealevents_mealeventid"] = newMealEventId;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = isNaN(newLastModifiedTimeStamp) ? (new Date()).valueOf() : newLastModifiedTimeStamp;
				localSqlStatement.addEventListener(SQLEvent.RESULT, selectedItemUpdated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, selectedItemUpdateFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database. Database0101");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			
			function selectedItemUpdated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,selectedItemUpdated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,selectedItemUpdateFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function selectedItemUpdateFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,selectedItemUpdated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,selectedItemUpdateFailed);
				trace("Failed to update a insulinratio. Database0102");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
		}
		
		
		/**
		 * new medicin event will be added to the database<br>
		 * here the medicineventid will get the value of current date and time as Number 
		 */
		internal function createNewMedicinEvent(amount:Number,medicin:String, timeStamp:Number,newLastModifiedTimeStamp:Number,medicineventid:Number, comment:String,dispatcher:EventDispatcher = null):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = INSERT_MEDICINEVENT;
				//(bloodglucoseeventid, unit, creationtimestamp, value)
				localSqlStatement.parameters[":medicineventid"] = medicineventid;
				localSqlStatement.parameters[":amount"] = amount;
				localSqlStatement.parameters[":creationtimestamp"] = timeStamp;
				localSqlStatement.parameters[":medicinname"] = medicin;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = isNaN(newLastModifiedTimeStamp) ? (new Date()).valueOf() : newLastModifiedTimeStamp;
				localSqlStatement.parameters[":comment_2"] = comment;
				localSqlStatement.addEventListener(SQLEvent.RESULT, medicinEventCreated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, medicinEventCreationFailed);
				localSqlStatement.execute();
			}
			
			function medicinEventCreated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,medicinEventCreated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,medicinEventCreationFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function medicinEventCreationFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,medicinEventCreated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,medicinEventCreationFailed);
				trace("Failed to create a medicinEvent. Database0091");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database. Database0092");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		/**
		* medicinevent with specified medicineventid is updated with new values for timestamp, amount and medicinname
		*/ 	
		internal function updateMedicinEvent(medicinEventId:Number,newAmount:Number,newMedicinName:String,newCreationTimeStamp:Number, newLastModifiedTimeStamp:Number, comment:String,dispatcher:EventDispatcher = null):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = UPDATE_MEDICINEVENT;
				localSqlStatement.parameters[":id"] = medicinEventId;
				localSqlStatement.parameters[":amount"] = newAmount;
				localSqlStatement.parameters[":creationtimestamp"] = newCreationTimeStamp;
				localSqlStatement.parameters[":medicinname"] = newMedicinName;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = isNaN(newLastModifiedTimeStamp) ? (new Date()).valueOf() : newLastModifiedTimeStamp;
				localSqlStatement.parameters[":comment_2"] = comment;
				localSqlStatement.addEventListener(SQLEvent.RESULT, medicinEventUpdated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, medicinEventUpdateFailed);
				localSqlStatement.execute();
			}
			
			function medicinEventUpdated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,medicinEventUpdated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,medicinEventUpdateFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function medicinEventUpdateFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,medicinEventUpdated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,medicinEventUpdateFailed);
				trace("Failed to update a medicinEvent. Database0100");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database. Database0101");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
				
		/**
		 * new exercise event will be added to the database<br>
		 * here the exerciseeventid will get the value of current date and time as Number 
		 */
		internal function createNewExerciseEvent(level:String, comment:String, timeStamp:Number, newLastModifiedTimeStamp:Number,exerciseeventid:Number,dispatcher:EventDispatcher = null):void {
			var localSqlStatement:SQLStatement = new SQLStatement()
			var localdispatcher:EventDispatcher = new EventDispatcher();
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = INSERT_EXERCISEEVENT;
				//(bloodglucoseeventid, unit, creationtimestamp, value)
				localSqlStatement.parameters[":level"] = level;
				localSqlStatement.parameters[":creationtimestamp"] = timeStamp;
				localSqlStatement.parameters[":comment_2"] = comment;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = isNaN(newLastModifiedTimeStamp) ? (new Date()).valueOf() : newLastModifiedTimeStamp;
				localSqlStatement.parameters[":exerciseeventid"] = exerciseeventid;
				localSqlStatement.addEventListener(SQLEvent.RESULT, exerciseEventCreated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, exerciseEventCreationFailed);
				localSqlStatement.execute();
			}
			
			function exerciseEventCreated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,exerciseEventCreated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,exerciseEventCreationFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function exerciseEventCreationFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,exerciseEventCreated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,exerciseEventCreationFailed);
				trace("Failed to create a medicinEvent. Database0093");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database. Database0094");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		/**
		 * exerciseevent with specified exerciseeventid is updated with new values for timestamp, level and comment
		 */ 	
		internal function updateExerciseEvent(exerciseEventId:Number,newLevel:String,newComment_2:String,newCreationTimeStamp:Number,  newLastModifiedTimeStamp:Number,dispatcher:EventDispatcher = null):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = UPDATE_EXERCISEEVENT;
				localSqlStatement.parameters[":id"] = exerciseEventId;
				localSqlStatement.parameters[":level"] = newLevel;
				localSqlStatement.parameters[":creationtimestamp"] = newCreationTimeStamp;
				localSqlStatement.parameters[":comment_2"] = newComment_2;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = isNaN(newLastModifiedTimeStamp) ? (new Date()).valueOf() : newLastModifiedTimeStamp;
				localSqlStatement.addEventListener(SQLEvent.RESULT, exerciseEventUpdated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, exerciseEventUpdateFailed);
				localSqlStatement.execute();
			}
			
			function exerciseEventUpdated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,exerciseEventUpdated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,exerciseEventUpdateFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function exerciseEventUpdateFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,exerciseEventUpdated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,exerciseEventUpdateFailed);
				trace("Failed to update an exerciseEvent. Database0102");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database. Database0102");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}

		
		/**
		 * bloodglucoseevent with specified bloodglucoseeventid is updated with new values  level and unit
		 */ 	
		internal function updateBloodGlucoseEvent(bloodglucoseEventId:Number,unit:String,bloodGlucoseLevel:Number,newCreationTimeStamp:Number,  newLastModifiedTimeStamp:Number, comment:String,dispatcher:EventDispatcher = null):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = UPDATE_BLOODGLUCOSEEVENT;
				localSqlStatement.parameters[":id"] = bloodglucoseEventId;
				localSqlStatement.parameters[":unit"] = unit;
				if (unit  == ResourceManager.getInstance().getString('general','mmoll'))
					bloodGlucoseLevel = bloodGlucoseLevel * 10;
				localSqlStatement.parameters[":value"] = bloodGlucoseLevel;
				localSqlStatement.parameters[":creationtimestamp"] = newCreationTimeStamp;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = isNaN(newLastModifiedTimeStamp) ? (new Date()).valueOf() : newLastModifiedTimeStamp;
				localSqlStatement.parameters[":comment_2"] = comment;
				localSqlStatement.addEventListener(SQLEvent.RESULT, bloodglucoseEventUpdated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, bloodglucoseEventUpdateFailed);
				localSqlStatement.execute();
			}
			
			function bloodglucoseEventUpdated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bloodglucoseEventUpdated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bloodglucoseEventUpdateFailed);
				trace("bloodglucoseevent updated in database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function bloodglucoseEventUpdateFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bloodglucoseEventUpdated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bloodglucoseEventUpdateFailed);
				trace("Failed to update a bloodglucoseEvent. Database0110");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database. Database0111");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		
		internal function deleteMealEvent(mealEventId:Number,dispatcher:EventDispatcher = null):void {
			var yes:int=0;
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = DELETE_ROW_IN_TABLE_MEALEVENTS;
				localSqlStatement.parameters[":mealeventid"] = mealEventId;
				localSqlStatement.addEventListener(SQLEvent.RESULT, mealeventDeleted);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, mealeventDeletionFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database in unction deleteMealEvent in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			
			function mealeventDeleted(se:SQLEvent):void {
				if (yes < 10) {
					yes ++;
					trace("in database.as mealeventDeleted");
				}
				localSqlStatement.removeEventListener(SQLEvent.RESULT,mealeventDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,mealeventDeletionFailed);
				localSqlStatement.addEventListener(SQLEvent.RESULT,selectedFoodItemsDeleted);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,selectedFoodItemsDeletionFailed);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = DELETE_ROW_IN_TABLE_SELECTED_FOODITEMS_MATCHING_MEALEVENTID;
				localSqlStatement.clearParameters();
				localSqlStatement.parameters[":mealevents_mealeventid"] = mealEventId;
				localSqlStatement.execute();
			}
			
			function selectedFoodItemsDeleted (se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,selectedFoodItemsDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,selectedFoodItemsDeletionFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function selectedFoodItemsDeletionFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,selectedFoodItemsDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,selectedFoodItemsDeletionFailed);
				trace("SelectedFoodItemsDeletionFailed. function deleteMealEvent in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function mealeventDeletionFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,mealeventDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,mealeventDeletionFailed);
				trace("Mealeventdeletionfailed, function deleteMealEvent in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		internal function deleteMedicinEvent(medicinEventId:Number, dispatcher:EventDispatcher = null):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = DELETE_ROW_IN_TABLE_MEDICINEVENTS;
				localSqlStatement.parameters[":medicineventid"] = medicinEventId;
				localSqlStatement.addEventListener(SQLEvent.RESULT, medicineventDeleted);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, medicineventDeletionFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database in unction deleteMealEvent in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function medicineventDeleted(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,medicineventDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,medicineventDeletionFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function medicineventDeletionFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,medicineventDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,medicineventDeletionFailed);
				trace("medicineventdeletionfailed, function delete Event in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		internal function deleteBloodGlucoseEvent(bloodglucoseEventId:Number, dispatcher:EventDispatcher = null):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = DELETE_ROW_IN_TABLE_BLOODGLUCOSEEVENTS;
				localSqlStatement.parameters[":bloodglucoseeventid"] = bloodglucoseEventId;
				localSqlStatement.addEventListener(SQLEvent.RESULT, bloodglucoseeventDeleted);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, bloodglucoseeventDeletionFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database in unction deleteMealEvent in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function bloodglucoseeventDeleted(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bloodglucoseeventDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bloodglucoseeventDeletionFailed);
				trace("bloodglucoseevent deleted in database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function bloodglucoseeventDeletionFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bloodglucoseeventDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bloodglucoseeventDeletionFailed);
				trace("bloodglucoseeventdeletionfailed, function delete Event in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		internal function deleteExerciseEvent(exerciseEventId:Number, dispatcher:EventDispatcher = null):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = DELETE_ROW_IN_TABLE_EXERCISEEVENTS;
				localSqlStatement.parameters[":exerciseeventid"] = exerciseEventId;
				localSqlStatement.addEventListener(SQLEvent.RESULT, exerciseeventDeleted);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, exerciseeventDeletionFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database in unction deleteMealEvent in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function exerciseeventDeleted(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,exerciseeventDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,exerciseeventDeletionFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function exerciseeventDeletionFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,exerciseeventDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,exerciseeventDeletionFailed);
				trace("exerciseeventdeletionfailed, function delete Event in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		/**
		 * deletes the selectedfooditem from the database, nothing changes to the mealevent or meal that has this selectedfooditem 
		 */
		internal function deleteSelectedFoodItem(selectedFoodItemId:Number, dispatcher:EventDispatcher = null):void {
			var localSqlStatement:SQLStatement = new SQLStatement();
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			localdispatcher.addEventListener(SQLEvent.RESULT,onOpenResult);
			localdispatcher.addEventListener(SQLErrorEvent.ERROR,onOpenError);
			if (openSQLConnection(localdispatcher))
				onOpenResult(null);
			
			function onOpenResult(se:SQLEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = DELETE_ROW_IN_TABLE_SELECTED_FOODITEMS_MATCHING_SELECTEDFOODITEMID;
				localSqlStatement.parameters[":selectedfooditemid"] = selectedFoodItemId;
				localSqlStatement.addEventListener(SQLEvent.RESULT, selectedFoodItemDeleted);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, selectedFoodItemDeletionFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				trace("Failed to open the database in function deleteSelectedFoodItem in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function selectedFoodItemDeleted(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,selectedFoodItemDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,selectedFoodItemDeletionFailed);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function selectedFoodItemDeletionFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,selectedFoodItemDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,selectedFoodItemDeletionFailed);
				trace("selectedFoodItemDeletionFailed, function deleteSelectedFoodItem in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		/**
		 * return true if database already exists, false in the other case
		 */
		public static function databaseExists():Boolean {
			dbFile  = File.applicationStorageDirectory.resolvePath(dbFileName);
			var sqlConnection:SQLConnection = new SQLConnection();
			try {
				sqlConnection.open(dbFile, SQLMode.READ);
				sqlConnection.close();
				return true;
			} catch (error:SQLError) {
				return false;
			}
			return true;//should never come here
		}
	} //class
} //package
