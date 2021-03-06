/**
 Copyright (C) 2016  hippoandfriends
 
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
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.collections.ArrayCollection;
	
	import model.ModelLocator;
	
	import myComponents.DayLineWithTotalAmount;
	
	import utilities.DateTimeUtilities;
	import utilities.Trace;
	
	
	
	/**
	 * Database class is a singleton
	 */ 
	public final class Database extends EventDispatcher
	{
		[ResourceBundle("general")]
		[ResourceBundle("editmedicineventview")]
		
		private static var instance:Database = new Database();
		
		public var aConn:SQLConnection;		
		
		private var sqlStatement:SQLStatement;
		
		private var globalDispatcher:EventDispatcher;
		
		private var sampleDbFileName:String;
		private static const dbFileName:String = "foodfile.db";
		private  static var dbFile:File  ;
		private var xmlFileName:String;
		public static const medicinnamesplitter:String = "-";//medicinname stored in database will be used for medicinname and bolustype
		
		private const DATABASE_VERSION_1:String = "version1";
		private const DATABASE_VERSION_2:String = "version2";
		private const DATABASE_VERSION_3:String = "version3";
		private const DATABASE_HIGHEST_VERSION:String = DATABASE_VERSION_3;
		
		private const CHECK_IF_VERSIONINFO_TABLE_EXISTS:String = "SELECT * FROM versioninfo";
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
		private const CREATE_TABLE_EXERCISE_EVENTS:String = "CREATE TABLE IF NOT EXISTS exerciseevents (exerciseeventid INTEGER," +//just there for legacy , will actually always have value 0
			"newexerciseeventid STRING PRIMARY KEY, " +
			"level TEXT, " +
			"creationtimestamp TIMESTAMP NOT NULL," +
			"comment_2 TEXT, lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		private const CREATE_TABLE_BLOODGLUCOSE_EVENTS:String = "CREATE TABLE IF NOT EXISTS bloodglucoseevents (bloodglucoseeventid INTEGER," +//just there for legacy , will actually always have value 0
			"newbloodglucoseeventid STRING PRIMARY KEY, " +
			"unit TEXT NOT NULL, " +
			"creationtimestamp TIMESTAMP NOT NULL," +
			"value REAL NOT NULL, comment_2 TEXT, lastmodifiedtimestamp TIMESTAMP NOT NULL)";
		private const CREATE_TABLE_MEDICIN_EVENTS:String = "CREATE TABLE IF NOT EXISTS medicinevents (medicineventid INTEGER," +//just there for legacy , will actually always have value 0
			"newmedicineventid STRING PRIMARY KEY, " +
			"medicinname TEXT NOT NULL, " +
			"creationtimestamp TIMESTAMP NOT NULL," +
			"amount REAL NOT NULL, comment_2 TEXT, lastmodifiedtimestamp TIMESTAMP NOT NULL)";		
		private const CREATE_TABLE_MEAL_EVENTS:String = "CREATE TABLE IF NOT EXISTS mealevents (mealeventid INTEGER," +//just there for legacy , will actually always have value 0
			"newmealeventid STRING PRIMARY KEY, " +
			"mealname TEXT NOT NULL, " +
			"comment_2 TEXT, lastmodifiedtimestamp TIMESTAMP NOT NULL, " +
			"insulinratio REAL," +
			"correctionfactor REAL," +
			"creationtimestamp TIMESTAMP NOT NULL," +
			"previousBGlevel REAL)";	//previousBGlevel is not used anymore	
		private const CREATE_TABLE_SELECTED_FOODITEMS:String = "CREATE TABLE IF NOT EXISTS selectedfooditems (selectedfooditemid INTEGER," +//just there for legacy , will actually always have value 0
			"newselectedfooditemid STRING PRIMARY KEY , " +
			"mealevents_mealeventid STRING NOT NULL, " +
			"newmealevents_mealeventid TEXT, " +
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
			"DELETE FROM selectedfooditems where (mealevents_mealeventid = :mealevents_mealeventid OR newmealevents_mealeventid = :mealevents_mealeventid)";
		private const DELETE_ROW_IN_TABLE_EXERCISEEVENTS:String = 
			"DELETE FROM exerciseevents where (exerciseeventid = :exerciseeventid OR newexerciseeventid = :exerciseeventid)";
		private const DELETE_ROW_IN_TABLE_BLOODGLUCOSEEVENTS:String = 
			"DELETE FROM bloodglucoseevents where (bloodglucoseeventid = :bloodglucoseeventid OR newbloodglucoseeventid = :bloodglucoseeventid)";
		private const DELETE_ROW_IN_TABLE_MEDICINEVENTS:String = 
			"DELETE FROM medicinevents where (medicineventid = :medicineventid OR newmedicineventid = :medicineventid)";
		private const DELETE_ROW_IN_TABLE_MEALEVENTS:String = 
			"DELETE FROM mealevents where (mealeventid = :mealeventid OR newmealeventid = :mealeventid)";
		private const DELETE_ROW_IN_TABLE_SELECTED_FOODITEMS_MATCHING_SELECTEDFOODITEMID:String = 
			"DELETE FROM selectedfooditems where (selectedfooditemid = :selectedfooditemid OR newselectedfooditemid = :selectedfooditemid)";
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
		private const UPDATE_MEALEVENT_LASTMODIFIEDTIMESTAMP:String = "UPDATE mealevents SET lastmodifiedtimestamp = :lastmodifiedtimestamp WHERE (mealeventid = :mealeventid OR newmealeventid = :mealeventid)";
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
		private const UPDATE_MEAL_EVENT:String = "UPDATE mealevents set comment_2 = :comment_2, mealname = :mealname, insulinratio = :insulinratio, creationtimestamp = :creationtimestamp, lastmodifiedtimestamp = :lastmodifiedtimestamp,correctionfactor = :correctionfactor WHERE (mealeventid = :id OR newmealeventid = :id)";
		private const UPDATE_SELECTED_FOOD_ITEM:String="UPDATE selectedfooditems set mealevents_mealeventid = 0, newmealevents_mealeventid = :mealevents_mealeventid,itemdescription = :itemdescription, standardamount = :standardamount,unitdescription = :unitdescription,kcal = :kcal,protein = :protein,carbs = :carbs,fat = :fat,chosenamount = :chosenamount,lastmodifiedtimestamp = :lastmodifiedtimestamp WHERE (selectedfooditemid = :selectedfooditemid OR newselectedfooditemid = :selectedfooditemid)";
		private const UPDATE_MEDICINEVENT:String="UPDATE medicinevents set comment_2 = :comment_2, amount = :amount, medicinname = :medicinname, lastmodifiedtimestamp = :lastmodifiedtimestamp, creationtimestamp = :creationtimestamp WHERE (medicineventid = :id OR newmedicineventid = :id)";
		private const UPDATE_EXERCISEEVENT:String="UPDATE exerciseevents set comment_2 = :comment_2, level = :level, comment_2 = :comment_2, lastmodifiedtimestamp = :lastmodifiedtimestamp, creationtimestamp = :creationtimestamp WHERE (exerciseeventid = :id OR newexerciseeventid = :id)";
		private const UPDATE_BLOODGLUCOSEEVENT:String="UPDATE bloodglucoseevents set comment_2 = :comment_2, unit = :unit, value = :value, lastmodifiedtimestamp = :lastmodifiedtimestamp, creationtimestamp = :creationtimestamp WHERE (bloodglucoseeventid = :id OR newbloodglucoseeventid = :id)";
		
		/**
		 * INSERT INTO mealevents (mealeventid , mealname , lastmodifiedtimestamp ) VALUES (:mealeventid,:mealname,:lastmodifiedtimestamp)
		 */ 
		private const INSERT_MEALEVENT:String = "INSERT INTO mealevents (mealeventid , newmealeventid, mealname , lastmodifiedtimestamp, insulinratio, correctionfactor, creationtimestamp, comment_2 ) VALUES (:mealeventid, :newmealeventid,:mealname,:lastmodifiedtimestamp,:insulinratio,:correctionfactor,:creationtimestamp,:comment_2)";
		
		private const INSERT_SELECTED_FOOD_ITEM:String = "INSERT INTO selectedfooditems (selectedfooditemid, newselectedfooditemid, mealevents_mealeventid, newmealevents_mealeventid, itemdescription ,unitdescription,standardamount,kcal,protein,carbs, fat, chosenamount,lastmodifiedtimestamp ) VALUES (:selectedfooditemid, :newselectedfooditemid, 0, :mealevents_mealeventid,:itemdescription ,:unitdescription,:standardamount,:kcal,:protein,:carbs,:fat,:chosenamount, :lastmodifiedtimestamp)";
		
		private const INSERT_BLOODGLUCOSEEVENT:String = "INSERT INTO bloodglucoseevents (bloodglucoseeventid, newbloodglucoseeventid, unit, creationtimestamp, value, lastmodifiedtimestamp, comment_2) VALUES (:bloodglucoseeventid, :newbloodglucoseeventid, :unit,:creationtimestamp, :value, :lastmodifiedtimestamp,:comment_2)";
		
		private const INSERT_MEDICINEVENT:String = "INSERT INTO medicinevents (medicineventid, newmedicineventid, medicinname, amount, creationtimestamp, lastmodifiedtimestamp, comment_2) VALUES (:medicineventid, :newmedicineventid, :medicinname,  :amount, :creationtimestamp, :lastmodifiedtimestamp,:comment_2)";
		
		private const INSERT_EXERCISEEVENT:String = "INSERT INTO exerciseevents (exerciseeventid, newexerciseeventid, level, creationtimestamp, comment_2, lastmodifiedtimestamp, comment_2) VALUES (:exerciseeventid, :newexerciseeventid, :level, :creationtimestamp, :comment_2, :lastmodifiedtimestamp,:comment_2)";
		
		private const INSERT_COMMENT_COLUMN_IN_MEALEVENTS:String = "ALTER TABLE mealevents ADD comment_2 TEXT";
		private const INSERT_COMMENT_COLUMN_IN_MEDICINEVENTS:String = "ALTER TABLE medicinevents ADD comment_2 TEXT";
		private const INSERT_COMMENT_COLUMN_IN_BLOODGLUCOSEEVENTS:String = "ALTER TABLE bloodglucoseevents ADD comment_2 TEXT";
		/**
		 * insert version info should only be used in upgrade to version 2
		 */
		private const INSERT_VERSIONINFO:String = "INSERT INTO versioninfo (info,lastmodifiedtimestamp) VALUES (:info, :lastmodifiedtimestamp)";
		private const UPDATE_VERSIONINFO:String = "UPDATE versioninfo set info = :info, lastmodifiedtimestamp = :lastmodifiedtimestamp";
		/**
		 * upgrade to version 3
		 */
		private const UPDATE_TABLE_EXERCISE_EVENTS_ADD_COLUMN_NEWEVENTID:String = "ALTER TABLE exerciseevents ADD newexerciseeventid TEXT";
		private const UPDATE_TABLE_BLOODGLUCOSE_EVENTS_ADD_COLUMN_NEWEVENTID:String = "ALTER TABLE bloodglucoseevents ADD newbloodglucoseeventid TEXT";
		private const UPDATE_TABLE_MEDICIN_EVENTS_ADD_COLUMN_NEWEVENTID:String = "ALTER TABLE medicinevents ADD newmedicineventid TEXT";
		private const UPDATE_TABLE_MEAL_EVENTS_ADD_COLUMN_NEWEVENTID:String = "ALTER TABLE mealevents ADD newmealeventid TEXT";
		private const UPDATE_TABLE_SELECTED_FOODITEMS_ADD_COLUMN_NEWEVENTID:String = "ALTER TABLE selectedfooditems ADD newselectedfooditemid TEXT";
		private const UPDATE_TABLE_SELECTED_FOODITEMS_ADD_COLUMN_NEWMEALEVENTID:String = "ALTER TABLE selectedfooditems ADD newmealevents_mealeventid TEXT";
		
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
		
		private var tempId:int;
		
		
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
					Trace.myTrace("Database.as : writing complete");
					fs.close();
					dbFile.deleteFile();
					Trace.myTrace("Database.as : deletion complete");					
					success = true;
				}
				catch (e:Error)
				{
					Trace.myTrace(e.name + ", " + e.message );
					fs.close();
				}				
			}
			return success;
		}
		
		/**
		 * will get the setting from the database<br>
		 * if there's no connection yet, then a connection will be opened in synchronous mode in order to retrieve the setting<br>
		 * Goal is that this is only used to get the setting from the database before init is called, because if that's the case, the values in the Settings class are not
		 * yet overwritten by the values in the database<br>
		 * returns the literal string "null" if setting not found in the database or database not existing yet
		 */
		public function getSetting(settingId:int):String {
			var sqlConn:SQLConnection = new SQLConnection();
			var sqlStatement:SQLStatement = new SQLStatement();
			
			dbFile  = File.applicationStorageDirectory.resolvePath(dbFileName);
			try {
				sqlConn.open(dbFile,SQLMode.READ);
			} catch (error:SQLError) {
				return "null";//database not existing yet, default values from settings should be taken
			}
			
			sqlStatement.text = this.GET_ALL_SETTINGS + " where id = " + new Number(settingId);
			sqlStatement.sqlConnection = sqlConn;
			sqlStatement.execute();
			var result:Object = sqlStatement.getResult().data;
			sqlConn.close();
			if (result != null && result is Array) {
				return result[0].value;
			}
			return "null";
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
			
			Trace.myTrace("Database.as : HelpDiabetes-air : Database.init");
			
			this.globalDispatcher = dispatcher;
			dbFile  = File.applicationStorageDirectory.resolvePath(dbFileName);
			
			this.aConn = new SQLConnection();
			this.aConn.addEventListener(SQLEvent.OPEN, onConnOpen);
			this.aConn.addEventListener(SQLErrorEvent.ERROR, onConnError);
			Trace.myTrace("Database.as : Attempting to open database in update mode. Database:0004");
			this.aConn.openAsync(dbFile, SQLMode.UPDATE);
			
			function onConnOpen(se:SQLEvent):void
			{
				Trace.myTrace("Database.as : SQL Connection successfully opened. Database:0001");
				aConn.removeEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.removeEventListener(SQLErrorEvent.ERROR, onConnError);	
				createTables();
			}
			
			function onConnError(see:SQLErrorEvent):void
			{
				Trace.myTrace("Database.as : SQL Error while attempting to open database. Database:0002");
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
				Trace.myTrace("Database.as : Attempting to open database in creation mode. Database:0003");
				aConn.openAsync(dbFile, SQLMode.CREATE);
			}
		}
		
		/**
		 * Will execute SQL that will either create the tables in a fresh database or return, if they're already creatd.
		 **/
		private function createTables():void
		{			
			Trace.myTrace("Database.as : in method createtables");
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
				Trace.myTrace("Database.as : Failed to create settings table. Database:0005");
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
							retrievalResult[(o.id as int) + 100] = (o.value as String);
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
					if (retrievalResult[id] == null && (id - 100) != Settings.SettingsAccessToken) {
						tempId = id as int;
						trace ("adding setting with id = " + id);
						sqlStatement.clearParameters();
						sqlStatement.addEventListener(SQLEvent.RESULT,settingAdded);
						sqlStatement.addEventListener(SQLErrorEvent.ERROR,addingSettingFailed);
						sqlStatement.text = 
							(id - 100 != Settings.SettingsFirstStartUp || !databaseWasCopiedFromSampleFile)
							?
							INSERT_SETTING
							:
							UPDATE_SETTING;
						sqlStatement.parameters[":id"] = id - 100;
						sqlStatement.parameters[":value"] = Settings.getInstance().getSetting(id - 100);
						sqlStatement.parameters[":lastmodifiedtimestamp"] = Settings.getInstance().getSettingLastModifiedTimeStamp(id - 100);
						sqlStatement.execute();
					} else {
						addMissingSetting(id + 1);
					}
				}
			}
			
			function settingAdded (se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,settingAdded);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,addingSettingFailed);
				
				addMissingSetting((sqlStatement.parameters[":id"] as int) + 1 + 100);
			}
			
			function addingSettingFailed (se:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,settingAdded);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,addingSettingFailed);
				Trace.myTrace("Database.as : Failed to add setting " + tempId + ". Database:0006");
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to add setting " + tempId + ". Database:0006";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
			}
			
			function settingsRetrievalFailed(se:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,settingsRetrieved);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,settingsRetrievalFailed);
				Trace.myTrace("Database.as : Failed to retrieve settings. Database:0007");
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
				Trace.myTrace("Database.as : Failed to create table :" + sqlStatement.text + ". Database0008");
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
				Trace.myTrace("Database.as : Failed to create table :" + sqlStatement.text + ". Database0009");
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
				Trace.myTrace("Database.as : Failed to create table :" + sqlStatement.text + ". Database0011");
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
				Trace.myTrace("Database.as : Failed to create table :" + sqlStatement.text + ". Database0012");
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
				Trace.myTrace("Database.as : Failed to create table :" + sqlStatement.text + ". Database0013");
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
				Trace.myTrace("Database.as : Failed to create table :" + sqlStatement.text + ". Database0014");
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
				Trace.myTrace("Database.as : Failed to create table :" + sqlStatement.text + ". Database0015" + "error = " + see.toString());
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
				Trace.myTrace("Database.as : Failed to create table :" + sqlStatement.text + ". Database0016" + "error = " + see.toString());
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
			sqlStatement.addEventListener(SQLEvent.RESULT,templateTableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function templateTableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,templateTableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				checkTableVersionInfo();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,templateTableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				Trace.myTrace("Database.as : Failed to create table :" + sqlStatement.text + ". Database0017");
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0017";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
			}
		}
		
		private function checkTableVersionInfo():void {
			sqlStatement.text = CHECK_IF_VERSIONINFO_TABLE_EXISTS;
			sqlStatement.clearParameters();
			sqlStatement.addEventListener(SQLEvent.RESULT,tableExists);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableDoesNotExist);
			sqlStatement.execute();
			
			function tableExists(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableExists);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableDoesNotExist);
				checkVersionInfo();
			}
			
			function tableDoesNotExist(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,tableExists);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableDoesNotExist);
				createTableVersionInfo();
			}
		}
		
		private function createTableVersionInfo():void {
			sqlStatement.text = CREATE_TABLE_VERSIONINFO;
			sqlStatement.clearParameters();
			sqlStatement.addEventListener(SQLEvent.RESULT,versionInfoTableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,tableCreationError);
			sqlStatement.execute();
			
			function versionInfoTableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,versionInfoTableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				insertLatestVersionInfo();
			}
			
			function tableCreationError(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,versionInfoTableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,tableCreationError);
				Trace.myTrace("Database.as : Failed to create table :" + sqlStatement.text + ". Database0120");
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to create table :" + sqlStatement.text + ". Database0120";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
			}
			
		}
		
		private function insertLatestVersionInfo():void {
			sqlStatement.addEventListener(SQLEvent.RESULT,latestVersionInfoInserted);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,insertLatestVersionInfoFailed);
			sqlStatement.text = INSERT_VERSIONINFO;
			sqlStatement.clearParameters();
			sqlStatement.parameters[":info"] = DATABASE_HIGHEST_VERSION;
			sqlStatement.parameters[":lastmodifiedtimestamp"] = (new Date()).valueOf();
			sqlStatement.execute();
			
			function latestVersionInfoInserted(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,latestVersionInfoInserted);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,insertLatestVersionInfoFailed);
				createTableSource();
			}
			
			function insertLatestVersionInfoFailed(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,latestVersionInfoInserted);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,insertLatestVersionInfoFailed);
				Trace.myTrace("Database.as : Failed to insert version :" + sqlStatement.text + ". Database0121");
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to insert version :" + sqlStatement.text + ". Database0121";
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
						Trace.myTrace("Database.as : database version = " + version);
						if (version == DATABASE_VERSION_1)//in fact will never happen, because we don't insert this string during creation of version 1
							upgradeToVersion2();
						else if (version == DATABASE_VERSION_2)//in fact will never happen, because we don't insert this string during creation of version 1
							upgradeToVersion3();
						else {
							//we should already be on version 3, later on, if there's a version 4, will check on version 3
							createTableSource();
						}
					}
				} else {//so this is if database version would be version 1, in which case VERSION_INFO would not even have existed yet
					//should normally not happen anymore
					upgradeToVersion2();
				}
			}
			
			function checkVersionInfoError(se:SQLError):void {
				localSqlStatement.removeEventListener(DatabaseEvent.RESULT_EVENT,checkVersionInfoResult);	
				localSqlStatement.removeEventListener(DatabaseEvent.ERROR_EVENT,checkVersionInfoError);	
				Trace.myTrace("Database.as : Failed to get the versioninfo. Database0121");
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
				Trace.myTrace("Database.as : Failed to upgrade to version 2 :" + sqlStatement.text + ". Database0121. see.error.details = " + see.error.details);
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to upgrade to version 2 :" + sqlStatement.text + ". Database0121";
					globalDispatcher.dispatchEvent(errorEvent);
					globalDispatcher = null;
				}
			}
		}
		
		/**
		 *  version 3 is about changing the type of eventid to TEXT
		 */
		private function upgradeToVersion3():void {
			sqlStatement = new SQLStatement();
			sqlStatement.sqlConnection = aConn;

			sqlStatement.text = UPDATE_TABLE_BLOODGLUCOSE_EVENTS_ADD_COLUMN_NEWEVENTID;
			sqlStatement.clearParameters();
			sqlStatement.addEventListener(SQLEvent.RESULT,alterTableBloodGlucoseEventsFinished);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,alterTableEventsFailed);
			sqlStatement.execute();
			
			function alterTableBloodGlucoseEventsFinished(se:SQLEvent):void {
				Trace.myTrace("Database.as : alter table bloodglucoseevents success");
				sqlStatement.removeEventListener(SQLEvent.RESULT,alterTableBloodGlucoseEventsFinished);
				sqlStatement = new SQLStatement();
				sqlStatement.sqlConnection = aConn;

				sqlStatement.text = UPDATE_TABLE_EXERCISE_EVENTS_ADD_COLUMN_NEWEVENTID;
				sqlStatement.clearParameters();
				sqlStatement.addEventListener(SQLEvent.RESULT,alterTableExerciseEventsFinished);
				sqlStatement.execute();
			}
			
			function alterTableExerciseEventsFinished(se:SQLEvent):void {
				Trace.myTrace("Database.as : alter table exerciseevents success");
				sqlStatement.removeEventListener(SQLEvent.RESULT,alterTableExerciseEventsFinished);
				sqlStatement = new SQLStatement();
				sqlStatement.sqlConnection = aConn;

				sqlStatement.text = UPDATE_TABLE_MEDICIN_EVENTS_ADD_COLUMN_NEWEVENTID;
				sqlStatement.clearParameters();
				sqlStatement.addEventListener(SQLEvent.RESULT,alterTableMedicinEventsFinished);
				sqlStatement.execute();
			}
			
			function alterTableMedicinEventsFinished(se:SQLEvent):void {
				Trace.myTrace("Database.as : alter table medicinevents success");
				sqlStatement.removeEventListener(SQLEvent.RESULT,alterTableExerciseEventsFinished);
				sqlStatement = new SQLStatement();
				sqlStatement.sqlConnection = aConn;

				sqlStatement.text = UPDATE_TABLE_MEAL_EVENTS_ADD_COLUMN_NEWEVENTID;
				sqlStatement.clearParameters();
				sqlStatement.addEventListener(SQLEvent.RESULT,alterTableMealEventsFinished);
				sqlStatement.execute();
			}
			
			function alterTableMealEventsFinished(se:SQLEvent):void {
				Trace.myTrace("Database.as : alter table mealevents success");
				sqlStatement.removeEventListener(SQLEvent.RESULT,alterTableMealEventsFinished);
				sqlStatement = new SQLStatement();
				sqlStatement.sqlConnection = aConn;

				sqlStatement.text = UPDATE_TABLE_SELECTED_FOODITEMS_ADD_COLUMN_NEWEVENTID;
				sqlStatement.clearParameters();
				sqlStatement.addEventListener(SQLEvent.RESULT,alterTableSelectedFoodItemsFinished);
				sqlStatement.execute();
			}
			
			function alterTableSelectedFoodItemsFinished(se:SQLEvent):void {
				Trace.myTrace("Database.as : alter table selectedfooditems success");
				sqlStatement.removeEventListener(SQLEvent.RESULT,alterTableSelectedFoodItemsFinished);
				sqlStatement = new SQLStatement();
				sqlStatement.sqlConnection = aConn;

				sqlStatement.text = UPDATE_TABLE_SELECTED_FOODITEMS_ADD_COLUMN_NEWMEALEVENTID;
				sqlStatement.clearParameters();
				sqlStatement.addEventListener(SQLEvent.RESULT,alterTableSelectedFoodItemsNewMealEventIdFinished);
				sqlStatement.execute();
			}
			
			function alterTableSelectedFoodItemsNewMealEventIdFinished(se:SQLEvent):void {
				Trace.myTrace("Database.as : alter table selectedfooditems 2 success");
				sqlStatement.removeEventListener(SQLEvent.RESULT,alterTableSelectedFoodItemsNewMealEventIdFinished);
				sqlStatement = new SQLStatement();
				sqlStatement.sqlConnection = aConn;

				sqlStatement.text = UPDATE_VERSIONINFO;
				sqlStatement.clearParameters();
				sqlStatement.parameters[":info"] = DATABASE_VERSION_3;
				sqlStatement.parameters[":lastmodifiedtimestamp"] = (new Date()).valueOf();
				sqlStatement.addEventListener(SQLEvent.RESULT,updateVersionInfoFinished);
				sqlStatement.execute();
			}
			
			function updateVersionInfoFinished(se:SQLEvent):void {
				Trace.myTrace("Database.as : update version info success");
				sqlStatement.removeEventListener(SQLEvent.RESULT,updateVersionInfoFinished);
				sqlStatement.removeEventListener(SQLEvent.RESULT,alterTableEventsFailed);
				checkVersionInfo();
			}
			
			function alterTableEventsFailed(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,alterTableBloodGlucoseEventsFinished);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,alterTableEventsFailed);
				Trace.myTrace("Database.as : Failed to upgrade to version 3 :" + sqlStatement.text + ". Database0122. see.error.details = " + see.error.details);
				if (globalDispatcher != null) {
					var errorEvent:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					errorEvent.data = "Failed to upgrade to version 3 :" + sqlStatement.text + ". Database0122";
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
			sqlStatement.addEventListener(SQLEvent.RESULT,sourceTableCreated);
			sqlStatement.addEventListener(SQLErrorEvent.ERROR,sourceTableCreationError);
			sqlStatement.execute();
			
			function sourceTableCreated(se:SQLEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,sourceTableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,sourceTableCreationError);
				checkSource();
			}
			
			function sourceTableCreationError(see:SQLErrorEvent):void {
				sqlStatement.removeEventListener(SQLEvent.RESULT,sourceTableCreated);
				sqlStatement.removeEventListener(SQLErrorEvent.ERROR,sourceTableCreationError);
				Trace.myTrace("Database.as : Failed to create table :" + sqlStatement.text + ". Database0018");
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
				Trace.myTrace("Database.as : Failed to get the source. Database0019");
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
				Trace.myTrace("Database.as : Failed to insert the source. Database0020");
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
				Trace.myTrace("Database.as : Failed to insert a food item. Database0021");
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
				Trace.myTrace("Database.as : Failed to delete fooditems from database");
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
			}
			
			function foodItemsDeleted(se:SQLEvent):void  {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,foodItemsDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,foodItemDeletionFailed);
				Trace.myTrace("Database.as : fooditems deleted from database");
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
				Trace.myTrace("Database.as : Failed to delete units from database");
				if (dispatcher != null)
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
			}
			
			function unitsDeleted(se:SQLEvent):void  {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,unitsDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,unitDeletionFailed);
				Trace.myTrace("Database.as : units deleted from database");
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
				Trace.myTrace("Database.as : Failed to insert a unit. Database0022");
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
				Trace.myTrace("Database.as : Failed to get the source. Database0023");
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
				Trace.myTrace("Database.as : Failed to delete the fooddatabase");
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
		private function loadFoodTableInternal(functionToCallWhenFinished:Function,foodtableXML:XML = null,dispatcher:EventDispatcher  = null):void {
			if (foodtableXML == null) {
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
				Trace.myTrace("Database.as : Failed to insert the source. Database0024");
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
				Trace.myTrace("Database.as : Failed to insert a fooditem. Database0025");
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
				Trace.myTrace("Database.as : Failed to insert a unit. Database0026");
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
			foodFileName = "foodfile-" + ModelLocator.resourceManagerInstance.getString("general","TableLanguage");
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
				Trace.myTrace("Database.as : Failed to retrieve a fooditem. Database0027");
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
				Trace.myTrace("Database.as : Failed to open the database. Database0028");
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
				Trace.myTrace("Database.as : Failed to retrieve the fooditem. Database0029");
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
				Trace.myTrace("Database.as : Failed to retrieve the unitlist. Database0030");
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
				Trace.myTrace("Database.as : Failed to open the database. Database0032");
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
				Trace.myTrace("Database.as : Failed to retrieve the unitlist. Database0040");
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
		internal function updateMealEvent(mealEventId:String, newMealName:String,newInsulinRatio:Number,newCorrectionFactor:Number,newLastModifiedTimeStamp:Number,newCreationTimeStamp:Number, comment:String, dispatcher:EventDispatcher):void {
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
				Trace.myTrace("Database.as : Failed to open the database. Database0071");
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
				Trace.myTrace("Database.as : Failed to update a mealevent. Database0070");
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
				Trace.myTrace("Database.as : SQL Connection successfully opened in method Database.openSQLConnection");
				aConn.removeEventListener(SQLEvent.OPEN, onConnOpen);
				aConn.removeEventListener(SQLErrorEvent.ERROR, onConnError);	
				if (dispatcher != null) {
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.RESULT_EVENT));
				}
			}
			
			function onConnError(see:SQLErrorEvent):void
			{
				Trace.myTrace("Database.as : SQL Error while attempting to open database in method Database.openSQLConnection");
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
				localSqlStatement.parameters[":id"] = id - 100;
				localSqlStatement.parameters[":value"] = value;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = (isNaN(lastModifiedTimeStamp) ? (new Date()).valueOf() : lastModifiedTimeStamp);
				localSqlStatement.addEventListener(SQLEvent.RESULT, settingUpdated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, settingUpdateFailed);
				//SQLErrorEvent.
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				Trace.myTrace("Database.as : Failed to open the database. Database0041");
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
				Trace.myTrace("Database.as : Failed to update a setting. Database0031");
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
			mealEventId:String,
			mealname:String,
			lastmodifiedtimestamp:Number,
			insulinRatio:Number,
			correctionFactor:Number,
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
				localSqlStatement.parameters[":mealeventid"] = new Date().valueOf() + DateTimeUtilities.randomRange(1000,10000);//legacy, actually will not be used anymore but there are old databases that still have this column and it must be unique
				localSqlStatement.parameters[":newmealeventid"] = mealEventId;
				localSqlStatement.parameters[":mealname"] = mealname;
				localSqlStatement.parameters[":lastmodifiedtimestamp"] = lastmodifiedtimestamp;
				localSqlStatement.parameters[":insulinratio"] = insulinRatio;
				localSqlStatement.parameters[":correctionfactor"] = correctionFactor;
				localSqlStatement.parameters[":creationtimestamp"] = creationtimestamp;
				localSqlStatement.parameters[":comment_2"] = comment;
				localSqlStatement.addEventListener(SQLEvent.RESULT, mealEventCreated);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR, mealEventCreationFailed);
				localSqlStatement.execute();
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				Trace.myTrace("Database.as : Failed to open the database. Database0050");
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
				Trace.myTrace("Database.as : Failed to create a mealEvent. Database0051");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
		}
		
		/**
		 * new bloodglucoselevel event will be added to the database<br>
		 */
		internal function createNewBloodGlucoseEvent(level:Number,timeStamp:Number,newLastModifiedTimeStamp:Number,unit:String,bloodglucoseeventid:String, comment:String,dispatcher:EventDispatcher = null ):void {
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
				localSqlStatement.parameters[":bloodglucoseeventid"] = new Date().valueOf() + DateTimeUtilities.randomRange(1000,10000);//legacy, actually will not be used anymore but there are old databases that still have this column and it must be unique  
				localSqlStatement.parameters[":newbloodglucoseeventid"] = bloodglucoseeventid;
				localSqlStatement.parameters[":unit"] = unit;
				localSqlStatement.parameters[":creationtimestamp"] = timeStamp;
				if (unit  == ModelLocator.resourceManagerInstance.getString('general','mmoll'))
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
				Trace.myTrace("Database.as : Failed to create a bloodglucseevent. Database0081");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				Trace.myTrace("Database.as : Failed to open the database. Database0080");
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
			selectedItemId:String,
			mealEventId:String,
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
				localSqlStatement.parameters[":selectedfooditemid"] = new Date().valueOf() + DateTimeUtilities.randomRange(1000,10000);//legacy 
				localSqlStatement.parameters[":newselectedfooditemid"] = selectedItemId;
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
				Trace.myTrace("Database.as : Failed to open the database. Database0050");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function selectedItemCreated(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,selectedItemCreated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,selectedItemCreationFailed);
				//Trace.myTrace("Database.as : newSelectedItem successfully stored");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function selectedItemCreationFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,selectedItemCreated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,selectedItemCreationFailed);
				Trace.myTrace("Database.as : Failed to create a selectedItem. Database0052");
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
			var currentMealEventID:String;//used in the filterfunction for the selectedfooditems
			
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
				
				localSqlStatement.addEventListener(SQLEvent.RESULT,bloodGlucoseEventsRetrieved);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,bloodGlucoseRetrievalFailed);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = GET_ALLBLOODGLUCOSEEVENTS;
				localSqlStatement.execute();
				
			}
			
			function selectedFoodItemsRetrieved(result:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,selectedFoodItemsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,failedGettingSelectedFoodItems);
				var tempObject:Object = localSqlStatement.getResult().data;
				if (tempObject != null && tempObject is Array) {
					for each (var o:Object in tempObject ) {
						var selectedFoodItemId:String;
						if (o.newselectedfooditemid) {
							selectedFoodItemId = o.newselectedfooditemid as String;
						} else {
							selectedFoodItemId = (o.selectedfooditemid as Number).toString();
						}
						var newSelectedFoodItem:SelectedFoodItem = new SelectedFoodItem(
							selectedFoodItemId,
							o.itemdescription as String,
							new Unit(o.unitdescription as String,o.standardamount as int,o.kcal as int,o.protein as Number,o.carbs as Number,o.fat as Number),
							o.chosenamount,
							o.lastmodifiedtimestamp);
						var newMealevents_Mealeventid:String;
						if (o.newmealevents_mealeventid) {
							newMealevents_Mealeventid = o.newmealevents_mealeventid as String;
						} else {
							newMealevents_Mealeventid = (o.mealevents_mealeventid as Number).toString();
						}
						newSelectedFoodItem.mealEventId = newMealevents_Mealeventid;
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
				localSqlStatement.removeEventListener(SQLEvent.RESULT,selectedFoodItemsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,failedGettingSelectedFoodItems);
				Trace.myTrace("Database.as : Failed to get all selectedFoodItems. Database0061");
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
						var mealEventId:String;
						if (o.newmealeventid) {
							mealEventId = o.newmealeventid as String;
						} else {
							mealEventId = (o.mealeventid as Number).toString();
						}
						if ((o.lastmodifiedtimestamp as Number) < minimumTimeStamp) {
							deleteMealEvent(mealEventId);
						} else {
							currentMealEventID = mealEventId;
							selectedFoodItems.refresh();

							var newMealEvent:MealEvent = new MealEvent(o.mealname as String,
								o.insulinratio as Number,
								o.correctionfactor as Number,
								o.creationtimestamp as Number,
								null,
								mealEventId,
								o.comment_2 as String,
								o.lastmodifiedtimestamp  as Number,
								false,
								new ArrayCollection(selectedFoodItems.toArray()),
								null,
								false);
							ModelLocator.trackingList.addItem(newMealEvent);
							var creationTimeStampAsDate:Date = new Date(newMealEvent.timeStamp);
							var creationTimeStampAtMidNight:Number = (new Date(creationTimeStampAsDate.fullYearUTC,creationTimeStampAsDate.monthUTC,creationTimeStampAsDate.dateUTC,0,0,0,0)).valueOf();
							if (creationTimeStampAtMidNight < ModelLocator.youngestDayLineStoredInTrackingList) {
								ModelLocator.youngestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
								if (ModelLocator.oldestDayLineStoredInTrackingList == 0)
									ModelLocator.oldestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
							} 
							if (creationTimeStampAtMidNight > ModelLocator.oldestDayLineStoredInTrackingList) {
								ModelLocator.oldestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
								if (ModelLocator.youngestDayLineStoredInTrackingList == 5000000000000)
									ModelLocator.youngestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
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
			
			function bloodGlucoseEventsRetrieved(result:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bloodGlucoseEventsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bloodGlucoseRetrievalFailed);
				
				var tempObject:Object = localSqlStatement.getResult().data;
				
				if (tempObject != null && tempObject is Array) {
					for each ( var o:Object in tempObject ) {
						var bloodGlucoseEventId:String;
						if (o.newbloodglucoseeventid) {
							bloodGlucoseEventId = o.newbloodglucoseeventid as String;
						} else {
							bloodGlucoseEventId = (o.bloodglucoseeventid as Number).toString();
						}
						if ((o.lastmodifiedtimestamp as Number) < minimumTimeStamp) {
							deleteBloodGlucoseEvent(bloodGlucoseEventId);
						} else {
							var tempLevel:Number = o.value as Number;
							if (o.unit as String  == ModelLocator.resourceManagerInstance.getString('general','mmoll'))
								tempLevel = tempLevel/10;
							var newBloodGlucoseEvent:BloodGlucoseEvent = new BloodGlucoseEvent(tempLevel as Number,o.unit as String, bloodGlucoseEventId, o.comment_2 as String, o.creationtimestamp as Number,o.lastmodifiedtimestamp as Number,false, false);
							ModelLocator.trackingList.addItem(newBloodGlucoseEvent);
							var creationTimeStampAsDate:Date = new Date(newBloodGlucoseEvent.timeStamp);
							var creationTimeStampAtMidNight:Number = (new Date(creationTimeStampAsDate.fullYearUTC,creationTimeStampAsDate.monthUTC,creationTimeStampAsDate.dateUTC,0,0,0,0)).valueOf();
							if (creationTimeStampAtMidNight < ModelLocator.youngestDayLineStoredInTrackingList) {
								ModelLocator.youngestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
								if (ModelLocator.oldestDayLineStoredInTrackingList == 0)
									ModelLocator.oldestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
							} 
							if (creationTimeStampAtMidNight > ModelLocator.oldestDayLineStoredInTrackingList) {
								ModelLocator.oldestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
								if (ModelLocator.youngestDayLineStoredInTrackingList == 5000000000000)
									ModelLocator.youngestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
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
						var medicinEventId:String;
						if (o.newmedicineventid) {
							medicinEventId = o.newmedicineventid as String;
						} else {
							medicinEventId = (o.medicineventid as Number).toString();
						}

						if ((o.lastmodifiedtimestamp as Number) < minimumTimeStamp) {
							deleteMedicinEvent(medicinEventId);
						} else {
							var medicinArray:Array = (o.medicinname as String).split(medicinnamesplitter);
							
							var bolusType:String;
							var bolusDuration:Number;
							if (medicinArray.length > 1)
								bolusType = medicinArray[1];
							else 
								bolusType = ModelLocator.resourceManagerInstance.getString('editmedicineventview',MedicinEvent.BOLUS_TYPE_NORMAL);
							if (medicinArray.length > 2)
								bolusDuration = new Number(medicinArray[2] as String);
							else
								bolusDuration = new Number(0);
							
							var medicinName:String = medicinArray[0];
							
							//Trace.myTrace(" in database.as, creating a newMedicinEvent with timestamp = " + (new Date(o.creationtimestamp as Number)).toString() + " and eventid = " + medicinEventId);
							var newMedicinEvent:MedicinEvent = new MedicinEvent( o.amount as Number, medicinName, medicinEventId, o.comment_2 as String, o.creationtimestamp as Number, o.lastmodifiedtimestamp as Number, false, bolusType, bolusDuration, false);
							ModelLocator.trackingList.addItem(newMedicinEvent);
							var creationTimeStampAsDate:Date = new Date(newMedicinEvent.timeStamp);
							var creationTimeStampAtMidNight:Number = (new Date(creationTimeStampAsDate.fullYearUTC,creationTimeStampAsDate.monthUTC,creationTimeStampAsDate.dateUTC,0,0,0,0)).valueOf();
							if (creationTimeStampAtMidNight < ModelLocator.youngestDayLineStoredInTrackingList) {
								ModelLocator.youngestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
								if (ModelLocator.oldestDayLineStoredInTrackingList == 0)
									ModelLocator.oldestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
							} 
							if (creationTimeStampAtMidNight > ModelLocator.oldestDayLineStoredInTrackingList) {
								ModelLocator.oldestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
								if (ModelLocator.youngestDayLineStoredInTrackingList == 5000000000000)
									ModelLocator.youngestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
							}
						}
					}
				}
				localSqlStatement.addEventListener(SQLEvent.RESULT,selectedFoodItemsRetrieved);
				localSqlStatement.addEventListener(SQLErrorEvent.ERROR,failedGettingSelectedFoodItems);
				localSqlStatement.sqlConnection = aConn;
				localSqlStatement.text = GET_ALLSELECTEDFOODITEMS;
				localSqlStatement.execute();
				ModelLocator.recalculateActiveInsulin();
			}
			
			function exerciseEventsRetrieved(result:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,exerciseEventsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,exerciseEventsRetrievalFailed);
				
				var tempObject:Object = localSqlStatement.getResult().data;
				var creationTimeStampAtMidNight:Number ;
				
				if (tempObject != null && tempObject is Array) {
					for each ( var o:Object in tempObject ) {
						var exerciseEventId:String;
						if (o.newexerciseeventid) {
							exerciseEventId = o.newexerciseeventid as String;
						} else {
							exerciseEventId = (o.exerciseeventid as Number).toString();
						}
						if ((o.lastmodifiedtimestamp as Number) < minimumTimeStamp) {
							deleteExerciseEvent(exerciseEventId);
						} else {
							var newExerciseEvent:ExerciseEvent = new ExerciseEvent(o.level as String,o.comment_2 as String,exerciseEventId,o.creationtimestamp as Number,o.lastmodifiedtimestamp as Number,false);
							ModelLocator.trackingList.addItem(newExerciseEvent);
							var creationTimeStampAsDate:Date = new Date(newExerciseEvent.timeStamp);
							creationTimeStampAtMidNight = (new Date(creationTimeStampAsDate.fullYearUTC,creationTimeStampAsDate.monthUTC,creationTimeStampAsDate.dateUTC,0,0,0,0)).valueOf();
							if (creationTimeStampAtMidNight < ModelLocator.youngestDayLineStoredInTrackingList) {
								ModelLocator.youngestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
								if (ModelLocator.oldestDayLineStoredInTrackingList == 0)
									ModelLocator.oldestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
							} 
							if (creationTimeStampAtMidNight > ModelLocator.oldestDayLineStoredInTrackingList) {
								ModelLocator.oldestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
								if (ModelLocator.youngestDayLineStoredInTrackingList == 5000000000000)
									ModelLocator.youngestDayLineStoredInTrackingList = creationTimeStampAtMidNight;
							}
						}
					}
				}
				
				var oldest:Number = (new Date(ModelLocator.oldestDayLineStoredInTrackingList)).valueOf();
				var youngest :Number = (new Date(ModelLocator.youngestDayLineStoredInTrackingList)).valueOf();
				
				//Now add list of daylines 
				for (var counter:Number = youngest;counter<= oldest + 3600000;counter = counter + 86400000) {
					//why counter <= oldest + 360000 ? because i noticed when switching from wintertime to summertime, if oldest was winter, and youngest was summer, there's a difference of an hour
					ModelLocator.trackingList.addItem(new DayLineWithTotalAmount(counter));
				}
				
				ModelLocator.trackingList.refresh();
				
				// now populate ModelLocator.meals
				ModelLocator.refreshMeals();
				
				MealEvent.asyncRecalculateInsulinAmountForAllMealEvents(null, true);

				if (globalDispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					globalDispatcher.dispatchEvent(event);
					globalDispatcher =  null;
					Trace.myTrace("Database.as : finished populating the database");
				}
			}
			
			function exerciseEventsRetrievalFailed(error:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,exerciseEventsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,exerciseEventsRetrievalFailed);
				Trace.myTrace("Database.as : Failed to get all exerciseevents. Database0095");
				if (globalDispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					event.data = "Failed to get all exerciseevents. Database0095";
					globalDispatcher.dispatchEvent(event);
					globalDispatcher =  null;
				}
			}
			
			function medicinEventsRetrievalFailed(error:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,medicinEventsRetrieved);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,medicinEventsRetrievalFailed);
				Trace.myTrace("Database.as : Failed to get all medicinevents. Database0094");
				if (globalDispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					event.data = "Failed to get all medicinevents. Database0094";
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
				Trace.myTrace("Database.as : Failed to get all mealevents. Database0060");
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
				Trace.myTrace("Database.as : Failed to get all mealevents. Database0090");
				if (globalDispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					event.data = "Failed to get all mealevents. Database0090";
					globalDispatcher.dispatchEvent(event);
					globalDispatcher =  null;
				}
			}
		}
		
		internal function updateSelectedFoodItem(selectedFoodItemId:String, newMealEventId:String,newDescription:String,newChosenAmount:Number, newUnit:Unit, newLastModifiedTimeStamp:Number, dispatcher:EventDispatcher):void {
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
				Trace.myTrace("Database.as : Failed to open the database. Database0101");
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
				Trace.myTrace("Database.as : Failed to update a insulinratio. Database0102");
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
		internal function createNewMedicinEvent(bolusType:String, bolusDuration:Number, amount:Number,medicin:String, timeStamp:Number,newLastModifiedTimeStamp:Number,medicineventid:String, comment:String,dispatcher:EventDispatcher = null):void {
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
				localSqlStatement.parameters[":medicineventid"] = new Date().valueOf() + DateTimeUtilities.randomRange(1000,10000);//legacy
				localSqlStatement.parameters[":newmedicineventid"] = medicineventid;
				localSqlStatement.parameters[":amount"] = amount;
				localSqlStatement.parameters[":creationtimestamp"] = timeStamp;
				localSqlStatement.parameters[":medicinname"] = medicin + medicinnamesplitter + bolusType + medicinnamesplitter + bolusDuration.toString();
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
				Trace.myTrace("Database.as : Failed to create a medicinEvent. Database0091");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				Trace.myTrace("Database.as : Failed to open the database. Database0092");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		/**
		 * medicinevent with specified medicineventid is updated with new values for timestamp, amount and medicinname
		 */ 	
		internal function updateMedicinEvent(newBolusType:String, newBolusDuration:Number, medicinEventId:String,newAmount:Number,newMedicinName:String,newCreationTimeStamp:Number, newLastModifiedTimeStamp:Number, comment:String,dispatcher:EventDispatcher = null):void {
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
				localSqlStatement.parameters[":medicinname"] = newMedicinName + medicinnamesplitter + newBolusType + medicinnamesplitter + newBolusDuration.toString();
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
				Trace.myTrace("Database.as : Failed to update a medicinEvent. Database0100");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				Trace.myTrace("Database.as : Failed to open the database. Database0101");
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
		internal function createNewExerciseEvent(level:String, comment:String, timeStamp:Number, newLastModifiedTimeStamp:Number,exerciseeventid:String,dispatcher:EventDispatcher = null):void {
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
				localSqlStatement.parameters[":exerciseeventid"] = new Date().valueOf() + DateTimeUtilities.randomRange(1000,10000);//legacy, adding random because sometimes on pc this was getting called within the same millisecond, generating duplicate keys
				localSqlStatement.parameters[":newexerciseeventid"] = exerciseeventid;
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
				Trace.myTrace("Database.as : Failed to create an exercise Event. Database0093");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				Trace.myTrace("Database.as : Failed to open the database. Database0094");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		/**
		 * exerciseevent with specified exerciseeventid is updated with new values for timestamp, level and comment
		 */ 	
		internal function updateExerciseEvent(exerciseEventId:String,newLevel:String,newComment_2:String,newCreationTimeStamp:Number,  newLastModifiedTimeStamp:Number,dispatcher:EventDispatcher = null):void {
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
				Trace.myTrace("Database.as : Failed to update an exerciseEvent. Database0102");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				Trace.myTrace("Database.as : Failed to open the database. Database0102");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		
		/**
		 * bloodglucoseevent with specified bloodglucoseeventid is updated with new values  level and unit
		 */ 	
		internal function updateBloodGlucoseEvent(bloodglucoseEventId:String,unit:String,bloodGlucoseLevel:Number,newCreationTimeStamp:Number,  newLastModifiedTimeStamp:Number, comment:String,dispatcher:EventDispatcher = null):void {
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
				if (unit  == ModelLocator.resourceManagerInstance.getString('general','mmoll'))
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
				Trace.myTrace("Database.as : bloodglucoseevent updated in database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function bloodglucoseEventUpdateFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bloodglucoseEventUpdated);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bloodglucoseEventUpdateFailed);
				Trace.myTrace("Database.as : Failed to update a bloodglucoseEvent. Database0110");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function onOpenError(see:SQLErrorEvent):void {
				localdispatcher.removeEventListener(SQLEvent.RESULT,onOpenResult);
				localdispatcher.removeEventListener(SQLErrorEvent.ERROR,onOpenError);
				Trace.myTrace("Database.as : Failed to open the database. Database0111");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		
		internal function deleteMealEvent(mealEventId:String,dispatcher:EventDispatcher = null):void {
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
				Trace.myTrace("Database.as : Failed to open the database in unction deleteMealEvent in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			
			function mealeventDeleted(se:SQLEvent):void {
				if (yes < 10) {
					yes ++;
					Trace.myTrace("Database.as : in database.as mealeventDeleted");
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
				Trace.myTrace("Database.as : SelectedFoodItemsDeletionFailed. function deleteMealEvent in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function mealeventDeletionFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,mealeventDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,mealeventDeletionFailed);
				Trace.myTrace("Database.as : Mealeventdeletionfailed, function deleteMealEvent in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		internal function deleteMedicinEvent(medicinEventId:String, dispatcher:EventDispatcher = null):void {
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
				Trace.myTrace("Database.as : Failed to open the database in unction deleteMealEvent in Database.as");
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
				Trace.myTrace("Database.as : medicineventdeletionfailed, function delete Event in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		internal function deleteBloodGlucoseEvent(bloodglucoseEventId:String, dispatcher:EventDispatcher = null):void {
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
				Trace.myTrace("Database.as : Failed to open the database in unction deleteMealEvent in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function bloodglucoseeventDeleted(se:SQLEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bloodglucoseeventDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bloodglucoseeventDeletionFailed);
				Trace.myTrace("Database.as : bloodglucoseevent deleted in database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function bloodglucoseeventDeletionFailed(see:SQLErrorEvent):void {
				localSqlStatement.removeEventListener(SQLEvent.RESULT,bloodglucoseeventDeleted);
				localSqlStatement.removeEventListener(SQLErrorEvent.ERROR,bloodglucoseeventDeletionFailed);
				Trace.myTrace("Database.as : bloodglucoseeventdeletionfailed, function delete Event in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		internal function deleteExerciseEvent(exerciseEventId:String, dispatcher:EventDispatcher = null):void {
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
				Trace.myTrace("Database.as : Failed to open the database in unction deleteMealEvent in Database.as");
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
				Trace.myTrace("Database.as : exerciseeventdeletionfailed, function delete Event in Database.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		/**
		 * deletes the selectedfooditem from the database, nothing changes to the mealevent or meal that has this selectedfooditem 
		 */
		internal function deleteSelectedFoodItem(selectedFoodItemId:String, dispatcher:EventDispatcher = null):void {
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
				Trace.myTrace("Database.as : Failed to open the database in function deleteSelectedFoodItem in Database.as");
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
				Trace.myTrace("Database.as : selectedFoodItemDeletionFailed, function deleteSelectedFoodItem in Database.as");
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
