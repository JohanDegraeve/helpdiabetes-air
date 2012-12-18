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
package utilities
{
	import com.google.analytics.AnalyticsTracker;
	import com.google.analytics.GATracker;
	
	import databaseclasses.BloodGlucoseEvent;
	import databaseclasses.Database;
	import databaseclasses.DatabaseEvent;
	import databaseclasses.ExerciseEvent;
	import databaseclasses.MealEvent;
	import databaseclasses.MedicinEvent;
	import databaseclasses.SelectedFoodItem;
	import databaseclasses.Settings;
	import databaseclasses.Unit;
	
	import flash.data.SQLStatement;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	
	import model.ModelLocator;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.formatters.DateFormatter;
	import mx.resources.ResourceManager;
	import mx.utils.Base64Encoder;
	
	import myComponents.TrackingViewElement;
	
	import spark.components.Application;
	import spark.formatters.DateTimeFormatter;
	
	/**
	 * class with function to synchronize with google docs, and to export tracking history 
	 *
	 */
	public class Synchronize
	{
		[ResourceBundle("analytics")]
		private static var googleRequestTablesUrl:String = "https://www.googleapis.com/fusiontables/v1/tables";
		private static var googleSelectUrl:String = "https://www.googleapis.com/fusiontables/v1/query";
		private static var googleDriveFilesUrl:String = "https://www.googleapis.com/drive/v2/files";
		private static var googleTokenRefreshUrl:String = "https://accounts.google.com/o/oauth2/token";
		/**
		 * replace {key} by the spreadsheet key<br>
		 * replace {worksheetid} by the worksheetid
		 */
		private static var googleExcelInsertRowInFoodTableUrl:String = "https://spreadsheets.google.com/feeds/list/{key}/{worksheetid}/private/full";
		private var googleExcelDeleteWorkSheetUrl:String = "";
//https://spreadsheets.google.com/feeds/spreadsheets/private/full
		
		/**
		 * replace {key} by the spreadsheet key<br>
		 */
		private static var googleExcelFindFoodTableWorkSheetUrl:String = "https://spreadsheets.google.com/feeds/worksheets/{key}/private/full"
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
		
		/**
		 * how many minutes between two synchronisations 
		 */
		private static var secondsBetweenTwoSync:int = 10;
		
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
		 * If  (syncRunning is true and currentSyncTimeStamp > 5 minutes ago) or  (syncRunning is false & (immediateRunNecessary or currentSyncTimeStamp > 5 minutes ago)), then run the sync, reset timestamp of startrun to current time, 
		 * set rerunnecessary to false<br>
		 * <br>
		 * If  (syncRunning is true and currentSyncTimeStamp < 5 minutes ago) don't run, if immediateRunNecessary set rerunNecessary to true; else don't set anything. 
		 */
		private var currentSyncTimeStamp:Number;
		/**
		 * parameter showing of synchronisation is running or not<br>
		 * One of the variables that determines if sync will run immediately when synchronize is called<br>
		 * <br>
		 * immediateRunNecessary is a parameter in the synchronize method<br>
		 * <br>
		 * If  (syncRunning is true and currentSyncTimeStamp > 5 minutes ago) or  (syncRunning is false & (immediateRunNecessary or currentSyncTimeStamp > 5 minutes ago)), then run the sync, reset timestamp of startrun to current time, 
		 * set rerunnecessary to false<br>
		 * <br>
		 * If  (syncRunning is true and currentSyncTimeStamp < 5 minutes ago) don't run, if immediateRunNecessary set rerunNecessary to true; else don't set anything. 
		 */
		private var syncRunning:Boolean;
		/**
		 * parameter that says if sync should restart when finished<br>
		 * One of the variables that determines if sync will run immediately when synchronize is called<br>
		 * <br>
		 * immediateRunNecessary is a parameter in the synchronize method<br>
		 * <br>
		 * If  (syncRunning is true and currentSyncTimeStamp > 5 minutes ago) or  (syncRunning is false & (immediateRunNecessary or currentSyncTimeStamp > 5 minutes ago)), then run the sync, reset timestamp of startrun to current time, 
		 * set rerunnecessary to false<br>
		 * <br>
		 * If  (syncRunning is true and currentSyncTimeStamp < 5 minutes ago) don't run, if immediateRunNecessary set rerunNecessary to true; else don't set anything. 
		 */
		private var rerunNecessary:Boolean;
		
		/**
		 * this is the earliest creationtimestamp of the events that will be taken into account 
		 */
		private var asOfTimeStamp:Number
		
		/**
		 * tablename, tableid and list of columns with columnname and type <br>
		 * tableid "" string means there's no table i known yet
		 */
		private var tableNamesAndColumnNames:Array = [
			[	"HD-MedicinEvent",
				"",	
				[						
					["id","NUMBER"],//the unique identifier
					["medicinname","STRING"],//medicin name
					["value","NUMBER"],//amount of medicin
					["creationtimestamp","NUMBER"],//timestamp that the event was created
					["modifiedtimestamp","NUMBER"],//timestamp that the event was last modified
					["deleted","STRING"],//was the event deleted or not
					["addedtoormodifiedintabletimestamp","NUMBER"]//the timestamp that the row was added to the table
				],
				"MedicinEvents"//description
			],
			[	"HD-BloodglucoseEvent",
				"",	
				[						
					["id","NUMBER"],//the unique identifier
					["unit","STRING"],//unit name
					["value","NUMBER"],//value
					["creationtimestamp","NUMBER"],//timestamp that the event was created
					["modifiedtimestamp","NUMBER"],//timestamp that the event was last modified
					["deleted","STRING"],//was the event deleted or not
					["addedtoormodifiedintabletimestamp","NUMBER"]//the timestamp that the row was added to the table
				],
				"BloodglucoseEvents"//description
			],
			[	"HD-ExerciseEvent",
				"",	
				[						
					["id","NUMBER"],//the unique identifier
					["level","STRING"],//unit name
					["creationtimestamp","NUMBER"],//timestamp that the event was created
					["modifiedtimestamp","NUMBER"],//timestamp that the event was last modified
					["deleted","STRING"],//was the event deleted or not
					["addedtoormodifiedintabletimestamp","NUMBER"]//the timestamp that the row was added to the table
				],
				"ExerciseEvents"//description
			],
			[	"HD-MealEvent",
				"",	
				[						
					["id","NUMBER"],//the unique identifier
					["mealname","STRING"],
					["insulinratio","NUMBER"],
					["correctionfactor","NUMBER"],
					["previousbglevel","NUMBER"],
					["creationtimestamp","NUMBER"],//timestamp that the event was created
					["modifiedtimestamp","NUMBER"],//timestamp that the event was last modified
					["deleted","STRING"],//was the event deleted or not
					["addedtoormodifiedintabletimestamp","NUMBER"]//the timestamp that the row was added to the table
				],
				"MealEvents"//description
			],
			[	"HD-SelectedFoodItem",
				"",	
				[						
					["id","NUMBER"],//the unique identifier
					["description","STRING"],
					["unitdescription","STRING"],
					["unitstandardamount","NUMBER"],
					["unitkcal","NUMBER"],
					["unitprotein","NUMBER"],
					["unitcarbs","NUMBER"],
					["unitfat","NUMBER"],
					["chosenamount","NUMBER"],
					["mealeventid","NUMBER"],
					["creationtimestamp","NUMBER"],//timestamp that the event was created, in case of selectedfooditems, creationtimestamp will not really be usefull
					["modifiedtimestamp","NUMBER"],//timestamp that the event was last modified
					["deleted","STRING"],//was the event deleted or not
					["addedtoormodifiedintabletimestamp","NUMBER"]//the timestamp that the row was added to the table
				],
				"Selected Food Items"//description
			]
		];
		
		private var googleExcelGoodTableColumnNames:Array = [
			"description",
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
		
		/**
		 * name of the spreadsheet used when uploading the foodtable 
		 */
		private static var foodtableName:String = "HelpDiabetesFoodTable";
		
		/**
		 * list of elements (events, selectedfooditems) that need to get deleted=true in remote database 
		 */
		private var listOfElementsToBeDeleted:ArrayList;
		
		/**
		 * list of objects found in local database 
		 */
		private var localElements:ArrayList;
		/**
		 * list of objects found in remote database 
		 */
		private var remoteElements:ArrayList;
		/**
		 * this array will just have all id's of the elements that were found remotely<br><br>
		 * actually each element will be an array with  two numbers, first the eventid, secondly the rowid if already retrieved and found, if not null as second element
		 */
		private var remoteElementIds:ArrayList;
		
		/**
		 * the access_token to use the google api 
		 */
		private var access_token:String;
		
		/**
		 * wil be equal to modellocator.trackinglist, it's just to avoid that I need to type to much 
		 */
		private var trackingList:ArrayCollection;
		
		private var tracker:AnalyticsTracker;
		private var alReadyGATracked:Boolean;
		
		private static var instance:Synchronize = new Synchronize();
		
		private var loader:URLLoader;
		/**when a function tries to access google api, but that fails due to invalid access_token, then the token
		 * should be refreshed, this variable will store the function to retry as soon as token is refreshed
		 */
		private var functionToRecall:Function;
		/**
		 * this will be the event listener to remove
		 */
		private var functionToRemoveFromEventListener:Function;
		
		/**
		 * nextpagetoken received from google while accessing list of tables, .. <br>
		 * null means there's no next page
		 */
		private var nextPageToken:String;
		
		private var indexOfRetrievedRowId:int;
		
		private var amountofSpaces:int;
		
		private static var traceNeeded:Boolean = true;
		
		private var localElementsUpdated:Boolean;
		
		private var objectToBeDeleted:Object;
		
		/**
		 *  to avoid endless loops, see code
		 */
		private var retrievalCounter:int;
		
		private var secondAttempt:Boolean;
		
		private var trackingListAlreadyModified:Boolean;
		
		private var helpDiabetesSpreadSheetKey:String;//key to spreadsheet in google docs that has foodtable
		private var helpDiabetesWorkSheetId:String;//key to worksheet in google docs that has foodtable
		
		/**
		 * constructor not to be used, get an instance with getInstance() 
		 */
		public function Synchronize()
		{
			if (instance != null) {
				throw new Error("Synchronize class can only be accessed through Synchronize.getInstance()");	
			}
			syncRunning = false;
			rerunNecessary = false;
			amountofSpaces = 0;
			alReadyGATracked = false;//only one google analytics tracking per instance
			listOfElementsToBeDeleted = new ArrayList();
			instance = this;
			currentSyncTimeStamp = 0;
		}
		
		public static function getInstance():Synchronize {
			if (instance == null) instance = new Synchronize();
			return instance;
		}
		
		/**
		 * If  (syncRunning is true and currentSyncTimeStamp > 5 minutes ago) or  (syncRunning is false & (immediateRunNecessary or currentSyncTimeStamp > 5 minutes ago)), then run the sync, reset timestamp of startrun to current time, 
		 * set rerunnecessary to false<br>
		 * <br>
		 * If  (syncRunning is true and currentSyncTimeStamp < 5 minutes ago) don't run, if immediateRunNecessary set rerunNecessary to true; else don't set anything.<br>
		 * if tracker is null, then no tracking will be done next time 
		 */
		public function startSynchronize(callingTracker:AnalyticsTracker,immediateRunNecessary:Boolean):void {
			helpDiabetesWorkSheetId = "";//not really necessary to reset it each time to empty string, but you never know it could be that user deletes the foodtable worksheet in between to syncs,
			helpDiabetesSpreadSheetKey = "";//same comment
			
			tracker = callingTracker;
			
			retrievalCounter = 0;
			trackingList = ModelLocator.getInstance().trackingList;
			localElementsUpdated  = false;
			
			
			var timeSinceLastSyncMoreThanXMinutes:Boolean = (new Date().valueOf() - currentSyncTimeStamp) > secondsBetweenTwoSync * 1000;
			if (traceNeeded) {
			}
			if ((syncRunning && (timeSinceLastSyncMoreThanXMinutes))  || (!syncRunning && (immediateRunNecessary || timeSinceLastSyncMoreThanXMinutes))) {
				currentSyncTimeStamp = new Date().valueOf();
				lastSyncTimeStamp = new Number(Settings.getInstance().getSetting(Settings.SettingsLastSyncTimeStamp));
				asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;
				rerunNecessary = false;
				syncRunning = true;
				currentSyncTimeStamp = new Date().valueOf();
				asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;
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
		private function synchronize():void {
			trackingListAlreadyModified = false;
			if (traceNeeded)
				trace("start method synchronize");
			//ModelLocator.getInstance().logString += "start method synchronize"+ "\n";;
			
			//we could be arriving here after a retempt, example, first time failed due to invalid credentials, token refresh occurs, with success, we come back to here
			//first thing to do is to removeeventlisteners
			
			access_token = Settings.getInstance().getSetting(Settings.SettingsAccessToken);
			
			if (access_token.length == 0  ) {
				//there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize
				//ModelLocator.getInstance().logString += "error 1 : there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize"+ "\n";
				syncFinished(false);
			} else {
				if (tracker != null && !alReadyGATracked) {
					tracker.trackPageview( "Synchronize-SyncStarted" );
					alReadyGATracked = true;
				}
				
				//first get all the tables 
				var request:URLRequest = new URLRequest(googleRequestTablesUrl);
				request.contentType = "application/x-www-form-urlencoded";
				var urlVariables:URLVariables = new URLVariables();
				urlVariables.access_token = access_token;
				urlVariables.maxResults = maxResults;
				if (nextPageToken != null)
					urlVariables.pageToken = nextPageToken;
				request.data = urlVariables;
				request.method = URLRequestMethod.GET;
				loader = new URLLoader();
				functionToRecall = synchronize;
				loader.addEventListener(Event.COMPLETE,tablesListRetrieved);
				functionToRemoveFromEventListener = tablesListRetrieved;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded) {
					trace("loader : url = " + request.url);
					trace("loader : request = " + request.data); 
				}
			}
		}
		
		private function tablesListRetrieved(event:Event):void {
			if (traceNeeded)
				trace("start method tablesListRetrieved");
			
			loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
			loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
			var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
			
			if  (eventAsJSONObject.error) {
				if (eventAsJSONObject.error.message == googleError_Invalid_Credentials && !secondAttempt) {
					secondAttempt = true;
					functionToRecall = synchronize;
					functionToRemoveFromEventListener = null;
					googleAPICallFailed(event);
				} else {
					//some other kind of yet unidentified error 
				}
			} else {
				nextPageToken = eventAsJSONObject.nextPageToken;
				if (eventAsJSONObject.items) {
					//there are table names retrieved, let's go through them
					for (var i:int = 0;i < eventAsJSONObject.items.length;i++) {
						//go through each item, see if name matches one in the tablelist, if so store tableid
						for (var j:int = 0;j < tableNamesAndColumnNames.length;j++) {
							if (eventAsJSONObject.items[i].name == tableNamesAndColumnNames[j][0]) {
								if (traceNeeded)
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
		}
		
		private function createMissingTables(event:Event = null): void {
			if (traceNeeded)
				trace("start method createMissingTables");
			//ModelLocator.getInstance().logString += "start method createmissingtables"+ "\n";;
			
			if (event != null) {
				//here we come if actually a table has just been created and an Event.COMPLETE is dispatched to notify the completion.
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if  (eventAsJSONObject.error) {
					if (eventAsJSONObject.error.message == googleError_Invalid_Credentials && !secondAttempt) {
						secondAttempt = true;
						functionToRecall = createMissingTables;
						functionToRemoveFromEventListener = null;
						googleAPICallFailed(event);
					} else {
						//ModelLocator.getInstance().logString += (event.target.data as String) + "\n";
						//some other kind of yet unidentified error 
					}
					return;
				} 
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
					
					var request:URLRequest = new URLRequest(googleRequestTablesUrl);
					request.requestHeaders.push(new URLRequestHeader("Content-Type","application/json"));
					request.requestHeaders.push(new URLRequestHeader("X-JavaScript-User-Agent","Google APIs Explorer"));
					request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
					
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
					var bodyString:String = JSON.stringify(jsonObject);
					request.data = bodyString;
					request.method = URLRequestMethod.POST;
					loader = new URLLoader();
					functionToRecall = createMissingTables;
					loader.addEventListener(Event.COMPLETE,createMissingTables);
					functionToRemoveFromEventListener = createMissingTables;
					loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
					loader.load(request);
					if (traceNeeded)
						trace("loader : request = " + request.data); 
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
		
		private function getTheMedicinEvents(event:Event = null):void {
			var positionId:int;
			var positionMedicinname:int;
			var positionValue:int;
			var positionCreationTimeStamp:int;
			var positionModifiedTimeStamp:int;
			var positionDeleted:int;
			var positionAddedTimeStamp:int;
			
			if (traceNeeded)
				trace("start method getTheMedicinEvents");
			//ModelLocator.getInstance().logString += "start method getthemedicinevents"+ "\n";;
			//start with remoteElements
			//I'm assuming here that the nextpagetoken principle will be used by google, not sure however
			if (event != null) {
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if  (eventAsJSONObject.error) {
					
					if (eventAsJSONObject.error.message == googleError_Invalid_Credentials && !secondAttempt) {
						secondAttempt = true;
						functionToRecall = getTheMedicinEvents;
						functionToRemoveFromEventListener = null;
						googleAPICallFailed(event);
					} else {
						//some other kind of yet unidentified error 
					}
				} else {
					//just to be sure, we need to find the order of the columns in our jsonobject .. boring
					//we might be going several times through this, in case nextPageToken is not null, should give the same result each time.
					var ctr:int;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[0][2][0][0] == eventAsJSONObject.columns[ctr])
							positionId = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[0][2][1][0] == eventAsJSONObject.columns[ctr])
							positionMedicinname = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[0][2][2][0] == eventAsJSONObject.columns[ctr])
							positionValue = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[0][2][3][0] == eventAsJSONObject.columns[ctr])
							positionCreationTimeStamp = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[0][2][4][0] == eventAsJSONObject.columns[ctr])
							positionModifiedTimeStamp = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[0][2][5][0] == eventAsJSONObject.columns[ctr])
							positionDeleted = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[0][2][6][0] == eventAsJSONObject.columns[ctr])
							positionAddedTimeStamp = ctr;
					
					var elementAlreadyThere:Boolean;
					if (eventAsJSONObject.rows) {
						for (var rowctr:int = 0;rowctr < eventAsJSONObject.rows.length;rowctr++) {
							elementAlreadyThere = false;
							for (var rowctr2:int = 0;rowctr2 < remoteElements.length;rowctr2++) {
								if ((remoteElements.getItemAt(rowctr2) as Array)[positionId] == eventAsJSONObject.rows[rowctr][positionId]) {
									elementAlreadyThere = true;
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
				var request:URLRequest = new URLRequest(googleSelectUrl);
				request.contentType = "application/x-www-form-urlencoded";
				var urlVariables:URLVariables = new URLVariables();
				//request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				
				urlVariables.sql = createSQLQueryToSelectAll(0);
				if (nextPageToken != null)
					urlVariables.pageToken = nextPageToken;
				urlVariables.access_token = access_token;
				request.data = urlVariables;
				request.method = URLRequestMethod.GET;
				loader = new URLLoader();
				functionToRecall = getTheMedicinEvents;
				loader.addEventListener(Event.COMPLETE,getTheMedicinEvents);
				functionToRemoveFromEventListener = getTheMedicinEvents;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded)
					trace("get the medicinevents " + " loader : request = " + request.data); 
			} else {
				//get the medicinevents in the trackinglist and store them in localElements.
				//trace("filtering events, asOfTimeStamp = " + asOfTimeStamp + ", lastSyncTimeStamp = " + lastSyncTimeStamp);
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
							if (new Number((remoteElements.getItemAt(k) as Array)[positionModifiedTimeStamp]) != (localElements.getItemAt(j) as MedicinEvent).lastModifiedTimestamp) {
								//no lastmodifiedtimestamps are not equal, we need to see which one is most recent
								//but first let's see if the remoteelement has the deleted flag set
								if (((remoteElements.getItemAt(k) as Array)[positionDeleted] as String) == "true") {
									//its a deleted item remove it from both lists
									remoteElements.removeItemAt(k);
									if (!trackingListAlreadyModified) {
										trackingListAlreadyModified = true;
										ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
									}
									(localElements.getItemAt(j) as MedicinEvent).deleteEvent();//delete from local database
									localElementsUpdated = true;//as we deleted one from local database, 
									localElements.removeItemAt(j);//remove also from list used here
									j--;//j is going to be incrased and will point to the next element, as we've just deleted one
									break;
								} else {
									if (new Number((remoteElements.getItemAt(k) as Array)[positionModifiedTimeStamp]) < (localElements.getItemAt(j) as MedicinEvent).lastModifiedTimestamp) {
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
					//j could be -1 now, and there might not be anymore elements inlocalemenets so
					if (j + 1 == localElements.length)
						break;
				}
				//we've got to start updating
				if (traceNeeded)
					trace("there are " + remoteElements.length + " remote elements to store or update locally");
				for (var m:int = 0; m < remoteElements.length; m++) {
					//we have to find the medicinevent in the trackinglist that has the same id
					var l:int=0;
					for (l = 0; l < trackingList.length;l++) {
						if (trackingList.getItemAt(l) is MedicinEvent) {
							if ((trackingList.getItemAt(l) as MedicinEvent).eventid == remoteElements.getItemAt(m)[positionId] ) {
								localElementsUpdated = true;
								/*if (!trackingListAlreadyModified) {
								trackingListAlreadyModified = true;
								ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
								}*/
								if ((remoteElements.getItemAt(m)[positionDeleted] as String) == "true") {
									(trackingList.getItemAt(l) as MedicinEvent).deleteEvent();
								} else {
									(trackingList.getItemAt(l) as MedicinEvent).updateMedicinEvent(
										remoteElements.getItemAt(m)[positionMedicinname],
										remoteElements.getItemAt(m)[positionValue],
										new Number(remoteElements.getItemAt(m)[positionCreationTimeStamp]),
										new Number(remoteElements.getItemAt(m)[positionModifiedTimeStamp]));
								}
								break;
							}
						}
					}
					if (l == trackingList.length) {
						//it means we didn't find the remotelement in the trackinglist, so we need to create it
						//but only if deleted is false
						if (((remoteElements.getItemAt(m) as Array)[positionDeleted] as String) == "false") {
							localElementsUpdated = true;
							/*if (!trackingListAlreadyModified) {
							trackingListAlreadyModified = true;
							ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
							}*/
							
							/*trackingList.addItem*/(new MedicinEvent(
								remoteElements.getItemAt(m)[positionValue],
								remoteElements.getItemAt(m)[positionMedicinname],
								remoteElements.getItemAt(m)[positionId],
								new Number(remoteElements.getItemAt(m)[positionCreationTimeStamp]),
								new Number(remoteElements.getItemAt(m)[positionModifiedTimeStamp]),
								true));
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
			var positionUnit:int;
			var positionValue:int;
			var positionCreationTimeStamp:int;
			var positionModifiedTimeStamp:int;
			var positionDeleted:int;
			var positionAddedTimeStamp:int;
			
			if (traceNeeded)
				trace("start method getTheBloodGlucoseEvents");
			//ModelLocator.getInstance().logString += "start method getthebloodglucoseevents"+ "\n";
			
			//start with remoteElements
			//I'm assuming here that the nextpagetoken principle will be used by google, not sure however
			if (event != null) {
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if  (eventAsJSONObject.error) {
					
					if (eventAsJSONObject.error.message == googleError_Invalid_Credentials && !secondAttempt) {
						secondAttempt = true;
						functionToRecall = getTheBloodGlucoseEvents;
						functionToRemoveFromEventListener = null;
						googleAPICallFailed(event);
					} else {
						//some other kind of yet unidentified error 
					}
				} else {
					//just to be sure, we need to find the order of the columns in our jsonobject .. boring
					//we might be going several times through this, in case nextPageToken is not null, should give the same result each time.
					var ctr:int;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[1][2][0][0] == eventAsJSONObject.columns[ctr])
							positionId = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[1][2][1][0] == eventAsJSONObject.columns[ctr])
							positionUnit = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[1][2][2][0] == eventAsJSONObject.columns[ctr])
							positionValue = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[1][2][3][0] == eventAsJSONObject.columns[ctr])
							positionCreationTimeStamp = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[1][2][4][0] == eventAsJSONObject.columns[ctr])
							positionModifiedTimeStamp = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[1][2][5][0] == eventAsJSONObject.columns[ctr])
							positionDeleted = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[1][2][6][0] == eventAsJSONObject.columns[ctr])
							positionAddedTimeStamp = ctr;
					
					var elementAlreadyThere:Boolean;
					if (eventAsJSONObject.rows) {
						for (var rowctr:int = 0;rowctr < eventAsJSONObject.rows.length;rowctr++) {
							elementAlreadyThere = false;
							for (var rowctr2:int = 0;rowctr2 < remoteElements.length;rowctr2++) {
								if ((remoteElements.getItemAt(rowctr2) as Array)[positionId] == eventAsJSONObject.rows[rowctr][positionId]) {
									elementAlreadyThere = true;
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
				var request:URLRequest = new URLRequest(googleSelectUrl);
				request.contentType = "application/x-www-form-urlencoded";
				var urlVariables:URLVariables = new URLVariables();
				//request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				
				urlVariables.sql = createSQLQueryToSelectAll(1);
				if (nextPageToken != null)
					urlVariables.pageToken = nextPageToken;
				urlVariables.access_token = access_token;
				request.data = urlVariables;
				request.method = URLRequestMethod.GET;
				loader = new URLLoader();
				functionToRecall = getTheBloodGlucoseEvents;
				loader.addEventListener(Event.COMPLETE,getTheBloodGlucoseEvents);
				functionToRemoveFromEventListener = getTheBloodGlucoseEvents;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded)
					trace("get the bloodglucoseevents , loader : request = " + request.data); 
			} else {
				//get the bloodglucoseevents in the trackinglist and store them in localElements.
				//trace("filtering events, asOfTimeStamp = " + asOfTimeStamp + ", lastSyncTimeStamp = " + lastSyncTimeStamp);
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
								if (new Number((remoteElements.getItemAt(k) as Array)[positionModifiedTimeStamp]) != (localElements.getItemAt(j) as BloodGlucoseEvent).lastModifiedTimestamp) {
									//no lastmodifiedtimestamps are not equal, we need to see which one is most recent
									//but first let's see if the remoteelement has the deleted flag set
									if (((remoteElements.getItemAt(k) as Array)[positionDeleted] as String) == "true") {
										//its a deleted item remove it from both lists
										remoteElements.removeItemAt(k);
										if (!trackingListAlreadyModified) {
											trackingListAlreadyModified = true;
											ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
										}
										(localElements.getItemAt(j) as BloodGlucoseEvent).deleteEvent();//delete from local database
										localElementsUpdated = true;//as we deleted one from local database, 
										localElements.removeItemAt(j);//remove also from list used here
										j--;//j is going to be incrased and will point to the next element, as we've just deleted one
										break;
									} else {
										if (new Number((remoteElements.getItemAt(k) as Array)[positionModifiedTimeStamp]) < (localElements.getItemAt(j) as BloodGlucoseEvent).lastModifiedTimestamp) {
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
				if (traceNeeded)
					trace("there are " + remoteElements.length + " remote elements to store or update locally");
				for (var m:int = 0; m < remoteElements.length; m++) {
					//we have to find the medicinevent in the trackinglist that has the same id
					var l:int=0;
					for (l = 0; l < trackingList.length;l++) {
						if (trackingList.getItemAt(l) is BloodGlucoseEvent) {
							if ((trackingList.getItemAt(l) as BloodGlucoseEvent).eventid == remoteElements.getItemAt(m)[positionId] ) {
								if (traceNeeded) trace("find an element in with same eventid");
								if (traceNeeded) trace ("bg event  = " + (trackingList.getItemAt(l) as BloodGlucoseEvent).toString());
								localElementsUpdated = true;
								/*if (!trackingListAlreadyModified) {
								trackingListAlreadyModified = true;
								ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
								}*/
								if ((remoteElements.getItemAt(m)[positionDeleted] as String) == "true") {
									if (traceNeeded)
										trace("call to bloodglucoseevent.deleteevent");
									(trackingList.getItemAt(l) as BloodGlucoseEvent).deleteEvent();
								} else {
									if (traceNeeded) trace("call to update bloodglucoseevent");
									(trackingList.getItemAt(l) as BloodGlucoseEvent).updateBloodGlucoseEvent(
										remoteElements.getItemAt(m)[positionUnit],
										remoteElements.getItemAt(m)[positionValue],
										new Number(remoteElements.getItemAt(m)[positionCreationTimeStamp]),
										new Number(remoteElements.getItemAt(m)[positionModifiedTimeStamp]));
								}
								break;
							}
						}
					}
					if (l == trackingList.length) {
						//it means we didn't find the remotelement in the trackinglist, so we need to create it
						//but only if deleted is false
						if (((remoteElements.getItemAt(m) as Array)[positionDeleted] as String) == "false") {
							localElementsUpdated = true;
							/*if (!trackingListAlreadyModified) {
							trackingListAlreadyModified = true;
							ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
							}*/
							
							/*trackingList.addItem*/(new BloodGlucoseEvent(
								remoteElements.getItemAt(m)[positionValue],
								remoteElements.getItemAt(m)[positionUnit],
								remoteElements.getItemAt(m)[positionId],
								new Number(remoteElements.getItemAt(m)[positionCreationTimeStamp]),
								new Number(remoteElements.getItemAt(m)[positionModifiedTimeStamp]),
								true));
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
			var positionLevel:int;
			var positionCreationTimeStamp:int;
			var positionModifiedTimeStamp:int;
			var positionDeleted:int;
			var positionAddedTimeStamp:int;
			
			if (traceNeeded)
				trace("start method getTheExerciseEvents");
			//ModelLocator.getInstance().logString += "start method getTheExerciseEvents"+ "\n";
			//start with remoteElements
			//I'm assuming here that the nextpagetoken principle will be used by google, not sure however
			if (event != null) {
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if  (eventAsJSONObject.error) {
					
					if (eventAsJSONObject.error.message == googleError_Invalid_Credentials && !secondAttempt) {
						secondAttempt = true;
						functionToRecall = getTheMedicinEvents;
						functionToRemoveFromEventListener = null;
						googleAPICallFailed(event);
					} else {
						//some other kind of yet unidentified error 
					}
				} else {
					//just to be sure, we need to find the order of the columns in our jsonobject .. boring
					//we might be going several times through this, in case nextPageToken is not null, should give the same result each time.
					var ctr:int;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[2][2][0][0] == eventAsJSONObject.columns[ctr])
							positionId = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[2][2][1][0] == eventAsJSONObject.columns[ctr])
							positionLevel = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[2][2][2][0] == eventAsJSONObject.columns[ctr])
							positionCreationTimeStamp = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[2][2][3][0] == eventAsJSONObject.columns[ctr])
							positionModifiedTimeStamp = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[2][2][4][0] == eventAsJSONObject.columns[ctr])
							positionDeleted = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[2][2][5][0] == eventAsJSONObject.columns[ctr])
							positionAddedTimeStamp = ctr;
					
					var elementAlreadyThere:Boolean;
					if (eventAsJSONObject.rows) {
						for (var rowctr:int = 0;rowctr < eventAsJSONObject.rows.length;rowctr++) {
							elementAlreadyThere = false;
							for (var rowctr2:int = 0;rowctr2 < remoteElements.length;rowctr2++) {
								if ((remoteElements.getItemAt(rowctr2) as Array)[positionId] == eventAsJSONObject.rows[rowctr][positionId]) {
									elementAlreadyThere = true;
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
			
			if (event == null || nextPageToken != null) {//two reasons to try to fetch data from google
				var request:URLRequest = new URLRequest(googleSelectUrl);
				request.contentType = "application/x-www-form-urlencoded";
				var urlVariables:URLVariables = new URLVariables();
				//request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				
				urlVariables.sql = createSQLQueryToSelectAll(2);
				if (nextPageToken != null)
					urlVariables.pageToken = nextPageToken;
				urlVariables.access_token = access_token;
				request.data = urlVariables;
				request.method = URLRequestMethod.GET;
				loader = new URLLoader();
				functionToRecall = getTheExerciseEvents;
				loader.addEventListener(Event.COMPLETE,getTheExerciseEvents);
				functionToRemoveFromEventListener = getTheExerciseEvents;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded)
					trace("get the medicinevents , loader : request = " + request.data); 
			} else {
				//get the medicinevents in the trackinglist and store them in localElements.
				//trace("filtering events, asOfTimeStamp = " + asOfTimeStamp + ", lastSyncTimeStamp = " + lastSyncTimeStamp);
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
								if (new Number((remoteElements.getItemAt(k) as Array)[positionModifiedTimeStamp]) != (localElements.getItemAt(j) as ExerciseEvent).lastModifiedTimestamp) {
									//no lastmodifiedtimestamps are not equal, we need to see which one is most recent
									//but first let's see if the remoteelement has the deleted flag set
									if (((remoteElements.getItemAt(k) as Array)[positionDeleted] as String) == "true") {
										//its a deleted item remove it from both lists
										remoteElements.removeItemAt(k);
										if (!trackingListAlreadyModified) {
											trackingListAlreadyModified = true;
											ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
										}
										localElementsUpdated = true;//as we deleted one from local database, 
										(localElements.getItemAt(j) as ExerciseEvent).deleteEvent();//delete from local database
										localElements.removeItemAt(j);//remove also from list used here
										j--;//j is going to be incrased and will point to the next element, as we've just deleted one
										break;
									} else {
										if (new Number((remoteElements.getItemAt(k) as Array)[positionModifiedTimeStamp]) < (localElements.getItemAt(j) as ExerciseEvent).lastModifiedTimestamp) {
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
				if (traceNeeded)
					trace("there are " + remoteElements.length + " remote elements to store or update locally");
				for (var m:int = 0; m < remoteElements.length; m++) {
					//we have to find the medicinevent in the trackinglist that has the same id
					var l:int=0;
					for (l = 0; l < trackingList.length;l++) {
						if (trackingList.getItemAt(l) is ExerciseEvent) {
							if ((trackingList.getItemAt(l) as ExerciseEvent).eventid == remoteElements.getItemAt(m)[positionId] ) {
								localElementsUpdated = true;
								/*if (!trackingListAlreadyModified) {
								trackingListAlreadyModified = true;
								ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
								}*/
								if ((remoteElements.getItemAt(m)[positionDeleted] as String) == "true") {
									(trackingList.getItemAt(l) as ExerciseEvent).deleteEvent();
								} else {
									(trackingList.getItemAt(l) as ExerciseEvent).updateExerciseEvent(
										remoteElements.getItemAt(m)[positionLevel],
										new Number(remoteElements.getItemAt(m)[positionCreationTimeStamp]),
										new Number(remoteElements.getItemAt(m)[positionModifiedTimeStamp]),
										"");
								}
								break;
							}
						}
					}
					if (l == trackingList.length) {
						//it means we didn't find the remotelement in the trackinglist, so we need to create it
						//but only if deleted is false
						if (((remoteElements.getItemAt(m) as Array)[positionDeleted] as String) == "false") {
							localElementsUpdated = true;
							/*if (!trackingListAlreadyModified) {
							trackingListAlreadyModified = true;
							ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
							}*/
							
							/*trackingList.addItem*/(new ExerciseEvent(
								remoteElements.getItemAt(m)[positionLevel],
								"",
								remoteElements.getItemAt(m)[positionId],
								new Number(remoteElements.getItemAt(m)[positionCreationTimeStamp]),
								new Number(remoteElements.getItemAt(m)[positionModifiedTimeStamp]),
								true));
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
			var positionMealName:int;
			var positionInsulinRatio:int;
			var positionCFFactor:int;
			var positionPreviousBGLevel:int;
			var positionCreationTimeStamp:int;
			var positionModifiedTimeStamp:int;
			var positionDeleted:int;
			var positionAddedTimeStamp:int;
			
			if (traceNeeded)
				trace("start method getTheMealEvents");
			//ModelLocator.getInstance().logString += "start method getTheMealEvents"+ "\n";
			//start with remoteElements
			//I'm assuming here that the nextpagetoken principle will be used by google, not sure however
			if (event != null) {
				//ModelLocator.getInstance().logString += "in getthemealevents, receved an event, event.target.data = " + event.target.data + "\n";
				
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if  (eventAsJSONObject.error) {
					
					if (eventAsJSONObject.error.message == googleError_Invalid_Credentials && !secondAttempt) {
						secondAttempt = true;
						functionToRecall = getTheMealEvents;
						functionToRemoveFromEventListener = null;
						googleAPICallFailed(event);
					} else {
						//some other kind of yet unidentified error 
						//ModelLocator.getInstance().logString += "Error in Synchronize.as - unidentified cause 1  : " + (event.target.data as String) + "\n";
						syncFinished(false);
					}
				} else {
					//just to be sure, we need to find the order of the columns in our jsonobject .. boring
					//we might be going several times through this, in case nextPageToken is not null, should give the same result each time.
					var ctr:int;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[3][2][0][0] == eventAsJSONObject.columns[ctr])
							positionId = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[3][2][1][0] == eventAsJSONObject.columns[ctr])
							positionMealName = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[3][2][2][0] == eventAsJSONObject.columns[ctr])
							positionInsulinRatio = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[3][2][3][0] == eventAsJSONObject.columns[ctr])
							positionCFFactor = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[3][2][4][0] == eventAsJSONObject.columns[ctr])
							positionPreviousBGLevel = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[3][2][5][0] == eventAsJSONObject.columns[ctr])
							positionCreationTimeStamp = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[3][2][6][0] == eventAsJSONObject.columns[ctr])
							positionModifiedTimeStamp = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[3][2][7][0] == eventAsJSONObject.columns[ctr])
							positionDeleted = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[3][2][8][0] == eventAsJSONObject.columns[ctr])
							positionAddedTimeStamp = ctr;
					
					var elementAlreadyThere:Boolean;
					if (eventAsJSONObject.rows) {
						for (var rowctr:int = 0;rowctr < eventAsJSONObject.rows.length;rowctr++) {
							elementAlreadyThere = false;
							for (var rowctr2:int = 0;rowctr2 < remoteElements.length;rowctr2++) {
								if ((remoteElements.getItemAt(rowctr2) as Array)[positionId] == eventAsJSONObject.rows[rowctr][positionId]) {
									elementAlreadyThere = true;
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
				var request:URLRequest = new URLRequest(googleSelectUrl);
				request.contentType = "application/x-www-form-urlencoded";
				var urlVariables:URLVariables = new URLVariables();
				//request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				
				urlVariables.sql = createSQLQueryToSelectAll(3);
				if (nextPageToken != null)
					urlVariables.pageToken = nextPageToken;
				urlVariables.access_token = access_token;
				request.data = urlVariables;
				request.method = URLRequestMethod.GET;
				loader = new URLLoader();
				functionToRecall = getTheMealEvents;
				loader.addEventListener(Event.COMPLETE,getTheMealEvents);
				functionToRemoveFromEventListener = getTheMealEvents;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded)
					trace("get the mealevents " + " loader : request = " + request.data); 
			} else {
				for (var i:int = 0; i < trackingList.length; i++) {
					if (trackingList.getItemAt(i) is MealEvent) {
						if ((trackingList.getItemAt(i) as MealEvent).timeStamp >= asOfTimeStamp)
							if ((trackingList.getItemAt(i) as MealEvent).lastModifiedTimeStamp >= lastSyncTimeStamp)
								localElements.addItem(trackingList.getItemAt(i));
					}
				}
				//ModelLocator.getInstance().logString += "here i am, localElements.length = " + localElements.length + "\n";
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
									if (new Number((remoteElements.getItemAt(k) as Array)[positionModifiedTimeStamp]) != (localElements.getItemAt(j) as MealEvent).lastModifiedTimeStamp) {
										//ModelLocator.getInstance().logString += "4" + "\n";
										//no lastmodifiedtimestamps are not equal, we need to see which one is most recent
										//but first let's see if the remoteelement has the deleted flag set
										if (((remoteElements.getItemAt(k) as Array)[positionDeleted] as String) == "true") {
											//ModelLocator.getInstance().logString += "5" + "\n";
											//its a deleted item remove it from both lists
											remoteElements.removeItemAt(k);
											(localElements.getItemAt(j) as MealEvent).deleteEvent();//delete from local database
											localElementsUpdated = true;//as we deleted one from local database, 
											if (!trackingListAlreadyModified) {
												trackingListAlreadyModified = true;
												ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
											}
											localElements.removeItemAt(j);//remove also from list used here
											j--;//j is going to be incrased and will point to the next element, as we've just deleted one
											break;
										} else {
											//ModelLocator.getInstance().logString += "6" + "\n";
											if (new Number((remoteElements.getItemAt(k) as Array)[positionModifiedTimeStamp]) < (localElements.getItemAt(j) as MealEvent).lastModifiedTimeStamp) {
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
				if (traceNeeded)
					trace("there are " + remoteElements.length + " remote elements to store or update locally");
				//ModelLocator.getInstance().logString += "in getthemealevents, ready to start updating, remoteElements.length = " + remoteElements.length + "\n";
				for (var m:int = 0; m < remoteElements.length; m++) {
					//we have to find the medicinevent in the trackinglist that has the same id
					var l:int=0;
					for (l = 0; l < trackingList.length;l++) {
						if (trackingList.getItemAt(l) is MealEvent) {
							if ((trackingList.getItemAt(l) as MealEvent).eventid == remoteElements.getItemAt(m)[positionId] ) {
								localElementsUpdated = true;
								/*if (!trackingListAlreadyModified) {
								trackingListAlreadyModified = true;
								ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
								}*/
								if ((remoteElements.getItemAt(m)[positionDeleted] as String) == "true") {
									if (traceNeeded)
										trace("in synchronize.as, calling mealevent.deleteevent");
									(trackingList.getItemAt(l) as MealEvent).deleteEvent();
								} else {
									(trackingList.getItemAt(l) as MealEvent).updateMealEvent(
										remoteElements.getItemAt(m)[positionMealName],
										remoteElements.getItemAt(m)[positionInsulinRatio],
										remoteElements.getItemAt(m)[positionCFFactor],
										remoteElements.getItemAt(m)[positionPreviousBGLevel],
										new Number(remoteElements.getItemAt(m)[positionModifiedTimeStamp]),
										new Number(remoteElements.getItemAt(m)[positionCreationTimeStamp]));
								}
								break;
							}
						}
					}
					if (l == trackingList.length) {
						//it means we didn't find the remotelement in the trackinglist, so we need to create it
						//but only if deleted is false
						if (((remoteElements.getItemAt(m) as Array)[positionDeleted] as String) == "false") {
							localElementsUpdated = true;
							if (!trackingListAlreadyModified) {
								trackingListAlreadyModified = true;
								ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
							}
							
							trackingList.addItem(new MealEvent(//in contradiction to medicin/bloodglucose and exerciseevents, I must add new mealevents to the trackinglist, because if i don't, the adding of selectedfooditems would fail because I wouldn't find the mealevent
								remoteElements.getItemAt(m)[positionMealName],
								remoteElements.getItemAt(m)[positionInsulinRatio],
								remoteElements.getItemAt(m)[positionCFFactor],
								remoteElements.getItemAt(m)[positionPreviousBGLevel],
								new Number(remoteElements.getItemAt(m)[positionCreationTimeStamp]),
								null,
								remoteElements.getItemAt(m)[positionId],
								new Number(remoteElements.getItemAt(m)[positionModifiedTimeStamp]),
								true));
						}
					}
				}
				remoteElements = new ArrayList();
				getTheSelectedFoodItems(null);
			}
		}
		
		private function getTheSelectedFoodItems(event:Event = null):void {
			var positionId:int;
			var positionDescription:int;
			var positionUnitDescription:int;
			var positionUnitStandardAmount:int;
			var positionUnitKcal:int;
			var positionUnitProtein:int;
			var positionUnitCarbs:int;
			var positionUnitFat:int;
			var positionChosenAmount:int;
			var positionMealEventId:int;
			var positionCreationTimeStamp:int;
			var positionModifiedTimeStamp:int;
			var positionDeleted:int;
			var positionAddedTimeStamp:int;
			
			if (traceNeeded)
				trace("start method getTheSelectedItems");
			//ModelLocator.getInstance().logString += "start method getTheSelectedFoodItems" + "\n";
			//start with remoteElements
			//I'm assuming here that the nextpagetoken principle will be used by google, not sure however
			if (event != null) {
				//ModelLocator.getInstance().logString += "in method getTheSelectedFoodItems, event != null"+ "\n";
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if  (eventAsJSONObject.error) {
					
					if (eventAsJSONObject.error.message == googleError_Invalid_Credentials && !secondAttempt) {
						secondAttempt = true;
						functionToRecall = getTheMealEvents;
						functionToRemoveFromEventListener = null;
						googleAPICallFailed(event);
					} else {
						//some other kind of yet unidentified error
						//ModelLocator.getInstance().logString += "in method gettheselecteditems, unidentified error"+ "\n";
						//ModelLocator.getInstance().logString += "event.target.data = " + event.target.data + "\n";
					}
				} else {
					//just to be sure, we need to find the order of the columns in our jsonobject .. boring
					//we might be going several times through this, in case nextPageToken is not null, should give the same result each time.
					var ctr:int;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][0][0] == eventAsJSONObject.columns[ctr])
							positionId = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][1][0] == eventAsJSONObject.columns[ctr])
							positionDescription = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][2][0] == eventAsJSONObject.columns[ctr])
							positionUnitDescription = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][3][0] == eventAsJSONObject.columns[ctr])
							positionUnitStandardAmount = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][4][0] == eventAsJSONObject.columns[ctr])
							positionUnitKcal = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][5][0] == eventAsJSONObject.columns[ctr])
							positionUnitProtein = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][6][0] == eventAsJSONObject.columns[ctr])
							positionUnitCarbs = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][7][0] == eventAsJSONObject.columns[ctr])
							positionUnitFat = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][8][0] == eventAsJSONObject.columns[ctr])
							positionChosenAmount = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][9][0] == eventAsJSONObject.columns[ctr])
							positionMealEventId = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][10][0] == eventAsJSONObject.columns[ctr])
							positionCreationTimeStamp = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][11][0] == eventAsJSONObject.columns[ctr])
							positionModifiedTimeStamp = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][12][0] == eventAsJSONObject.columns[ctr])
							positionDeleted = ctr;
					for (ctr = 0;ctr < eventAsJSONObject.columns.length;ctr++)
						if (tableNamesAndColumnNames[4][2][13][0] == eventAsJSONObject.columns[ctr])
							positionAddedTimeStamp = ctr;
					
					var elementAlreadyThere:Boolean;
					if (eventAsJSONObject.rows) {
						for (var rowctr:int = 0;rowctr < eventAsJSONObject.rows.length;rowctr++) {
							elementAlreadyThere = false;
							for (var rowctr2:int = 0;rowctr2 < remoteElements.length;rowctr2++) {
								if ((remoteElements.getItemAt(rowctr2) as Array)[positionId] == eventAsJSONObject.rows[rowctr][positionId]) {
									elementAlreadyThere = true;
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
				//ModelLocator.getInstance().logString += "in gettheselectedfooditems, event = null or nextpagetoken != null" + "\n";;
				var request:URLRequest = new URLRequest(googleSelectUrl);
				request.contentType = "application/x-www-form-urlencoded";
				var urlVariables:URLVariables = new URLVariables();
				
				urlVariables.sql = createSQLQueryToSelectAll(4);
				if (nextPageToken != null)
					urlVariables.pageToken = nextPageToken;
				urlVariables.access_token = access_token;
				request.data = urlVariables;
				request.method = URLRequestMethod.GET;
				loader = new URLLoader();
				functionToRecall = getTheSelectedFoodItems;
				loader.addEventListener(Event.COMPLETE,getTheSelectedFoodItems);
				functionToRemoveFromEventListener = getTheSelectedFoodItems;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded)
					trace("get the selectedfooditems " + " loader : request = " + request.data); 
				//ModelLocator.getInstance().logString += " loader : request = " + request.data + "\n";;
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
								if (new Number((remoteElements.getItemAt(k) as Array)[positionModifiedTimeStamp]) != (localElements.getItemAt(j) as SelectedFoodItem).lastModifiedTimestamp) {
									//no lastmodifiedtimestamps are not equal, we need to see which one is most recent
									//but first let's see if the remoteelement has the deleted flag set
									if (((remoteElements.getItemAt(k) as Array)[positionDeleted] as String) == "true") {
										//its a deleted item remove it from both lists
										remoteElements.removeItemAt(k);
										(localElements.getItemAt(j) as SelectedFoodItem).deleteEvent();//delete from local database
										localElementsUpdated = true;//as we deleted one from local database, 
										if (!trackingListAlreadyModified) {
											trackingListAlreadyModified = true;
											ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
										}
										localElements.removeItemAt(j);//remove also from list used here
										j--;//j is going to be incrased and will point to the next element, as we've just deleted one
										break;
									} else {
										if (new Number((remoteElements.getItemAt(k) as Array)[positionModifiedTimeStamp]) < (localElements.getItemAt(j) as SelectedFoodItem).lastModifiedTimestamp) {
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
				if (traceNeeded)
					trace("there are " + remoteElements.length + " remote elements to store or update locally");
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
									/*if (!trackingListAlreadyModified) {
									trackingListAlreadyModified = true;
									ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
									}*/
									if ((remoteElements.getItemAt(m)[positionDeleted] as String) == "true") {
										theSelectedFoodItem.deleteEvent();
									} else {
										theSelectedFoodItem.updateSelectedFoodItem(
											remoteElements.getItemAt(m)[positionDescription],
											new Unit(
												remoteElements.getItemAt(m)[positionUnitDescription],
												remoteElements.getItemAt(m)[positionUnitStandardAmount],
												remoteElements.getItemAt(m)[positionUnitKcal],
												remoteElements.getItemAt(m)[positionUnitProtein],
												remoteElements.getItemAt(m)[positionUnitCarbs],
												remoteElements.getItemAt(m)[positionUnitFat]),
											remoteElements.getItemAt(m)[positionModifiedTimeStamp],
											remoteElements.getItemAt(m)[positionChosenAmount]);
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
						if (((remoteElements.getItemAt(m) as Array)[positionDeleted] as String) == "false") {
							//we need to find the mealevent
							for (var lstctr:int = 0; lstctr < trackingList.length; lstctr++) {
								if (trackingList.getItemAt(lstctr) is MealEvent) {
									if ((trackingList.getItemAt(lstctr) as MealEvent).timeStamp >= asOfTimeStamp) {
										if ((trackingList.getItemAt(lstctr) as MealEvent).eventid == remoteElements.getItemAt(m)[positionMealEventId]) {
											localElementsUpdated = true;
											/*if (!trackingListAlreadyModified) {
											trackingListAlreadyModified = true;
											ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
											}*/
											(trackingList.getItemAt(lstctr) as MealEvent).addSelectedFoodItem(
												new SelectedFoodItem(
													remoteElements.getItemAt(m)[positionId],
													remoteElements.getItemAt(m)[positionDescription],
													new Unit(
														remoteElements.getItemAt(m)[positionUnitDescription],
														remoteElements.getItemAt(m)[positionUnitStandardAmount],
														remoteElements.getItemAt(m)[positionUnitKcal],
														remoteElements.getItemAt(m)[positionUnitProtein],
														remoteElements.getItemAt(m)[positionUnitCarbs],
														remoteElements.getItemAt(m)[positionUnitFat]
													),
													remoteElements.getItemAt(m)[positionChosenAmount],
													remoteElements.getItemAt(m)[positionModifiedTimeStamp]
												),
												null)
										}
									}
								}
							}
						}
					}
				}
				getRowIds(null);
			}
		}
		
		/**
		 * we need to get the rowids for all localevents that have a remote copy, we need to do that to be able to update 
		 */
		private function getRowIds(event:Event):void {
			if (traceNeeded)
				trace ("in method getrowids");
			//ModelLocator.getInstance().logString += "in method getrowids" + "\n";
			if (event != null) {
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if  (eventAsJSONObject.error) {
					if (eventAsJSONObject.error.message == googleError_Invalid_Credentials && !secondAttempt) {
						secondAttempt = true;
						functionToRecall = getRowIds;
						functionToRemoveFromEventListener = null;
						googleAPICallFailed(event);
					} else {
						//some other kind of yet unidentified error 
					}
					return;
				} 
				
				remoteElementIds.getItemAt(indexOfRetrievedRowId)[1] =  new Number(eventAsJSONObject.rows[0][0]);
			} 
			
			var sqlStatement:String = "";
			var j:int;
			for (var i:int = 0;i < localElements.length; i++) {
				if (localElements.getItemAt(i) is MedicinEvent) {//later on we will add exerciseevents, ...
					for (j = 0;j < remoteElementIds.length; j++) {
						if ((localElements.getItemAt(i) as TrackingViewElement).eventid == remoteElementIds.getItemAt(j)[0]) {
							if (!remoteElementIds.getItemAt(j)[1]) {
								sqlStatement = "SELECT ROWID FROM " + tableNamesAndColumnNames[0][1] + " WHERE id = \'" + (localElements.getItemAt(i) as TrackingViewElement).eventid + "\'";
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
								sqlStatement = "SELECT ROWID FROM " + tableNamesAndColumnNames[1][1] + " WHERE id = \'" + (localElements.getItemAt(i) as TrackingViewElement).eventid + "\'";
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
								sqlStatement = "SELECT ROWID FROM " + tableNamesAndColumnNames[2][1] + " WHERE id = \'" + (localElements.getItemAt(i) as TrackingViewElement).eventid + "\'";
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
								sqlStatement = "SELECT ROWID FROM " + tableNamesAndColumnNames[3][1] + " WHERE id = \'" + (localElements.getItemAt(i) as TrackingViewElement).eventid + "\'";
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
								sqlStatement = "SELECT ROWID FROM " + tableNamesAndColumnNames[4][1] + " WHERE id = \'" + (localElements.getItemAt(i) as SelectedFoodItem).eventid + "\'";
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
				syncLocalEvents(null);
			} else {
				var request:URLRequest = new URLRequest(googleSelectUrl);
				request.contentType = "application/x-www-form-urlencoded";
				var urlVariables:URLVariables = new URLVariables();
				
				urlVariables.sql = sqlStatement;
				request.data = urlVariables;
				urlVariables.access_token = access_token;
				request.method = URLRequestMethod.GET;
				loader = new URLLoader();
				functionToRecall = getRowIds;
				loader.addEventListener(Event.COMPLETE,getRowIds);
				functionToRemoveFromEventListener = getRowIds;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded)
					trace("loader : request = " + request.data); 
			}
		}
		
		/**
		 * inserts and updates local events to remote server
		 */
		private function syncLocalEvents(event:Event):void {
			if (traceNeeded)
				trace ("in method synclocalevents");
			if (event != null) {
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if  (eventAsJSONObject.error) {
					if (eventAsJSONObject.error.message == googleError_Invalid_Credentials && !secondAttempt) {
						secondAttempt = true;
						functionToRecall = getRowIds;
						functionToRemoveFromEventListener = null;
						googleAPICallFailed(event);
					} else {
						//some other kind of yet unidentified error 
					}
					return;
				} 
			}
			
			if (localElements.length > 0) {
				var request:URLRequest = new URLRequest(googleSelectUrl);
				request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				request.contentType = "application/x-www-form-urlencoded";
				
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
							sqlStatement += "(id,medicinname,value,creationtimestamp,modifiedtimestamp,deleted,addedtoormodifiedintabletimestamp) VALUES (\'" +
								(localElements.getItemAt(i) as MedicinEvent).eventid.toString() + "\',\'" +
								(localElements.getItemAt(i) as MedicinEvent).medicinName + "\',\'" +
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
								+ "\')";
							localElements.removeItemAt(i);
							i--;
						}
					}  else if (localElements.getItemAt(i) is BloodGlucoseEvent && !previousTypeOfEventAlreadyUsed) {
						if (!elementFoundWithSameId) {
							previousTypeOfEventAlreadyUsed = true;
							sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "INSERT INTO " + tableNamesAndColumnNames[1][1] + " ";
							sqlStatement += "(id,unit,value,creationtimestamp,modifiedtimestamp,deleted,addedtoormodifiedintabletimestamp) VALUES (\'" +
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
								+ "\')";
							localElements.removeItemAt(i);
							i--;
						}
					}  else if (localElements.getItemAt(i) is ExerciseEvent && !previousTypeOfEventAlreadyUsed) {
						if (!elementFoundWithSameId) {
							previousTypeOfEventAlreadyUsed = true;
							sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "INSERT INTO " + tableNamesAndColumnNames[2][1] + " ";
							sqlStatement += "(id,level,creationtimestamp,modifiedtimestamp,deleted,addedtoormodifiedintabletimestamp) VALUES (\'" +
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
								+ "\')";
							localElements.removeItemAt(i);
							i--;
						}
					}  else if (localElements.getItemAt(i) is MealEvent && !previousTypeOfEventAlreadyUsed) {
						if (!elementFoundWithSameId) {
							previousTypeOfEventAlreadyUsed = true;
							sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "INSERT INTO " + tableNamesAndColumnNames[3][1] + " ";
							sqlStatement += "(id,mealname,insulinratio,correctionfactor,previousbglevel,creationtimestamp,modifiedtimestamp,deleted,addedtoormodifiedintabletimestamp) VALUES (\'" +
								(localElements.getItemAt(i) as MealEvent).eventid.toString() + "\',\'" +
								(localElements.getItemAt(i) as MealEvent).mealName + "\',\'" +
								(localElements.getItemAt(i) as MealEvent).insulinRatio.toString() + "\',\'" +
								(localElements.getItemAt(i) as MealEvent).correctionFactor.toString() + "\',\'" +
								(localElements.getItemAt(i) as MealEvent).previousBGlevel + "\',\'" +
								(localElements.getItemAt(i) as MealEvent).timeStamp.toString() + "\',\'" +
								(localElements.getItemAt(i) as MealEvent).lastModifiedTimeStamp.toString() + "\'," +
								"\'false\'" +
								",\'" +  
								((new Date()).valueOf() - (localElements.getItemAt(i) as MealEvent).lastModifiedTimeStamp > 10000 
									? 
									(new Date()).valueOf().toString() 
									:
									(localElements.getItemAt(i) as MealEvent).lastModifiedTimeStamp.toString())
								+ "\')";
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
										"medicinname = \'" + (localElements.getItemAt(k) as MedicinEvent).medicinName + "\'," +
										"value = \'" + (localElements.getItemAt(k) as MedicinEvent).amount.toString() + "\'," +
										"creationtimestamp = \'" + (localElements.getItemAt(k) as MedicinEvent).timeStamp.toString() + "\'," +
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
										"previousbglevel = \'" + (localElements.getItemAt(k) as MealEvent).previousBGlevel + "\'," +
										"creationtimestamp = \'" + (localElements.getItemAt(k) as MealEvent).timeStamp.toString() + "\'," +
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
					request.data = new URLVariables(
						"sql=" + sqlStatement);
					
					request.method = URLRequestMethod.POST;
					loader = new URLLoader();
					functionToRecall = syncLocalEvents;
					loader.addEventListener(Event.COMPLETE,syncLocalEvents);
					functionToRemoveFromEventListener = syncLocalEvents;
					loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
					loader.load(request);
					if (traceNeeded)
						trace("loader : request = " + request.data); 
				}
				
			} else {
				//sync other kinds of tables like settings..
				googleExcelFindFoodTableSpreadSheet(null);
			}
			//there should not be code here
		}
		
		
		
		private function googleAPICallFailed(event:Event):void {
			if (functionToRemoveFromEventListener != null)
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
			loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
			
			if (traceNeeded)
				trace("in googleapicall failed : event.target.data = " + event.target.data as String);
			//let's first see if the event.target.data has json
			try {
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				var message:String = eventAsJSONObject.error.message as String;
				if (message == googleError_Invalid_Credentials) {
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
					if (traceNeeded)
						trace("loader : request = " + request.data); 
				} else {
					//ModelLocator.getInstance().logString += "error 3 : " + event.target.data + "\n";;
					/*if (trackingListAlreadyModified)
					ModelLocator.getInstance().copyOfTrackingList = ModelLocator.getInstance().trackingList;*/
					syncFinished(false);
				}
			} catch (e:SyntaxError) {
				//event.taregt.data is not json
				if (event.type == "ioError") {
					/*if (trackingListAlreadyModified)
					ModelLocator.getInstance().copyOfTrackingList = ModelLocator.getInstance().trackingList;*/
					//an ioError, forget about it, the show doesn't go on
					//ModelLocator.getInstance().logString += "error 4 : " + event.target.data+ "\n";;
					syncFinished(false);
				}
			}
		}
		
		private function accessTokenRefreshed(event:Event):void {
			loader.removeEventListener(Event.COMPLETE,accessTokenRefreshed);
			loader.removeEventListener(IOErrorEvent.IO_ERROR,accessTokenRefreshFailed);
			
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
					//an ioError, forget about it, the show doesn't go on
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
			var whichTimeStamp:String = "addedtoormodifiedintabletimestamp";
			returnValue = 
				"SELECT * FROM " + spaces +
				tableNamesAndColumnNames[index][1] +
				" WHERE " + whichTimeStamp + " >= '" + lastSyncTimeStamp.toString() + "' AND " +
				"creationtimestamp >= '" + asOfTimeStamp.toString() + "'";
			if (traceNeeded)
				trace("querystring = " + returnValue);
			return returnValue;
		}
		
		private function deleteRemoteMedicinEvent(event:Event,medicinEvent:MedicinEvent = null):void {
			var request:URLRequest
			
			if (traceNeeded)
				trace("in method deleteremotemedicinevent");
			if (medicinEvent != null)
				objectToBeDeleted = medicinEvent;
			if (event != null)  {
				if (functionToRemoveFromEventListener != null)
					loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventAsJSONObject.rows) {//if rows doesn't exist then there wasn't a remote element with that eventid
					sqlStatement = "UPDATE " + tableNamesAndColumnNames[0][1] + " SET ";
					sqlStatement += 
						"id = \'" + objectToBeDeleted.eventid.toString() + "\'," +
						"medicinname = \'" + (objectToBeDeleted as MedicinEvent).medicinName + "\'," +
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
					
					
					request = new URLRequest(googleSelectUrl);
					request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
					request.data = new URLVariables(
						"sql=" + sqlStatement);
					
					request.method = URLRequestMethod.POST;
					loader = new URLLoader();
					
					//in case delete would fail, and functiontorecall is called, then we arrive back here, well understood with event=null and medicinevent = null
					//but with objecttobedeleted != null
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);//next time we come into deleteRemoteItems, we won't treat this element anymore
					functionToRecall = deleteRemoteMedicinEvent;
					loader.addEventListener(Event.COMPLETE,deleteRemoteItems);
					functionToRemoveFromEventListener = deleteRemoteItems;
					loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
					loader.load(request);
					if (traceNeeded)
						trace("loader : request = " + request.data); 
				} else {
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);
					deleteRemoteItems();
				}
			} else {
				if (traceNeeded)
					trace("start method deleteMedicinEvent");
				
				
				access_token = Settings.getInstance().getSetting(Settings.SettingsAccessToken);
				var sqlStatement:String;
				
				if (access_token.length == 0 ) {
					//there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize
				} else {
					
					sqlStatement = "SELECT ROWID FROM " + tableNamesAndColumnNames[0][1] + " WHERE id = \'" + medicinEvent.eventid + "\'";
					request = new URLRequest(googleSelectUrl);
					request.contentType = "application/x-www-form-urlencoded";
					var urlVariables:URLVariables = new URLVariables();
					//request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
					
					urlVariables.sql = sqlStatement;
					urlVariables.access_token = access_token;
					request.data = urlVariables;
					request.method = URLRequestMethod.GET;
					loader = new URLLoader();
					functionToRecall = deleteRemoteMedicinEvent;
					loader.addEventListener(Event.COMPLETE,deleteRemoteMedicinEvent);
					functionToRemoveFromEventListener = deleteRemoteMedicinEvent;
					loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
					loader.load(request);
					if (traceNeeded)
						trace("loader : request = " + request.data); 
				}
			}
		}
		
		private function deleteRemoteBloodGlucoseEvent(event:Event, bloodglucoseEvent:BloodGlucoseEvent = null):void {
			var request:URLRequest
			
			if (traceNeeded)
				trace("in method deleteremotebloodglucoseevent");
			if (bloodglucoseEvent != null)
				objectToBeDeleted = bloodglucoseEvent;
			if (event != null)  {
				if (functionToRemoveFromEventListener != null)
					loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventAsJSONObject.rows) {//if rows doesn't exist then there wasn't a remote element with that eventid
					sqlStatement = "UPDATE " + tableNamesAndColumnNames[1][1] + " SET ";
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
					
					
					request = new URLRequest(googleSelectUrl);
					request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
					request.data = new URLVariables(
						"sql=" + sqlStatement);
					
					request.method = URLRequestMethod.POST;
					loader = new URLLoader();
					
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);//next time we come into deleteRemoteItems, we won't treat this element anymore
					functionToRecall = deleteRemoteMedicinEvent;
					loader.addEventListener(Event.COMPLETE,deleteRemoteItems);
					functionToRemoveFromEventListener = deleteRemoteItems;
					
					loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
					loader.load(request);
					if (traceNeeded)
						trace("loader : request = " + request.data); 
				} else {
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);
					deleteRemoteItems();
				}
			} else {
				if (traceNeeded)
					trace("start method deleteBloodGlucoseEvent");
				
				
				access_token = Settings.getInstance().getSetting(Settings.SettingsAccessToken);
				var sqlStatement:String;
				
				if (access_token.length == 0 ) {
					//there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize
				} else {
					
					sqlStatement = "SELECT ROWID FROM " + tableNamesAndColumnNames[1][1] + " WHERE id = \'" + bloodglucoseEvent.eventid + "\'";
					request = new URLRequest(googleSelectUrl);
					request.contentType = "application/x-www-form-urlencoded";
					var urlVariables:URLVariables = new URLVariables();
					
					urlVariables.sql = sqlStatement;
					urlVariables.access_token = access_token;
					request.data = urlVariables;
					request.method = URLRequestMethod.GET;
					loader = new URLLoader();
					functionToRecall = deleteRemoteBloodGlucoseEvent;
					loader.addEventListener(Event.COMPLETE,deleteRemoteBloodGlucoseEvent);
					functionToRemoveFromEventListener = deleteRemoteBloodGlucoseEvent;
					loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
					loader.load(request);
					if (traceNeeded)
						trace("loader : request = " + request.data); 
					
				}
			}
		}
		
		private function deleteRemoteExerciseEvent(event:Event, exerciseEvent:ExerciseEvent = null):void {
			var request:URLRequest
			
			if (traceNeeded)
				trace("in method deleteremoteexerciseevent");
			if (exerciseEvent != null)
				objectToBeDeleted = exerciseEvent;
			if (event != null)  {
				if (functionToRemoveFromEventListener != null)
					loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventAsJSONObject.rows) {//if rows doesn't exist then there wasn't a remote element with that eventid
					sqlStatement = "UPDATE " + tableNamesAndColumnNames[2][1] + " SET ";
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
					
					
					request = new URLRequest(googleSelectUrl);
					request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
					request.data = new URLVariables(
						"sql=" + sqlStatement);
					
					request.method = URLRequestMethod.POST;
					loader = new URLLoader();
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);//next time we come into deleteRemoteItems, we won't treat this element anymore
					functionToRecall = deleteRemoteMedicinEvent;
					loader.addEventListener(Event.COMPLETE,deleteRemoteItems);
					functionToRemoveFromEventListener = deleteRemoteItems;
					loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
					loader.load(request);
					if (traceNeeded)
						trace("loader : request = " + request.data); 
				} else {
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);
					deleteRemoteItems();
				}
			} else {
				if (traceNeeded)
					trace("start method deleteExerciseEvent");
				
				
				access_token = Settings.getInstance().getSetting(Settings.SettingsAccessToken);
				var sqlStatement:String;
				
				if (access_token.length == 0 ) {
					//there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize
				} else {
					
					sqlStatement = "SELECT ROWID FROM " + tableNamesAndColumnNames[2][1] + " WHERE id = \'" + exerciseEvent.eventid + "\'";
					request = new URLRequest(googleSelectUrl);
					request.contentType = "application/x-www-form-urlencoded";
					var urlVariables:URLVariables = new URLVariables();
					
					urlVariables.sql = sqlStatement;
					urlVariables.access_token = access_token;
					request.data = urlVariables;
					request.method = URLRequestMethod.GET;
					loader = new URLLoader();
					functionToRecall = deleteRemoteExerciseEvent;
					loader.addEventListener(Event.COMPLETE,deleteRemoteExerciseEvent);
					functionToRemoveFromEventListener = deleteRemoteExerciseEvent;
					loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
					loader.load(request);
					if (traceNeeded)
						trace("loader : request = " + request.data); 
					
				}
			}
		}
		
		private function deleteRemoteMealEvent(event:Event, mealEvent:MealEvent = null):void {
			var request:URLRequest
			
			if (traceNeeded)
				trace("in method deleteremotemealevent");
			if (mealEvent != null)
				objectToBeDeleted = mealEvent;
			if (event != null)  {
				if (functionToRemoveFromEventListener != null)
					loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventAsJSONObject.rows) {//if rows doesn't exist then there wasn't a remote element with that eventid
					sqlStatement = "UPDATE " + tableNamesAndColumnNames[3][1] + " SET ";
					sqlStatement += 
						"id = \'" + objectToBeDeleted.eventid.toString() + "\'," +
						"mealname = \'" + (objectToBeDeleted as MealEvent).mealName + "\'," +
						"insulinratio = \'" + (objectToBeDeleted as MealEvent).insulinRatio + "\'," +
						"correctionfactor = \'" + (objectToBeDeleted as MealEvent).correctionFactor + "\'," +
						"previousbglevel = \'" + (objectToBeDeleted as MealEvent).previousBGlevel + "\'," +
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
					
					
					request = new URLRequest(googleSelectUrl);
					request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
					request.data = new URLVariables(
						"sql=" + sqlStatement);
					
					request.method = URLRequestMethod.POST;
					loader = new URLLoader();
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);//next time we come into deleteRemoteItems, we won't treat this element anymore
					functionToRecall = deleteRemoteMedicinEvent;
					loader.addEventListener(Event.COMPLETE,deleteRemoteItems);
					functionToRemoveFromEventListener = deleteRemoteItems;
					loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
					loader.load(request);
					if (traceNeeded)
						trace("loader : request = " + request.data); 
				} else {
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);
					deleteRemoteItems();
				}
			} else {
				if (traceNeeded)
					trace("start method deleteRemoteMealEvent");
				
				
				access_token = Settings.getInstance().getSetting(Settings.SettingsAccessToken);
				var sqlStatement:String;
				
				if (access_token.length == 0 ) {
					//there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize
					
				} else {
					
					sqlStatement = "SELECT ROWID FROM " + tableNamesAndColumnNames[3][1] + " WHERE id = \'" + mealEvent.eventid + "\'";
					request = new URLRequest(googleSelectUrl);
					request.contentType = "application/x-www-form-urlencoded";
					var urlVariables:URLVariables = new URLVariables();
					
					urlVariables.sql = sqlStatement;
					urlVariables.access_token = access_token;
					request.data = urlVariables;
					request.method = URLRequestMethod.GET;
					loader = new URLLoader();
					functionToRecall = deleteRemoteMealEvent;
					loader.addEventListener(Event.COMPLETE,deleteRemoteMealEvent);
					functionToRemoveFromEventListener = deleteRemoteMealEvent;
					loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
					loader.load(request);
					if (traceNeeded)
						trace("loader : request = " + request.data); 
					
				}
			}
		}
		
		private function deleteRemoteSelectedFoodItem(event:Event, selectedFoodItem:SelectedFoodItem = null):void {
			var request:URLRequest;
			
			if (traceNeeded)
				trace("in method deleteremoteselectedfooditem");
			if (selectedFoodItem != null)
				objectToBeDeleted = selectedFoodItem;
			if (event != null)  {
				if (functionToRemoveFromEventListener != null)
					loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				if (eventAsJSONObject.rows) {//if rows doesn't exist then there wasn't a remote element with that eventid
					var selectedItemToBeDeleted:Object = objectToBeDeleted as SelectedFoodItem;
					sqlStatement = "UPDATE " + tableNamesAndColumnNames[4][1] + " SET ";
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
					
					
					request = new URLRequest(googleSelectUrl);
					request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
					request.data = new URLVariables(
						"sql=" + sqlStatement);
					
					request.method = URLRequestMethod.POST;
					loader = new URLLoader();
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);//next time we come into deleteRemoteItems, we won't treat this element anymore
					functionToRecall = deleteRemoteMedicinEvent;
					loader.addEventListener(Event.COMPLETE,deleteRemoteItems);
					functionToRemoveFromEventListener = deleteRemoteItems;
					loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
					loader.load(request);
					if (traceNeeded)
						trace("loader : request = " + request.data); 
				} else {
					listOfElementsToBeDeleted.removeItem(objectToBeDeleted);
					deleteRemoteItems();
				}
			} else {
				if (traceNeeded)
					trace("start method deleteRemoteSelectedFoodItem");
				
				
				access_token = Settings.getInstance().getSetting(Settings.SettingsAccessToken);
				var sqlStatement:String;
				
				if (access_token.length == 0 ) {
					//there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize
					
				} else {
					
					sqlStatement = "SELECT ROWID FROM " + tableNamesAndColumnNames[4][1] + " WHERE id = \'" + selectedFoodItem.eventid + "\'";
					request = new URLRequest(googleSelectUrl);
					request.contentType = "application/x-www-form-urlencoded";
					var urlVariables:URLVariables = new URLVariables();
					
					urlVariables.sql = sqlStatement;
					urlVariables.access_token = access_token;
					request.data = urlVariables;
					request.method = URLRequestMethod.GET;
					loader = new URLLoader();
					functionToRecall = deleteRemoteSelectedFoodItem;
					loader.addEventListener(Event.COMPLETE,deleteRemoteSelectedFoodItem);
					functionToRemoveFromEventListener = deleteRemoteSelectedFoodItem;
					loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
					loader.load(request);
					if (traceNeeded)
						trace("loader : request = " + request.data); 
				}
			}
		}
		
		private function googleExcelInsertFoodItems(event:Event = null):void {
			var request:URLRequest;
			if (event != null) {
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				syncFinished(true);
			} else {
				if (traceNeeded)
					trace("start method googleExcelInsertFoodItems");
				
				var outputString:String = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
				outputString += '<entry xmlns="http://www.w3.org/2005/Atom\" xmlns:gsx=\"http://schemas.google.com/spreadsheets/2006/extended">\n';
				outputString += '    <gsx:description>1</gsx:description>\n';
				outputString += '</entry>\n';
				outputString = outputString.replace(/\n/g, File.lineEnding);
				
				request = new URLRequest(googleExcelInsertRowInFoodTableUrl.replace("{key}",helpDiabetesSpreadSheetKey).replace("{worksheetid}",helpDiabetesWorkSheetId));
				request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				request.requestHeaders.push(new URLRequestHeader("Content-Type","application/atom+xml"));
				
				request.data = outputString;
				request.method = URLRequestMethod.POST;
				
				loader = new URLLoader();
				functionToRecall = googleExcelInsertFoodItems;
				loader.addEventListener(Event.COMPLETE,googleExcelInsertFoodItems);
				functionToRemoveFromEventListener = googleExcelInsertFoodItems;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded)
					trace("loader : request = " + request.data); 
			}
		}
		
		private function googleExcelCreateHeader(event:Event = null):void  {
			var request:URLRequest;
			if (event != null)  {
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				if ((event.target.data as String).search("updated") != -1) {
					Settings.getInstance().setSetting(Settings.SettingsNextColumnToAdd,(new Number(Settings.getInstance().getSetting(Settings.SettingsNextColumnToAdd)) + 1).toString());
					//seems insert of cel was successfull
				} else {
					syncFinished(false);
					return;
				}
			} 
			
			if (traceNeeded)
				trace("start method googleExcelCreateHeader");
			
			if (new Number(Settings.getInstance().getSetting(Settings.SettingsNextColumnToAdd)) == googleExcelGoodTableColumnNames.length)  {
				googleExcelInsertFoodItems();
			} else {
				var nextColumn:int = new Number(Settings.getInstance().getSetting(Settings.SettingsNextColumnToAdd)) + 1;//index starts at 0, but column number at 1
				var outputString:String = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
				outputString += '<entry xmlns="http://www.w3.org/2005/Atom\" xmlns:gs=\"http://schemas.google.com/spreadsheets/2006">\n';
				outputString += '    <gs:cell row="1" col="' + nextColumn + '" inputValue="' + googleExcelGoodTableColumnNames[nextColumn - 1] + '"/>\n';
				outputString += '</entry>\n';
				outputString = outputString.replace(/\n/g, File.lineEnding);
				
				request = new URLRequest(googleExcelUpdateCellUrl.replace("{key}",helpDiabetesSpreadSheetKey).replace("{worksheetid}",helpDiabetesWorkSheetId));
				request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				request.requestHeaders.push(new URLRequestHeader("Content-Type","application/atom+xml"));
				
				request.data = outputString;
				request.method = URLRequestMethod.POST;
				
				loader = new URLLoader();
				functionToRecall = googleExcelCreateHeader;
				loader.addEventListener(Event.COMPLETE,googleExcelCreateHeader);
				functionToRemoveFromEventListener = googleExcelCreateHeader;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded)
					trace("loader : request = " + request.data); 
			}
		}
		
		/**
		 * this function will create the foodtable on google excel, so it should only be called if it doesn't exist yet<br>
		 * if excel sheet successfully created, then it will mark this instance of the app as the creator of the foodtable
		 */
		private function googleExcelCreateFoodTable(event:Event = null):void  {
			var request:URLRequest;
			
			if (event != null)  {
				//SHOULD BE CHECKING HERE WHAT CAN GO WRONG - BECAUSE I SEEM TO ASSUME HERE THAT THE FOODTABLE CREATION WILL ALWAYS BE SUCCESSFUL
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				Settings.getInstance().setSetting(Settings.SettingsIMtheCreateorOfGoogleExcelFoodTable,"true");
				
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if  (eventAsJSONObject.error) {
					
					if (eventAsJSONObject.error.message == googleError_Invalid_Credentials && !secondAttempt) {
						secondAttempt = true;
						functionToRecall = googleExcelCreateFoodTable;
						functionToRemoveFromEventListener = null;
						googleAPICallFailed(event);
					} else {
						//some other kind of yet unidentified error 
					}
				} else {
					if (eventAsJSONObject.id)  {
						helpDiabetesSpreadSheetKey = eventAsJSONObject.id;
						googleExcelCreateWorkSheet();
					} else {
						//something went wrong, syncfinished successfully because sync itself was ok
					}
				}
				
			} else {
				if (traceNeeded)
					trace("start method googleExcelCreateFoodTable");
				request = new URLRequest(googleDriveFilesUrl);
				request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				request.requestHeaders.push(new URLRequestHeader("X-JavaScript-User-Agent", "Google APIs Explorer"));
				request.requestHeaders.push(new URLRequestHeader("Content-Type","application/json"));
				
				var jsonObject:Object = new Object();
				jsonObject.mimeType = "application/vnd.google-apps.spreadsheet";
				jsonObject.title = foodtableName;
				var bodyString:String = JSON.stringify(jsonObject);
				request.data = bodyString;
				request.method = URLRequestMethod.POST;
				
				loader = new URLLoader();
				functionToRecall = googleExcelCreateFoodTable;
				loader.addEventListener(Event.COMPLETE,googleExcelCreateFoodTable);
				functionToRemoveFromEventListener = googleExcelCreateFoodTable;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded)
					trace("loader : request = " + request.data); 
			}
		}
		
		/**
		 * this function will create the worksheet in foodtable,  on google excel, so it should only be called if it doesn't exist yet<br>
		 * it will mark this instance of the app as the creator of the foodtable
		 */
		private function googleExcelCreateWorkSheet(event:Event = null):void  {
			var request:URLRequest;
			
			if (event != null)  {
				//ASSUMING HERE THAT EVERHTHING WORKS FINE, BUT THINGS COULD BE GOING WRONG
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				//Settings.getInstance().setSetting(Settings.SettingsIMtheCreateorOfGoogleExcelFoodTable,"true");
				
				//ASSUMING HERE THAT WORKSHEET CREATION WAS SUCCESSFULL, WHICH IS NOT SURE
				var cratedWorkSheetAsXML:XML = new XML(event.target.data as String);
				//info about namespaces found on http://userflex.files.wordpress.com/2008/06/getstatuscodeas.pdf and http://userflex.wordpress.com/2008/04/03/xml-ns-e4x/
				var xmlns : Namespace;
				// namespace declarations defined in the xml
				var namespaces : Array = cratedWorkSheetAsXML.namespaceDeclarations();
				// looks for the default namespace, i know that entry is in the default namespace, so that's what i'm looking for
				for each (var ns : Namespace in namespaces)
				{
					if (ns.prefix == "")//there's two other in this kind of xml that google returns : openSearch and gs but I don't need xml objects of that kind
					{
						xmlns = ns;
						break;
					}
				}
				
				
				//ASSUMING HERE THAT EVERHTHING WORKS FINE, BUT THINGS COULD BE GOING WRONG
				helpDiabetesWorkSheetId = cratedWorkSheetAsXML..xmlns::id;
				var helpdiabetesWorkSheetIdSplitted:Array = helpDiabetesWorkSheetId.split("/");
				helpDiabetesWorkSheetId = helpdiabetesWorkSheetIdSplitted[helpdiabetesWorkSheetIdSplitted.length - 1];
				
				if (helpDiabetesWorkSheetId == "") {
					//we can say here that something went wrong with the creation of the worksheet
					//we'll stop but say that sync was successful, because that already ended successfully, it's just the creation of the worksheet that failed
					syncFinished(true);
					return;
				} else {
					googleExcelCreateHeader(null);
				}
			} else {
				if (traceNeeded)
					trace("start method googleExcelCreateWorkSheet");
				var outputString:String = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
				outputString += '<entry xmlns="http://www.w3.org/2005/Atom\" xmlns:gs=\"http://schemas.google.com/spreadsheets/2006">\n';
				outputString += '    <title>foodtable</title>\n';
				outputString += '        <gs:rowCount>' + ModelLocator.getInstance().foodItemList.length + '</gs:rowCount>';
				outputString += '        <gs:colCount>' + googleExcelGoodTableColumnNames.length + '</gs:colCount>';
				outputString += '</entry>\n';
				outputString = outputString.replace(/\n/g, File.lineEnding);
				
				request = new URLRequest(googleExcelCreateWorkSheetUrl.replace("{key}",helpDiabetesSpreadSheetKey));
				request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				request.requestHeaders.push(new URLRequestHeader("Content-Type","application/atom+xml"));
				
				
				request.data = outputString;
				request.method = URLRequestMethod.POST;
				
				loader = new URLLoader();
				functionToRecall = googleExcelCreateWorkSheet;
				loader.addEventListener(Event.COMPLETE,googleExcelCreateWorkSheet);
				functionToRemoveFromEventListener = googleExcelCreateWorkSheet;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded)
					trace("loader : request = " + request.data); 
			}
		}
		
		/**
		 *  deletes "sheet 1" from the foodtable spreadsheet<br>
		 * goal is that this can run in parallel with other calls op google docs, so it will not listen to events
		 */
		private function googleExcelDeleteWorkSheet1():void {
			if (googleExcelDeleteWorkSheetUrl == "")
				return;
			
			var request:URLRequest;
			if (traceNeeded)
				trace("start method googleExcelDeleteWorkSheet1");
			request = new URLRequest(googleExcelDeleteWorkSheetUrl);//.replace("{key}",helpDiabetesSpreadSheetKey).replace("{worksheetid}",helpDiabetesWorkSheetIDOfSheet1));
			googleExcelDeleteWorkSheetUrl = "";
			request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
			request.requestHeaders.push(new URLRequestHeader("X-JavaScript-User-Agent", "Google APIs Explorer"));
			request.contentType = "application/x-www-form-urlencoded";
						
			request.method = URLRequestMethod.DELETE;
			loader = new URLLoader();
			//functionToRecall = ;not changing becaues this might be running in parallel with otheer calls
			//loader.addEventListener(Event.COMPLETE,googleExcelFindFoodTableWorkSheet);
			//functionToRemoveFromEventListener = googleExcelFindFoodTableWorkSheet;
			//loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
			loader.load(request);
			if (traceNeeded)
				trace("loader : request = " + request.data); 
			

		}
		
		private function googleExcelFindFoodTableWorkSheet(event:Event = null):void {
			var request:URLRequest;
			if (event != null)  {
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				
				var workSheetListAsXML:XML = new XML(event.target.data as String);
				//info about namespaces found on http://userflex.files.wordpress.com/2008/06/getstatuscodeas.pdf and http://userflex.wordpress.com/2008/04/03/xml-ns-e4x/
				var xmlns : Namespace;
				// namespace declarations defined in the xml
				var namespaces : Array = workSheetListAsXML.namespaceDeclarations();
				// looks for the default namespace, i know that entry is in the default namespace, so that's what i'm looking for
				for each (var ns : Namespace in namespaces)
				{
					if (ns.prefix == "")//there's two other in this kind of xml that google returns : openSearch and gs but I don't need xml objects of that kind
					{
						xmlns = ns;
						break;
					}
				}
				
				var entryXMLList:XMLList = new XMLList(workSheetListAsXML..xmlns::entry);
				
				for (var listCounter:int = 0 ; listCounter < entryXMLList.length();listCounter++)  {
					var titleXML:XMLList = entryXMLList[listCounter]..xmlns::title;
					if (entryXMLList[listCounter]..xmlns::title == "foodtable") {
						helpDiabetesWorkSheetId = entryXMLList[listCounter]..xmlns::id;
						var helpdiabetesWorkSheetIdSplitted:Array = helpDiabetesWorkSheetId.split("/");
						helpDiabetesWorkSheetId = helpdiabetesWorkSheetIdSplitted[helpdiabetesWorkSheetIdSplitted.length - 1];
						
					}
					if (entryXMLList[listCounter]..xmlns::title == "Sheet 1") {
						var linkListForThisentryXMLList:XMLList = new XMLList(entryXMLList[listCounter]..xmlns::link);
						for (var linkListCounter:int = 0; linkListCounter < linkListForThisentryXMLList.length();linkListCounter++)  {
							if (linkListForThisentryXMLList[linkListCounter].attribute("rel"))  {
								if (linkListForThisentryXMLList[linkListCounter].attribute("rel") == "edit")  {
									googleExcelDeleteWorkSheetUrl = linkListForThisentryXMLList[linkListCounter].attribute("href"); 
								}
							}
						}
					}
				}
				if (googleExcelDeleteWorkSheetUrl != "")  {
					googleExcelDeleteWorkSheet1();
				}
				
				if (helpDiabetesWorkSheetId == "") {
					//we'll have to create the worksheet but it could also be that we have to recreate the worksheet, in which case we reset columns to add to 0
					Settings.getInstance().setSetting(Settings.SettingsNextColumnToAdd,"0");
					googleExcelCreateWorkSheet(null);
					return;
				} else {
					googleExcelCreateHeader(null);
				}
				
			} else {
				if (traceNeeded)
					trace("start method googleExcelFindFoodTableWorkSheet");
				request = new URLRequest(googleExcelFindFoodTableWorkSheetUrl.replace("{key}",helpDiabetesSpreadSheetKey));
				request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				request.requestHeaders.push(new URLRequestHeader("X-JavaScript-User-Agent", "Google APIs Explorer"));
				request.contentType = "application/x-www-form-urlencoded";
				
				request.method = URLRequestMethod.GET;
				loader = new URLLoader();
				functionToRecall = googleExcelFindFoodTableWorkSheet;
				loader.addEventListener(Event.COMPLETE,googleExcelFindFoodTableWorkSheet);
				functionToRemoveFromEventListener = googleExcelFindFoodTableWorkSheet;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded)
					trace("loader : request = " + request.data); 
			}
		}
		
		
		/**
		 * will try to find the foodtable spreadsheet in google docs account<br>
		 * if not found then googleExcelCreateFoodTable will be called<br>
		 * if found and if imthecreater, then proceed to findfoodtableworksheet<br>
		 * if found and im not the creator, then syncfinished. 
		 */
		private function googleExcelFindFoodTableSpreadSheet(event:Event = null):void  {
			var request:URLRequest;
			if (event != null)  {
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				if  (eventAsJSONObject.error) {
					
					if (eventAsJSONObject.error.message == googleError_Invalid_Credentials && !secondAttempt) {
						secondAttempt = true;
						functionToRecall = googleExcelFindFoodTableSpreadSheet;
						functionToRemoveFromEventListener = null;
						googleAPICallFailed(event);
					} else {
						//some other kind of yet unidentified error 
					}
				} else {
					if (eventAsJSONObject.items)  {
						if (eventAsJSONObject.items.length > 0)  {
							//foodtable found
							if (Settings.getInstance().getSetting(Settings.SettingsIMtheCreateorOfGoogleExcelFoodTable) == "true")  {
								helpDiabetesSpreadSheetKey = eventAsJSONObject.items[0].id;
								googleExcelFindFoodTableWorkSheet();
							} else {
								//this instance has not created the foodtable
								syncFinished(true);
							}
						} else {
							googleExcelCreateFoodTable();
							Settings.getInstance().setSetting(Settings.SettingsNextColumnToAdd,"0");
						}
					} else  {
						googleExcelCreateFoodTable();
						Settings.getInstance().setSetting(Settings.SettingsNextColumnToAdd,"0");
					}
				}
			} else {
				if (traceNeeded)
					trace("start method googleExcelFindFoodTableSpreadSheet");
				request = new URLRequest(googleDriveFilesUrl);
				request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				request.requestHeaders.push(new URLRequestHeader("X-JavaScript-User-Agent", "Google APIs Explorer"));
				request.contentType = "application/x-www-form-urlencoded";
				var urlVariables:URLVariables = new URLVariables();
				
				urlVariables.q = "title = '" + foodtableName + "'";
				request.data = urlVariables;
				request.method = URLRequestMethod.GET;
				loader = new URLLoader();
				functionToRecall = googleExcelFindFoodTableSpreadSheet;
				loader.addEventListener(Event.COMPLETE,googleExcelFindFoodTableSpreadSheet);
				functionToRemoveFromEventListener = googleExcelFindFoodTableSpreadSheet;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded)
					trace("loader : request = " + request.data); 
			}
		}
		
		/**
		 * to call when sync has finished 
		 */
		private function syncFinished(success:Boolean):void {
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			if (success) {
				//ModelLocator.getInstance().logString += "sync successful" + "\n";
				Settings.getInstance().setSetting(Settings.SettingsLastSyncTimeStamp,currentSyncTimeStamp.toString());
				lastSyncTimeStamp = currentSyncTimeStamp;
				
				if (localElementsUpdated) {
					localElementsUpdated = false;
					if (!trackingListAlreadyModified) {//this may be the case, eg when adding remote elements to local database, we don't update the trackinglist, but still elementsupdated = true
						trackingListAlreadyModified = true;
						ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
					}
					
					ModelLocator.getInstance().trackingList = new ArrayCollection();
					
					localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,getAllEventsAndFillUpMealsFinished);
					localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,getAllEventsAndFillUpMealsFinished);//don't see what to do in case of error
					
					Database.getInstance().getAllEventsAndFillUpMeals(localdispatcher);
				}
			} else {
				if (localElementsUpdated) {
					if (!trackingListAlreadyModified) {//this may be the case, eg when adding remote elements to local database, we don't update the trackinglist, but still elementsupdated = true
						trackingListAlreadyModified = true;
						ModelLocator.getInstance().copyOfTrackingList = new ArrayCollection();
					}
					ModelLocator.getInstance().trackingList = new ArrayCollection();
					localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,getAllEventsAndFillUpMealsFinished);
					localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,getAllEventsAndFillUpMealsFinished);//don't see what to do in case of error
					Database.getInstance().getAllEventsAndFillUpMeals(localdispatcher);
				}
			}
			
			if (rerunNecessary) {
				currentSyncTimeStamp = new Date().valueOf();
				asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;
				syncRunning = true;
				rerunNecessary = false;
				synchronize();
			} else {
				syncRunning = false;
			}
			
			function getAllEventsAndFillUpMealsFinished(event:Event):void
			{
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT, getAllEventsAndFillUpMealsFinished);
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT, getAllEventsAndFillUpMealsFinished);
				ModelLocator.getInstance().trackingList.refresh();
				
				ModelLocator.getInstance().refreshMeals();
				ModelLocator.getInstance().copyOfTrackingList = ModelLocator.getInstance().trackingList;
				// now populate ModelLocator.getInstance().meals
			}
		}
		
		public function addObjectToBeDeleted(object:Object):void {
			listOfElementsToBeDeleted.addItem(object);
		}
	}
}


