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
package utilities
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.formatters.DateFormatter;
	import mx.resources.ResourceManager;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	import spark.formatters.DateTimeFormatter;
	
	import databaseclasses.BloodGlucoseEvent;
	import databaseclasses.Database;
	import databaseclasses.DatabaseEvent;
	import databaseclasses.ExerciseEvent;
	import databaseclasses.FoodItem;
	import databaseclasses.MealEvent;
	import databaseclasses.MedicinEvent;
	import databaseclasses.SelectedFoodItem;
	import databaseclasses.Settings;
	import databaseclasses.Unit;
	
	import model.ModelLocator;
	
	import myComponents.IListElement;
	import myComponents.TrackingViewElement;
	
	/**
	 * class with function to synchronize with google docs, and to export tracking history 
	 *
	 */
	public class Synchronize extends EventDispatcher
	{
		[ResourceBundle("analytics")]
		[ResourceBundle("uploadtrackingview")] 
		private static var googleRequestTablesUrl:String = "https://www.googleapis.com/fusiontables/v1/tables";
		private static var googleSelectUrl:String = "https://www.googleapis.com/fusiontables/v1/query";
		private static var googleDriveFilesUrl:String = "https://www.googleapis.com/drive/v2/files";
		private static var googleTokenRefreshUrl:String = "https://accounts.google.com/o/oauth2/token";
		private static var googleInsertColumnInTableUrl:String = "https://www.googleapis.com/fusiontables/v1/tables/{tableId}/columns";
		
		/**
		 * replace {key} by the spreadsheet key<br>
		 * replace {worksheetid} by the worksheetid
		 */
		private static var googleExcelManageWorkSheetUrl:String = "https://spreadsheets.google.com/feeds/list/{key}/{worksheetid}/private/full";
		private var googleExcelDeleteWorkSheetUrl:String = "";
		//https://spreadsheets.google.com/feeds/spreadsheets/private/full
		
		/**
		 * replace {key} by the spreadsheet key<br>
		 */
		private static var googleExcelFindWorkSheetUrl:String = "https://spreadsheets.google.com/feeds/worksheets/{key}/private/full"
		/**
		 * replace {key} by the spreadsheet key<br>
		 * replace {worksheetid} by the worksheetid
		 */
		private static var googleExcelUpdateCellUrl:String = "https://spreadsheets.google.com/feeds/cells/{key}/{worksheetid}/private/full";
		/**
		 * replace {key} by the spreadsheet key<br>
		 * replace {worksheetid} by the worksheetid
		 */
		private static var googleExcelCreateWorkSheetUrl:String = "https://spreadsheets.google.com/feeds/worksheets/{key}/private/full";
		
		/**
		 * the maximum number of tables when asking list of tables, 25 is also the default value that google applies.<br>
		 */
		private static var maxResults:int = 25;
		
		private static var minimSettingCntrToSync:int = -87;
		
		/**
		 * how many minutes between two synchronisations, normal value
		 */
		private static var normalValueForSecondsBetweenTwoSync:int = 30;
		/**
		 * how many minutes between two synchronisations, actual value
		 */
		private var secondsBetweenTwoSync:int = normalValueForSecondsBetweenTwoSync;
		
		private static var googleError_Invalid_Credentials:String = "Invalid Credentials";
		
		/**
		 * copied from settings at start of sync, timestamp of last synchronisation 
		 */
		private var lastSyncTimeStamp:Number;
		/**
		 * timestamp when sync here starts<br>
		 * One of the variables that determines if sync will run immediately when synchronize is called<br>
		 * <br>
		 * immediateRunNecessary is a parameter in the synchronize method<br>
		 * <br>
		 * If  (syncRunning is true and currentSyncTimeStamp > 30 seconds ago) or  (syncRunning is false & (immediateRunNecessary or currentSyncTimeStamp > 30 seconds ago)), then run the sync, reset timestamp of startrun to current time, 
		 * set rerunnecessary to false<br>
		 * <br>
		 * If  (syncRunning is true and currentSyncTimeStamp < 30 seconds ago) don't run, if immediateRunNecessary set rerunNecessary to true; else don't set anything. 
		 */
		private var currentSyncTimeStamp:Number;
		/**
		 * parameter showing of synchronisation is running or not<br>
		 * One of the variables that determines if sync will run immediately when synchronize is called<br>
		 * <br>
		 * immediateRunNecessary is a parameter in the synchronize method<br>
		 * <br>
		 * If  (syncRunning is true and currentSyncTimeStamp > 30 seconds ago) or  (syncRunning is false & (immediateRunNecessary or currentSyncTimeStamp > 30 seconds ago)), then run the sync, reset timestamp of startrun to current time, 
		 * set rerunnecessary to false<br>
		 * <br>
		 * If  (syncRunning is true and currentSyncTimeStamp < 30 seconds ago) don't run, if immediateRunNecessary set rerunNecessary to true; else don't set anything. 
		 */
		private var syncRunning:Boolean;
		/**
		 * parameter that says if sync should restart when finished<br>
		 * One of the variables that determines if sync will run immediately when synchronize is called<br>
		 * <br>
		 * immediateRunNecessary is a parameter in the synchronize method<br>
		 * <br>
		 * If  (syncRunning is true and currentSyncTimeStamp > 30 seconds ago) or  (syncRunning is false & (immediateRunNecessary or currentSyncTimeStamp > 30 seconds ago)), then run the sync, reset timestamp of startrun to current time, 
		 * set rerunnecessary to false<br>
		 * <br>
		 * If  (syncRunning is true and currentSyncTimeStamp < 30 seconds ago) don't run, if immediateRunNecessary set rerunNecessary to true; else don't set anything. 
		 */
		private var rerunNecessary:Boolean;
		
		/**
		 * if findAllSpreadSheetsWaiting is called while sync running, then this value needs to be set to true<br>
		 * as soon as sync is finished, this variable will be checked and if necessary findallspreadsheets will be launched 
		 */
		private var findAllSpreadSheetsWaiting:Boolean;
		
		/**
		 * if downloadfoodtablespreadsheet is called while sync running, then this value needs to be set to true<br>
		 * as soon as sync is finished, this variable will be checked and if necessary downloadfoodtable will be launched 
		 */
		private var downloadFoodTableSpreadSheetWaiting:Boolean;
		
		/**
		 * if findallworksheetsinfoodtable is called while sync running, then this value needs to be set to true<br>
		 * as soon as sync is finished, this variable will be checked and if necessary findallworksheetsinfoodtable will be launched 
		 */
		private var findAllWorkSheetsInFoodTableSpreadSheetWaiting:Boolean;
		//////////// Waiting Booleans in upload tracking
		private var createlogbookheaderWaiting:Boolean;
		private var createlogbookWaiting:Boolean;
		private var createlogbookworksheetWaiting:Boolean;
		private var findlogbookspreadsheetWaiting:Boolean;
		private var findlogbookworksheetWaiting:Boolean;
		private var insertlogbookeventsWaiting:Boolean;
		////////////
		/**
		 * if  findAllWorkSheetsInFoodTableSpreadSheetWaiting or downloadFoodTableSpreadSheetWaiting = true, then this variable points to the spreadsheet index to find or download
		 */
		private var indexOfSpreadSheetToFind:int;
		/**
		 * if  downloadFoodTableSpreadSheetWaiting = true, then this variable points to the worksheet index to download
		 */
		private var indexOfWorkSheetToFind:int;
		
		/**
		 * this is the earliest creationtimestamp of the events that will be taken into account 
		 */
		private var asOfTimeStamp:Number
		
		private var _synchronize_debugString:String = "";

		public function get synchronize_debugString():String
		{
			return _synchronize_debugString;
		}

		public static const SYNCHRONIZE_ERROR_OCCURRED:String="error_occurred";

		/////columnnames
		private static var ColumnName_id:String = "id";
		private static var ColumnName_medicinname:String = "medicinname";
		private static var ColumnName_value:String = "value";
		private static var ColumnName_creationtimestamp:String = "creationtimestamp";
		private static var ColumnName_modifiedtimestamp:String = "modifiedtimestamp";
		private static var ColumnName_deleted:String = "deleted";
		private static var ColumnName_addedtoormodifiedintabletimestamp:String = "addedtoormodifiedintabletimestamp";
		private static var ColumnName_unit:String = "unit";
		private static var ColumnName_level:String = "level";
		private static var ColumnName_mealname:String = "mealname";
		private static var ColumnName_insulinratio:String = "insulinratio";
		private static var ColumnName_correctionfactor:String = "correctionfactor";
		private static var ColumnName_previousbglevel:String = "previousbglevel";//not used anymore
		private static var ColumnName_description:String = "description";
		private static var ColumnName_unitdescription:String = "unitdescription";
		private static var ColumnName_unitstandardamount:String = "unitstandardamount";
		private static var ColumnName_unitkcal:String = "unitkcal";
		private static var ColumnName_unitprotein:String = "unitprotein";
		private static var ColumnName_unitcarbs:String = "unitcarbs";
		private static var ColumnName_unitfat:String = "unitfat";
		private static var ColumnName_chosenamount:String = "chosenamount";
		private static var ColumnName_mealeventid:String = "mealeventid";
		private static var ColumnName_comment:String = "comment";
		
		/**
		 * tablename, tableid and list of columns with columnname and type <br>
		 * tableid "" string means there's no table i known yet
		 */
		private var tableNamesAndColumnNames:Array = [
			[	"HD-MedicinEvent",
				"",	
				[						
					[ColumnName_id,"NUMBER"],//the unique identifier
					[ColumnName_medicinname,"STRING"],//medicin name
					[ColumnName_value,"NUMBER"],//amount of medicin
					[ColumnName_creationtimestamp,"NUMBER"],//timestamp that the event was created
					[ColumnName_modifiedtimestamp,"NUMBER"],//timestamp that the event was last modified
					[ColumnName_deleted,"STRING"],//was the event deleted or not
					[ColumnName_comment,"STRING"],//the comment
					[ColumnName_addedtoormodifiedintabletimestamp,"NUMBER"]//the timestamp that the row was added to the table
				],
				"MedicinEvents"//description
			],
			[	"HD-BloodglucoseEvent",
				"",	
				[						
					[ColumnName_id,"NUMBER"],//the unique identifier
					[ColumnName_unit,"STRING"],//unit name
					[ColumnName_value,"NUMBER"],//value
					[ColumnName_creationtimestamp,"NUMBER"],//timestamp that the event was created
					[ColumnName_modifiedtimestamp,"NUMBER"],//timestamp that the event was last modified
					[ColumnName_deleted,"STRING"],//was the event deleted or not
					[ColumnName_comment,"STRING"],//the comment
					[ColumnName_addedtoormodifiedintabletimestamp,"NUMBER"]//the timestamp that the row was added to the table
				],
				"BloodglucoseEvents"//description
			],
			[	"HD-ExerciseEvent",
				"",	
				[						
					[ColumnName_id,"NUMBER"],//the unique identifier
					[ColumnName_level,"STRING"],//unit name
					[ColumnName_creationtimestamp,"NUMBER"],//timestamp that the event was created
					[ColumnName_modifiedtimestamp,"NUMBER"],//timestamp that the event was last modified
					[ColumnName_deleted,"STRING"],//was the event deleted or not
					[ColumnName_comment,"STRING"],//the comment
					[ColumnName_addedtoormodifiedintabletimestamp,"NUMBER"]//the timestamp that the row was added to the table
				],
				"ExerciseEvents"//description
			],
			[	"HD-MealEvent",
				"",	
				[						
					[ColumnName_id,"NUMBER"],//the unique identifier
					[ColumnName_mealname,"STRING"],
					[ColumnName_insulinratio,"NUMBER"],
					[ColumnName_correctionfactor,"NUMBER"],
					[ColumnName_previousbglevel,"NUMBER"],//not used anymore
					[ColumnName_creationtimestamp,"NUMBER"],//timestamp that the event was created
					[ColumnName_modifiedtimestamp,"NUMBER"],//timestamp that the event was last modified
					[ColumnName_deleted,"STRING"],//was the event deleted or not
					[ColumnName_comment,"STRING"],//the comment
					[ColumnName_addedtoormodifiedintabletimestamp,"NUMBER"]//the timestamp that the row was added to the table
				],
				"MealEvents"//description
			],
			[	"HD-SelectedFoodItem",
				"",	
				[						
					[ColumnName_id,"NUMBER"],//the unique identifier
					[ColumnName_description,"STRING"],
					[ColumnName_unitdescription,"STRING"],
					[ColumnName_unitstandardamount,"NUMBER"],
					[ColumnName_unitkcal,"NUMBER"],
					[ColumnName_unitprotein,"NUMBER"],
					[ColumnName_unitcarbs,"NUMBER"],
					[ColumnName_unitfat,"NUMBER"],
					[ColumnName_chosenamount,"NUMBER"],
					[ColumnName_mealeventid,"NUMBER"],
					[ColumnName_creationtimestamp,"NUMBER"],//timestamp that the event was created, in case of selectedfooditems, creationtimestamp will not really be usefull
					[ColumnName_modifiedtimestamp,"NUMBER"],//timestamp that the event was last modified
					[ColumnName_deleted,"STRING"],//was the event deleted or not
					[ColumnName_addedtoormodifiedintabletimestamp,"NUMBER"]//the timestamp that the row was added to the table
				],
				"Selected Food Items"//description
			],
			[	"HD-Settings",
				"",	
				[						
					[ColumnName_id,"NUMBER"],//the unique identifier
					[ColumnName_value,"STRING"],
					[ColumnName_addedtoormodifiedintabletimestamp,"NUMBER"]//the timestamp that the row was added to the table
				],
				"Settings"//description
			]
		];
		
		private var googleExcelFoodTableColumnNames:Array = [
			ColumnName_description,
			"unit1",	
			"standardamount1",	
			"kcal1",
			"protein1",	
			"carbo1",	
			"fat1",
			"unit2",	
			"standardamount2",	
			"kcal2",
			"protein2",	
			"carbo2",	
			"fat2",
			"unit3",	
			"standardamount3",	
			"kcal3",
			"protein3",	
			"carbo3",	
			"fat3",
			"unit4",	
			"standardamount4",	
			"kcal4",
			"protein4",	
			"carbo4",	
			"fat4",
			"unit5",	
			"standardamount5",	
			"kcal5",
			"protein5",	
			"carbo5",	
			"fat5",
		];
		
		private var foodValueNames:Array = [
			"standardamount",	
			"kcal",
			"protein",	
			"carbs",	
			"fat",
		];
		
		private var googleExcelLogBookColumnNames:Array = new Array;
		
		//indexes into googleExcelLogBookColumnNames
		private static const foodValueNames_Index_date:int = 0;
		private static const foodValueNames_Index_time:int = 1;
		private static const foodValueNames_Index_eventtype:int = 2;
		private static const foodValueNames_Index_bloodglucosevalue:int = 3;
		private static const foodValueNames_Index_medicinvalue:int = 4;
		private static const foodValueNames_Index_exerciselevel:int = 5;
		private static const foodValueNames_Index_medicintype:int = 6;
		private static const foodValueNames_Index_mealtype:int = 7;
		private static const foodValueNames_Index_mealcarbamount:int = 8;
		private static const foodValueNames_Index_mealinsulinratio:int = 9;
		private static const foodValueNames_Index_mealcalculatedinsulin:int = 10;
		private static const foodValueNames_Index_mealselecteditems:int = 11;
		private static const foodValueNames_Index_comment:int = 12;
		private static const foodValueNames_Index_mealkcalamount:int = 13;
		private static const foodValueNames_Index_mealproteinamount:int = 14;
		private static const foodValueNames_Index_mealfatamount:int = 15;
		
		/**
		 * name of the spreadsheet used when uploading the foodtable 
		 */
		private static var foodtableName:String = "HelpDiabetesFoodTable";
		/**
		 * name of the spreadsheet used when uploading the logbook 
		 */
		private static var logBookName:String = "HelpDiabetesLogBook";
		
		/**
		 * list of elements (events, selectedfooditems) that need to get deleted=true in remote database 
		 */
		private var listOfElementsToBeDeleted:ArrayList;
		
		/**
		 * list of objects found in local database
		 */
		private var localElements:ArrayList;
		/**
		 * list of objects found in remote database<br>
		 * in case of syncing settings, it is used differently
		 */
		private var remoteElements:ArrayList;
		/**
		 * this array will just have all id's of the elements that were found remotely<br><br>
		 * actually each element will be an array with  two numbers, first the eventid, secondly the rowid if already retrieved and found, if not null as second element<br>
		 * in case of syncing settings, it is used differently
		 */
		private var remoteElementIds:ArrayList;
		/**
		 * will have rowid's off elements that need to be deleted remotely 
		 */
		private var remoteElementRowIdsToBeDeleted:ArrayList;
		/**
		 * will have eventid's off elements that need to be deleted remotely 
		 */
		private var remoteElementEventIdsToBeDeleted:ArrayList;
		
		/**
		 * temporary variable used in getrowids
		 */
		private  var tableId:String;

		
		/**
		 * the access_token to use the google api 
		 */
		private var access_token:String;
		
		/**
		 * wil be equal to modellocator.trackinglist, it's just to avoid that I need to type to much 
		 */
		private var trackingList:ArrayCollection;
		
		private var alReadyGATracked:Boolean;
		
		private static var instance:Synchronize = new Synchronize();
		
		private var loader:URLLoader;
		
		/**
		 * when a function tries to access google api, but that fails due to invalid access_token, then the token
		 * should be refreshed, this variable will store the function to retry as soon as token is refreshed
		 */
		private var functionToRecall:Function;
		
		/**
		 * nextpagetoken received from google while accessing list of tables, .. <br>
		 * null means there's no next page
		 */
		private var nextPageToken:String;
		
		private var indexOfRetrievedRowId:int;
		
		private var amountofSpaces:int;
		
		private var debugMode:Boolean;
		
		private var localElementsUpdated:Boolean;
		
		private var objectToBeDeleted:Object;
		
		/**
		 *  to avoid endless loops, see code
		 */
		private var retrievalCounter:int;
		
		private var secondAttempt:Boolean;
		
		private var trackingListAlreadyModified:Boolean;
		
		private var helpDiabetesFoodTableSpreadSheetKey:String;//key to spreadsheet in google docs that has foodtable
		private var helpDiabetesFoodTableWorkSheetId:String;//key to worksheet in google docs that has foodtable
		private var helpDiabetesLogBookSpreadSheetKey:String;
		private var helpDiabetesLogBookWorkSheetId:String;//key to worksheet in google docs that has logbook
		
		private var foodItemIdBeingTreated:int;
		
		private static var callingDispatcher:EventDispatcher;

		
		/**
		 * used for event dispatching, when sync finished, no matter if it was successful or not
		 */
		public static const SYNC_FINISHED:String="sync_finished";
		
		/**
		 * used for event dispatching, when dispatched, it means there's a result of fetching spreadsheets from google docs account<br>
		 * it doesn't say anything about the result, just that there is a result 
		 */
		public static const SPREADSHEET_LIST_RETRIEVED:String="spreadsheet_list_retrieved";
		
		/**
		 * used for event dispatching, when dispatched, it means there's a result of downloading foodtable from google docs account<br>
		 * it doesn't say anything about the result, just that there is a result 
		 */
		public static const FOODTABLE_DOWNLOADED:String="foodtable_downloaded";
		/**
		 * used for event dispatching, when dispatched, it means there's a result of retrieving spreadsheets from google docs account<br>
		 * it doesn't say anything about the result, just that there is a result 
		 */
		public static const WORKSHEETS_IN_FOODTABLE_RETRIEVED:String = "worksheets_in_foodtable_retrieved";
		/**
		 * used for event dispatching<br>
		 */
		public static const CREATING_LOGBOOK_SPREADSHEET:String = "creating_logbook";
		/**
		 * used for event dispatching<br>
		 */
		public static const SEARCHING_LOGBOOK:String = "searching_lobook_spreadsheet";
		/**
		 * used for event dispatching<br>
		 */
		public static const CREATING_LOGBOOK_WORKSHEET:String = "creating_logbook_worksheet";
		/**
		 * used for event dispatching<br>
		 */
		public static const CREATING_LOGBOOK_HEADERS:String = "creating_logbook_headers";
		/**
		 * used for event dispatching<br>
		 */
		public static const INSERTING_NEW_EVENTS:String = "inserting_new_events";
		/**
		 * used for event dispatching<br>
		 */
		public static const EVENTS_UPLOADED_NOW_SYNCING_THE_SETTINGS:String = "events_uploaded";
		/**
		 * used for event dispatching<br>
		 */
		public static const SEARCHING_LOGBOOK_WORKSHEET:String = "searching_logbook_worksheet";
		/**
		 * used for event dispatching<br>
		 */
		public static const WAITING_FOR_SYNC_TO_FINISH:String = "waiting_for_sync_to_finish";
		/**
		 * used for event dispatching<br>
		 */
		public static const NEW_EVENT_UPLOADED:String = "new_event_uploaded";
		
		private var _foodtable:XML = <foodtable/>;
		
		/**
		 * foodtable downloaded, if null then download failed
		 */
		public function get foodtable():XML
			
		{
			return _foodtable;
		}
		
		private var _uploadFoodDatabaseStatus:String = "";

		/**
		 * text to use in downloadfoodtableview, for showing status 
		 */
		public function get uploadFoodDatabaseStatus():String

		{
			return _uploadFoodDatabaseStatus;
		}
		
		private var _workSheetList:ArrayList;
		
		/**
		 * list of worksheets in selected spreadsheetlist
		 */
		public function get workSheetList():ArrayList
			
		{
			return _workSheetList;
		}
		
		private var _spreadSheetList:ArrayList;
		
		/**
		 * list of spreadsheets retrieved from google docs. objects will be so called items (see google docs documentation or check the code)
		 */
		public function get spreadSheetList():ArrayList
			
		{
			return _spreadSheetList;
		}
		
		public static const prefix_default:String = "";
		public static const prefix_gs:String = "gs";
		private static var _namespace_default:Namespace;
		
		public function get namespace_default():Namespace
			
		{
			return _namespace_default;
		}
		
		private static var _namespace_gs:Namespace;
		
		public function get namespace_gs():Namespace
			
		{
			return _namespace_gs;
		}
		
		
		/**
		 * constructor not to be used, get an instance with getInstance() 
		 */
		public function Synchronize()
		{
			if (instance != null) {
				throw new Error("Synchronize class can only be accessed through Synchronize.getInstance()");	
			}
			debugMode = ModelLocator.debugMode;
			
			syncRunning = false;
			findAllSpreadSheetsWaiting = false;
			downloadFoodTableSpreadSheetWaiting = false;
			findAllWorkSheetsInFoodTableSpreadSheetWaiting = false;
			
			createlogbookheaderWaiting = false;
			createlogbookWaiting = false;
			createlogbookworksheetWaiting = false;
			findlogbookspreadsheetWaiting = false;
			findlogbookworksheetWaiting = false;
			insertlogbookeventsWaiting = false;
			
			rerunNecessary = false;
			
			amountofSpaces = 0;
			alReadyGATracked = false;//only one google analytics tracking per instance
			listOfElementsToBeDeleted = new ArrayList();
			instance = this;
			currentSyncTimeStamp = 0;
			googleExcelLogBookColumnNames[foodValueNames_Index_date] = ResourceManager.getInstance().getString('uploadtrackingview','date');
			googleExcelLogBookColumnNames[foodValueNames_Index_time] = ResourceManager.getInstance().getString('uploadtrackingview','time');
			googleExcelLogBookColumnNames[foodValueNames_Index_eventtype] = ResourceManager.getInstance().getString('uploadtrackingview','eventtype');
			googleExcelLogBookColumnNames[foodValueNames_Index_bloodglucosevalue] = ResourceManager.getInstance().getString('uploadtrackingview','bloodglucosevalue');
			googleExcelLogBookColumnNames[foodValueNames_Index_medicinvalue] = ResourceManager.getInstance().getString('uploadtrackingview','medicinvalue');
			googleExcelLogBookColumnNames[foodValueNames_Index_exerciselevel] = ResourceManager.getInstance().getString('uploadtrackingview','exerciselevel');
			googleExcelLogBookColumnNames[foodValueNames_Index_medicintype] = ResourceManager.getInstance().getString('uploadtrackingview','medicintype');
			googleExcelLogBookColumnNames[foodValueNames_Index_mealtype] = ResourceManager.getInstance().getString('uploadtrackingview','mealtype');
			googleExcelLogBookColumnNames[foodValueNames_Index_mealcarbamount] = ResourceManager.getInstance().getString('uploadtrackingview','mealcarbamount');
			googleExcelLogBookColumnNames[foodValueNames_Index_mealinsulinratio] = ResourceManager.getInstance().getString('uploadtrackingview','mealinsulinratio');
			googleExcelLogBookColumnNames[foodValueNames_Index_mealcalculatedinsulin] = ResourceManager.getInstance().getString('uploadtrackingview','mealcalculatedinsulin');
			googleExcelLogBookColumnNames[foodValueNames_Index_mealselecteditems] = ResourceManager.getInstance().getString('uploadtrackingview','mealselecteditems');
			googleExcelLogBookColumnNames[foodValueNames_Index_comment] = ResourceManager.getInstance().getString('uploadtrackingview','comment');
			googleExcelLogBookColumnNames[foodValueNames_Index_mealkcalamount] = ResourceManager.getInstance().getString('uploadtrackingview','mealkcalamount');
			googleExcelLogBookColumnNames[foodValueNames_Index_mealproteinamount] = ResourceManager.getInstance().getString('uploadtrackingview','mealproteinamount');
			googleExcelLogBookColumnNames[foodValueNames_Index_mealfatamount] = ResourceManager.getInstance().getString('uploadtrackingview','mealfatamount');
		}
		
		public static function getInstance():Synchronize {
			if (instance == null) instance = new Synchronize();
			return instance;
		}
		
		/**
		 * If  (syncRunning is true and currentSyncTimeStamp > 30 seconds ago) or  (syncRunning is false & (immediateRunNecessary or currentSyncTimeStamp > 30 seconds ago)), then run the sync, reset timestamp of startrun to current time, 
		 * set rerunnecessary to false<br>
		 * <br>
		 * If  (syncRunning is true and currentSyncTimeStamp < 30 seconds ago) don't run, if immediateRunNecessary set rerunNecessary to true; else don't set anything.<br>
		 * onlySyncTheSettings =  if true synchronize will jump immediately to syncing the settings, assuming all tables are already there. Should only be true if it's sure that tables are existing on google docs account
		 */
		public function startSynchronize(immediateRunNecessary:Boolean,onlySyncTheSettings:Boolean):void {

			//to make sure there's at least one complete resync per day
			if ((new Date()).date != new Number(Settings.getInstance().getSetting(Settings.SettingsDayOfLastCompleteSync))) {
				Settings.getInstance().setSetting(Settings.SettingsLastSyncTimeStamp,
					( (
						(new Date()).valueOf() 
						- 
						new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000
					).toString()
					)
				);
				Settings.getInstance().setSetting(Settings.SettingsDayOfLastCompleteSync,(new Date()).date.toString());
			}
			
			if (
				(!(Settings.getInstance().getSetting(Settings.SettingsAllFoodItemsUploadedToGoogleExcel) == "true"))
				&&
				(Settings.getInstance().getSetting(Settings.SettingsIMtheCreateorOfGoogleExcelFoodTable) == "true")
			)//uploading foodtable can take a very long time 
				secondsBetweenTwoSync = 3600;
			else 
				secondsBetweenTwoSync = normalValueForSecondsBetweenTwoSync;
			
			var timeSinceLastSyncMoreThanXMinutes:Boolean = (new Date().valueOf() - currentSyncTimeStamp) > secondsBetweenTwoSync * 1000;
			
			if ((syncRunning && (timeSinceLastSyncMoreThanXMinutes))  || (!syncRunning && (immediateRunNecessary || timeSinceLastSyncMoreThanXMinutes))) {
				localElementsUpdated  = false;
				retrievalCounter = 0;
				helpDiabetesFoodTableWorkSheetId = "";//not really necessary to reset it each time to empty string, but you never know it could be that user deletes the foodtable worksheet in between to syncs,
				helpDiabetesFoodTableSpreadSheetKey = "";//same comment
				trackingList = ModelLocator.getInstance().trackingList;
				currentSyncTimeStamp = new Date().valueOf();
				lastSyncTimeStamp = new Number(Settings.getInstance().getSetting(Settings.SettingsLastSyncTimeStamp));
				if (debugMode)
					trace("lastsynctimestamp = " + new DateFormatter().format(new Date(lastSyncTimeStamp)));
				asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;
				rerunNecessary = false;
				syncRunning = true;
				currentSyncTimeStamp = new Date().valueOf();
				asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;
				findAllSpreadSheetsWaiting = false;
				downloadFoodTableSpreadSheetWaiting = false;
				findAllWorkSheetsInFoodTableSpreadSheetWaiting = false;
				
				createlogbookheaderWaiting = false;
				createlogbookWaiting = false;
				createlogbookworksheetWaiting = false;
				findlogbookspreadsheetWaiting = false;
				findlogbookworksheetWaiting = false;
				insertlogbookeventsWaiting = false;
				
				if (onlySyncTheSettings)
					getTheSettings();
				else
					synchronize();
			} else {
				if (immediateRunNecessary) {
					rerunNecessary = true;
				}
			}
		}
		
		/**
		 * if there's no valid access_token or refresh_token, then this method will do nothing<br>
		 * if there's a valid access_token or refresh_token, then this method will synchronize the database with 
		 * Google Fusion Tables 
		 */
		private function synchronize(event:Event = null):void {
			_synchronize_debugString = "";
			if (event != null)  {
				removeEventListeners();
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if (eventHasError(event,synchronize))
					return;
				else
				{
					nextPageToken = eventAsJSONObject.nextPageToken;
					if (eventAsJSONObject.items) {
						//there are table names retrieved, let's go through them
						for (var i:int = 0;i < eventAsJSONObject.items.length;i++) {
							//go through each item, see if name matches one in the tablelist, if so store tableid
							for (var j:int = 0;j < tableNamesAndColumnNames.length;j++) {
								if (eventAsJSONObject.items[i].name == tableNamesAndColumnNames[j][0]) {
									if (debugMode)
										trace("found a table : " + eventAsJSONObject.items[i].name);
									tableNamesAndColumnNames[j][1] = eventAsJSONObject.items[i].tableId;	
								}
							}
						}
					}
					if (nextPageToken != null)
						//there's more tables, get the next list
						synchronize(); 
					else {
						createMissingTables();
					}
				}
			} else  {
				trackingListAlreadyModified = false;
				if (debugMode)
					trace("start method synchronize");
				
				//we could be arriving here after a retempt, example, first time failed due to invalid credentials, token refresh occurs, with success, we come back to here
				//first thing to do is to removeeventlisteners
				
				access_token = Settings.getInstance().getSetting(Settings.SettingsAccessToken);
				
				if (access_token.length == 0  ) {
					//there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize
					//ModelLocator.getInstance().logString += "error 1 : there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize"+ "\n";
					syncFinished(false);
				} else {
					if (!alReadyGATracked) {
						alReadyGATracked = MyGATracker.getInstance().trackPageview( "Synchronize-SyncStarted");
					}
					
					//first get all the tables
					var urlVariables:URLVariables = new URLVariables();
					urlVariables.maxResults = maxResults;
					if (nextPageToken != null)
						urlVariables.pageToken = nextPageToken;
					
					createAndLoadURLRequest(
						googleRequestTablesUrl,
						URLRequestMethod.GET,
						urlVariables,
						null,
						synchronize,
						true,
						null);
				}
			}
		}
		
		private function createMissingTables(event:Event = null): void {
			if (debugMode)
				trace("start method createMissingTables");
			
			if (event != null) {
				removeEventListeners();
				
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventHasError(event,createMissingTables))
					return;
				
				for (var k:int = 0;k < tableNamesAndColumnNames.length;k++) {
					if (tableNamesAndColumnNames[k][0] == eventAsJSONObject.name as String) {
						tableNamesAndColumnNames[k][1] = eventAsJSONObject.tableId as String;
						break;//we have to create this table so break the loop
					}
				}
			} else 
				retrievalCounter++;
			
			if (retrievalCounter > 100)  {
				//stop it, we seem to be in an endless loop
				//ModelLocator.getInstance().logString += "error 2 : " + event.target.data;
				syncFinished(false);
			} else {
				var i:int=0;
				//first find next missing table, for that one will try to create it
				for (i = 0;i < tableNamesAndColumnNames.length;i++) {
					if (tableNamesAndColumnNames[i][1] == "")
						break;//we have to create this table so break the loop
				}
				
				if (i == tableNamesAndColumnNames.length)	{
					//if we get here, it means all table have a tableid, means they all exist at google docs
					startSync();
				} else {
					
					var jsonObject:Object = new Object();
					jsonObject.isExportable = "false";
					jsonObject.name = tableNamesAndColumnNames[i][0];
					var columns:ArrayList = new ArrayList();
					for (var l:int = 0;l < tableNamesAndColumnNames[i][2].length;l++) {
						var jsonObject2:Object =  new Object();
						jsonObject2.name = tableNamesAndColumnNames[i][2][l][0]; 
						jsonObject2.type = tableNamesAndColumnNames[i][2][l][1]; 
						columns.addItem(jsonObject2);
					}
					jsonObject.columns = columns.toArray();
					
					jsonObject.description =   tableNamesAndColumnNames[i][3];
					
					createAndLoadURLRequest(googleRequestTablesUrl,URLRequestMethod.POST,null,JSON.stringify(jsonObject),createMissingTables,true,"application/json");
				}
				
			}			
		}
		
		private function startSync():void {
			localElements = new ArrayList();
			
			remoteElements = new ArrayList();
			remoteElementIds = new ArrayList();
			nextPageToken = null;//not sure if nextPageToken is used by google when doing a select
			secondAttempt = false;
			deleteRemoteItems();
		}
		
		/**
		 * will start deleting all the items in listofElementsToBeDeleted<br>
		 * event will be there if called after update of previous element in remote database finished, but we're not interested in the result
		 */
		private function deleteRemoteItems(event:Event = null):void {
			if (listOfElementsToBeDeleted.length > 0) {
				var firstelementToDeleted:Object = listOfElementsToBeDeleted.getItemAt(0);
				if (firstelementToDeleted is MedicinEvent)
					deleteRemoteMedicinEvent(null, firstelementToDeleted as MedicinEvent);
				else if (firstelementToDeleted is BloodGlucoseEvent)
					deleteRemoteBloodGlucoseEvent(null, firstelementToDeleted as BloodGlucoseEvent);
				else if (firstelementToDeleted is ExerciseEvent)
					deleteRemoteExerciseEvent(null, firstelementToDeleted as ExerciseEvent);
				else if (firstelementToDeleted is MealEvent)
					deleteRemoteMealEvent(null, firstelementToDeleted as MealEvent);
				else if (firstelementToDeleted is SelectedFoodItem)
					deleteRemoteSelectedFoodItem(null, firstelementToDeleted as SelectedFoodItem);
			} else {
				getTheMedicinEvents();
			}
		}
		
		/**
		 * adds missing column to a table<br>
		 * functionToRecall will be called when finished 
		 */
		private function addColumnToExistingTable(functionToReCall:Function,tableId:String,columnName:String,columnType:String):void {
			if (debugMode)
				trace("start method addColumnToExistingTable for tableid = " + tableId + "columnName = " + columnName);
			
			var jsonObject:Object = new Object();
			jsonObject.name = columnName;
			jsonObject.type = columnType;
			
			createAndLoadURLRequest(googleInsertColumnInTableUrl.replace("{tableId}",tableId),URLRequestMethod.POST,null,JSON.stringify(jsonObject),functionToReCall,true,"application/json");
		}
		
		/**
		 * checks of all columns that should be there are available remotely<br>
		 * at first column that is not there, will call addcolumntoexistingtable, with functiontorecall as callback function, and in that case stops searching for other columns and returns false<br>
		 * columnsInRemoteTable is an array<br>
		 * columnsThatShouldBeThere is an array of array, with first element in each array being the column name, second element the column type
		 * returns true if all columns are there
		 */
		private function checkMissingColumn(tableId:String,columnsInRemoteTable:Array,columnsThatShouldBeThere:Array,functionToReCall:Function):Boolean {
			var remotectr:int;
			for (var localctr:int = 0;localctr < columnsThatShouldBeThere.length;localctr++) {
				for (remotectr = 0;remotectr < columnsInRemoteTable.length;remotectr++) {
					if (columnsInRemoteTable[remotectr] == columnsThatShouldBeThere[localctr][0])
						break;
				}
				if (remotectr == columnsInRemoteTable.length) {
					addColumnToExistingTable(functionToReCall,tableId,columnsThatShouldBeThere[localctr][0],columnsThatShouldBeThere[localctr][1]);
					return false;
				}
			}
			return true;
		}
		
		private function getTheMedicinEvents(event:Event = null):void {
			var positionId:int;
			var eventAsJSONObject:Object;
			
			if (debugMode)
				trace("start method getTheMedicinEvents");
			//ModelLocator.getInstance().logString += "start method getthemedicinevents"+ "\n";;
			//start with remoteElements
			//I'm assuming here that the nextpagetoken principle will be used by google, not sure however
			if (event != null) {
				removeEventListeners();
				eventAsJSONObject = JSON.parse(event.target.data as String);
				
				if (eventHasError(event,getTheMedicinEvents))
					return;

				else {
					if (eventAsJSONObject.kind != "fusiontables#column")  {//if it would have been fusiontables#column, it would mean we come here after having added a missing column
						positionId = eventAsJSONObject.columns.indexOf(ColumnName_id);
						
						if (!(checkMissingColumn(tableNamesAndColumnNames[0][1],eventAsJSONObject.columns,tableNamesAndColumnNames[0][2],getTheMedicinEvents)))
							return;
						var elementAlreadyThere:Boolean;
						if (eventAsJSONObject.rows) {
							for (var rowctr:int = 0;rowctr < eventAsJSONObject.rows.length;rowctr++) {
								elementAlreadyThere = false;
								for (var rowctr2:int = 0;rowctr2 < remoteElements.length;rowctr2++) {
									if ((remoteElements.getItemAt(rowctr2) as Array)[positionId] == eventAsJSONObject.rows[rowctr][positionId]) {
										elementAlreadyThere = true;
										if (remoteElementEventIdsToBeDeleted == null) {
											remoteElementEventIdsToBeDeleted = new ArrayList();
										}
										//now remoteelementidstobedeleted is array of tableid, eventid pair, eventid still needs to be changed to rowid
										remoteElementEventIdsToBeDeleted.addItem(new Array(tableNamesAndColumnNames[0][1],(remoteElements.getItemAt(rowctr2) as Array)[positionId]));
										break;
									}
								}
								if (!elementAlreadyThere) {
									remoteElements.addItem(eventAsJSONObject.rows[rowctr]);
									remoteElementIds.addItem([new Number(eventAsJSONObject.rows[rowctr][positionId]),null]);
								}
							}
						}
						nextPageToken = eventAsJSONObject.nextPageToken;
					}
				}
			} 
			
			if (event == null || nextPageToken != null ) {//two reasons to try to fetch data from google
				var urlVariables:URLVariables = new URLVariables();
				urlVariables.sql = createSQLQueryToSelectAll(0);
				if (nextPageToken != null)
					urlVariables.pageToken = nextPageToken;
				
				createAndLoadURLRequest(googleSelectUrl,URLRequestMethod.GET,urlVariables,null,getTheMedicinEvents,true,null);
				var request:URLRequest = new URLRequest(googleSelectUrl);
			} else {
				//get the medicinevents in the trackinglist and store them in localElements.
				for (var i:int = 0; i < trackingList.length; i++) {
					if (trackingList.getItemAt(i) is MedicinEvent) {
						if ((trackingList.getItemAt(i) as MedicinEvent).timeStamp >= asOfTimeStamp)
							if ((trackingList.getItemAt(i) as MedicinEvent).lastModifiedTimestamp >= lastSyncTimeStamp)
								localElements.addItem(trackingList.getItemAt(i));
					}
				}
				//time to start comparing
				//we go through each list, for elements with matching id, any element that is found in the other list with the same modifiedtimestamp is removed from both lists
				for (var j:int = 0; j < localElements.length; j++) {
					for (var k:int = 0; k < remoteElements.length; k++) {
						if ((remoteElements.getItemAt(k) as Array)[positionId] == (localElements.getItemAt(j) as MedicinEvent).eventid) {
							//got a matching element, let's see if we need to remove it from both lists
							if (new Number((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][4][0])]) != (localElements.getItemAt(j) as MedicinEvent).lastModifiedTimestamp) {
								//no lastmodifiedtimestamps are not equal, we need to see which one is most recent
								//but first let's see if the remoteelement has the deleted flag set
								if (((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][5][0])] as String) == "true") {
									//its a deleted item remove it from both lists
									remoteElements.removeItemAt(k);
									copyTrackingListIfNotDoneYet();
									(localElements.getItemAt(j) as MedicinEvent).deleteEvent();//delete from local database
									localElementsUpdated = true;//as we deleted one from local database, 
									localElements.removeItemAt(j);//remove also from list used here
									j--;//j is going to be incrased and will point to the next element, as we've just deleted one
									break;
								} else {
									if (new Number((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][4][0])]) < (localElements.getItemAt(j) as MedicinEvent).lastModifiedTimestamp) {
										remoteElements.removeItemAt(k);
										break;
									} else {
										localElements.removeItemAt(j);
										j--;
										break;
									}
								}
							} else {
								//yes lastmodifiedtimestamps are equal, so let's remove them from both lists
								remoteElements.removeItemAt(k);
								localElements.removeItemAt(j);
								j--;//j is going to be incrased and will point to the next element, as we've just deleted one
								break;//jump out of th einnter for loop
							}
						}
					}
					//j could be -1 now, and there might not be anymore elements inlocalemenets so
					if (j + 1 == localElements.length)
						break;
				}
				//we've got to start updating
				for (var m:int = 0; m < remoteElements.length; m++) {
					//we have to find the medicinevent in the trackinglist that has the same id
					var l:int=0;
					for (l = 0; l < trackingList.length;l++) {
						if (trackingList.getItemAt(l) is MedicinEvent) {
							if ((trackingList.getItemAt(l) as MedicinEvent).eventid == remoteElements.getItemAt(m)[positionId] ) {
								localElementsUpdated = true;
								if ((remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][5][0])] as String) == "true") {
									if (debugMode)
										if (debugMode) trace("local element deleted, id = " + (trackingList.getItemAt(l) as MedicinEvent).eventid);
									(trackingList.getItemAt(l) as MedicinEvent).deleteEvent();
								} else {
									var medicinArray:Array = (remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][1][0])] as String).split(Database.medicinnamesplitter);
									var bolusType:String;
									var bolusDuration:Number;
									if (medicinArray.length > 1)
										bolusType = medicinArray[1];
									else 
										bolusType = ResourceManager.getInstance().getString('editmedicineventview',MedicinEvent.BOLUS_TYPE_NORMAL);
									if (medicinArray.length > 2)
										bolusDuration = new Number(medicinArray[2] as String);
									else
										bolusDuration = new Number(0);

									var medicinName:String = medicinArray[0];

									(trackingList.getItemAt(l) as MedicinEvent).updateMedicinEvent(
										bolusType,
										bolusDuration,
										medicinName,
										remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][2][0])],
										remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][6][0])],//comment
										new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][3][0])]),
										new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][4][0])]));
									if (debugMode) trace("local element updated, id = " + (trackingList.getItemAt(l) as MedicinEvent).eventid);
								}
								break;
							}
						}
					}
					if (l == trackingList.length) {
						//it means we didn't find the remotelement in the trackinglist, so we need to create it
						//but only if deleted is false
						if (((remoteElements.getItemAt(m) as Array)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][5][0])] as String) == "false") {
							localElementsUpdated = true;
							var medicinArray1:Array = (remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][1][0])] as String).split(Database.medicinnamesplitter);
							var bolusType1:String;
							var bolusDuration2:Number;
							if (medicinArray1.length > 1)
								bolusType1 = medicinArray1[1];
							else 
								bolusType1 = ResourceManager.getInstance().getString('editmedicineventview',MedicinEvent.BOLUS_TYPE_NORMAL);
							if (medicinArray1.length > 2)
								bolusDuration2 = new Number(medicinArray1[2] as String);
							else
								bolusDuration2 = new Number(0);

							var medicinName1:String = medicinArray1[0];

							(new MedicinEvent(
								remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][2][0])],
								medicinName1,
								remoteElements.getItemAt(m)[positionId],
								remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][6][0])],//comment
								new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][3][0])]),
								new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(tableNamesAndColumnNames[0][2][4][0])]),
								true,
								bolusType1,
								bolusDuration2));
							if (debugMode) trace("local element created, id = " + remoteElements.getItemAt(m)[positionId]);
						}
					}
				}
				remoteElements = new ArrayList();
				//let's go for the bloodglucoseevents
				getTheBloodGlucoseEvents(null);
			}
		}
		
		private function getTheBloodGlucoseEvents(event:Event = null):void {
			var positionId:int;
			var eventAsJSONObject:Object;
			
			if (debugMode)
				trace("start method getTheBloodGlucoseEvents");
			
			//start with remoteElements
			//I'm assuming here that the nextpagetoken principle will be used by google, not sure however
			if (event != null) {
				removeEventListeners();
				eventAsJSONObject = JSON.parse(event.target.data as String);
				
				if (eventHasError(event,getTheBloodGlucoseEvents))
					return;
				else {
					if (eventAsJSONObject.kind != "fusiontables#column")  {
						positionId = eventAsJSONObject.columns.indexOf(ColumnName_id);
						
						if (!(checkMissingColumn(tableNamesAndColumnNames[1][1],eventAsJSONObject.columns,tableNamesAndColumnNames[1][2],getTheBloodGlucoseEvents)))
							return;

						var elementAlreadyThere:Boolean;
						if (eventAsJSONObject.rows) {
							for (var rowctr:int = 0;rowctr < eventAsJSONObject.rows.length;rowctr++) {
								elementAlreadyThere = false;
								for (var rowctr2:int = 0;rowctr2 < remoteElements.length;rowctr2++) {
									if ((remoteElements.getItemAt(rowctr2) as Array)[positionId] == eventAsJSONObject.rows[rowctr][positionId]) {
										elementAlreadyThere = true;
										if (remoteElementEventIdsToBeDeleted == null) {
											remoteElementEventIdsToBeDeleted = new ArrayList();
										}
										//now remoteelementidstobedeleted is array of tableid, eventid pair, eventid still needs to be changed to rowid
										remoteElementEventIdsToBeDeleted.addItem(new Array(tableNamesAndColumnNames[1][1],(remoteElements.getItemAt(rowctr2) as Array)[positionId]));
										break;
									}
								}
								if (!elementAlreadyThere) {
									remoteElements.addItem(eventAsJSONObject.rows[rowctr]);
									remoteElementIds.addItem([new Number(eventAsJSONObject.rows[rowctr][positionId]),null]);
								}
							}
						}
						nextPageToken = eventAsJSONObject.nextPageToken;
					}
				}
			} 
			
			if (event == null || nextPageToken != null ) {//two reasons to try to fetch data from google
				var urlVariables:URLVariables = new URLVariables();
				urlVariables.sql = createSQLQueryToSelectAll(1);
				if (nextPageToken != null)
					urlVariables.pageToken = nextPageToken;
				
				createAndLoadURLRequest(googleSelectUrl,null,urlVariables,null,getTheBloodGlucoseEvents,true,null);
			} else {
				//get the bloodglucoseevents in the trackinglist and store them in localElements.
				for (var i:int = 0; i < trackingList.length; i++) {
					if (trackingList.getItemAt(i) is BloodGlucoseEvent) {
						if ((trackingList.getItemAt(i) as BloodGlucoseEvent).timeStamp >= asOfTimeStamp)
							if ((trackingList.getItemAt(i) as BloodGlucoseEvent).lastModifiedTimestamp >= lastSyncTimeStamp)
								localElements.addItem(trackingList.getItemAt(i));
					}
				}
				//time to start comparing
				//we go through each list, for elements with matching id, any element that is found in the other list with the same modifiedtimestamp is removed from both lists
				for (var j:int = 0; j < localElements.length; j++) {
					for (var k:int = 0; k < remoteElements.length; k++) {
						if (localElements.getItemAt(j) is BloodGlucoseEvent)  {
							if ((remoteElements.getItemAt(k) as Array)[positionId] == (localElements.getItemAt(j) as BloodGlucoseEvent).eventid) {
								//got a matching element, let's see if we need to remove it from both lists
								if (new Number((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]) != (localElements.getItemAt(j) as BloodGlucoseEvent).lastModifiedTimestamp) {
									//no lastmodifiedtimestamps are not equal, we need to see which one is most recent
									//but first let's see if the remoteelement has the deleted flag set
									if (((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_deleted)] as String) == "true") {
										//its a deleted item remove it from both lists
										remoteElements.removeItemAt(k);
										copyTrackingListIfNotDoneYet();
										(localElements.getItemAt(j) as BloodGlucoseEvent).deleteEvent();//delete from local database
										localElementsUpdated = true;//as we deleted one from local database, 
										localElements.removeItemAt(j);//remove also from list used here
										j--;//j is going to be incrased and will point to the next element, as we've just deleted one
										break;
									} else {
										if (new Number((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]) < (localElements.getItemAt(j) as BloodGlucoseEvent).lastModifiedTimestamp) {
											remoteElements.removeItemAt(k);
											break;
										} else {
											localElements.removeItemAt(j);
											j--;
											break;
										}
									}
								} else {
									//yes lastmodifiedtimestamps are equal, so let's remove them from both lists
									remoteElements.removeItemAt(k);
									//remoteElementIds.removeItemAt(k);
									localElements.removeItemAt(j);
									j--;//j is going to be incrased and will point to the next element, as we've just deleted one
									break;//jump out of th einnter for loop
								}
							}
						}
					}
					//j could be -1 now, and there might not be anymore elements inlocalemenets so
					if (j + 1 == localElements.length)
						break;
				}
				//we've got to start updating
				for (var m:int = 0; m < remoteElements.length; m++) {
					//we have to find the medicinevent in the trackinglist that has the same id
					var l:int=0;
					for (l = 0; l < trackingList.length;l++) {
						if (trackingList.getItemAt(l) is BloodGlucoseEvent) {
							if ((trackingList.getItemAt(l) as BloodGlucoseEvent).eventid == remoteElements.getItemAt(m)[positionId] ) {
								localElementsUpdated = true;
								if ((remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_deleted)] as String) == "true") {
									if (debugMode)
										if (debugMode) trace("local element deleted, id = " + (trackingList.getItemAt(l) as BloodGlucoseEvent).eventid);
									(trackingList.getItemAt(l) as BloodGlucoseEvent).deleteEvent();
								} else {
									(trackingList.getItemAt(l) as BloodGlucoseEvent).updateBloodGlucoseEvent(
										remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unit)],
										remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_value)],
										new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_creationtimestamp)]),
										remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_comment)],
										new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]));
									if (debugMode) trace("local element updated, id = " + (trackingList.getItemAt(l) as BloodGlucoseEvent).eventid);
								}
								break;
							}
						}
					}
					if (l == trackingList.length) {
						//it means we didn't find the remotelement in the trackinglist, so we need to create it
						//but only if deleted is false
						if (((remoteElements.getItemAt(m) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_deleted)] as String) == "false") {
							localElementsUpdated = true;
							
							(new BloodGlucoseEvent(
								remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_value)],
								remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unit)],
								remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_id)],
								remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_comment)],
								new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_creationtimestamp)]),
								new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]),
								true));
							if (debugMode) trace("local element created, id = " + remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_id)]);
						}
					}
				}
				remoteElements = new ArrayList();
				//let's go for the localevents
				getTheExerciseEvents(null);
			}
		}
		
		private function getTheExerciseEvents(event:Event = null):void {
			var positionId:int;
			var eventAsJSONObject:Object;
			
			if (debugMode)
				trace("start method getTheExerciseEvents");
			//start with remoteElements
			//I'm assuming here that the nextpagetoken principle will be used by google, not sure however
			if (event != null) {
				removeEventListeners();
				eventAsJSONObject = JSON.parse(event.target.data as String);
				
				if (eventHasError(event,getTheExerciseEvents))
					return;
				else {
					if (eventAsJSONObject.kind != "fusiontables#column")  {
						positionId = eventAsJSONObject.columns.indexOf(ColumnName_id);
						
						if (!(checkMissingColumn(tableNamesAndColumnNames[2][1],eventAsJSONObject.columns,tableNamesAndColumnNames[2][2],getTheExerciseEvents)))
							return;

						var elementAlreadyThere:Boolean;
						if (eventAsJSONObject.rows) {
							for (var rowctr:int = 0;rowctr < eventAsJSONObject.rows.length;rowctr++) {
								elementAlreadyThere = false;
								for (var rowctr2:int = 0;rowctr2 < remoteElements.length;rowctr2++) {
									if ((remoteElements.getItemAt(rowctr2) as Array)[positionId] == eventAsJSONObject.rows[rowctr][positionId]) {
										elementAlreadyThere = true;
										if (remoteElementEventIdsToBeDeleted == null) {
											remoteElementEventIdsToBeDeleted = new ArrayList();
										}
										//now remoteelementidstobedeleted is array of tableid, eventid pair, eventid still needs to be changed to rowid
										remoteElementEventIdsToBeDeleted.addItem(new Array(tableNamesAndColumnNames[2][1],(remoteElements.getItemAt(rowctr2) as Array)[positionId]));
										break;
									}
								}
								if (!elementAlreadyThere) {
									remoteElements.addItem(eventAsJSONObject.rows[rowctr]);
									remoteElementIds.addItem([new Number(eventAsJSONObject.rows[rowctr][positionId]),null]);
								}
							}
						}
						nextPageToken = eventAsJSONObject.nextPageToken;
					}
				}
			} 
			
			if (event == null || nextPageToken != null) {//two reasons to try to fetch data from google
				var urlVariables:URLVariables = new URLVariables();
				urlVariables.sql = createSQLQueryToSelectAll(2);
				if (nextPageToken != null)
					urlVariables.pageToken = nextPageToken;
				createAndLoadURLRequest(googleSelectUrl,null,urlVariables,null,getTheExerciseEvents,true,null);
			} else {
				//get the exerciseevents in the trackinglist and store them in localElements.
				for (var i:int = 0; i < trackingList.length; i++) {
					if (trackingList.getItemAt(i) is ExerciseEvent) {
						if ((trackingList.getItemAt(i) as ExerciseEvent).timeStamp >= asOfTimeStamp)
							if ((trackingList.getItemAt(i) as ExerciseEvent).lastModifiedTimestamp >= lastSyncTimeStamp)
								localElements.addItem(trackingList.getItemAt(i));
					}
				}
				//time to start comparing
				//we go through each list, for elements with matching id, any element that is found in the other list with the same modifiedtimestamp is removed from both lists
				for (var j:int = 0; j < localElements.length; j++) {
					for (var k:int = 0; k < remoteElements.length; k++) {//not a logical implementation, we should first check if it's an exerciseevent, and then go through the list of remoteleements
						if (localElements.getItemAt(j) is ExerciseEvent) {
							if ((remoteElements.getItemAt(k) as Array)[positionId] == (localElements.getItemAt(j) as ExerciseEvent).eventid) {
								//got a matching element, let's see if we need to remove it from both lists
								if (new Number((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]) != (localElements.getItemAt(j) as ExerciseEvent).lastModifiedTimestamp) {
									//no lastmodifiedtimestamps are not equal, we need to see which one is most recent
									//but first let's see if the remoteelement has the deleted flag set
									if (((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_deleted)] as String) == "true") {
										//its a deleted item remove it from both lists
										remoteElements.removeItemAt(k);
										copyTrackingListIfNotDoneYet();
										localElementsUpdated = true;//as we deleted one from local database, 
										(localElements.getItemAt(j) as ExerciseEvent).deleteEvent();//delete from local database
										localElements.removeItemAt(j);//remove also from list used here
										j--;//j is going to be incrased and will point to the next element, as we've just deleted one
										break;
									} else {
										if (new Number((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]) < (localElements.getItemAt(j) as ExerciseEvent).lastModifiedTimestamp) {
											remoteElements.removeItemAt(k);
											break;
										} else {
											localElements.removeItemAt(j);
											j--;
											break;
										}
									}
								} else {
									//yes lastmodifiedtimestamps are equal, so let's remove them from both lists
									remoteElements.removeItemAt(k);
									//remoteElementIds.removeItemAt(k);
									localElements.removeItemAt(j);
									j--;//j is going to be incrased and will point to the next element, as we've just deleted one
									break;//jump out of th einnter for loop
								}
							}
						}
					}
					//j could be -1 now, and there might not be anymore elements inlocalemenets so
					if (j + 1 == localElements.length)
						break;
				}
				//we've got to start updating
				for (var m:int = 0; m < remoteElements.length; m++) {
					//we have to find the medicinevent in the trackinglist that has the same id
					var l:int=0;
					for (l = 0; l < trackingList.length;l++) {
						if (trackingList.getItemAt(l) is ExerciseEvent) {
							if ((trackingList.getItemAt(l) as ExerciseEvent).eventid == remoteElements.getItemAt(m)[positionId] ) {
								localElementsUpdated = true;
								if ((remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_deleted)] as String) == "true") {
									if (debugMode)
										if (debugMode) trace("local element deleted, id = " + (trackingList.getItemAt(l) as ExerciseEvent).eventid);
									(trackingList.getItemAt(l) as ExerciseEvent).deleteEvent();
								} else {
									(trackingList.getItemAt(l) as ExerciseEvent).updateExerciseEvent(
										remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_level)],
										new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_creationtimestamp)]),
										new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]),
										remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_comment)]);
									if (debugMode) trace("local element updated, id = " + (trackingList.getItemAt(l) as ExerciseEvent).eventid);
								}
								break;
							}
						}
					}
					if (l == trackingList.length) {
						//it means we didn't find the remotelement in the trackinglist, so we need to create it
						//but only if deleted is false
						if (((remoteElements.getItemAt(m) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_deleted)] as String) == "false") {
							localElementsUpdated = true;
							
							(new ExerciseEvent(
								remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_level)],
								remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_comment)],
								remoteElements.getItemAt(m)[positionId],
								new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_creationtimestamp)]),
								new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]),
								true));
							if (debugMode) trace("local element created, id = " + remoteElements.getItemAt(m)[positionId]);
						}
					}
				}
				remoteElements = new ArrayList();
				//let's go for the bloodglucoseevents
				getTheMealEvents(null);
				//let's go for the localevents
			}
		}
		
		private function getTheMealEvents(event:Event = null):void {
			var positionId:int;
			var eventAsJSONObject:Object;
			
			if (debugMode)
				trace("start method getTheMealEvents");
			//start with remoteElements
			//I'm assuming here that the nextpagetoken principle will be used by google, not sure however
			if (event != null) {
				removeEventListeners();
				eventAsJSONObject = JSON.parse(event.target.data as String);
				
				if (eventHasError(event,getTheMealEvents))
					return;
				else {
					if (eventAsJSONObject.kind != "fusiontables#column")  {
						positionId = eventAsJSONObject.columns.indexOf(ColumnName_id);
						
						if (!(checkMissingColumn(tableNamesAndColumnNames[3][1],eventAsJSONObject.columns,tableNamesAndColumnNames[3][2],getTheMealEvents)))
							return;

						var elementAlreadyThere:Boolean;
						if (eventAsJSONObject.rows) {
							for (var rowctr:int = 0;rowctr < eventAsJSONObject.rows.length;rowctr++) {
								elementAlreadyThere = false;
								for (var rowctr2:int = 0;rowctr2 < remoteElements.length;rowctr2++) {
									if ((remoteElements.getItemAt(rowctr2) as Array)[positionId] == eventAsJSONObject.rows[rowctr][positionId]) {
										elementAlreadyThere = true;
										if (remoteElementEventIdsToBeDeleted == null) {
											remoteElementEventIdsToBeDeleted = new ArrayList();
										}
										//now remoteelementidstobedeleted is array of tableid, eventid pair, eventid still needs to be changed to rowid
										remoteElementEventIdsToBeDeleted.addItem(new Array(tableNamesAndColumnNames[3][1],(remoteElements.getItemAt(rowctr2) as Array)[positionId]));
										break;
									}
								}
								if (!elementAlreadyThere) {
									remoteElements.addItem(eventAsJSONObject.rows[rowctr]);
									remoteElementIds.addItem([new Number(eventAsJSONObject.rows[rowctr][positionId]),null]);
								}
							}
						}
						nextPageToken = eventAsJSONObject.nextPageToken;
					}
				}
			} 
			
			if (event == null || nextPageToken != null ) {//two reasons to try to fetch data from google
				var urlVariables:URLVariables = new URLVariables();
				urlVariables.sql = createSQLQueryToSelectAll(3);
				if (nextPageToken != null)
					urlVariables.pageToken = nextPageToken;
				
				createAndLoadURLRequest(googleSelectUrl,null,urlVariables,null,getTheMealEvents,true,null);
			} else {
				for (var i:int = 0; i < trackingList.length; i++) {
					if (trackingList.getItemAt(i) is MealEvent) {
						if ((trackingList.getItemAt(i) as MealEvent).timeStamp >= asOfTimeStamp)
							if ((trackingList.getItemAt(i) as MealEvent).lastModifiedTimeStamp >= lastSyncTimeStamp)
								localElements.addItem(trackingList.getItemAt(i));
					}
				}
				//time to start comparing
				//we go through each list, for elements with matching id, any element that is found in the other list with the same modifiedtimestamp is removed from both lists
				try {
					for (var j:int = 0; j < localElements.length; j++) {
						//ModelLocator.getInstance().logString += "1\n";
						//ModelLocator.getInstance().logString += "remoteElements.length = " + remoteElements.length + "\n";
						if (localElements.getItemAt(j) is MealEvent) {
							for (var k:int = 0; k < remoteElements.length; k++) {
								//ModelLocator.getInstance().logString += "2"  + "\n";
								if ((remoteElements.getItemAt(k) as Array)[positionId] == (localElements.getItemAt(j) as MealEvent).eventid) {
									//ModelLocator.getInstance().logString += "3" + "\n";
									
									//got a matching element, let's see if we need to remove it from both lists
									if (new Number((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]) != (localElements.getItemAt(j) as MealEvent).lastModifiedTimeStamp) {
										//ModelLocator.getInstance().logString += "4" + "\n";
										//no lastmodifiedtimestamps are not equal, we need to see which one is most recent
										//but first let's see if the remoteelement has the deleted flag set
										if (((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_deleted)] as String) == "true") {
											//ModelLocator.getInstance().logString += "5" + "\n";
											//its a deleted item remove it from both lists
											remoteElements.removeItemAt(k);
											(localElements.getItemAt(j) as MealEvent).deleteEvent();//delete from local database
											localElementsUpdated = true;//as we deleted one from local database,
											copyTrackingListIfNotDoneYet();
											localElements.removeItemAt(j);//remove also from list used here
											j--;//j is going to be incrased and will point to the next element, as we've just deleted one
											break;
										} else {
											//ModelLocator.getInstance().logString += "6" + "\n";
											if (new Number((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]) < (localElements.getItemAt(j) as MealEvent).lastModifiedTimeStamp) {
												//ModelLocator.getInstance().logString += "7" + "\n";
												remoteElements.removeItemAt(k);
												break;
											} else {
												//ModelLocator.getInstance().logString += "8" + "\n";
												localElements.removeItemAt(j);
												j--;
												break;
											}
										}
									} else {
										//ModelLocator.getInstance().logString += "9" + "\n";
										//yes lastmodifiedtimestamps are equal, so let's remove them from both lists
										remoteElements.removeItemAt(k);
										//remoteElementIds.removeItemAt(k);
										localElements.removeItemAt(j);
										j--;//j is going to be incrased and will point to the next element, as we've just deleted one
										break;//jump out of th einnter for loop
									}
								}
							}
							//j could be -1 now, and there might not be anymore elements inlocalemenets so
							if (j + 1 == localElements.length) {
								//ModelLocator.getInstance().logString += "j + 1 = localElements.length\n";
								break;
							}
						}
					}
				} catch (error:Error) {
					//ModelLocator.getInstance().logString += "exception 1 = " + error.toString() + " stacktrace = " + error.getStackTrace() + "\n";
					syncFinished(false);
				}
				//we've got to start updating
				for (var m:int = 0; m < remoteElements.length; m++) {
					//we have to find the medicinevent in the trackinglist that has the same id
					var l:int=0;
					for (l = 0; l < trackingList.length;l++) {
						if (trackingList.getItemAt(l) is MealEvent) {
							if ((trackingList.getItemAt(l) as MealEvent).eventid == remoteElements.getItemAt(m)[positionId] ) {
								localElementsUpdated = true;
								if ((remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_deleted)] as String) == "true") {
									if (debugMode)
										(trackingList.getItemAt(l) as MealEvent).deleteEvent();
								} else {
									(trackingList.getItemAt(l) as MealEvent).updateMealEvent(
										remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_mealname)],
										remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_comment)],
										remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_insulinratio)],
										remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_correctionfactor)],
										new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]),
										new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_creationtimestamp)]));
									if (debugMode) trace("local element updated, id = " + (trackingList.getItemAt(l) as MealEvent).eventid);
								}
								break;
							}
						}
					}
					if (l == trackingList.length) {
						//it means we didn't find the remotelement in the trackinglist, so we need to create it
						//but only if deleted is false
						if (((remoteElements.getItemAt(m) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_deleted)] as String) == "false") {
							localElementsUpdated = true;
							copyTrackingListIfNotDoneYet();							
							trackingList.addItem(new MealEvent(//in contradiction to medicin/bloodglucose and exerciseevents, I must add new mealevents to the trackinglist, because if i don't, the adding of selectedfooditems would fail because I wouldn't find the mealevent
								remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_mealname)],
								remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_insulinratio)],
								remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_correctionfactor)],
								new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_creationtimestamp)]),
								null,
								remoteElements.getItemAt(m)[positionId],
								remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_comment)],
								new Number(remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]),
								true));
							if (debugMode) trace("local element created, id = " + remoteElements.getItemAt(m)[positionId]);
						}
					}
				}
				remoteElements = new ArrayList();
				getTheSelectedFoodItems(null);
			}
		}
		
		private function getTheSelectedFoodItems(event:Event = null):void {
			var positionId:int;
			var eventAsJSONObject:Object;
			
			if (debugMode)
				trace("start method getTheSelectedItems");
			//start with remoteElements
			//I'm assuming here that the nextpagetoken principle will be used by google, not sure however
			if (event != null) {
				removeEventListeners();
				eventAsJSONObject = JSON.parse(event.target.data as String);
				
				if (eventHasError(event,getTheSelectedFoodItems))
					return;
				else {
					positionId = eventAsJSONObject.columns.indexOf(ColumnName_id);
					
					var elementAlreadyThere:Boolean;
					if (eventAsJSONObject.rows) {
						for (var rowctr:int = 0;rowctr < eventAsJSONObject.rows.length;rowctr++) {
							elementAlreadyThere = false;
							for (var rowctr2:int = 0;rowctr2 < remoteElements.length;rowctr2++) {
								if ((remoteElements.getItemAt(rowctr2) as Array)[positionId] == eventAsJSONObject.rows[rowctr][positionId]) {
									elementAlreadyThere = true;
									if (remoteElementEventIdsToBeDeleted == null) {
										remoteElementEventIdsToBeDeleted = new ArrayList();
									}
									//now remoteelementidstobedeleted is array of tableid, eventid pair, eventid still needs to be changed to rowid
									remoteElementEventIdsToBeDeleted.addItem(new Array(tableNamesAndColumnNames[4][1],(remoteElements.getItemAt(rowctr2) as Array)[positionId]));
									break;
								}
							}
							if (!elementAlreadyThere) {
								remoteElements.addItem(eventAsJSONObject.rows[rowctr]);
								remoteElementIds.addItem([new Number(eventAsJSONObject.rows[rowctr][positionId]),null]);
							}
						}
					}
					nextPageToken = eventAsJSONObject.nextPageToken;
				}
			} 
			
			if (event == null || nextPageToken != null ) {//two reasons to try to fetch data from google
				var urlVariables:URLVariables = new URLVariables();
				urlVariables.sql = createSQLQueryToSelectAll(4);
				if (nextPageToken != null)
					urlVariables.pageToken = nextPageToken;
				createAndLoadURLRequest(googleSelectUrl,null,urlVariables,null,getTheSelectedFoodItems,true,null);
			} else {
				for (var i:int = 0; i < trackingList.length; i++) {
					if (trackingList.getItemAt(i) is MealEvent) {
						if ((trackingList.getItemAt(i) as MealEvent).timeStamp >= asOfTimeStamp) {
							var theMealEvent:MealEvent = trackingList.getItemAt(i) as MealEvent;
							//not checking here for creationtimestamp as with other table elements, but that should not be necessary
							//because a selectedfooditem is always linked to a mealevent, mealevent has already been checked for creationtimestamp, so ..
							for (var selctr:int = 0; selctr < theMealEvent.selectedFoodItems.length; selctr++) {
								if ((theMealEvent.selectedFoodItems.getItemAt(selctr) as SelectedFoodItem).lastModifiedTimestamp >= lastSyncTimeStamp)
									localElements.addItem(theMealEvent.selectedFoodItems.getItemAt(selctr));						
							}
						}
					}
				}
				//time to start comparing
				//we go through each list, for elements with matching id, any element that is found in the other list with the same modifiedtimestamp is removed from both lists
				for (var j:int = 0; j < localElements.length; j++) {
					if (localElements.getItemAt(j) is SelectedFoodItem) {
						for (var k:int = 0; k < remoteElements.length; k++) {
							if ((remoteElements.getItemAt(k) as Array)[positionId] == (localElements.getItemAt(j) as SelectedFoodItem).eventid) {
								//got a matching element, let's see if we need to remove it from both lists
								if (new Number((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]) != (localElements.getItemAt(j) as SelectedFoodItem).lastModifiedTimestamp) {
									//no lastmodifiedtimestamps are not equal, we need to see which one is most recent
									//but first let's see if the remoteelement has the deleted flag set
									if (((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_deleted)] as String) == "true") {
										//its a deleted item remove it from both lists
										remoteElements.removeItemAt(k);
										(localElements.getItemAt(j) as SelectedFoodItem).deleteEvent();//delete from local database
										localElementsUpdated = true;//as we deleted one from local database,
										copyTrackingListIfNotDoneYet();
										localElements.removeItemAt(j);//remove also from list used here
										j--;//j is going to be incrased and will point to the next element, as we've just deleted one
										break;
									} else {
										if (new Number((remoteElements.getItemAt(k) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]) < (localElements.getItemAt(j) as SelectedFoodItem).lastModifiedTimestamp) {
											remoteElements.removeItemAt(k);
											break;
										} else {
											localElements.removeItemAt(j);
											j--;
											break;
										}
									}
								} else {
									//yes lastmodifiedtimestamps are equal, so let's remove them from both lists
									remoteElements.removeItemAt(k);
									localElements.removeItemAt(j);
									j--;//j is going to be incrased and will point to the next element, as we've just deleted one
									break;//jump out of th einnter for loop
								}
							}
						}
						//j could be -1 now, and there might not be anymore elements inlocalemenets so
						if (j + 1 == localElements.length)
							break;
					}
				}
				//we've got to start updating
				for (var m:int = 0; m < remoteElements.length; m++) {
					//we have to find the selectedfooditem in the trackinglist that has the same id
					var l:int=0;
					var selectedFoodItemFound:Boolean = false;
					for (l = 0; l < trackingList.length;l++) {
						if (trackingList.getItemAt(l) is MealEvent) {
							var theMealEvent2:MealEvent = trackingList.getItemAt(l) as MealEvent;
							for (var selctr2:int = 0;selctr2 < theMealEvent2.selectedFoodItems.length; selctr2++) {
								if ((theMealEvent2.selectedFoodItems.getItemAt(selctr2) as SelectedFoodItem).eventid == remoteElements.getItemAt(m)[positionId]) {
									var theSelectedFoodItem:SelectedFoodItem = theMealEvent2.selectedFoodItems.getItemAt(selctr2) as SelectedFoodItem;
									localElementsUpdated = true;
									selectedFoodItemFound = true;
									if ((remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_deleted)] as String) == "true") {
										theSelectedFoodItem.deleteEvent();
									} else {
										theSelectedFoodItem.updateSelectedFoodItem(
											remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_description)],
											new Unit(
												remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unitdescription)],
												remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unitstandardamount)],
												remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unitkcal)],
												remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unitprotein)],
												remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unitcarbs)],
												remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unitfat)]),
											remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)],
											remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_chosenamount)]);
										if (debugMode) trace("local element updated, id = " + theSelectedFoodItem.eventid);
									}
									break;
									//l =  trackingList.length;
								}
							}
						}
						if (selectedFoodItemFound)
							break;
					}
					if (l == trackingList.length) {
						//it means we didn't find the remotelement in the trackinglist, so we need to create it
						//but only if deleted is false
						if (((remoteElements.getItemAt(m) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_deleted)] as String) == "false") {
							//we need to find the mealevent
							for (var lstctr:int = 0; lstctr < trackingList.length; lstctr++) {
								if (trackingList.getItemAt(lstctr) is MealEvent) {
									if ((trackingList.getItemAt(lstctr) as MealEvent).timeStamp >= asOfTimeStamp) {
										if ((trackingList.getItemAt(lstctr) as MealEvent).eventid == remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_mealeventid)]) {
											localElementsUpdated = true;
											(trackingList.getItemAt(lstctr) as MealEvent).addSelectedFoodItem(
												new SelectedFoodItem(
													remoteElements.getItemAt(m)[positionId],
													remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_description)],
													new Unit(
														remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unitdescription)],
														remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unitstandardamount)],
														remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unitkcal)],
														remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unitprotein)],
														remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unitcarbs)],
														remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_unitfat)]
													),
													remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_chosenamount)],
													remoteElements.getItemAt(m)[eventAsJSONObject.columns.indexOf(ColumnName_modifiedtimestamp)]
												),
												null)
										}
									}
								}
							}
						}
					}
				}
				getRowIdsOfRemoteElementsToBeDeleted(null);
			}
		}
		
		private function getRowIdsOfRemoteElementsToBeDeleted(event:Event = null):void {
			if (debugMode)
				trace ("in method getRowIdsOfRemoteElementsToBeDeleted");
			if (event != null) {
				removeEventListeners();
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if (eventHasError(event,getRowIdsOfRemoteElementsToBeDeleted))
					return;
				
				if ((eventAsJSONObject.rows as Array).length > 1) {
					//there seem to be duplicate events on remote site, let's delete one of them
					if (remoteElementRowIdsToBeDeleted == null)
						remoteElementRowIdsToBeDeleted = new ArrayList();
					for (var cntr:int = 1;cntr < (eventAsJSONObject.rows as Array).length;cntr++) {
						remoteElementRowIdsToBeDeleted.addItem(new Array(tableId,eventAsJSONObject.rows[cntr][0]));
					}
				}
			} 
			
			if (remoteElementEventIdsToBeDeleted != null)  {
				if (remoteElementEventIdsToBeDeleted.length > 0) {
					var sqlStatement:String;
					tableId = (remoteElementEventIdsToBeDeleted.getItemAt(0) as Array)[0];
					sqlStatement = "SELECT ROWID FROM " + tableId + " WHERE id = \'" + (remoteElementEventIdsToBeDeleted.getItemAt(0) as Array)[1] + "\'";
					var urlVariables:URLVariables = new URLVariables();
					urlVariables.sql = sqlStatement;
					createAndLoadURLRequest(googleSelectUrl,URLRequestMethod.POST,urlVariables,null,getRowIdsOfRemoteElementsToBeDeleted,true,null);
					remoteElementEventIdsToBeDeleted.removeItemAt(0);
				} else
					getRowIdsOfLocalElements();
			} else 
				getRowIdsOfLocalElements();
		}
		
		
		/**
		 * deletes remote events that are in remoteElementIdsToBeDeleted, the calls synclocalevents 
		 * I think actually there's never going to be any more event, this was added before getrowidsofremotelementstobedeleted, which will delete all double events
		 */
		private function deleteRemoteEvents(event:Event = null):void {
			if (debugMode)
				trace ("in method deleteremoteevents");
			if (remoteElementRowIdsToBeDeleted != null) {
				if (remoteElementRowIdsToBeDeleted.length > 0) {
					var sqlStatement:String ;
					sqlStatement = "DELETE FROM  " + (remoteElementRowIdsToBeDeleted.getItemAt(0) as Array)[0] + " WHERE ROWID = \'" + (remoteElementRowIdsToBeDeleted.getItemAt(0) as Array)[1]  + "\'";
					var urlVariables:URLVariables = new URLVariables();
					urlVariables.sql = sqlStatement;
					createAndLoadURLRequest(googleSelectUrl,URLRequestMethod.POST,urlVariables,null,deleteRemoteEvents,true,null);
					remoteElementRowIdsToBeDeleted.removeItemAt(0);
				} else
					syncLocalEvents();
			} else 
				syncLocalEvents();
		}
		
		/**
		 * we need to get the rowids for all localevents that have a remote copy, we need to do that to be able to update 
		 */
		private function getRowIdsOfLocalElements(event:Event = null):void {
			if (debugMode)
				trace ("in method getrowids");
			//ModelLocator.getInstance().logString += "in method getrowids" + "\n";
			if (event != null) {
				removeEventListeners();
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if (eventHasError(event,getRowIdsOfLocalElements))
					return;
				
				remoteElementIds.getItemAt(indexOfRetrievedRowId)[1] =  new Number(eventAsJSONObject.rows[0][0]);
				if ((eventAsJSONObject.rows as Array).length > 1) {
					//there seem to be duplicate events on remote site, let's delete one of them
					if (remoteElementRowIdsToBeDeleted == null)
						remoteElementRowIdsToBeDeleted = new ArrayList();
					for (var cntr:int = 1;cntr < (eventAsJSONObject.rows as Array).length;cntr++) {
						remoteElementRowIdsToBeDeleted.addItem(new Array(tableId,eventAsJSONObject.rows[cntr][0]));
					}
				}
			} 
			
			var sqlStatement:String = "";
			var j:int;
			for (var i:int = 0;i < localElements.length; i++) {
				if (localElements.getItemAt(i) is MedicinEvent) {//later on we will add exerciseevents, ...
					for (j = 0;j < remoteElementIds.length; j++) {
						if ((localElements.getItemAt(i) as TrackingViewElement).eventid == remoteElementIds.getItemAt(j)[0]) {
							if (!remoteElementIds.getItemAt(j)[1]) {
								tableId = tableNamesAndColumnNames[0][1] ;
								sqlStatement = "SELECT ROWID FROM " + tableId + " WHERE id = \'" + (localElements.getItemAt(i) as TrackingViewElement).eventid + "\'";
								i = localElements.length;
								indexOfRetrievedRowId = j;
							}
							j = remoteElementIds.length;
						}
					}
				}  else if (localElements.getItemAt(i) is BloodGlucoseEvent) {
					for (j = 0;j < remoteElementIds.length; j++) {
						if ((localElements.getItemAt(i) as TrackingViewElement).eventid == remoteElementIds.getItemAt(j)[0]) {
							if (!remoteElementIds.getItemAt(j)[1]) {
								tableId = tableNamesAndColumnNames[1][1] ;
								sqlStatement = "SELECT ROWID FROM " + tableId + " WHERE id = \'" + (localElements.getItemAt(i) as TrackingViewElement).eventid + "\'";
								i = localElements.length;
								indexOfRetrievedRowId = j;
							}
							j = remoteElementIds.length;
						}
					}
				} else if (localElements.getItemAt(i) is ExerciseEvent) {
					for (j = 0;j < remoteElementIds.length; j++) {
						if ((localElements.getItemAt(i) as TrackingViewElement).eventid == remoteElementIds.getItemAt(j)[0]) {
							if (!remoteElementIds.getItemAt(j)[1]) {
								tableId = tableNamesAndColumnNames[2][1] ;
								sqlStatement = "SELECT ROWID FROM " + tableId + " WHERE id = \'" + (localElements.getItemAt(i) as TrackingViewElement).eventid + "\'";
								i = localElements.length;
								indexOfRetrievedRowId = j;
							}
							j = remoteElementIds.length;
						}
					}
				} else if (localElements.getItemAt(i) is MealEvent) {
					for (j = 0;j < remoteElementIds.length; j++) {
						if ((localElements.getItemAt(i) as TrackingViewElement).eventid == remoteElementIds.getItemAt(j)[0]) {
							if (!remoteElementIds.getItemAt(j)[1]) {
								tableId = tableNamesAndColumnNames[3][1] ;
								sqlStatement = "SELECT ROWID FROM " + tableId + " WHERE id = \'" + (localElements.getItemAt(i) as TrackingViewElement).eventid + "\'";
								i = localElements.length;
								indexOfRetrievedRowId = j;
							}
							j = remoteElementIds.length;
						}
					}
				} else if (localElements.getItemAt(i) is SelectedFoodItem) {
					for (j = 0;j < remoteElementIds.length; j++) {
						if ((localElements.getItemAt(i) as SelectedFoodItem).eventid == remoteElementIds.getItemAt(j)[0]) {
							if (!remoteElementIds.getItemAt(j)[1]) {
								tableId = tableNamesAndColumnNames[4][1] ;
								sqlStatement = "SELECT ROWID FROM " + tableId + " WHERE id = \'" + (localElements.getItemAt(i) as SelectedFoodItem).eventid + "\'";
								i = localElements.length;
								indexOfRetrievedRowId = j;
							}
							j = remoteElementIds.length;
						}
					}
				} else {
					//anything else ?
				}
			}
			
			if (sqlStatement.length == 0) {
				deleteRemoteEvents();
			} else {
				var urlVariables:URLVariables = new URLVariables();
				urlVariables.sql = sqlStatement;
				
				createAndLoadURLRequest(googleSelectUrl,null,urlVariables,null,getRowIdsOfLocalElements,true,null);
			}
		}
		
		/**
		 * inserts and updates local events to remote server
		 */
		private function syncLocalEvents(event:Event = null):void {
			if (debugMode)
				trace ("in method synclocalevents");
			if (event != null) {
				removeEventListeners();
				
				if (eventHasError(event,syncLocalEvents))
					return;
			}
			
			if (localElements.length > 0) {
				//start with the medicinevents
				var previousTypeOfEventAlreadyUsed:Boolean = false;
				var sqlStatement:String = "";
				var i:int = 0;
				while (i < localElements.length) {
					//goal is to insert only elements that are not yet found in remoteelements, those will need updates later on iso inserts
					var elementFoundWithSameId:Boolean = false;
					for (var j:int = 0;j < remoteElementIds.length; j++) {
						if ((localElements.getItemAt(i)).eventid == remoteElementIds.getItemAt(j)[0]) {
							elementFoundWithSameId = true;
							j = remoteElementIds.length;
						}
					}
					if (localElements.getItemAt(i) is MedicinEvent) {//later on we will add exerciseevents, ...
						if (!elementFoundWithSameId) {
							previousTypeOfEventAlreadyUsed = true;
							sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "INSERT INTO " + tableNamesAndColumnNames[0][1] + " ";
							sqlStatement += "(id,medicinname,value,creationtimestamp,modifiedtimestamp,deleted,addedtoormodifiedintabletimestamp,comment) VALUES (\'" +
								(localElements.getItemAt(i) as MedicinEvent).eventid.toString() + "\',\'" +
								(localElements.getItemAt(i) as MedicinEvent).medicinName + Database.medicinnamesplitter + (localElements.getItemAt(i) as MedicinEvent).bolustype + Database.medicinnamesplitter + (localElements.getItemAt(i) as MedicinEvent).bolusDurationInMinutes.toString() + "\',\'" +
								(localElements.getItemAt(i) as MedicinEvent).amount.toString() + "\',\'" +
								(localElements.getItemAt(i) as MedicinEvent).timeStamp.toString() + "\',\'" +
								(localElements.getItemAt(i) as MedicinEvent).lastModifiedTimestamp.toString() + "\'," +
								"\'false\'" +
								",\'" +  
								((new Date()).valueOf() - (localElements.getItemAt(i) as MedicinEvent).lastModifiedTimestamp > 10000 
									? 
									(new Date()).valueOf().toString() 
									:
									(localElements.getItemAt(i) as MedicinEvent).lastModifiedTimestamp.toString())
								+ "\',\'" +
								(localElements.getItemAt(i) as MedicinEvent).comment + "\')" ;
							localElements.removeItemAt(i);
							i--;
						}
					}  else if (localElements.getItemAt(i) is BloodGlucoseEvent && !previousTypeOfEventAlreadyUsed) {
						if (!elementFoundWithSameId) {
							previousTypeOfEventAlreadyUsed = true;
							sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "INSERT INTO " + tableNamesAndColumnNames[1][1] + " ";
							sqlStatement += "(id,unit,value,creationtimestamp,modifiedtimestamp,deleted,addedtoormodifiedintabletimestamp,comment) VALUES (\'" +
								(localElements.getItemAt(i) as BloodGlucoseEvent).eventid.toString() + "\',\'" +
								(localElements.getItemAt(i) as BloodGlucoseEvent).unit + "\',\'" +
								(localElements.getItemAt(i) as BloodGlucoseEvent).bloodGlucoseLevel + "\',\'" +
								(localElements.getItemAt(i) as BloodGlucoseEvent).timeStamp.toString() + "\',\'" +
								(localElements.getItemAt(i) as BloodGlucoseEvent).lastModifiedTimestamp.toString() + "\'," +
								"\'false\'" +
								",\'" +  
								((new Date()).valueOf() - (localElements.getItemAt(i) as BloodGlucoseEvent).lastModifiedTimestamp > 10000 
									? 
									(new Date()).valueOf().toString() 
									:
									(localElements.getItemAt(i) as BloodGlucoseEvent).lastModifiedTimestamp.toString())
								+ "\',\'" +
								(localElements.getItemAt(i) as BloodGlucoseEvent).comment + "\')" ;
							localElements.removeItemAt(i);
							i--;
						}
					}  else if (localElements.getItemAt(i) is ExerciseEvent && !previousTypeOfEventAlreadyUsed) {
						if (!elementFoundWithSameId) {
							previousTypeOfEventAlreadyUsed = true;
							sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "INSERT INTO " + tableNamesAndColumnNames[2][1] + " ";
							sqlStatement += "(id,level,creationtimestamp,modifiedtimestamp,deleted,addedtoormodifiedintabletimestamp,comment) VALUES (\'" +
								(localElements.getItemAt(i) as ExerciseEvent).eventid.toString() + "\',\'" +
								(localElements.getItemAt(i) as ExerciseEvent).level + "\',\'" +
								(localElements.getItemAt(i) as ExerciseEvent).timeStamp.toString() + "\',\'" +
								(localElements.getItemAt(i) as ExerciseEvent).lastModifiedTimestamp.toString() + "\'," +
								"\'false\'" +
								",\'" +  
								((new Date()).valueOf() - (localElements.getItemAt(i) as ExerciseEvent).lastModifiedTimestamp > 10000 
									? 
									(new Date()).valueOf().toString() 
									:
									(localElements.getItemAt(i) as ExerciseEvent).lastModifiedTimestamp.toString())
								+ "\',\'" +
								(localElements.getItemAt(i) as ExerciseEvent).comment + "\')" ;
							localElements.removeItemAt(i);
							i--;
						}
					}  else if (localElements.getItemAt(i) is MealEvent && !previousTypeOfEventAlreadyUsed) {
						if (!elementFoundWithSameId) {
							previousTypeOfEventAlreadyUsed = true;
							sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "INSERT INTO " + tableNamesAndColumnNames[3][1] + " ";
							sqlStatement += "(id,mealname,insulinratio,correctionfactor,creationtimestamp,modifiedtimestamp,deleted,addedtoormodifiedintabletimestamp,comment) VALUES (\'" +
								(localElements.getItemAt(i) as MealEvent).eventid.toString() + "\',\'" +
								(localElements.getItemAt(i) as MealEvent).mealName + "\',\'" +
								(localElements.getItemAt(i) as MealEvent).insulinRatio.toString() + "\',\'" +
								(localElements.getItemAt(i) as MealEvent).correctionFactor.toString() + "\',\'" +
								(localElements.getItemAt(i) as MealEvent).timeStamp.toString() + "\',\'" +
								(localElements.getItemAt(i) as MealEvent).lastModifiedTimeStamp.toString() + "\'," +
								"\'false\'" +
								",\'" +  
								((new Date()).valueOf() - (localElements.getItemAt(i) as MealEvent).lastModifiedTimeStamp > 10000 
									? 
									(new Date()).valueOf().toString() 
									:
									(localElements.getItemAt(i) as MealEvent).lastModifiedTimeStamp.toString())
								+ "\',\'" +
								(localElements.getItemAt(i) as MealEvent).comment + "\')" ;
							localElements.removeItemAt(i);
							i--;
						}
					}  else if (localElements.getItemAt(i) is SelectedFoodItem && !previousTypeOfEventAlreadyUsed) {
						if (!elementFoundWithSameId) {
							sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "INSERT INTO " + tableNamesAndColumnNames[4][1] + " ";
							sqlStatement += "(id,description,unitdescription,unitstandardamount,unitkcal,unitprotein,unitcarbs,unitfat,chosenamount,mealeventid,creationtimestamp,modifiedtimestamp,deleted,addedtoormodifiedintabletimestamp) VALUES (\'" +
								(localElements.getItemAt(i) as SelectedFoodItem).eventid.toString() + "\',\'" +
								(localElements.getItemAt(i) as SelectedFoodItem).itemDescription + "\',\'" +
								(localElements.getItemAt(i) as SelectedFoodItem).unit.unitDescription + "\',\'" +
								(localElements.getItemAt(i) as SelectedFoodItem).unit.standardAmount + "\',\'" +
								(localElements.getItemAt(i) as SelectedFoodItem).unit.kcal + "\',\'" +
								(localElements.getItemAt(i) as SelectedFoodItem).unit.protein + "\',\'" +
								(localElements.getItemAt(i) as SelectedFoodItem).unit.carbs + "\',\'" +
								(localElements.getItemAt(i) as SelectedFoodItem).unit.fat + "\',\'" +
								(localElements.getItemAt(i) as SelectedFoodItem).chosenAmount + "\',\'" +
								(localElements.getItemAt(i) as SelectedFoodItem).mealEventId + "\',\'" +
								new Date().valueOf() + "\',\'" +
								(localElements.getItemAt(i) as SelectedFoodItem).lastModifiedTimestamp + "\'," +
								"\'false\'" +
								",\'" +  
								((new Date()).valueOf() - (localElements.getItemAt(i) as SelectedFoodItem).lastModifiedTimestamp > 10000 
									? 
									(new Date()).valueOf().toString() 
									:
									(localElements.getItemAt(i) as SelectedFoodItem).lastModifiedTimestamp.toString())
								+ "\')";
							localElements.removeItemAt(i);
							i--;
						}
					}  else {
						//other kinds of events ?
						//IF SELECTEDITEM THEN SET CREATIONTIMESTAMP TO CURRENT DATE AND TIME
					}
					i++;
				}
				
				//if we haven't found new events, then we need to update all remaining, if any off course
				if (sqlStatement.length == 0) {
					var k:int = 0;
					var l:int;
					var weHaveAlreadyAnUpdate:Boolean = false;//google api only allows one update per statement, so if there's multiple elements to update, we'll have to go through this multiple times
					while (k < localElements.length && !weHaveAlreadyAnUpdate) {
						//goal is to update all remaining events
						if (localElements.getItemAt(k) is MedicinEvent) { //later on we will add exerciseevents, ...
							for (l = 0;l < remoteElementIds.length; l++) {
								if ((localElements.getItemAt(k) as MedicinEvent).eventid == remoteElementIds.getItemAt(l)[0]) {
									weHaveAlreadyAnUpdate = true;
									sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "UPDATE " + tableNamesAndColumnNames[0][1] + " SET ";
									sqlStatement += 
										"id = \'" + (localElements.getItemAt(k) as MedicinEvent).eventid.toString() + "\'," +
										"medicinname = \'" + (localElements.getItemAt(k) as MedicinEvent).medicinName + Database.medicinnamesplitter + (localElements.getItemAt(k) as MedicinEvent).bolustype + Database.medicinnamesplitter + (localElements.getItemAt(k) as MedicinEvent).bolusDurationInMinutes.toString() + "\'," +
										"value = \'" + (localElements.getItemAt(k) as MedicinEvent).amount.toString() + "\'," +
										"creationtimestamp = \'" + (localElements.getItemAt(k) as MedicinEvent).timeStamp.toString() + "\'," +
										"comment = \'" + (localElements.getItemAt(k) as MedicinEvent).comment + "\'," +
										"modifiedtimestamp = \'" + (localElements.getItemAt(k) as MedicinEvent).lastModifiedTimestamp.toString() + "\'," +
										"addedtoormodifiedintabletimestamp = \'" +
										((new Date()).valueOf() - (localElements.getItemAt(k) as MedicinEvent).lastModifiedTimestamp > 10000 
											? 
											(new Date()).valueOf().toString() 
											:
											(localElements.getItemAt(k) as MedicinEvent).lastModifiedTimestamp.toString())
										+ "\'," +
										"deleted = \'false\' WHERE ROWID = \'" +
										remoteElementIds.getItemAt(l)[1] + "\'";
									
									localElements.removeItemAt(k);
									k--;//reducing k because we just removed one element
									
									l = remoteElementIds.length;//it's not necessary to go through the rest of the remotelementids
								}
							}
						}  else if (localElements.getItemAt(k) is BloodGlucoseEvent) { 
							for (l = 0;l < remoteElementIds.length; l++) {
								if ((localElements.getItemAt(k) as BloodGlucoseEvent).eventid == remoteElementIds.getItemAt(l)[0]) {
									weHaveAlreadyAnUpdate = true;
									sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "UPDATE " + tableNamesAndColumnNames[1][1] + " SET ";
									sqlStatement += 
										"id = \'" + (localElements.getItemAt(k) as BloodGlucoseEvent).eventid.toString() + "\'," +
										"unit = \'" + (localElements.getItemAt(k) as BloodGlucoseEvent).unit + "\'," +
										"value = \'" + (localElements.getItemAt(k) as BloodGlucoseEvent).bloodGlucoseLevel + "\'," +
										"creationtimestamp = \'" + (localElements.getItemAt(k) as BloodGlucoseEvent).timeStamp.toString() + "\'," +
										"comment = \'" + (localElements.getItemAt(k) as BloodGlucoseEvent).comment + "\'," +
										"modifiedtimestamp = \'" + (localElements.getItemAt(k) as BloodGlucoseEvent).lastModifiedTimestamp.toString() + "\'," +
										"addedtoormodifiedintabletimestamp = \'" +
										((new Date()).valueOf() - (localElements.getItemAt(k) as BloodGlucoseEvent).lastModifiedTimestamp > 10000 
											? 
											(new Date()).valueOf().toString() 
											:
											(localElements.getItemAt(k) as BloodGlucoseEvent).lastModifiedTimestamp.toString())
										+ "\'," +
										"deleted = \'false\' WHERE ROWID = \'" +
										remoteElementIds.getItemAt(l)[1] + "\'";
									
									localElements.removeItemAt(k);
									k--;//reducing k because we just removed one element
									
									l = remoteElementIds.length;//it's not necessary to go through the rest of the remotelementids
								}
							}
						}  else if (localElements.getItemAt(k) is ExerciseEvent) { 
							for (l = 0;l < remoteElementIds.length; l++) {
								if ((localElements.getItemAt(k) as ExerciseEvent).eventid == remoteElementIds.getItemAt(l)[0]) {
									weHaveAlreadyAnUpdate = true;
									sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "UPDATE " + tableNamesAndColumnNames[2][1] + " SET ";
									sqlStatement += 
										"id = \'" + (localElements.getItemAt(k) as ExerciseEvent).eventid.toString() + "\'," +
										"level = \'" + (localElements.getItemAt(k) as ExerciseEvent).level + "\'," +
										"creationtimestamp = \'" + (localElements.getItemAt(k) as ExerciseEvent).timeStamp.toString() + "\'," +
										"modifiedtimestamp = \'" + (localElements.getItemAt(k) as ExerciseEvent).lastModifiedTimestamp.toString() + "\'," +
										"comment = \'" + (localElements.getItemAt(k) as ExerciseEvent).comment + "\'," +
										"addedtoormodifiedintabletimestamp = \'" +
										((new Date()).valueOf() - (localElements.getItemAt(k) as ExerciseEvent).lastModifiedTimestamp > 10000 
											? 
											(new Date()).valueOf().toString() 
											:
											(localElements.getItemAt(k) as ExerciseEvent).lastModifiedTimestamp.toString())
										+ "\'," +
										"deleted = \'false\' WHERE ROWID = \'" +
										remoteElementIds.getItemAt(l)[1] + "\'";
									
									localElements.removeItemAt(k);
									k--;//reducing k because we just removed one element
									
									l = remoteElementIds.length;//it's not necessary to go through the rest of the remotelementids
								}
							}
						}  else if (localElements.getItemAt(k) is MealEvent) { 
							for (l = 0;l < remoteElementIds.length; l++) {
								if ((localElements.getItemAt(k) as MealEvent).eventid == remoteElementIds.getItemAt(l)[0]) {
									weHaveAlreadyAnUpdate = true;
									sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "UPDATE " + tableNamesAndColumnNames[3][1] + " SET ";
									sqlStatement += 
										"id = \'" + (localElements.getItemAt(k) as MealEvent).eventid.toString() + "\'," +
										"mealname = \'" + (localElements.getItemAt(k) as MealEvent).mealName + "\'," +
										"insulinratio = \'" + (localElements.getItemAt(k) as MealEvent).insulinRatio.toString() + "\'," +
										"correctionfactor = \'" + (localElements.getItemAt(k) as MealEvent).correctionFactor.toString() + "\'," +
										"creationtimestamp = \'" + (localElements.getItemAt(k) as MealEvent).timeStamp.toString() + "\'," +
										"comment = \'" + (localElements.getItemAt(k) as MealEvent).comment + "\'," +
										"modifiedtimestamp = \'" + (localElements.getItemAt(k) as MealEvent).lastModifiedTimeStamp.toString() + "\'," +
										"addedtoormodifiedintabletimestamp = \'" +
										((new Date()).valueOf() - (localElements.getItemAt(k) as MealEvent).lastModifiedTimeStamp > 10000 
											? 
											(new Date()).valueOf().toString() 
											:
											(localElements.getItemAt(k) as MealEvent).lastModifiedTimeStamp.toString())
										+ "\'," +
										"deleted = \'false\' WHERE ROWID = \'" +
										remoteElementIds.getItemAt(l)[1] + "\'";
									
									localElements.removeItemAt(k);
									k--;//reducing k because we just removed one element
									
									l = remoteElementIds.length;//it's not necessary to go through the rest of the remotelementids
								}
							}
						}  else if (localElements.getItemAt(k) is SelectedFoodItem) { 
							for (l = 0;l < remoteElementIds.length; l++) {
								if ((localElements.getItemAt(k) as SelectedFoodItem).eventid == remoteElementIds.getItemAt(l)[0]) {
									weHaveAlreadyAnUpdate = true;
									sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "UPDATE " + tableNamesAndColumnNames[4][1] + " SET ";
									sqlStatement += 
										"id = \'" + (localElements.getItemAt(k) as SelectedFoodItem).eventid.toString() + "\'," +
										"description = \'" + (localElements.getItemAt(k) as SelectedFoodItem).itemDescription + "\'," +
										"unitdescription = \'" + (localElements.getItemAt(k) as SelectedFoodItem).unit.unitDescription + "\'," +
										"unitstandardamount = \'" + (localElements.getItemAt(k) as SelectedFoodItem).unit.standardAmount + "\'," +
										"unitkcal = \'" + (localElements.getItemAt(k) as SelectedFoodItem).unit.kcal + "\'," +
										"unitprotein = \'" + (localElements.getItemAt(k) as SelectedFoodItem).unit.protein + "\'," +
										"unitcarbs = \'" + (localElements.getItemAt(k) as SelectedFoodItem).unit.carbs + "\'," +
										"unitfat = \'" + (localElements.getItemAt(k) as SelectedFoodItem).unit.fat + "\'," +
										"chosenamount = \'" + (localElements.getItemAt(k) as SelectedFoodItem).chosenAmount.toString() + "\'," +
										"mealeventid = \'" + (localElements.getItemAt(k) as SelectedFoodItem).mealEventId.toString() + "\'," +
										//"creationtimestamp = \'" + (localElements.getItemAt(k) as SelectedFoodItem).timeStamp.toString() + "\'," +
										"modifiedtimestamp = \'" + (localElements.getItemAt(k) as SelectedFoodItem).lastModifiedTimestamp.toString() + "\'," +
										"addedtoormodifiedintabletimestamp = \'" +
										((new Date()).valueOf() - (localElements.getItemAt(k) as SelectedFoodItem).lastModifiedTimestamp > 10000 
											? 
											(new Date()).valueOf().toString() 
											:
											(localElements.getItemAt(k) as SelectedFoodItem).lastModifiedTimestamp.toString())
										+ "\'," +
										"deleted = \'false\' WHERE ROWID = \'" +
										remoteElementIds.getItemAt(l)[1] + "\'";
									
									localElements.removeItemAt(k);
									k--;//reducing k because we just removed one element
									
									l = remoteElementIds.length;//it's not necessary to go through the rest of the remotelementids
								}
							}
						}  else {
							//other kinds of events ?
							//IF SELECTEDITEM THEN DONT UPDATE THE CREATIONTIMESTAMP
							
						}
						k++;
					}
				}
				
				if (sqlStatement.length != 0) {
					var request:URLRequest = new URLRequest(googleSelectUrl);
					request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
					request.contentType = "application/x-www-form-urlencoded";
					
					createAndLoadURLRequest(googleSelectUrl,URLRequestMethod.POST,new URLVariables("sql=" + escape(sqlStatement)),null,syncLocalEvents,true,null);
				}
				
			} else {
				//sync other kinds of tables like settings..
				remoteElements = new ArrayList();
				remoteElementIds = new ArrayList();
				localElements = new ArrayList();
				getTheSettings(null);
			}
			//there should not be code here
		}
		
		private function getTheSettings(event:Event = null):void {
			//here remoteelements are all remote settings, since we queried on id >= -86 and < 29
			//we will go through them and any missing settingid will be added in remoteelementids
			//any element in remotelements that needs no update (ie same modifiedtimestamp)  will be removed
			//any element in remotelements that needs local update will be added in localElements and then removed from remotelements
			//we will end up with remotelements that need remote update, localemenets that need local update, remoteelementids that need remote insert
			//localelements will be all local elements that are not in the remotelements
			
			if (debugMode)
				trace("start method getTheSettings");
			
			var positionId:int;
			var eventAsJSONObject:Object;
			
			if (event != null) {
				removeEventListeners();
				eventAsJSONObject = JSON.parse(event.target.data as String);
				
				if (eventHasError(event,getTheSettings))
					return;
				else {
					positionId = eventAsJSONObject.columns.indexOf(ColumnName_id);
					
					if (eventAsJSONObject.rows) {
						for (var rowctr:int = 0;rowctr < eventAsJSONObject.rows.length;rowctr++) {
							remoteElements.addItem(eventAsJSONObject.rows[rowctr]);
						}
					}
					nextPageToken = eventAsJSONObject.nextPageToken;
				}
			} 
			
			if (event == null || nextPageToken != null ) {//two reasons to try to fetch data from google
				var urlVariables:URLVariables = new URLVariables();
				amountofSpaces = (amountofSpaces == 10) ? 0:amountofSpaces + 1;
				var spaces:String = "";
				for (var i:int = 0;i < amountofSpaces;i++)
					spaces +=" ";
				urlVariables.sql = "SELECT * FROM " + spaces +
					tableNamesAndColumnNames[5][1] +
					" WHERE id > " + (new Number(minimSettingCntrToSync -1)).toString() + " AND id < 29";
				if (nextPageToken != null)
					urlVariables.pageToken = nextPageToken;//probably not used
				
				createAndLoadURLRequest(googleSelectUrl,null,urlVariables,null,getTheSettings,true,null);
			} else {
				//so time to start comparing
				//here the remoteelements  need to be interpreted differently than with events
				//but how ... well read the fucking code
				var settingCtr:int;
				for (settingCtr  = minimSettingCntrToSync; settingCtr < 29;settingCtr++) {
					var settingFoundInRemoteElements:Boolean = false;
					//first see if that setting is in the remoteelements
					for (var remoteElementCtr:int = 0;remoteElementCtr < remoteElements.length;remoteElementCtr++) {
						if ((remoteElements.getItemAt(remoteElementCtr) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_id)] == settingCtr)  {
							settingFoundInRemoteElements = true;
							//we found a remote setting with same setting id as settingCtr
							//so let's check the lastmodifiedtimestamp
							if ((remoteElements.getItemAt(remoteElementCtr) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_addedtoormodifiedintabletimestamp)] == Settings.getInstance().getSettingLastModifiedTimeStamp(settingCtr))  {
								remoteElements.removeItemAt(remoteElementCtr);
								remoteElementCtr--;
								break;
							} else  {
								if ((remoteElements.getItemAt(remoteElementCtr) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_addedtoormodifiedintabletimestamp)] < Settings.getInstance().getSettingLastModifiedTimeStamp(settingCtr))  {
									//remote element needs to be updated
									break;
								} else {
									//local element needs to be updated
									localElements.addItem(remoteElements.getItemAt(remoteElementCtr) as Array);
									remoteElements.removeItemAt(remoteElementCtr);
									remoteElementCtr--;
									break;
								}
							}
						}
					}
					if (!settingFoundInRemoteElements)
						remoteElementIds.addItem(settingCtr);
				}
				//we can start with updating the localElements
				for (settingCtr = 0; settingCtr < localElements.length; settingCtr++) {
					Settings.getInstance().
						setSetting(
							(localElements.getItemAt(settingCtr) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_id)],
							(localElements.getItemAt(settingCtr) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_value)],
							(localElements.getItemAt(settingCtr) as Array)[eventAsJSONObject.columns.indexOf(ColumnName_addedtoormodifiedintabletimestamp)]);
				}
				insertNextSetting(null);
			}
		}
		
		/**
		 * take next setting in remoteelementids that need to be inserted remotely
		 */
		private function insertNextSetting(event:Event):void {
			if (debugMode)
				trace ("in method insertNextSetting");
			if (event != null) {
				removeEventListeners();
				
				if (eventHasError(event,insertNextSetting))
					return;
				else  {
					//we assume here that insert was successful, not sure however
					getSettingRowIds(null);
					return;
				}
			}
			
			if (remoteElementIds.length > 0) {
				var sqlStatement:String = "";
				var i:int = 0;
				while (i < remoteElementIds.length) {
					sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "INSERT INTO " + tableNamesAndColumnNames[5][1] + " ";
					sqlStatement += "(id,value,addedtoormodifiedintabletimestamp) VALUES (\'" +
						(remoteElementIds.getItemAt(i) as int) + "\',\'" +
						(Settings.getInstance().getSetting(remoteElementIds.getItemAt(i) as int)) + "\',\'" +
						(Settings.getInstance().getSettingLastModifiedTimeStamp(remoteElementIds.getItemAt(i) as int)) +  "\')";
					i++;
				}
				createAndLoadURLRequest(googleSelectUrl,URLRequestMethod.POST,new URLVariables("sql=" + sqlStatement),null,insertNextSetting,true,null);
			} else  {
				remoteElementIds = new ArrayList(remoteElements.toArray());//this is just to have remoteElementIds as arrayList with the same size as remoteElements
				indexOfRetrievedRowId = 0;
				getSettingRowIds(null);
				return;
			}
		}
		
		private function getSettingRowIds(event:Event = null):void  {
			if (debugMode)
				trace ("in method getSettingRowIds");
			if (event != null) {
				removeEventListeners();
				
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventHasError(event,getSettingRowIds))
					return;
				
				remoteElementIds.setItemAt(new Number(eventAsJSONObject.rows[0][0]),indexOfRetrievedRowId);
				indexOfRetrievedRowId++;
			} 
			
			if (indexOfRetrievedRowId < remoteElements.length)  {
				var sqlStatement:String ;
				sqlStatement = "SELECT ROWID FROM " + tableNamesAndColumnNames[5][1] + " WHERE id = \'" + (remoteElements.getItemAt(indexOfRetrievedRowId) as Array)[0] + "\'";
				
				var urlVariables:URLVariables = new URLVariables();
				urlVariables.sql = sqlStatement;
				
				createAndLoadURLRequest(googleSelectUrl,null,urlVariables,null,getSettingRowIds,true,null);
			} else   {
				updateRemoteSettings();
			}
		}
		
		private function updateRemoteSettings(event:Event = null):void  {
			if (debugMode)
				trace ("in method updateRemoteSettings");
			if (event != null) {
				removeEventListeners();
				
				if (eventHasError(event,updateRemoteSettings))
					return;
				
				//if successful
				remoteElements.removeItemAt(0);
				remoteElementIds.removeItemAt(0);
			}
			
			if (remoteElements.length > 0)  {
				var sqlStatement:String;
				sqlStatement = "UPDATE " + tableNamesAndColumnNames[5][1] + " SET ";
				sqlStatement += 
					"id = \'" + (remoteElements.getItemAt(0) as Array)[0] + "\'," +
					"value = \'" + Settings.getInstance().getSetting(new Number((remoteElements.getItemAt(0) as Array)[0]) as int) + "\'," +
					"addedtoormodifiedintabletimestamp = \'" + 
					((((new Date()).valueOf() - new Number(Settings.getInstance().getSettingLastModifiedTimeStamp(new Number((remoteElements.getItemAt(0) as Array)[0]) as int))) > 10000)
						?
						(new Date()).valueOf().toString() 
						:
						Settings.getInstance().getSettingLastModifiedTimeStamp(new Number((remoteElements.getItemAt(0) as Array)[0]) as int))
					+
					"\' WHERE ROWID = \'" +
					remoteElementIds.getItemAt(0) + "\'";
				
				var urlVariables:URLVariables = new URLVariables();
				urlVariables.sql = sqlStatement;
				
				createAndLoadURLRequest(googleSelectUrl,URLRequestMethod.POST,urlVariables,null,updateRemoteSettings,true,null);
			} else  {
				googleExcelFindFoodTableSpreadSheet(null);
			}
			
		}
		
		private function googleAPICallFailed(event:Event):void {
			if (debugMode) {
				_synchronize_debugString = event.target.data as String;
				this.dispatchEvent(new Event(SYNCHRONIZE_ERROR_OCCURRED));
			}

			removeEventListeners();
			if (debugMode)
				trace("in googleapicall failed : event.target.data = " + event.target.data as String);
			//let's first see if the event.target.data has json
			try {
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				var message:String = eventAsJSONObject.error.message as String;
				if (message == googleError_Invalid_Credentials) {
						secondAttempt = true;
						//get a new access_token
						var request:URLRequest = new URLRequest(googleTokenRefreshUrl);
						request.contentType = "application/x-www-form-urlencoded";
						request.data = new URLVariables(
							"client_id=" + ResourceManager.getInstance().getString('client_secret','client_id') + "&" +
							"client_secret=" + ResourceManager.getInstance().getString('client_secret','client_secret') + "&" +
							"refresh_token=" + Settings.getInstance().getSetting(Settings.SettingsRefreshToken) + "&" + 
							"grant_type=refresh_token");
						request.method = URLRequestMethod.POST;
						loader = new URLLoader();
						loader.addEventListener(Event.COMPLETE,accessTokenRefreshed);
						loader.addEventListener(IOErrorEvent.IO_ERROR,accessTokenRefreshFailed);
						loader.load(request);
						if (debugMode)
							trace("loader : request = " + request.data); 
				} else {
					syncFinished(false);
				}
			} catch (e:SyntaxError) {
				if (event.type == "ioError") {
					syncFinished(false);
				}
			}
		}
		
		private function accessTokenRefreshed(event:Event):void {
			loader.removeEventListener(Event.COMPLETE,accessTokenRefreshed);
			loader.removeEventListener(IOErrorEvent.IO_ERROR,accessTokenRefreshFailed);
			
			secondAttempt = false;
			var temp:Object = JSON.parse(event.target.data as String);
			Settings.getInstance().setSetting(Settings.SettingsAccessToken,temp.access_token);
			
			functionToRecall.call();
		}
		
		private function accessTokenRefreshFailed(event:Event):void {
			try {
				loader.removeEventListener(Event.COMPLETE,accessTokenRefreshed);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,accessTokenRefreshFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventAsJSONObject.error == "invalid_grant") {
					//reset access_token and grant_token, user needs to go back to settingsscreen to reinitialize
					Settings.getInstance().setSetting(Settings.SettingsAccessToken,  "");
					Settings.getInstance().setSetting(Settings.SettingsRefreshToken, "");
					//the show stops
				}
			} catch (e:SyntaxError) {
				//event.taregt.data is not json
				if (event.type == "ioError") {
					//an ioError, forget about it, the show doesn't go on but we reset secondAttempt
					secondAttempt = false;
				}
			}
		}
		
		/**
		 * will create the query string to select all rows with a modifiedtimestamp higher than requested timestamp<br>
		 * index is the index in tableNamesAndColumnNames<br>
		 * returnvalue will be urlencoded
		 */
		private function createSQLQueryToSelectAll(index:int):String {
			var returnValue:String;
			
			//amountofSpaces is a trick to make sure that the query string changes each time, because it seems that with google api,
			//when doing exactly the same query two times, it gives the same result, even if the table itself has changed in between
			//adding some space, changes the query strange, and forces an update
			amountofSpaces = (amountofSpaces == 10) ? 0:amountofSpaces + 1;
			var spaces:String = "";
			for (var i:int = 0;i < amountofSpaces;i++)
				spaces +=" ";
			returnValue = 
				"SELECT * FROM " + spaces +
				tableNamesAndColumnNames[index][1] +
				" WHERE " + ColumnName_addedtoormodifiedintabletimestamp +  ">= '" + lastSyncTimeStamp.toString() + "' AND " +
				"creationtimestamp >= '" + asOfTimeStamp.toString() + "'";
			if (debugMode)
				trace("querystring = " + returnValue);
			return returnValue;
		}
		
		private function deleteRemoteMedicinEvent(event:Event,medicinEvent:MedicinEvent = null):void {
			if (debugMode)
				trace("in method deleteremotemedicinevent");
			if (medicinEvent != null)
				objectToBeDeleted = medicinEvent;
			if (event != null)  {
				removeEventListeners();
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventAsJSONObject.rows) {//if rows doesn't exist then there wasn't a remote element with that eventid
					var sqlStatement:String = "UPDATE " + tableNamesAndColumnNames[0][1] + " SET ";
					sqlStatement += 
						"id = \'" + objectToBeDeleted.eventid.toString() + "\'," +
						"medicinname = \'" + (objectToBeDeleted as MedicinEvent).medicinName + Database.medicinnamesplitter + (objectToBeDeleted as MedicinEvent).bolustype + Database.medicinnamesplitter + (objectToBeDeleted as MedicinEvent).bolusDurationInMinutes.toString() +"\'," + 
						"value = \'" + (objectToBeDeleted as MedicinEvent).amount.toString() + "\'," +
						"creationtimestamp = \'" + (objectToBeDeleted as MedicinEvent).timeStamp.toString() + "\'," +
						"modifiedtimestamp = \'" + (new Date()).valueOf() + "\'," +
						"addedtoormodifiedintabletimestamp = \'" +
						((new Date()).valueOf() - (objectToBeDeleted as MedicinEvent).lastModifiedTimestamp > 10000 
							? 
							(new Date()).valueOf().toString() 
							:
							(objectToBeDeleted as MedicinEvent).lastModifiedTimestamp.toString())
						+ "\'," +
						"deleted = \'true\' WHERE ROWID = \'" +
						eventAsJSONObject.rows[0][0] + "\'";
					
					createAndLoadURLRequest(googleSelectUrl,URLRequestMethod.POST,new URLVariables("sql=" + escape(sqlStatement)),null,deleteRemoteItems,true,null);
					
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);//next time we come into deleteRemoteItems, we won't treat this element anymore
				} else {
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);
					deleteRemoteItems();
				}
			} else {
				if (debugMode)
					trace("start method deleteMedicinEvent");
				
				access_token = Settings.getInstance().getSetting(Settings.SettingsAccessToken);
				
				if (access_token.length == 0 ) {
					//there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize
				} else {
					
					createAndLoadURLRequest(googleSelectUrl,null,
						new URLVariables("sql=" + "SELECT ROWID FROM " + tableNamesAndColumnNames[0][1] + " WHERE id = \'" + medicinEvent.eventid + "\'"),
						null,deleteRemoteMedicinEvent,true,null);
				}
			}
		}
		
		private function deleteRemoteBloodGlucoseEvent(event:Event, bloodglucoseEvent:BloodGlucoseEvent = null):void {
			if (debugMode)
				trace("in method deleteremotebloodglucoseevent");
			if (bloodglucoseEvent != null)
				objectToBeDeleted = bloodglucoseEvent;
			if (event != null)  {
				removeEventListeners();
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventAsJSONObject.rows) {//if rows doesn't exist then there wasn't a remote element with that eventid
					var sqlStatement:String = "UPDATE " + tableNamesAndColumnNames[1][1] + " SET ";
					sqlStatement += 
						"id = \'" + objectToBeDeleted.eventid.toString() + "\'," +
						"unit = \'" + (objectToBeDeleted as BloodGlucoseEvent).unit + "\'," +
						"value = \'" + (objectToBeDeleted as BloodGlucoseEvent).bloodGlucoseLevel + "\'," +
						"creationtimestamp = \'" + (objectToBeDeleted as BloodGlucoseEvent).timeStamp.toString() + "\'," +
						"modifiedtimestamp = \'" + (new Date()).valueOf() + "\'," +
						"addedtoormodifiedintabletimestamp = \'" +
						((new Date()).valueOf() - (objectToBeDeleted as BloodGlucoseEvent).lastModifiedTimestamp > 10000 
							? 
							(new Date()).valueOf().toString() 
							:
							(objectToBeDeleted as BloodGlucoseEvent).lastModifiedTimestamp.toString())
						+ "\'," +
						"deleted = \'true\' WHERE ROWID = \'" +
						eventAsJSONObject.rows[0][0] + "\'";
					
					createAndLoadURLRequest(googleSelectUrl,URLRequestMethod.POST,new URLVariables("sql=" + escape(sqlStatement)),null,deleteRemoteItems,true,null);
					
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);//next time we come into deleteRemoteItems, we won't treat this element anymore
				} else {
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);
					deleteRemoteItems();
				}
			} else {
				if (debugMode)
					trace("start method deleteBloodGlucoseEvent");
				
				access_token = Settings.getInstance().getSetting(Settings.SettingsAccessToken);
				
				if (access_token.length == 0 ) {
					//there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize
				} else {
					createAndLoadURLRequest(
						googleSelectUrl,
						null,
						new URLVariables("sql=" + "SELECT ROWID FROM " + tableNamesAndColumnNames[1][1] + " WHERE id = \'" + bloodglucoseEvent.eventid + "\'"),
						null,
						deleteRemoteBloodGlucoseEvent,
						true,
						null);
				}
			}
		}
		
		private function deleteRemoteExerciseEvent(event:Event, exerciseEvent:ExerciseEvent = null):void {
			if (debugMode)
				trace("in method deleteremoteexerciseevent");
			if (exerciseEvent != null)
				objectToBeDeleted = exerciseEvent;
			if (event != null)  {
				removeEventListeners();
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventAsJSONObject.rows) {//if rows doesn't exist then there wasn't a remote element with that eventid
					var sqlStatement:String = "UPDATE " + tableNamesAndColumnNames[2][1] + " SET ";
					sqlStatement += 
						"id = \'" + objectToBeDeleted.eventid.toString() + "\'," +
						"level = \'" + (objectToBeDeleted as ExerciseEvent).level + "\'," +
						"creationtimestamp = \'" + (objectToBeDeleted as ExerciseEvent).timeStamp.toString() + "\'," +
						"modifiedtimestamp = \'" + (new Date()).valueOf() + "\'," +
						"addedtoormodifiedintabletimestamp = \'" +
						((new Date()).valueOf() - (objectToBeDeleted as ExerciseEvent).lastModifiedTimestamp > 10000 
							? 
							(new Date()).valueOf().toString() 
							:
							(objectToBeDeleted as ExerciseEvent).lastModifiedTimestamp.toString())
						+ "\'," +
						"deleted = \'true\' WHERE ROWID = \'" +
						eventAsJSONObject.rows[0][0] + "\'";
					
					createAndLoadURLRequest(googleSelectUrl,URLRequestMethod.POST,new URLVariables("sql=" + escape(sqlStatement)),null,deleteRemoteItems,true,null);
					
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);//next time we come into deleteRemoteItems, we won't treat this element anymore
				} else {
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);
					deleteRemoteItems();
				}
			} else {
				if (debugMode)
					trace("start method deleteExerciseEvent");
				
				access_token = Settings.getInstance().getSetting(Settings.SettingsAccessToken);
				
				if (access_token.length == 0 ) {
					//there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize
				} else {
					
					createAndLoadURLRequest(googleSelectUrl,null,new URLVariables("sql=" + "SELECT ROWID FROM " + tableNamesAndColumnNames[2][1] + " WHERE id = \'" + exerciseEvent.eventid + "\'"),null,deleteRemoteExerciseEvent,true,null);
				}
			}
		}
		
		private function deleteRemoteMealEvent(event:Event, mealEvent:MealEvent = null):void {
			if (debugMode)
				trace("in method deleteremotemealevent");
			if (mealEvent != null)
				objectToBeDeleted = mealEvent;
			if (event != null)  {
				removeEventListeners();
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventAsJSONObject.rows) {//if rows doesn't exist then there wasn't a remote element with that eventid
					var sqlStatement:String = "UPDATE " + tableNamesAndColumnNames[3][1] + " SET ";
					sqlStatement += 
						"id = \'" + objectToBeDeleted.eventid.toString() + "\'," +
						"mealname = \'" + (objectToBeDeleted as MealEvent).mealName + "\'," +
						"insulinratio = \'" + (objectToBeDeleted as MealEvent).insulinRatio + "\'," +
						"correctionfactor = \'" + (objectToBeDeleted as MealEvent).correctionFactor + "\'," +
						"creationtimestamp = \'" + (objectToBeDeleted as MealEvent).timeStamp.toString() + "\'," +
						"modifiedtimestamp = \'" + (new Date()).valueOf() + "\'," +
						"addedtoormodifiedintabletimestamp = \'" +
						((new Date()).valueOf() - (objectToBeDeleted as MealEvent).lastModifiedTimeStamp > 10000 
							? 
							(new Date()).valueOf().toString() 
							:
							(objectToBeDeleted as MealEvent).lastModifiedTimeStamp.toString())
						+ "\'," +
						"deleted = \'true\' WHERE ROWID = \'" +
						eventAsJSONObject.rows[0][0] + "\'";
					
					createAndLoadURLRequest(googleSelectUrl,URLRequestMethod.POST,new URLVariables("sql=" + escape(sqlStatement)),null,deleteRemoteItems,true,null);
					
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);//next time we come into deleteRemoteItems, we won't treat this element anymore
				} else {
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);
					deleteRemoteItems();
				}
			} else {
				if (debugMode)
					trace("start method deleteRemoteMealEvent");
				
				access_token = Settings.getInstance().getSetting(Settings.SettingsAccessToken);
				
				if (access_token.length == 0 ) {
					//there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize
				} else {
					createAndLoadURLRequest(googleSelectUrl,null,new URLVariables("sql=" + "SELECT ROWID FROM " + tableNamesAndColumnNames[3][1] + " WHERE id = \'" + mealEvent.eventid + "\'"),null,deleteRemoteMealEvent,true,null);
				}
			}
		}
		
		private function deleteRemoteSelectedFoodItem(event:Event, selectedFoodItem:SelectedFoodItem = null):void {
			if (debugMode)
				trace("in method deleteremoteselectedfooditem");
			if (selectedFoodItem != null)
				objectToBeDeleted = selectedFoodItem;
			if (event != null)  {
				removeEventListeners();
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventAsJSONObject.rows) {//if rows doesn't exist then there wasn't a remote element with that eventid
					var selectedItemToBeDeleted:Object = objectToBeDeleted as SelectedFoodItem;
					var sqlStatement:String = "UPDATE " + tableNamesAndColumnNames[4][1] + " SET ";
					sqlStatement += 
						"id = \'" + selectedItemToBeDeleted.eventid.toString() + "\'," +
						"description = \'" + (selectedItemToBeDeleted).itemDescription + "\'," +
						"unitdescription = \'" + (selectedItemToBeDeleted).unit.unitDescription + "\'," +
						"unitstandardamount = \'" + (selectedItemToBeDeleted).unit.standardAmount + "\'," +
						"unitkcal = \'" + (selectedItemToBeDeleted).unit.kcal.toString() + "\'," +
						"unitprotein = \'" + (selectedItemToBeDeleted).unit.protein.toString() + "\'," +
						"unitcarbs = \'" + (selectedItemToBeDeleted).unit.carbs.toString() + "\'," +
						"unitfat = \'" + (selectedItemToBeDeleted).unit.fat.toString() + "\'," +
						"chosenamount = \'" + (selectedItemToBeDeleted).chosenAmount.toString() + "\'," +
						"mealeventid = \'" + (selectedItemToBeDeleted).mealEventId.toString() + "\'," +
						//"creationtimestamp = \'" + (selectedItemToBeDeleted ).timeStamp.toString() + "\'," +
						"modifiedtimestamp = \'" + (new Date()).valueOf() + "\'," +
						"addedtoormodifiedintabletimestamp = \'" +
						((new Date()).valueOf() - (selectedItemToBeDeleted).lastModifiedTimestamp > 10000 
							? 
							(new Date()).valueOf().toString() 
							:
							(selectedItemToBeDeleted).lastModifiedTimestamp.toString())
						+ "\'," +
						"deleted = \'true\' WHERE ROWID = \'" +
						eventAsJSONObject.rows[0][0] + "\'";
					
					
					createAndLoadURLRequest(googleSelectUrl,URLRequestMethod.POST,new URLVariables("sql=" + escape(sqlStatement)),null,deleteRemoteItems,true,null);
					
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);//next time we come into deleteRemoteItems, we won't treat this element anymore
				} else {
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);
					deleteRemoteItems();
				}
			} else {
				if (debugMode)
					trace("start method deleteRemoteSelectedFoodItem");
				
				access_token = Settings.getInstance().getSetting(Settings.SettingsAccessToken);
				
				if (access_token.length == 0 ) {
					//there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize
				} else {
					createAndLoadURLRequest(googleSelectUrl,null,new URLVariables("sql=" + "SELECT ROWID FROM " + tableNamesAndColumnNames[4][1] + " WHERE id = \'" + selectedFoodItem.eventid + "\'"),null,deleteRemoteSelectedFoodItem,true,null);
				}
			}
		}
		
		private function googleExcelInsertLogBookEvents(event:Event = null):void {
			if (syncRunning) {
				insertlogbookeventsWaiting=true;
				return;
			}
			
			if (event != null) {
				removeEventListeners();
			} else  {
			}
			if (debugMode)
				trace("start method googleExcelInsertLogBookEvents");
			this.dispatchEvent(new Event(INSERTING_NEW_EVENTS));
			var dateFormatter:DateTimeFormatter =  new DateTimeFormatter();
			dateFormatter.dateTimePattern = ResourceManager.getInstance().getString('uploadtrackingview','datepattern');
			dateFormatter.useUTC = false;
			dateFormatter.setStyle("locale",Capabilities.language.substr(0,2));
			var timeFormatter:DateTimeFormatter = new DateTimeFormatter();
			timeFormatter.dateTimePattern = ResourceManager.getInstance().getString('uploadtrackingview','timepattern');
			timeFormatter.useUTC = false;
			timeFormatter.setStyle("locale",Capabilities.language.substr(0,2));
			
			for (var trackinglistcntr:int = 0;trackinglistcntr < ModelLocator.getInstance().trackingList.length;trackinglistcntr++) {
				var trackElement:IListElement = ModelLocator.getInstance().trackingList.getItemAt(trackinglistcntr) as IListElement;
				if (trackElement.timeStamp > new Number(Settings.getInstance().getSetting(Settings.SettingLastUploadedEventTimeStamp))) {
					var outputString:String = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
					outputString += '<entry xmlns="http://www.w3.org/2005/Atom\" xmlns:gsx=\"http://schemas.google.com/spreadsheets/2006/extended">\n';
					outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_date],dateFormatter.format(trackElement.timeStamp));
					outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_time],timeFormatter.format(trackElement.timeStamp));
					if (ModelLocator.getInstance().trackingList.getItemAt(trackinglistcntr) is MealEvent) {
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_eventtype],ResourceManager.getInstance().getString('uploadtrackingview','eventnamemeal'));
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_mealtype],(trackElement as MealEvent).mealName);
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_mealcarbamount],(Math.round((trackElement as MealEvent).totalCarbs)).toString());
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_mealinsulinratio],((Math.round((trackElement as MealEvent).insulinRatio*10)/10)).toString().replace('.',','));
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_comment],(trackElement as MealEvent).comment);
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_mealkcalamount],(Math.round((trackElement as MealEvent).totalKilocalories)).toString());
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_mealproteinamount],(Math.round((trackElement as MealEvent).totalProtein)).toString());
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_mealfatamount],(Math.round((trackElement as MealEvent).totalFat)).toString());
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_mealcalculatedinsulin],((Math.round((trackElement as MealEvent).calculatedInsulinAmount*10))/10).toString().replace('.',','));
						var selectedItems:ArrayCollection = (trackElement as MealEvent).selectedFoodItems;
						var selectedItemsString:String = "";
						for (var selecteditemscntr:int = 0;selecteditemscntr < selectedItems.length;selecteditemscntr++) {
							selectedItemsString += (selectedItems.getItemAt(selecteditemscntr) as SelectedFoodItem).chosenAmount + ' ' + (selectedItems.getItemAt(selecteditemscntr) as SelectedFoodItem).unit.unitDescription + ' ' + (selectedItems.getItemAt(selecteditemscntr) as SelectedFoodItem).itemDescription;
							if (selecteditemscntr < selectedItems.length)
								selectedItemsString += "\n";
						}
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_mealselecteditems],selectedItemsString);
					} else if (ModelLocator.getInstance().trackingList.getItemAt(trackinglistcntr) is BloodGlucoseEvent) {
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_eventtype],ResourceManager.getInstance().getString('uploadtrackingview','eventnamebloodglucose'));
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_comment],(trackElement as BloodGlucoseEvent).comment);
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_bloodglucosevalue],((Math.round((trackElement as BloodGlucoseEvent).bloodGlucoseLevel * 10))/10).toString().replace('.',','));
					} else if (ModelLocator.getInstance().trackingList.getItemAt(trackinglistcntr) is ExerciseEvent) {
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_eventtype],ResourceManager.getInstance().getString('uploadtrackingview','eventnameexercise'));
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_comment],(trackElement as ExerciseEvent).comment);
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_exerciselevel],(trackElement as ExerciseEvent).level);
					} else if (ModelLocator.getInstance().trackingList.getItemAt(trackinglistcntr) is MedicinEvent) {
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_eventtype],ResourceManager.getInstance().getString('uploadtrackingview','eventnamemedicin'));
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_comment],(trackElement as MedicinEvent).comment);
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_medicintype],(trackElement as MedicinEvent).medicinName);
						outputString += '    ' + createGSXElement(googleExcelLogBookColumnNames[foodValueNames_Index_medicinvalue],((Math.round((trackElement as MedicinEvent).amount*10))/10).toString().replace('.',','));
					} else {
						//it's a dayline, no need to export
						Settings.getInstance().setSetting(Settings.SettingLastUploadedEventTimeStamp,trackElement.timeStamp.toString());
						googleExcelInsertLogBookEvents();
						break;
					}
					
					outputString += '</entry>\n';
					//if (debugMode)
					//	trace ("outputstring before replacing = " + outputString); 
					outputString = outputString.replace(/\n/g, File.lineEnding);
					//if (debugMode)
					//	trace ("outputstring after replacing = " + outputString); 
					
					createAndLoadURLRequest(googleExcelManageWorkSheetUrl.replace("{key}",helpDiabetesLogBookSpreadSheetKey).replace("{worksheetid}",helpDiabetesLogBookWorkSheetId),
						URLRequestMethod.POST,
						null,
						outputString,
						googleExcelInsertLogBookEvents,
						true,
						"application/atom+xml");
					Settings.getInstance().setSetting(Settings.SettingLastUploadedEventTimeStamp,trackElement.timeStamp.toString());
					break;
				}
			}
			if (trackinglistcntr == ModelLocator.getInstance().trackingList.length) {
				this.dispatchEvent(new Event(EVENTS_UPLOADED_NOW_SYNCING_THE_SETTINGS));
				MyGATracker.getInstance().trackPageview( "LogBookUploaded" );

				startSynchronize(true,true);
			}
		}
		
		private function createGSXElement(tagName:String,contents:String):String {
			return  '<gsx:' + tagName + '><![CDATA[' + contents + ']]></gsx:' + tagName + '> \n';
		}
		
		private function googleExcelInsertFoodItems(event:Event = null):void {
			if (Settings.getInstance().getSetting(Settings.SettingsAllFoodItemsUploadedToGoogleExcel) == "true")  {
				syncFinished(true);
				return;
			}
			
			if (event != null) {
				removeEventListeners();
				//not checking if there's an error in event, if we get here it should mean there wasn't an error - let's hope so
				if (foodItemIdBeingTreated == ModelLocator.getInstance().foodItemList.length - 1) {
					Settings.getInstance().setSetting(Settings.SettingsAllFoodItemsUploadedToGoogleExcel,"true");
					syncFinished(true);
					return;
				} // else we continue
				Settings.getInstance().setSetting(Settings.SettingsNextRowToAddInFoodTable,new Number(foodItemIdBeingTreated + 1).toString());
				
				//let anyone who is interested know that a new item is uploaded
				_uploadFoodDatabaseStatus = foodItemIdBeingTreated + " {outof} " + ModelLocator.getInstance().foodItemList.length  + " {elementsuploaded} ";
				this.dispatchEvent(new Event(NEW_EVENT_UPLOADED));
			} else  {//first time we come here, we need to initialize foodItemIdBeingTreated
				foodItemIdBeingTreated = new Number(Settings.getInstance().getSetting(Settings.SettingsNextRowToAddInFoodTable));
			}
			if (debugMode)
				trace("start method googleExcelInsertFoodItems");
			
			var dispatcher:EventDispatcher = new EventDispatcher();
			var retrievedFoodItem:FoodItem;
			dispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,unitListRetrieved);
			dispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,unitListRetrievelError);
			foodItemIdBeingTreated = new Number(Settings.getInstance().getSetting(Settings.SettingsNextRowToAddInFoodTable));
			Database.getInstance().getUnitList((ModelLocator.getInstance().foodItemList.getItemAt(foodItemIdBeingTreated) as FoodItem) ,dispatcher);
			
			function unitListRetrieved (event:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,unitListRetrieved);
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,unitListRetrievelError);
				
				//retrieved fooditem does not have a valid itemid, meaning it can not be used to manage the database
				//(comment copied from AddFoodItemView, not sure why and what
				retrievedFoodItem = new FoodItem((ModelLocator.getInstance().foodItemList.getItemAt(foodItemIdBeingTreated) as FoodItem).itemDescription,event.data as ArrayCollection,0);
				
				var outputString:String = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
				outputString += '<entry xmlns="http://www.w3.org/2005/Atom\" xmlns:gsx=\"http://schemas.google.com/spreadsheets/2006/extended">\n';
				outputString += '    <gsx:description><![CDATA[' + retrievedFoodItem.itemDescription + ']]></gsx:description>\n';
				for (var unitCtr:int = 0;unitCtr < retrievedFoodItem.getNumberOfUnits() && unitCtr < 5;unitCtr++ ) {
					outputString += '    <gsx:unit' + (unitCtr + 1) + '><![CDATA[' + retrievedFoodItem.getUnit(unitCtr).unitDescription + ']]></gsx:unit' + (unitCtr + 1) + '> \n';
					outputString += '    <gsx:standardamount' + (unitCtr + 1) + '>' + retrievedFoodItem.getUnit(unitCtr).standardAmount + '</gsx:standardamount' + (unitCtr + 1) + '>\n';
					outputString += '    <gsx:kcal' + (unitCtr + 1) + '>' + retrievedFoodItem.getUnit(unitCtr).kcal + '</gsx:kcal' + (unitCtr + 1) +  '>\n';
					outputString += '    <gsx:protein' + (unitCtr + 1) + '>' + retrievedFoodItem.getUnit(unitCtr).protein.toString().replace('.',',') + '</gsx:protein' + (unitCtr + 1) + '>\n';
					outputString += '    <gsx:carbo' + (unitCtr + 1) + '>' + retrievedFoodItem.getUnit(unitCtr).carbs.toString().replace('.',',') + '</gsx:carbo' + (unitCtr + 1) + '>\n';
					outputString += '    <gsx:fat' + (unitCtr + 1) + '>' + retrievedFoodItem.getUnit(unitCtr).fat.toString().replace('.',',') + '</gsx:fat' + (unitCtr + 1) + '>\n';
				}
				outputString += '</entry>\n';
				outputString = outputString.replace(/\n/g, File.lineEnding);
				
				var newOutputString:String = outputString.replace(">-1<","><");
				while (newOutputString != outputString) {
					outputString = newOutputString;
					newOutputString = outputString.replace(">-1<","><");
				}
				
				createAndLoadURLRequest(googleExcelManageWorkSheetUrl.replace("{key}",helpDiabetesFoodTableSpreadSheetKey).replace("{worksheetid}",helpDiabetesFoodTableWorkSheetId),
					URLRequestMethod.POST,
					null,
					outputString,
					googleExcelInsertFoodItems,
					true,
					"application/atom+xml");
			}
			
			function unitListRetrievelError(event:DatabaseEvent):void {
				trace("error in synchronize.as, unitlistretrievalerror, event = " + event.target.toString());
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,unitListRetrieved);
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,unitListRetrievelError);
				syncFinished(true);//stop the sync, sync itself was ok, but not the upload of fooditems
			}
		}
		
		private function googleExcelCreateLogBookHeader(event:Event = null):void  {
			if (syncRunning) {
				createlogbookheaderWaiting=true;
				return;
			}
			
			if (event != null)  {
				removeEventListeners();
				if ((event.target.data as String).search("updated") != -1) {
					Settings.getInstance().setSetting(Settings.SettingsNextColumnToAddInLogBook,(new Number(Settings.getInstance().getSetting(Settings.SettingsNextColumnToAddInLogBook)) + 1).toString());
					//seems insert of cel was successfull
				} else {
				}
			} 
			
			if (debugMode)
				trace("start method googleExcelCreateLogBookHeader");
			
			if (new Number(Settings.getInstance().getSetting(Settings.SettingsNextColumnToAddInLogBook)) == googleExcelLogBookColumnNames.length)  {
				googleExcelInsertLogBookEvents();
			} else {
				this.dispatchEvent(new Event(CREATING_LOGBOOK_HEADERS));
				var nextColumn:int = new Number(Settings.getInstance().getSetting(Settings.SettingsNextColumnToAddInLogBook)) + 1;//index starts at 0, but column number at 1
				var outputString:String = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
				outputString += '<entry xmlns="http://www.w3.org/2005/Atom\" xmlns:gs=\"http://schemas.google.com/spreadsheets/2006">\n';
				outputString += '    <gs:cell row="1" col="' + nextColumn + '" inputValue="' + googleExcelLogBookColumnNames[nextColumn - 1] + '"/>\n';
				outputString += '</entry>\n';
				outputString = outputString.replace(/\n/g, File.lineEnding);
				
				createAndLoadURLRequest(
					googleExcelUpdateCellUrl.replace("{key}",helpDiabetesLogBookSpreadSheetKey).replace("{worksheetid}",helpDiabetesLogBookWorkSheetId),
					URLRequestMethod.POST,
					null,
					outputString,
					googleExcelCreateLogBookHeader,
					false,
					"application/atom+xml");
			}
		}
		
		private function googleExcelCreateFoodTableHeader(event:Event = null):void  {
			if (event != null)  {
				removeEventListeners();
				if ((event.target.data as String).search("updated") != -1) {
					Settings.getInstance().setSetting(Settings.SettingsNextColumnToAddInFoodTable,(new Number(Settings.getInstance().getSetting(Settings.SettingsNextColumnToAddInFoodTable)) + 1).toString());
					//seems insert of cel was successfull
				} else {
					syncFinished(false);
					return;
				}
			} 
						
			if (new Number(Settings.getInstance().getSetting(Settings.SettingsNextColumnToAddInFoodTable)) == googleExcelFoodTableColumnNames.length)  {
				googleExcelInsertFoodItems();
			} else {
				if (debugMode)
					trace("start method googleExcelCreateHeader");
				_uploadFoodDatabaseStatus = ResourceManager.getInstance().getString('synchronizeview','creatingheaders');
				this.dispatchEvent(new Event(NEW_EVENT_UPLOADED));

				var nextColumn:int = new Number(Settings.getInstance().getSetting(Settings.SettingsNextColumnToAddInFoodTable)) + 1;//index starts at 0, but column number at 1
				var outputString:String = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
				outputString += '<entry xmlns="http://www.w3.org/2005/Atom\" xmlns:gs=\"http://schemas.google.com/spreadsheets/2006">\n';
				outputString += '    <gs:cell row="1" col="' + nextColumn + '" inputValue="' + googleExcelFoodTableColumnNames[nextColumn - 1] + '"/>\n';
				outputString += '</entry>\n';
				outputString = outputString.replace(/\n/g, File.lineEnding);
				
				createAndLoadURLRequest(
					googleExcelUpdateCellUrl.replace("{key}",helpDiabetesFoodTableSpreadSheetKey).replace("{worksheetid}",helpDiabetesFoodTableWorkSheetId),
					URLRequestMethod.POST,
					null,
					outputString,
					googleExcelCreateFoodTableHeader,
					true,
					"application/atom+xml");
			}
		}
		
		
		/**
		 * this function will create the logbook on google excel, so it should only be called if it doesn't exist yet<br>
		 */
		private function googleExcelCreateLogBook(event:Event = null):void  {
			if (syncRunning) {
				createlogbookWaiting=true;
				return;
			}
			
			if (event != null)  {
				//SHOULD BE CHECKING HERE WHAT CAN GO WRONG - BECAUSE I SEEM TO ASSUME HERE THAT THE LOGBOOK CREATION WILL ALWAYS BE SUCCESSFUL
				removeEventListeners();
				
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if (eventHasError(event,googleExcelCreateLogBook))
					return;
				else {
					if (eventAsJSONObject.id)  {
						helpDiabetesLogBookSpreadSheetKey = eventAsJSONObject.id;
						googleExcelCreateLogBookWorkSheet();
					} else {
						//something went wrong, syncfinished successfully because sync itself was ok
					}
				}
				
			} else {
				if (debugMode)
					trace("start method googleExcelCreateLoogBook");
				this.dispatchEvent(new Event(CREATING_LOGBOOK_SPREADSHEET));
				var jsonObject:Object = new Object();
				jsonObject.mimeType = "application/vnd.google-apps.spreadsheet";
				jsonObject.title = logBookName;
				
				createAndLoadURLRequest(
					googleDriveFilesUrl,
					URLRequestMethod.POST,
					null,
					JSON.stringify(jsonObject),googleExcelCreateLogBook,
					false,
					"application/json");
			}
		}
		
		
		
		/**
		 * this function will create the foodtable on google excel, so it should only be called if it doesn't exist yet<br>
		 * if excel sheet successfully created, then it will mark this instance of the app as the creator of the foodtable
		 */
		private function googleExcelCreateFoodTable(event:Event = null):void  {
			Settings.getInstance().setSetting(Settings.SettingsAllFoodItemsUploadedToGoogleExcel,"false");
			
			if (event != null)  {
				//SHOULD BE CHECKING HERE WHAT CAN GO WRONG - BECAUSE I SEEM TO ASSUME HERE THAT THE FOODTABLE CREATION WILL ALWAYS BE SUCCESSFUL
				removeEventListeners();
				Settings.getInstance().setSetting(Settings.SettingsIMtheCreateorOfGoogleExcelFoodTable,"true");
				
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if (eventHasError(event,googleExcelCreateFoodTable))
					return;
				else {
					if (eventAsJSONObject.id)  {
						helpDiabetesFoodTableSpreadSheetKey = eventAsJSONObject.id;
						googleExcelCreateFoodTableWorkSheet();
					} else {
						//something went wrong, syncfinished successfully because sync itself was ok
					}
				}
				
			} else {
				_uploadFoodDatabaseStatus = ResourceManager.getInstance().getString('synchronizeview','creatingfoodtablespreadsheet');
				this.dispatchEvent(new Event(NEW_EVENT_UPLOADED));

				if (debugMode)
					trace("start method googleExcelCreateFoodTable");
				
				var jsonObject:Object = new Object();
				jsonObject.mimeType = "application/vnd.google-apps.spreadsheet";
				jsonObject.title = foodtableName;
				
				createAndLoadURLRequest(
					googleDriveFilesUrl,
					URLRequestMethod.POST,
					null,
					JSON.stringify(jsonObject),googleExcelCreateFoodTable,
					true,
					"application/json");
			}
		}
		
		
		/**
		 * this function will create the worksheet in logbook,  on google excel, so it should only be called if it doesn't exist yet<br>
		 */
		private function googleExcelCreateLogBookWorkSheet(event:Event = null):void  {
			if (syncRunning) {
				createlogbookworksheetWaiting=true;
				return;
			}
			
			
			if (event != null)  {
				//ASSUMING HERE THAT EVERHTHING WORKS FINE, BUT THINGS COULD BE GOING WRONG
				removeEventListeners();
				
				//ASSUMING HERE THAT WORKSHEET CREATION WAS SUCCESSFULL, WHICH IS NOT SURE
				var createdWorkSheetAsXML:XML = new XML(event.target.data as String);
				//info about namespaces found on http://userflex.files.wordpress.com/2008/06/getstatuscodeas.pdf and http://userflex.wordpress.com/2008/04/03/xml-ns-e4x/
				var namespaces : Array = createdWorkSheetAsXML.namespaceDeclarations();
				// looks for the  namespaces that i need
				for each (var ns : Namespace in namespaces)
				{
					if (ns.prefix == prefix_default)//there's two other in this kind of xml that google returns : openSearch and gs but I don't need xml objects of that kind
					{
						_namespace_default = ns;
						break;
					}
					if (ns.prefix == prefix_gs)
					{
						_namespace_gs = ns;
						break;
					}
				}
				
				//ASSUMING HERE THAT EVERHTHING WORKS FINE, BUT THINGS COULD BE GOING WRONG
				helpDiabetesLogBookWorkSheetId = createdWorkSheetAsXML.._namespace_default::id;
				var helpdiabetesWorkSheetIdSplitted:Array = helpDiabetesLogBookWorkSheetId.split("/");
				helpDiabetesLogBookWorkSheetId = helpdiabetesWorkSheetIdSplitted[helpdiabetesWorkSheetIdSplitted.length - 1];
				
				if (helpDiabetesLogBookWorkSheetId == "") {
					//we can say here that something went wrong with the creation of the worksheet
					return;
				} else {
					googleExcelCreateLogBookHeader(null);
				}
			} else {
				if (debugMode)
					trace("start method googleExcelCreateLogBookWorkSheet");
				this.dispatchEvent(new Event(CREATING_LOGBOOK_WORKSHEET));
				var outputString:String = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
				outputString += '<entry xmlns="http://www.w3.org/2005/Atom\" xmlns:gs=\"http://schemas.google.com/spreadsheets/2006">\n';
				outputString += '    <title>logbook</title>\n';
				outputString += '        <gs:rowCount>' + 10 + '</gs:rowCount>';
				outputString += '        <gs:colCount>' + googleExcelLogBookColumnNames.length + '</gs:colCount>';
				outputString += '</entry>\n';
				outputString = outputString.replace(/\n/g, File.lineEnding);
				
				createAndLoadURLRequest(
					googleExcelCreateWorkSheetUrl.replace("{key}",helpDiabetesLogBookSpreadSheetKey),
					URLRequestMethod.POST,
					null,
					outputString,
					googleExcelCreateLogBookWorkSheet,
					true,
					"application/atom+xml");
			}
		}
		
		/**
		 * this function will create the worksheet in foodtable,  on google excel, so it should only be called if it doesn't exist yet<br>
		 * it will mark this instance of the app as the creator of the foodtable
		 */
		private function googleExcelCreateFoodTableWorkSheet(event:Event = null):void  {
			Settings.getInstance().setSetting(Settings.SettingsAllFoodItemsUploadedToGoogleExcel,"false");
			
			if (event != null)  {
				//ASSUMING HERE THAT EVERHTHING WORKS FINE, BUT THINGS COULD BE GOING WRONG
				removeEventListeners();
				//Settings.getInstance().setSetting(Settings.SettingsIMtheCreateorOfGoogleExcelFoodTable,"true");
				
				//ASSUMING HERE THAT WORKSHEET CREATION WAS SUCCESSFULL, WHICH IS NOT SURE
				var cratedWorkSheetAsXML:XML = new XML(event.target.data as String);
				//info about namespaces found on http://userflex.files.wordpress.com/2008/06/getstatuscodeas.pdf and http://userflex.wordpress.com/2008/04/03/xml-ns-e4x/
				var namespaces : Array = cratedWorkSheetAsXML.namespaceDeclarations();
				// looks for the  namespaces that i need
				for each (var ns : Namespace in namespaces)
				{
					if (ns.prefix == prefix_default)//there's two other in this kind of xml that google returns : openSearch and gs but I don't need xml objects of that kind
					{
						_namespace_default = ns;
						break;
					}
					if (ns.prefix == prefix_gs)
					{
						_namespace_gs = ns;
						break;
					}
				}
				
				//ASSUMING HERE THAT EVERHTHING WORKS FINE, BUT THINGS COULD BE GOING WRONG
				helpDiabetesFoodTableWorkSheetId = cratedWorkSheetAsXML.._namespace_default::id;
				var helpdiabetesWorkSheetIdSplitted:Array = helpDiabetesFoodTableWorkSheetId.split("/");
				helpDiabetesFoodTableWorkSheetId = helpdiabetesWorkSheetIdSplitted[helpdiabetesWorkSheetIdSplitted.length - 1];
				
				if (helpDiabetesFoodTableWorkSheetId == "") {
					//we can say here that something went wrong with the creation of the worksheet
					//we'll stop but say that sync was successful, because that already ended successfully, it's just the creation of the worksheet that failed
					syncFinished(true);
					return;
				} else {
					googleExcelCreateFoodTableHeader(null);
				}
			} else {
				_uploadFoodDatabaseStatus = ResourceManager.getInstance().getString('synchronizeview','creatingfoodtableworksheet');
				this.dispatchEvent(new Event(NEW_EVENT_UPLOADED));

				if (debugMode)
					trace("start method googleExcelCreateWorkSheet");
				var outputString:String = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
				outputString += '<entry xmlns="http://www.w3.org/2005/Atom\" xmlns:gs=\"http://schemas.google.com/spreadsheets/2006">\n';
				outputString += '    <title>foodtable</title>\n';
				outputString += '        <gs:rowCount>' + ModelLocator.getInstance().foodItemList.length + '</gs:rowCount>';
				outputString += '        <gs:colCount>' + googleExcelFoodTableColumnNames.length + '</gs:colCount>';
				outputString += '</entry>\n';
				outputString = outputString.replace(/\n/g, File.lineEnding);
				
				createAndLoadURLRequest(
					googleExcelCreateWorkSheetUrl.replace("{key}",helpDiabetesFoodTableSpreadSheetKey),
					URLRequestMethod.POST,
					null,
					outputString,
					googleExcelCreateFoodTableWorkSheet,
					true,
					"application/atom+xml");
			}
		}
		
		/**
		 *  deletes "sheet 1" from the foodtable spreadsheet<br>
		 * goal is that this can run in parallel with other calls op google docs, so it will not listen to events
		 */
		private function googleExcelDeleteWorkSheet1():void {
			if (googleExcelDeleteWorkSheetUrl == "")
				return;
			
			if (debugMode)
				trace("start method googleExcelDeleteWorkSheet1");
			createAndLoadURLRequest(googleExcelDeleteWorkSheetUrl,URLRequestMethod.DELETE,null,null,null,false,null);
			googleExcelDeleteWorkSheetUrl = "";
		}
		
		private function googleExcelFindLogBookWorkSheet(event:Event = null):void {
			var weNeedToAddColumns:Boolean = false;//if worksheet already exists, then we will check of all columns are there, if not we'll have to add column "comment", because that's the one that was add later on,
			var workSheetEditUrl:String;
			if (syncRunning) {
				findlogbookworksheetWaiting=true;
				return;
			}
			
			if (event != null)  {
				removeEventListeners();
				var workSheetListAsXML:XML = new XML(event.target.data as String);
				var xmlns : Namespace;
				var namespaces : Array = workSheetListAsXML.namespaceDeclarations();
				for each (var ns : Namespace in namespaces) {
					if (ns.prefix == "") {
						xmlns = ns;
					}
					if (ns.prefix == prefix_gs)
					{
						_namespace_gs = ns;
					}
				}
				helpDiabetesLogBookWorkSheetId = "";
				var indexOfLogbookEntry:int;
				var entryXMLList:XMLList = new XMLList(workSheetListAsXML..xmlns::entry);
				for (var listCounter:int = 0 ; listCounter < entryXMLList.length();listCounter++) {
					if (entryXMLList[listCounter]..xmlns::title == "logbook") {
						helpDiabetesLogBookWorkSheetId = entryXMLList[listCounter]..xmlns::id;
						var helpdiabetesWorkSheetIdSplitted:Array = helpDiabetesLogBookWorkSheetId.split("/");
						helpDiabetesLogBookWorkSheetId = helpdiabetesWorkSheetIdSplitted[helpdiabetesWorkSheetIdSplitted.length - 1];
						if (entryXMLList[listCounter].._namespace_gs::colCount < googleExcelLogBookColumnNames.length)  {
							weNeedToAddColumns = true;
							//to do that we need the editurl
							workSheetEditUrl = getEditURl(new XMLList(entryXMLList[listCounter]..xmlns::link));
							entryXMLList[listCounter].._namespace_gs::colCount =  googleExcelLogBookColumnNames.length;
							indexOfLogbookEntry = listCounter;
						}
					}
					if (entryXMLList[listCounter]..xmlns::title == "Sheet 1") {
						if (entryXMLList.length() > 1) {
							googleExcelDeleteWorkSheetUrl = getEditURl(new XMLList(entryXMLList[listCounter]..xmlns::link));
						}
					}
				}
				if (googleExcelDeleteWorkSheetUrl != "" && entryXMLList.length() > 1)  {
					googleExcelDeleteWorkSheet1();
				}
				if (helpDiabetesLogBookWorkSheetId != null) {
					if (helpDiabetesLogBookWorkSheetId == "") {
						Settings.getInstance().setSetting(Settings.SettingsNextColumnToAddInLogBook,"0");
						Settings.getInstance().setSetting(Settings.SettingLastUploadedEventTimeStamp,"0");
						googleExcelCreateLogBookWorkSheet(null);
						return;
					}
					else {
						if (!weNeedToAddColumns)
							googleExcelCreateLogBookHeader(null);
						else {
							
							googleExcelAddColumnToLogBookWorksheet(null,workSheetEditUrl,entryXMLList[indexOfLogbookEntry].toString());
						}
					}
				} else {
					Settings.getInstance().setSetting(Settings.SettingsNextColumnToAddInLogBook,"0");
					Settings.getInstance().setSetting(Settings.SettingLastUploadedEventTimeStamp,"0");
					googleExcelCreateLogBookWorkSheet(null);
				}
				
			} else {
				if (debugMode)
					trace("start method googleExcelFindLogBookWorkSheet");
				this.dispatchEvent(new Event(SEARCHING_LOGBOOK_WORKSHEET));
				createAndLoadURLRequest(
					googleExcelFindWorkSheetUrl.replace("{key}",helpDiabetesLogBookSpreadSheetKey),
					null,
					null,
					null,
					googleExcelFindLogBookWorkSheet,
					false,
					null);
			}
		}
		
		/**
		 * will extend an existing logbookworksheet so that it has enough columns, in case columns are added to an existing logbook<br>
		 */
		private function googleExcelAddColumnToLogBookWorksheet(event:Event = null, editUrl:String = null,xml:String = null):void  {
			if (event != null)  {
				removeEventListeners();
				googleExcelCreateLogBookHeader(null);//will actuall add the missing columnheaders
			} else {
				if (debugMode)
					trace("start method googleExcelAddColumnToLogBookWorksheet");
				
				createAndLoadURLRequest(
					editUrl,
					URLRequestMethod.PUT,
					null,
					xml,
					googleExcelAddColumnToLogBookWorksheet,
					true,
					"application/atom+xml");
			}
		}
				
		private function googleExcelFindFoodTableWorkSheet(event:Event = null):void {
			if (event != null)  {
				removeEventListeners();
				
				var workSheetListAsXML:XML = new XML(event.target.data as String);
				//info about namespaces found on http://userflex.files.wordpress.com/2008/06/getstatuscodeas.pdf and http://userflex.wordpress.com/2008/04/03/xml-ns-e4x/
				var xmlns : Namespace;
				// namespace declarations defined in the xml
				var namespaces : Array = workSheetListAsXML.namespaceDeclarations();
				// looks for the default namespace, i know that entry is in the default namespace, so that's what i'm looking for
				for each (var ns : Namespace in namespaces) {
					if (ns.prefix == "") {
						xmlns = ns;
						break;
					}
				}
				var entryXMLList:XMLList = new XMLList(workSheetListAsXML..xmlns::entry);
				for (var listCounter:int = 0 ; listCounter < entryXMLList.length();listCounter++)  {
					//var titleXML:XMLList = entryXMLList[listCounter]..xmlns::title;
					if (entryXMLList[listCounter]..xmlns::title == "foodtable") {
						helpDiabetesFoodTableWorkSheetId = entryXMLList[listCounter]..xmlns::id;
						var helpdiabetesWorkSheetIdSplitted:Array = helpDiabetesFoodTableWorkSheetId.split("/");
						helpDiabetesFoodTableWorkSheetId = helpdiabetesWorkSheetIdSplitted[helpdiabetesWorkSheetIdSplitted.length - 1];
					}
					if (entryXMLList[listCounter]..xmlns::title == "Sheet 1") {
						if (entryXMLList.length() > 1) {
							googleExcelDeleteWorkSheetUrl = getEditURl(new XMLList(entryXMLList[listCounter]..xmlns::link));
						}
					}
				}
				if (googleExcelDeleteWorkSheetUrl != "" && entryXMLList.length() > 1)  {
					googleExcelDeleteWorkSheet1();
				}
				
				if (helpDiabetesFoodTableWorkSheetId != null) {
					if (helpDiabetesFoodTableWorkSheetId == "") {
						//we'll have to create the worksheet but it could also be that we have to recreate the worksheet, in which case we reset columns to add to 0
						Settings.getInstance().setSetting(Settings.SettingsNextColumnToAddInFoodTable,"0");
						Settings.getInstance().setSetting(Settings.SettingsNextRowToAddInFoodTable,"0");
						googleExcelCreateFoodTableWorkSheet(null);
						return;
					} else
						googleExcelCreateFoodTableHeader(null);
				} else {
					Settings.getInstance().setSetting(Settings.SettingsNextColumnToAddInFoodTable,"0");
					Settings.getInstance().setSetting(Settings.SettingsNextRowToAddInFoodTable,"0");
					googleExcelCreateFoodTableWorkSheet(null);
				}
				
			} else {
				if (debugMode)
					trace("start method googleExcelFindFoodTableWorkSheet");
				createAndLoadURLRequest(
					googleExcelFindWorkSheetUrl.replace("{key}",helpDiabetesFoodTableSpreadSheetKey),
					null,
					null,
					null,
					googleExcelFindFoodTableWorkSheet,
					true,
					null);
			}
		}
		
		
		/**
		 * will try to find the foodtable spreadsheet in google docs account<br>
		 * if not found then googleExcelCreateFoodTable will be called<br>
		 * if found and if imthecreater, then proceed to findfoodtableworksheet<br>
		 * if found and im not the creator, then syncfinished. 
		 */
		private function googleExcelFindFoodTableSpreadSheet(event:Event = null):void  {
			if (event != null)  {
				removeEventListeners();
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if (eventHasError(event,googleExcelFindFoodTableSpreadSheet))
					return;
				else {
					if (eventAsJSONObject.items)  {
						if (eventAsJSONObject.items.length > 0)  {
							//foodtable found
							if (Settings.getInstance().getSetting(Settings.SettingsIMtheCreateorOfGoogleExcelFoodTable) == "true")  {
								helpDiabetesFoodTableSpreadSheetKey = eventAsJSONObject.items[0].id;
								googleExcelFindFoodTableWorkSheet();
							} else {
								//this instance has not created the foodtable
								syncFinished(true);
							}
						} else {
							googleExcelCreateFoodTable();
							Settings.getInstance().setSetting(Settings.SettingsNextColumnToAddInFoodTable,"0");
							Settings.getInstance().setSetting(Settings.SettingsNextRowToAddInFoodTable,"0");
						}
					} else  {
						googleExcelCreateFoodTable();
						Settings.getInstance().setSetting(Settings.SettingsNextColumnToAddInFoodTable,"0");
						Settings.getInstance().setSetting(Settings.SettingsNextRowToAddInFoodTable,"0");
					}
				}
			} else {
				if (debugMode)
					trace("start method googleExcelFindFoodTableSpreadSheet");
				var urlVariables:URLVariables = new URLVariables();
				urlVariables.q = "title = '" + foodtableName + "'";
				
				createAndLoadURLRequest(
					googleDriveFilesUrl,
					null,
					urlVariables,
					null,
					googleExcelFindFoodTableSpreadSheet,
					true,
					null);
			}
		}
		
		/**
		 * will try to find the logbook spreadsheet in google docs account<br>
		 * if not found then googleExcelCreateLogBook will be called<br>
		 */
		private function googleExcelFindLogBookSpreadSheet(event:Event = null):void  {
			if (syncRunning) {
				this.dispatchEvent(new Event(WAITING_FOR_SYNC_TO_FINISH));
				findlogbookspreadsheetWaiting=true;
				return;
			} 
			
			if (event != null)  {
				removeEventListeners();
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if (eventHasError(event,googleExcelFindLogBookSpreadSheet))
					return;
				else {
					if (eventAsJSONObject.items)  {
						if (eventAsJSONObject.items.length > 0)  {
							helpDiabetesLogBookSpreadSheetKey = eventAsJSONObject.items[0].id;
							googleExcelFindLogBookWorkSheet();
						} else {
							googleExcelCreateLogBook();
							Settings.getInstance().setSetting(Settings.SettingsNextColumnToAddInLogBook,"0");
							Settings.getInstance().setSetting(Settings.SettingLastUploadedEventTimeStamp,"0");
						}
					} else  {
						googleExcelCreateLogBook();
						Settings.getInstance().setSetting(Settings.SettingsNextColumnToAddInLogBook,"0");
						Settings.getInstance().setSetting(Settings.SettingLastUploadedEventTimeStamp,"0");
					}
				}
			} else {
				if (debugMode)
					trace("start method googleExcelFindLogBookSpreadSheet");
				this.dispatchEvent(new Event(SEARCHING_LOGBOOK));
				var urlVariables:URLVariables = new URLVariables();
				urlVariables.q = "title = '" + logBookName + "'";
				
				createAndLoadURLRequest(
					googleDriveFilesUrl,
					null,
					urlVariables,
					null,
					googleExcelFindLogBookSpreadSheet,
					false,
					null);
			}
		}
		
		/**
		 * to call when sync has finished 
		 */
		private function syncFinished(success:Boolean):void {
			
			if (debugMode) {
				_synchronize_debugString = "in syncFinished with success = " + success + "\n" 
					+ "syncRunning = " + syncRunning;
				this.dispatchEvent(new Event(SYNCHRONIZE_ERROR_OCCURRED));
			}

			
			if (!syncRunning)//syncfinished must have been called although sync is not running, not need to process any further
				return;
			
			this.dispatchEvent(new Event(SYNC_FINISHED));
			
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			if (debugMode)
				trace("in syncFinished with success = " + success);
			
			if (success) {
				Settings.getInstance().setSetting(Settings.SettingsLastSyncTimeStamp,currentSyncTimeStamp.toString());
				lastSyncTimeStamp = currentSyncTimeStamp;
			} else
				currentSyncTimeStamp = currentSyncTimeStamp - (secondsBetweenTwoSync * 1000 + 1);
			
			if (localElementsUpdated) {
				localElementsUpdated = false;
				copyTrackingListIfNotDoneYet();//this may be the case, eg when adding remote elements to local database, we don't update the trackinglist, but still elementsupdated = true
				ModelLocator.getInstance().trackingList = new ArrayCollection();
				localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,getAllEventsAndFillUpMealsFinished);
				localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,getAllEventsAndFillUpMealsFinished);//don't see what to do in case of error
				Database.getInstance().getAllEventsAndFillUpMeals(localdispatcher);
			}
			
			if (rerunNecessary) {
				currentSyncTimeStamp = new Date().valueOf();
				asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;
				syncRunning = true;
				rerunNecessary = false;
				synchronize();
			} else {
				syncRunning = false;
				if (findAllSpreadSheetsWaiting) {
					findAllSpreadSheetsWaiting = false;
					googleExcelFindAllSpreadSheets();
				} else if (downloadFoodTableSpreadSheetWaiting) {
					downloadFoodTableSpreadSheetWaiting = false;
					googleExcelDownloadFoodTableSpreadSheet();
				} else if (findAllWorkSheetsInFoodTableSpreadSheetWaiting) {
					findAllWorkSheetsInFoodTableSpreadSheetWaiting = false;
					googleExcelFindAllWorkSheetsInFoodTableSpreadSheet(null,-1);
				} else if (createlogbookheaderWaiting) {
					createlogbookheaderWaiting = false;
					googleExcelCreateLogBookHeader(null);
				} else if (createlogbookWaiting) {
					createlogbookWaiting = false;
					googleExcelCreateLogBook(null);
				} else if (createlogbookworksheetWaiting) {
					createlogbookworksheetWaiting = false;
					googleExcelCreateLogBookWorkSheet(null);
				} else if (findlogbookspreadsheetWaiting) {
					findlogbookspreadsheetWaiting = false;
					googleExcelFindLogBookSpreadSheet(null);
				} else if (findlogbookworksheetWaiting) {
					findlogbookworksheetWaiting = false;
					googleExcelFindLogBookWorkSheet(null);
				} else if (insertlogbookeventsWaiting) {
					insertlogbookeventsWaiting = false;
					googleExcelInsertLogBookEvents(null);
				} 
			}
			
			function getAllEventsAndFillUpMealsFinished(event:Event):void
			{
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT, getAllEventsAndFillUpMealsFinished);
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT, getAllEventsAndFillUpMealsFinished);
				ModelLocator.getInstance().trackingList.refresh();
				
				ModelLocator.getInstance().refreshMeals();
				ModelLocator.getInstance().copyOfTrackingList = ModelLocator.getInstance().trackingList;
			}
		}
		
		public function addObjectToBeDeleted(object:Object):void {
			listOfElementsToBeDeleted.addItem(object);
		}
		
		public function uploadLogBook():void {
			googleExcelFindLogBookSpreadSheet();
		}
		
		/**
		 * checks if there's an error, if yes then <br>
		 * - calls googleAPICallFailed with event as parameter <br>
		 * - sets functionToReCall to functionToRecallIfError<br>
		 * returns true if there's an error, returns false if no error
		 */
		private function eventHasError(event:Event,functionToRecallIfError:Function):Boolean  {
			var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
			if  (eventAsJSONObject.error) {
				if (eventAsJSONObject.error.message == googleError_Invalid_Credentials && !secondAttempt) {
					secondAttempt = true;
					functionToRecall = functionToRecallIfError;
					googleAPICallFailed(event);
					return true;
				} else {
					return true;
				}
			}
			else 
				return false;
		}
		
		/**
		 * cheks if functionToRemoveFromEventListner != null and if not removed from Event.COMPLETE<br>
		 * removes eventlistener googleAPICallFailed from IOErrorEvent.IO_ERROR
		 */
		private function removeEventListeners():void  {
			
			if (functionToRecall != null)
				loader.removeEventListener(Event.COMPLETE,functionToRecall);
			
			loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
		}
		
		/**
		 * creates URL request and loads it<br>
		 * if paramFunctionToRecall != null then <br>
		 * - eventlistener is registered for that function for Event.COMPLETE<br>
		 * - paramFunctionToRecall is assigned to variable functionToRemoveFromEventListener<br>
		 * - paramFunctionToRecall is assigned to variable functionToRecall<br>
		 * if addIOErrorListener then a listener will be added for the event IOErrorEvent.IO_ERROR, with function googleAPICallFailed<br>
		 * if ContentType = null then default ContentType = application/x-www-form-urlencoded<br>
		 * access_token will be added to urlVariables, if urlVariables != null<br>
		 * if requestMethod == null then GET is taken as default value
		 */
		private function createAndLoadURLRequest(url:String,requestMethod:String,urlVariables:URLVariables, data:String, paramFunctionToRecall:Function,addIOErrorListener:Boolean,contentType:String):void {
			var request:URLRequest = new URLRequest(url);
			loader = new URLLoader();
			if (debugMode) {
				trace ("in createAndLoadURLRequest, urlVariable string = " + urlVariables);
			}
			
			//all requestmethods
			if (!urlVariables)  {
				request.requestHeaders.push(new URLRequestHeader("X-JavaScript-User-Agent", "Google APIs Explorer"));
			}
			
			if (!contentType) {
				contentType = "application/x-www-form-urlencoded";
			}
			request.contentType = contentType;
			
			if (!requestMethod)
				requestMethod = URLRequestMethod.GET;
			request.method = requestMethod;
			
			//requestMethod = POST
			if (requestMethod == URLRequestMethod.POST) {
				request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
			} else {
				if (!urlVariables)  {
					request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				} else  {
					urlVariables.access_token = access_token;
				}
			}
			
			if (data != null)
				request.data = data;
			else if (urlVariables != null)
				request.data = urlVariables;
			
			if (paramFunctionToRecall != null) {
				loader.addEventListener(Event.COMPLETE,paramFunctionToRecall);
				functionToRecall = paramFunctionToRecall;
			}
			
			if (addIOErrorListener)
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
			
			loader.load(request);
			if (debugMode)
				trace("loader : url = " + request.url + ", request.data = " + request.data); 
		}
		
		public function googleExcelFindAllSpreadSheets(event:Event = null):void  {
			if (syncRunning) {
				findAllSpreadSheetsWaiting=true;
				return;
			}
			if (Settings.getInstance().getSetting(Settings.SettingsAccessToken) == "")  {
				//should normally not happen because when access_token is blank then option to load foodtable should not even be shown to user
				//but you never know
				_spreadSheetList = new ArrayList();
				this.dispatchEvent(new Event(SPREADSHEET_LIST_RETRIEVED));
				return;
			}
			if (event != null)  {
				removeEventListeners();
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				_spreadSheetList = new ArrayList();
				
				if (eventHasError(event,googleExcelFindAllSpreadSheets)) {
					this.dispatchEvent(new Event(SPREADSHEET_LIST_RETRIEVED));
					return;
				}
				else {
					if (eventAsJSONObject.items)  {
						if (eventAsJSONObject.items.length > 0) {
							//spreadsheets found
							//...application/vnd.google-apps.spreadsheet   eventAsJSONObject.items[0].id;
							for (var itemLength:int = 0;itemLength < eventAsJSONObject.items.length;itemLength++) {
								if (eventAsJSONObject.items[itemLength].mimeType)
									if (eventAsJSONObject.items[itemLength].mimeType == "application/vnd.google-apps.spreadsheet")
										_spreadSheetList.addItem(eventAsJSONObject.items[itemLength]);
							}
							this.dispatchEvent(new Event(SPREADSHEET_LIST_RETRIEVED));
						} else {
							this.dispatchEvent(new Event(SPREADSHEET_LIST_RETRIEVED));
							return;
						}
					} else  {
						this.dispatchEvent(new Event(SPREADSHEET_LIST_RETRIEVED));
						return;
					}
				}
			} else {
				if (debugMode)
					trace("start method googleExcelFindAllSpreadSheets");
				_spreadSheetList = new ArrayList();
				
				createAndLoadURLRequest(
					googleDriveFilesUrl,
					null,
					null,
					null,
					googleExcelFindAllSpreadSheets,
					false,
					null);
			}
		}
		
		/**
		 * gets the list of worksheets in the specified spreadsheet.<br>
		 * spreadSheetIndex points to the spreadsheet in _spreadSheetList<br>
		 * value of spreadSheetIndex - 1 means the value of indexOfSpreadSheetToFind needs to be used iso spreadSheetIndex
		 */
		public function googleExcelFindAllWorkSheetsInFoodTableSpreadSheet(event:Event = null,spreadSheetIndex:Number = -1):void {
			if (spreadSheetIndex != -1)
				indexOfSpreadSheetToFind = spreadSheetIndex;
			if (syncRunning) {
				findAllWorkSheetsInFoodTableSpreadSheetWaiting = true;
				return;
			}
			if (Settings.getInstance().getSetting(Settings.SettingsAccessToken) == "")  {
				_workSheetList = new ArrayList();
				this.dispatchEvent(new Event(WORKSHEETS_IN_FOODTABLE_RETRIEVED));
				return;
			}
			if (event != null)  {
				_workSheetList = new ArrayList();
				removeEventListeners();
				
				var workSheetListAsXML:XML = new XML(event.target.data as String);
				//info about namespaces found on http://userflex.files.wordpress.com/2008/06/getstatuscodeas.pdf and http://userflex.wordpress.com/2008/04/03/xml-ns-e4x/
				var cratedWorkSheetAsXML:XML = new XML(event.target.data as String);
				var namespaces : Array = cratedWorkSheetAsXML.namespaceDeclarations();
				// looks for the  namespaces that i need
				for each (var ns : Namespace in namespaces)
				{
					if (ns.prefix == prefix_default)//there's two other in this kind of xml that google returns : openSearch and gs but I don't need xml objects of that kind
					{
						_namespace_default = ns;
						break;
					}
					if (ns.prefix == prefix_gs)
					{
						_namespace_gs = ns;
						break;
					}
				}
				
				
				var entryXMLList:XMLList = new XMLList(workSheetListAsXML.._namespace_default::entry);
				
				for (var listCounter:int = 0; listCounter < entryXMLList.length(); listCounter++)  {
					_workSheetList.addItem(entryXMLList[listCounter]);
				}
				
				this.dispatchEvent(new Event(WORKSHEETS_IN_FOODTABLE_RETRIEVED));
			} else {
				if (debugMode)
					trace("start method googleExcelFindAllWorkSheetsInFoodTableSpreadSheet");
				_workSheetList = new ArrayList();
				
				createAndLoadURLRequest(
					googleExcelFindWorkSheetUrl.replace("{key}",spreadSheetList.getItemAt(indexOfSpreadSheetToFind).id),
					null,
					null,
					null,
					googleExcelFindAllWorkSheetsInFoodTableSpreadSheet,
					false,
					null);
			}
			
		}
		
		/**
		 * initiatiates foodtable spreadsheet download from googleaccounts<br>
		 *  dispatcher is used for dispatching failure notifications, it will dispatch DatabaseEvent, not logic because the errors will have nothing to do with database or database.as, but who cares .. 
		 */
		public function googleExcelDownloadFoodTableSpreadSheet(event:Event = null,spreadSheetIndex:Number = -1,workSheetIndex:Number = -1,dispatcher:EventDispatcher = null):void  {
			_foodtable = null;
			if (syncRunning) {
				downloadFoodTableSpreadSheetWaiting = true;
				return;
			}
			
			if (Settings.getInstance().getSetting(Settings.SettingsAccessToken) == "")  {
				//should normally not happen because when access_token is blank then option to load foodtable should not even be shown to user
				//but you never know
				this.dispatchEvent(new Event(FOODTABLE_DOWNLOADED));
				return;
			}
			if (event != null)  {
				removeEventListeners();
				
				if (eventHasError(event,googleExcelDownloadFoodTableSpreadSheet)) {
					this.dispatchEvent(new Event(FOODTABLE_DOWNLOADED));
					return;
				}
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventAsJSONObject.feed.entry.length == 0) {dispatchFunction("The foodtable is empty.");return;}
				
				var entryCtr:int = 0;
				while (entryCtr < eventAsJSONObject.feed.entry.length && eventAsJSONObject.feed.entry[entryCtr].gs$cell.row == 1) 
					entryCtr++;//ignore the first row because these are the column names
				
				var foodItemListArray:ArrayCollection  = new ArrayCollection();			
				while (entryCtr < eventAsJSONObject.feed.entry.length) {
					var row:int = eventAsJSONObject.feed.entry[entryCtr].gs$cell.row;
					var fooditem:XML = <fooditem/>;
					fooditem.description = eventAsJSONObject.feed.entry[entryCtr].content.$t;
					if (fooditem.description == "")
						{dispatchFunction(ResourceManager.getInstance().getString('synchronizeview','fooditemdescriptioncannotbeempty'),row,unitlist.length + 1);return;}
					var unitlist:XML = <unitlist/>;
					var unit:XML = null;
					entryCtr++;
					while (entryCtr < eventAsJSONObject.feed.entry.length && eventAsJSONObject.feed.entry[entryCtr].gs$cell.row == row) {
						if ((eventAsJSONObject.feed.entry[entryCtr].gs$cell.col - 2 ) % 6 == 0) {//the column has a unitname
							if (unit != null)
								unitlist.appendChild(unit);
							unit = <unit/>;
							unit.description = eventAsJSONObject.feed.entry[entryCtr].gs$cell.$t;
							entryCtr++;
						} else  {
							if (unit ==  null) {dispatchFunction(ResourceManager.getInstance().getString('synchronizeview','unitmusthaveaname'),row,unitlist.length + 1);return;}
							unit.appendChild(
								(new XML("<"+foodValueNames[(eventAsJSONObject.feed.entry[entryCtr].gs$cell.col - 2 ) % 6 - 1]+"/>"))
								.appendChild(eventAsJSONObject.feed.entry[entryCtr].gs$cell.$t)
							);
							entryCtr++;
						}
					}
					
					unitlist.appendChild(unit);
					fooditem.appendChild(unitlist);

					//////verify unit contents
					//check if mandatory fields exist
					//unit description is already checked in synchronize.as
					for (var unitListCounter:int = 0;unitListCounter < unitlist.unit.length();unitListCounter++) {
						unit = unitlist.unit[unitListCounter];
						
						if (unit.carbs ==  undefined)  {dispatchFunction(ResourceManager.getInstance().getString('synchronizeview','unitmusthaveacarbvalue'),row,unitListCounter + 1);return;}
						if (unit.standardamount ==  undefined)  {dispatchFunction(ResourceManager.getInstance().getString('synchronizeview','unitmusthaveastandardamount'),row,unitListCounter + 1);return;}
						//replace , by . and check if parseable to number
						
						var standardamount:Number;
						var carb:Number;
						var kcal:Number = -1;
						var protein:Number = -1;
						var fat:Number = -1;
						
						if (isNaN(carb = new Number((unit.carbs).toString().replace(",",".")))) {dispatchFunction(ResourceManager.getInstance().getString('synchronizeview','carbvaluemustbenumeric'),row,unitListCounter + 1,unit.carbs.toString());return;}
						if (isNaN(standardamount = new Number((unit.standardamount).toString().replace(",",".")))) {dispatchFunction(ResourceManager.getInstance().getString('synchronizeview','standardamountmustbeinteger'),row,unitListCounter + 1,unit.standardamount.toString());return;}
						if (unit.kcal != undefined) if (isNaN(kcal = new Number((unit.kcal).toString().replace(",",".")))) {dispatchFunction(ResourceManager.getInstance().getString('synchronizeview','kcalvaluemustbeinteger'),row,unitListCounter + 1,unit.kcal.toString());return;}
						if (unit.protein != undefined) if (isNaN(protein = new Number((unit.protein).toString().replace(",",".")))) {dispatchFunction(ResourceManager.getInstance().getString('synchronizeview','proteinvaluemustbenumeric'),row,unitListCounter + 1,unit.protein.toString());return;}
						if (unit.fat != undefined) if (isNaN(fat = new Number((unit.fat).toString().replace(",",".")))) {dispatchFunction(ResourceManager.getInstance().getString('synchronizeview','fatvaluemustbenumeric'),row,unitListCounter + 1,unit.fat.toString());return;}
						
						//check integers if necessary
						if (standardamount % 1 != 0)  {dispatchFunction(ResourceManager.getInstance().getString('synchronizeview','standardamountmustbeinteger'),row,unitListCounter + 1);return}
						if (kcal != -1) if (kcal % 1 != 0)  {dispatchFunction(ResourceManager.getInstance().getString('synchronizeview','kcalvaluemustbeinteger'),row,unitListCounter + 1);return}
						
					}
					//////////
										
					foodItemListArray.addItem(fooditem);
				}
				
				var sortField:SortField = new SortField();
				var sort:Sort = new Sort();
				sortField.name = "description"
				sortField.compareFunction = compareFoodItemDescriptions;
				sort.fields = [sortField];
				foodItemListArray.sort = sort;
				foodItemListArray.refresh();
				
				var fooditemlist:XML = <fooditemlist/>;
				for (var listlength:int = 0;listlength < foodItemListArray.length;listlength++)
					fooditemlist.appendChild(foodItemListArray.getItemAt(listlength));
				
				_foodtable = <foodtable/>;
				
				var datetimeformatter:DateTimeFormatter = new DateTimeFormatter();
				datetimeformatter.dateTimePattern = "yyyyMMddHHmmss";
				_foodtable.timestamp=datetimeformatter.format(new Date());
				_foodtable.source="";
				_foodtable.appendChild(fooditemlist);
				
				this.dispatchEvent(new Event(FOODTABLE_DOWNLOADED));
				
				return;
				
			} else {
				if (debugMode)
					trace("start method googleExcelDownloadFoodTableSpreadSheet");

				MyGATracker.getInstance().trackPageview( "DownLoadFoodTable" );
				
				callingDispatcher =  dispatcher;
				
				if (spreadSheetIndex != -1)
					indexOfSpreadSheetToFind = spreadSheetIndex;
				if (workSheetIndex != -1)
					indexOfWorkSheetToFind = workSheetIndex;
				helpDiabetesFoodTableWorkSheetId = _workSheetList.getItemAt(indexOfWorkSheetToFind).._namespace_default::id;
				var helpdiabetesWorkSheetIdSplitted:Array = helpDiabetesFoodTableWorkSheetId.split("/");
				helpDiabetesFoodTableWorkSheetId = helpdiabetesWorkSheetIdSplitted[helpdiabetesWorkSheetIdSplitted.length - 1];
				
				createAndLoadURLRequest(
					googleExcelUpdateCellUrl.replace("{key}",spreadSheetList.getItemAt(indexOfSpreadSheetToFind).id).replace("{worksheetid}",helpDiabetesFoodTableWorkSheetId),
					null,
					new URLVariables("alt=json"),
					null,
					googleExcelDownloadFoodTableSpreadSheet,
					false,
					null);
			}
			
			function dispatchFunction(message:String, fooditemctr:int,unitcntr:int = 0,found:String=null):void  {
				if (callingDispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					event.data = message + " " + ResourceManager.getInstance().getString('synchronizeview','checkthefoodtable') + fooditemctr ;
					if (unitcntr != 0) event.data += ", " + ResourceManager.getInstance().getString('ownitemview','unit') + " " + unitcntr + ". ";
					if (found != null) event.data +=  ResourceManager.getInstance().getString('synchronizeview','found') + " \"" + found + "\"";
					callingDispatcher.dispatchEvent(event);
				}
			}

			
		}
		
		private function copyTrackingListIfNotDoneYet():void {
			if (!trackingListAlreadyModified) {
				trackingListAlreadyModified = true;
				ModelLocator.getInstance().trackingEventToShow = (ModelLocator.getInstance().infoTrackingList.getItemAt(0) as TrackingViewElement).eventid;
				ModelLocator.getInstance().copyOfTrackingList = ModelLocator.getInstance().infoTrackingList;
			}			
		}
		
		public static function compareFoodItemDescriptions(a:Object,b:Object):int {
			//trace("in compare a = " + (a as XML).description.text() + ", b = " + (b as XML).description.text());
			return ExcelSorting.compareStrings((a as XML).description.text(),(b as XML).description.text());
		}
		
		private function getEditURl(linkListForThisentryXMLList:XMLList):String {
			for (var linkListCounter:int = 0; linkListCounter < linkListForThisentryXMLList.length();linkListCounter++)  {
				if (linkListForThisentryXMLList[linkListCounter].attribute("rel"))  {
					if (linkListForThisentryXMLList[linkListCounter].attribute("rel") == "edit")  {
						return linkListForThisentryXMLList[linkListCounter].attribute("href"); 
					}
				}
			}
			return "";
		}
	}
}


