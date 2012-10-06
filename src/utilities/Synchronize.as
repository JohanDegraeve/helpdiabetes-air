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
	
	import databaseclasses.MedicinEvent;
	import databaseclasses.Settings;
	
	import flash.data.SQLStatement;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
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
		private static var googleTokenRefreshUrl:String = "https://accounts.google.com/o/oauth2/token";
		/**
		 * the maximum number of tables when asking list of tables, 25 is also the default value that google applies.<br>
		 */
		private static var maxResults:int = 2;
		
		/**
		 * how many minutes between two synchronisations 
		 */
		private static var minutesBetweenTwoSync = 1;
		
		private static var googleError_Invalid_Credentials:String = "Invalid Credentials";
		
		private const GET_ALLMEDICINEVENTS:String = "SELECT * FROM medicinevents";
		
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
					["deleted","STRING"]//was the event deleted or not
				],
				"MedicinEvents"//description
			]
		];
		
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
		 * actually each element will be an array with two numbers, first the eventid, secondly the rowid if already retrieved and found, if not null as second element
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
		
		/**
		 * constructor not to be used, get an instance with getInstance() 
		 */
		public function Synchronize()
		{
			if (instance != null) {
				throw new Error("Synchronize class can only be accessed through Synchronize.getInstance()");	
			}
			trackingList = ModelLocator.getInstance().trackingList;
			syncRunning = false;
			rerunNecessary = false;
			amountofSpaces = 0;
			instance = this;
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
			tracker = callingTracker;

			lastSyncTimeStamp = new Number(Settings.getInstance().getSetting(Settings.SettingsLastSyncTimeStamp));
			currentSyncTimeStamp = new Date().valueOf();
			asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;

			var timeSinceLastSyncMoreThanXMinutes:Boolean = (new Date().valueOf() - lastSyncTimeStamp) > minutesBetweenTwoSync * 60 * 1000;
			if ((syncRunning && (timeSinceLastSyncMoreThanXMinutes))  || (!syncRunning && (immediateRunNecessary || timeSinceLastSyncMoreThanXMinutes))) {
				rerunNecessary = false;
				currentSyncTimeStamp = new Date().valueOf();
				asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;
				synchronize();
			} else {
				if (immediateRunNecessary)
					rerunNecessary = true;
			}
		}
		
		/**
		 * if there's no valid access_token or refresh_token, then this method will do nothing<br>
		 * if there's a valid access_token or refresh_token, then this method will synchronize the database with 
		 * Google Fusion Tables 
		 */
		private function synchronize():void {
			//we could be arriving here after a retempt, example, first time failed due to invalid credentials, token refresh occurs, with success, we come back to here
			//first thing to do is to removeeventlisteners
			
			access_token = Settings.getInstance().getSetting(Settings.SettingsAccessToken);
			if (access_token.length == 0) {
				//there's no access_token, and that means there should also be no refresh_token, so it's not possible to synchronize
				syncFinished(false);
			} 
			
			if (tracker != null)
				tracker.trackPageview( "Synchronize-SyncStarted" );
			

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
			if (traceNeeded)
				trace("loader : request = " + request.data); 
		}
		
		private function tablesListRetrieved(event:Event):void {
			loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
			loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
			var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
			nextPageToken = eventAsJSONObject.nextPageToken;
			if (eventAsJSONObject.items) {
				//there are table names retrieved, let's go through them
				for (var i:int = 0;i < eventAsJSONObject.items.length;i++) {
					//go through each item, see if name matches one in the tablelist, if so store tableid
					for (var j:int = 0;j < tableNamesAndColumnNames.length;j++) {
						if (eventAsJSONObject.items[i].name == tableNamesAndColumnNames[j][0]) {
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
		
		private function createMissingTables(event:Event = null): void {
			if (event != null) {
				//here we come if actually a table has just been created and an Event.COMPLETE is dispatched to notify the completion.
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				for (var k:int = 0;k < tableNamesAndColumnNames.length;k++) {
					if (tableNamesAndColumnNames[k][0] == eventAsJSONObject.name as String) {
						tableNamesAndColumnNames[k][1] = eventAsJSONObject.tableId as String;
						break;//we have to create this table so break the loop
					}
				}
			} 
			
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
		
		private function startSync():void {
			
			localElements = new ArrayList();
			remoteElements = new ArrayList();
			remoteElementIds = new ArrayList();
			nextPageToken = null;//not sure if nextPageToken is used by google when doing a select
			getTheMedicinEvents();
		}
		
		private function getTheMedicinEvents(event:Event = null):void {
			var positionId:int;
			var positionMedicinname;
			var positionValue;
			var positionCreationTimeStamp;
			var positionModifiedTimeStamp;
			var positionDeleted;
			
			//start with remoteElements
			//I'm assuming here that the nextpagetoken principle will be used by google, not sure however
			if (event != null) {
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);

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
				
				if (eventAsJSONObject.rows) {
					for (var rowctr:int = 0;rowctr < eventAsJSONObject.rows.length;rowctr++) {
						remoteElements.addItem(eventAsJSONObject.rows[rowctr]);
						remoteElementIds.addItem([new Number(eventAsJSONObject.rows[rowctr][positionId]),null]);
					}
				}

				nextPageToken = eventAsJSONObject.nextPageToken;
			} 
			
			if (event == null || nextPageToken != null) {//two reasons to try to fetch data from google
				var request:URLRequest = new URLRequest(googleSelectUrl);
				request.contentType = "application/x-www-form-urlencoded";
				var urlVariables:URLVariables = new URLVariables();
				request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				
				urlVariables.sql = createSQLQueryToSelectAll(0);
				if (nextPageToken != null)
					urlVariables.pageToken = nextPageToken;
				request.data = urlVariables;
				request.method = URLRequestMethod.GET;
				loader = new URLLoader();
				functionToRecall = getTheMedicinEvents;
				loader.addEventListener(Event.COMPLETE,getTheMedicinEvents);
				functionToRemoveFromEventListener = getTheMedicinEvents;
				loader.addEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				loader.load(request);
				if (traceNeeded)
					trace("loader : request = " + request.data); 
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
								if (new Number((remoteElements.getItemAt(k) as Array)[positionModifiedTimeStamp]) < (localElements.getItemAt(j) as MedicinEvent).lastModifiedTimestamp) {
									remoteElements.removeItemAt(k);
									//remoteElementIds.removeItemAt(k);
									break;
								} else {
									localElements.removeItemAt(j);
									j--;
									break;
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
				//only update the locals, the remote's will be done later all together (with exercise, medicin, meals)
				for (var m:int = 0; m < remoteElements.length; m++) {
					//we have to find the medicinevent in the trackinglist that has the same id
					var l:int=0;
					for (l = 0; l < trackingList.length;l++) {
						if (trackingList.getItemAt(l) is MedicinEvent) {
							if ((trackingList.getItemAt(l) as MedicinEvent).eventid == remoteElements.getItemAt(m)[positionId] ) {
								(trackingList.getItemAt(l) as MedicinEvent).updateMedicinEvent(
									remoteElements.getItemAt(m)[positionMedicinname],
									remoteElements.getItemAt(m)[positionValue],
									new Number(remoteElements.getItemAt(m)[positionCreationTimeStamp]),
									new Number(remoteElements.getItemAt(m)[positionModifiedTimeStamp]));
								break;
							}
						}
					}
					if (l == trackingList.length) {
						//var asstirng:String = dateTimeFormatterForQueryResult.format(remoteElements.getItemAt(m)[positionCreationTimeStamp]);
						//var nr:Number = Date.parse(dateTimeFormatterForQueryResult.format(remoteElements.getItemAt(m)[positionCreationTimeStamp]));
						//it means we didn't find the remotelement in the trackinglist, so we need to create it
						trackingList.addItem(new MedicinEvent(
							remoteElements.getItemAt(m)[positionValue],
							remoteElements.getItemAt(m)[positionMedicinname],
							remoteElements.getItemAt(m)[positionId],
							new Number(remoteElements.getItemAt(m)[positionCreationTimeStamp]),
							new Number(remoteElements.getItemAt(m)[positionModifiedTimeStamp]),
							true));
					}
				}
				//let's go for the localevents
				getRowIds(null);
			}
		}
		
		/**
		 * we need to get the rowids for all localevents that have a remote copy, we need to do that to be able to update 
		 */
		private function getRowIds(event:Event):void {
			if (event != null) {
				loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
				loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
				var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				
				/*if (eventAsJSONObject.columns)
					if (eventAsJSONObject.columns is Array)
						if ((eventAsJSONObject.columns as Array).length > 0)
							if ((eventAsJSONObject.columns as Array)[0] == "rowid")*/
				remoteElementIds.getItemAt(indexOfRetrievedRowId)[1] =  new Number(eventAsJSONObject.rows[0][0]);
			} 
			
			var sqlStatement:String = "";
			var elementFoundWithSameId:Boolean = false;
			for (var i:int = 0;i < localElements.length; i++) {
				if (localElements.getItemAt(i) is MedicinEvent) {//later on we will add exerciseevents, ...
					for (var j:int = 0;j < remoteElementIds.length; j++) {
						if ((localElements.getItemAt(i) as TrackingViewElement).eventid == remoteElementIds.getItemAt(j)[0]) {
							elementFoundWithSameId = true;
							if (!remoteElementIds.getItemAt(j)[1]) {
								sqlStatement = "SELECT ROWID FROM " + tableNamesAndColumnNames[0][1] + " WHERE id = \'" + (localElements.getItemAt(i) as TrackingViewElement).eventid + "\'";
								i = localElements.length;
								indexOfRetrievedRowId = j;
							}
							j = remoteElementIds.length;
						}
					}
				}  else {
					//here to continue with other kinds of events							
				}
			}
			
			if (sqlStatement.length == 0) {
				syncLocalEvents(null);
			} else {
				var request:URLRequest = new URLRequest(googleSelectUrl);
				request.contentType = "application/x-www-form-urlencoded";
				var urlVariables:URLVariables = new URLVariables();
				request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				
				urlVariables.sql = sqlStatement;
				request.data = urlVariables;
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
			if (localElements.length > 0) {
				var request:URLRequest = new URLRequest(googleSelectUrl);
				request.requestHeaders.push(new URLRequestHeader("Authorization", "Bearer " + access_token ));
				request.contentType = "application/x-www-form-urlencoded";
				
				//start with the medicinevents
				var sqlStatement:String = "";
				var i:int = 0;
				while (i < localElements.length) {
					//goal is to insert only elements that are not yet found in remoteelements, those will need updates later on iso inserts
					if (localElements.getItemAt(i) is MedicinEvent) {//later on we will add exerciseevents, ...
						var elementFoundWithSameId:Boolean = false;
						for (var j:int = 0;j < remoteElementIds.length; j++) {
							if ((localElements.getItemAt(i) as MedicinEvent).eventid == remoteElementIds.getItemAt(j)[0]) {
								elementFoundWithSameId = true;
								j = remoteElementIds.length;
							}
						}
						if (!elementFoundWithSameId) {
							sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "INSERT INTO " + tableNamesAndColumnNames[0][1] + " ";
							sqlStatement += "(id,medicinname,value,creationtimestamp,modifiedtimestamp,deleted) VALUES (\'" +
								(localElements.getItemAt(i) as MedicinEvent).eventid.toString() + "\',\'" +
								(localElements.getItemAt(i) as MedicinEvent).medicinName + "\',\'" +
								(localElements.getItemAt(i) as MedicinEvent).amount.toString() + "\',\'" +
								(localElements.getItemAt(i) as MedicinEvent).timeStamp.toString() + "\',\'" +
								(localElements.getItemAt(i) as MedicinEvent).lastModifiedTimestamp.toString() + "\'," +
								"\'false\')";
							localElements.removeItemAt(i);
							i--;
						}
					}  else {
						//here to continue with other kinds of events							
					}
					i++;
				}
				
				//if we haven't found new events, then we need to update all remaining, if any off course
				if (sqlStatement.length == 0) {
					var k:int = 0;
					while (k < localElements.length) {
						//goal is to update all remaining events
						if (localElements.getItemAt(k) is MedicinEvent) { //later on we will add exerciseevents, ...
							for (var l:int = 0;l < remoteElementIds.length; l++) {
								if ((localElements.getItemAt(k) as MedicinEvent).eventid == remoteElementIds.getItemAt(l)[0]) {
									sqlStatement += (sqlStatement.length == 0 ? "" : ";") + "UPDATE " + tableNamesAndColumnNames[0][1] + " SET ";
									sqlStatement += 
										"id = \'" + (localElements.getItemAt(k) as MedicinEvent).eventid.toString() + "\'," +
										"medicinname = \'" + (localElements.getItemAt(k) as MedicinEvent).medicinName + "\'," +
										"value = \'" + (localElements.getItemAt(k) as MedicinEvent).amount.toString() + "\'," +
										"creationtimestamp = \'" + (localElements.getItemAt(k) as MedicinEvent).timeStamp.toString() + "\'," +
										"modifiedtimestamp = \'" + (localElements.getItemAt(k) as MedicinEvent).lastModifiedTimestamp.toString() + "\'," +
										"deleted = \'false\' WHERE ROWID = \'" +
										remoteElementIds.getItemAt(l)[1] + "\'";
									
									localElements.removeItemAt(k);
									k--;//reducing k because we just removed one element
									
									l = remoteElementIds.length;//it's not necessary to go through the rest of the remotelementids
								}
							}
						}  else {
							//here to continue with other kinds of events							
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
				syncFinished(true);
			}
			//there should not be code here
		}
		
		private function googleAPICallFailed(event:Event):void {
			loader.removeEventListener(Event.COMPLETE,functionToRemoveFromEventListener);
			loader.removeEventListener(IOErrorEvent.IO_ERROR,googleAPICallFailed);
			
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
				} else
					syncFinished(false);
			} catch (e:SyntaxError) {
				//event.taregt.data is not json
				if (event.type == "ioError") {
					//an ioError, forget about it, the show doesn't go on
					syncFinished(false);
				}
			}
			syncFinished(false);
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
			
			returnValue = 
				"SELECT * FROM " + spaces +
				tableNamesAndColumnNames[index][1] +
				" WHERE modifiedtimestamp >= '" + lastSyncTimeStamp.toString() + "'" + " AND " +
				"creationtimestamp >= '" + asOfTimeStamp.toString() + "'";
			trace("querystring = " + returnValue);
			return returnValue;
		}
		
		/**
		 * to call when sync has finished 
		 */
		private function syncFinished(success:Boolean):void {
			if (success) {
				Settings.getInstance().setSetting(Settings.SettingsLastSyncTimeStamp,currentSyncTimeStamp.toString());
				lastSyncTimeStamp = currentSyncTimeStamp;
			} else {
				
			}
			if (rerunNecessary) {
				currentSyncTimeStamp = new Date().valueOf();
				asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;
				syncRunning = true;
				rerunNecessary = false;
				synchronize();
			} else  {
				syncRunning = false;
			}
		}
	}
	
}


