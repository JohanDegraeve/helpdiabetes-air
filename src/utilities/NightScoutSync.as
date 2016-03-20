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
 
 */package utilities
 {
	 import flash.events.Event;
	 import flash.events.EventDispatcher;
	 import flash.events.IOErrorEvent;
	 import flash.events.TimerEvent;
	 import flash.net.URLLoader;
	 import flash.net.URLRequest;
	 import flash.net.URLRequestHeader;
	 import flash.net.URLRequestMethod;
	 import flash.net.URLVariables;
	 import flash.utils.Timer;
	 
	 import mx.collections.ArrayCollection;
	 import mx.collections.ArrayList;
	 import mx.resources.ResourceManager;
	 
	 import spark.formatters.DateTimeFormatter;
	 
	 import databaseclasses.BloodGlucoseEvent;
	 import databaseclasses.Database;
	 import databaseclasses.DatabaseEvent;
	 import databaseclasses.ExerciseEvent;
	 import databaseclasses.Meal;
	 import databaseclasses.MealEvent;
	 import databaseclasses.MedicinEvent;
	 import databaseclasses.SelectedFoodItem;
	 import databaseclasses.Settings;
	 import databaseclasses.Unit;
	 
	 import model.ModelLocator;
	 
	 import myComponents.TrackingViewElement;
	 
	 import views.TrackingView;
	 
	 /**
	  * class with function to synchronize with NightScout<br>
	  * BG meter results, meals and medicin events<br> 
	  *
	  */
	 
	 public class NightScoutSync extends EventDispatcher
	 {
		 [ResourceBundle("analytics")]
		 private static var instance:NightScoutSync = new NightScoutSync();
		 private var debugMode:Boolean;
		 private var alReadyGATracked:Boolean;
		 private var timer2:Timer;
		 private var localElementsUpdated:Boolean;
		 private var retrievalCounter:int;
		 private var nightScoutError_Invalid_Credentials:String = "TO BE COMPLETED";
		 private var secondAttempt:Boolean;
		 public static var syncErrorList:ArrayList;
		 /**
		  * when a function tries to access nightscout api, but that fails ... to be completed<br>
		  * copied from google sync which works with access_tokens that need to be refreshed, not necessary here
		  * maybe we can also use it, eg in case of timeout, retry once
		  */
		 private var functionToRecall:Function;
		 
		 /**
		  * wil be equal to modellocator.trackinglist, it's just to avoid that I need to type to much 
		  */
		 private var trackingList:ArrayCollection;
		 /**
		  * copied from settings at start of sync, timestamp of last synchronisation 
		  */
		 private var lastSyncTimeStamp:Number;
		 /**
		  * this is the earliest creationtimestamp of the events that will be taken into account 
		  */
		 private var asOfTimeStamp:Number
		 
		 /**
		  * how many seconds between two synchronisations, normal value
		  */
		 private static var normalValueForSecondsBetweenTwoSync:int = 30;
		 
		 /**
		  * list of elements that need to be deleted in remote database 
		  */
		 private var listOfElementsToBeDeleted:ArrayList;
		 /**
		  * list of objects found in local database
		  */
		 private var localElements:ArrayList;
		 /**
		  * list of elements found in remote database<br>
		  * this will also be the list of elements that needs to be updated/created remotely, ie there can be elements retrieved, that need update. 
		  * Those elements will be stored in remoteElements, updated in remoteElements , and later on those elements will be put back to NightScout<br>
		  * Elements that don't need update will be removed from the list
		  */
		 private var remoteElements:ArrayList;
		 
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
		 private var nightScoutSyncRunning:Boolean;
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
		 
		 /**
		  * used in deleteRemoteItems 
		  */
		 private var elementToBeDeleted:Object;
		 private var loader:URLLoader;
		 private var trackingListAlreadyModified:Boolean;
		 private var previousTrackingEventToShow:String;
		 
		 private static var hashedApiSecret:String = "";
		 private static var nightScoutTreatmentsUrl:String = "";
		 /**
		  * how many seconds between two synchronisations, actual value
		  */
		 private var secondsBetweenTwoSync:int = 30;
		 private var remoteElementToBeAdaptedInDeleteRemoteObjects:Object;
		 private var tempStoreLocalElementForDeleteRemoteObjects:Object;
		 
		 public function NightScoutSync()
		 {
			 if (instance != null) {
				 throw new Error("NightScoutSync class can only be accessed through NightScoutSync.getInstance()");	
			 }
			 debugMode = ModelLocator.debugMode;
			 
			 nightScoutSyncRunning = false;
			 
			 rerunNecessary = false;
			 
			 alReadyGATracked = false;//only one google analytics tracking per instance
			 listOfElementsToBeDeleted = new ArrayList();
			 instance = this;
			 currentSyncTimeStamp = 0;
			 syncErrorList = new ArrayList();
		 }
		 
		 public static function getInstance():NightScoutSync {
			 if (instance == null) instance = new NightScoutSync();
			 return instance;
		 }
		 
		 /**
		  * If  (syncRunning is true and currentSyncTimeStamp > 30 seconds ago) or  (syncRunning is false & (immediateRunNecessary or currentSyncTimeStamp > 30 seconds ago)), then run the sync, reset timestamp of startrun to current time, 
		  * set rerunnecessary to false<br>
		  * <br>
		  * If  (syncRunning is true and currentSyncTimeStamp < 30 seconds ago) don't run, if immediateRunNecessary set rerunNecessary to true; else don't set anything.<br>
		  * onlySyncTheSettings =  if true synchronize will jump immediately to syncing the settings, assuming all tables are already there. Should only be true if it's sure that tables are existing on google docs account
		  */
		 public function startNightScoutSync(immediateRunNecessary:Boolean):void {
			 //first check if we have a (not necessariliy valid) api-secret, if not we stop
			 hashedApiSecret = Settings.getInstance().getSetting(Settings.SettingsNightScoutHashedAPISecret);
			 if (hashedApiSecret == "" || hashedApiSecret == "true") {
				 syncFinished(false);
			 } else {
				 //let's calculate the url, it might have changed
				 nightScoutTreatmentsUrl = "https://" + Settings.getInstance().getSetting(Settings.SettingsNightScoutWebsiteURL) + "/api/v1/treatments";
				 if (timer2 != null) {
					 if (timer2.hasEventListener(TimerEvent.TIMER))
						 timer2.removeEventListener(TimerEvent.TIMER,startNightScoutSync);
					 timer2.stop();
					 timer2 = null;
				 }
				 
				 
				 if (Settings.getInstance().getSetting(Settings.SettingsDayOfLastCompleteNightScoutSync) == "-1") {
					 Settings.getInstance().setSetting(Settings.SettingsLastNightScoutSyncTimeStamp,
						 ( (
							 (new Date()).valueOf() 
							 - 
							 new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000
						 ).toString()
						 )
					 );
					 Settings.getInstance().setSetting(Settings.SettingsDayOfLastCompleteNightScoutSync,(new Date()).date.toString());//not correct in case the sync fails
				 } else {
					 //to make sure there's at least one complete resync per day
					 if ((new Date()).date != new Number(Settings.getInstance().getSetting(Settings.SettingsDayOfLastCompleteNightScoutSync))) {
						 Settings.getInstance().setSetting(Settings.SettingsLastNightScoutSyncTimeStamp,
							 ( (
								 (new Date()).valueOf() 
								 - 
								 2 * 24 * 3600 * 1000 // resyncing only the last two days because nightscoutsync has the bad behaviour of putting all objects back to ns, even if it already exists up there
								 //that's a consequence of not being able to use lastmodifiedtimestamp
							 ).toString()
							 )
						 );
						 Settings.getInstance().setSetting(Settings.SettingsDayOfLastCompleteNightScoutSync,(new Date()).date.toString());//not correct in case the sync fails
					 }
				 }
				 
				 var timeSinceLastSyncMoreThanXMinutes:Boolean = (new Date().valueOf() - currentSyncTimeStamp) > normalValueForSecondsBetweenTwoSync * 1000;
				 
				 if ((nightScoutSyncRunning && (timeSinceLastSyncMoreThanXMinutes))  || (!nightScoutSyncRunning && (immediateRunNecessary || timeSinceLastSyncMoreThanXMinutes))) {
					 localElementsUpdated  = false;
					 retrievalCounter = 0;
					 trackingList = ModelLocator.trackingList;
					 currentSyncTimeStamp = new Date().valueOf();
					 lastSyncTimeStamp = new Number(Settings.getInstance().getSetting(Settings.SettingsLastNightScoutSyncTimeStamp));
					 if (debugMode) 
						 trace("NightScoutSync.as : lastsynctimestamp = " + new DateTimeFormatter().format(new Date(lastSyncTimeStamp)));
					 asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;
					 rerunNecessary = false;
					 nightScoutSyncRunning = true;
					 currentSyncTimeStamp = new Date().valueOf();
					 asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;
					 
					 trace("NightScoutSync.as : starting startNightScoutSync");
					 synchronize();
				 } else {
					 if (immediateRunNecessary) {
						 rerunNecessary = true;
					 }
				 }
				 
				 if (timer2 == null) {
					 timer2 = new Timer(300000, 1);
					 timer2.addEventListener(TimerEvent.TIMER, startNightScoutSync);
					 timer2.start();
				 }
			 }
			 
		 }
		 
		 private function synchronize():void {
			 if (debugMode)
				 trace("NightScoutSync.as : in synchronize");
			 localElements = new ArrayList();
			 trackingListAlreadyModified = false;
			 
			 remoteElements = new ArrayList();
			 //remoteElementIds = new ArrayList();
			 secondAttempt = false;
			 getAllEvents();
		 }
		 
		 public function addObjectToBeDeleted(object:Object):void {
			 if (hashedApiSecret == "" || hashedApiSecret == "true") {
			 } else {
				 listOfElementsToBeDeleted.addItem(object);
			 }
		 }
		 
		 /**
		  * will start deleting all the items in listofElementsToBeDeleted<br>
		  */
		 private function deleteRemoteItems(event:Event = null):void {
			 if (event != null) {
				 if (debugMode)
					 trace("NightScoutSync.as : in method deleteRemoteItems, there's a deletion result to be processed");
				 removeEventListeners();
				 var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				 //DEBUGGEN WAT HIER UIT KOMT EN HOE CONTROLEREN OF HET SUCCESVOL WAS EN EVENTUELE FOUTBEHANDELING DOEN
				 if (0 == 0) {
					 if (elementToBeDeleted != null)
						 listOfElementsToBeDeleted.removeItem(elementToBeDeleted);
				 } else {
					 //hier de foutjes behandelen
				 }
			 }
			 if (listOfElementsToBeDeleted.length > 0) {
				 elementToBeDeleted = listOfElementsToBeDeleted.getItemAt(0);
				 if (elementToBeDeleted is SelectedFoodItem) {
					 //Don't delete the selectedfooditem @ ns (because there isn't any), but set lastmodifiedtimestamp of the parentmeal to that of the fooditem
					 //next sync the mealevent will be uploaded
					 for (var i:int = 0; i < trackingList.length; i++) {
						 if ((trackingList.getItemAt(i) as TrackingViewElement).eventid == (elementToBeDeleted as SelectedFoodItem).mealEventId) {
							 (trackingList.getItemAt(i) as MealEvent).lastModifiedTimestamp = (new Date()).valueOf();
							 break;
						 }
					 }
					 listOfElementsToBeDeleted.removeItem(elementToBeDeleted);
					 deleteRemoteItems();
				 } else {
					 if (debugMode)
						 trace("NightScoutSync.as : in method deleteRemoteItems, there's an alement to be deleted");
					 //if the lengthe of the eventid is less than 24, then it's an  old element that was 'downloaded' from google sync, we will skip it
					 if ((elementToBeDeleted as TrackingViewElement).eventid.length < 24 || (elementToBeDeleted as TrackingViewElement).eventid.indexOf("HelpDiabet") > -1) {
						 listOfElementsToBeDeleted.removeItem(elementToBeDeleted);
						 deleteRemoteItems();
					 } else {
						 //it could be that this element is part of another larger object at NS, in this case we don't delete but update
						 var i:int;
						 for (i = 0; i < trackingList.length; i++) {
							 var item:TrackingViewElement = trackingList.getItemAt(i) as TrackingViewElement;
							 if (item.eventid == (elementToBeDeleted as TrackingViewElement).eventid) {
								 //skip this one - this is the item that is marked as to be deleted
							 } else {
								 if ((elementToBeDeleted as TrackingViewElement).eventid.split("-")[0] == item.eventid.split("-")[0]) {
									 var urlVariables:URLVariables = new URLVariables();
									 urlVariables["find[_id]"] = item.eventid.split("-")[0];
									 createAndLoadURLRequest(nightScoutTreatmentsUrl + ".json",URLRequestMethod.GET,urlVariables,null,usedByDeleteRemoteItems,true);
									 break;
								 }
							 }
							 
						 }
						 if (i == trackingList.length)
							 createAndLoadURLRequest(nightScoutTreatmentsUrl + "/" + (elementToBeDeleted as TrackingViewElement).eventid.split("-")[0],URLRequestMethod.DELETE,null,null,deleteRemoteItems,true);
					 }
				 }
			 } else {
				 syncFinished();
			 }
		 }
		 
		 private function usedByDeleteRemoteItems(event:Event = null):void {
			 removeEventListeners();
			 if (event != null) {
				 remoteElementToBeAdaptedInDeleteRemoteObjects = (JSON.parse(event.target.data as String) as Array)[0];
				 if (elementToBeDeleted is MedicinEvent) {
					 if (remoteElementToBeAdaptedInDeleteRemoteObjects.insulin)
						 delete remoteElementToBeAdaptedInDeleteRemoteObjects['insulin'];
				 } else if (elementToBeDeleted is BloodGlucoseEvent) {
					 if (remoteElementToBeAdaptedInDeleteRemoteObjects.glucose)
						 delete remoteElementToBeAdaptedInDeleteRemoteObjects['glucose'];
				 } else if (elementToBeDeleted is MealEvent) {
					 if (remoteElementToBeAdaptedInDeleteRemoteObjects.carbs) {
						 delete remoteElementToBeAdaptedInDeleteRemoteObjects['carbs'];
					 }
					 if (remoteElementToBeAdaptedInDeleteRemoteObjects.notes) {
						 delete remoteElementToBeAdaptedInDeleteRemoteObjects['notes'];
					 }
				 } else if (elementToBeDeleted is ExerciseEvent) {
					 if (remoteElementToBeAdaptedInDeleteRemoteObjects.duration)
						 delete remoteElementToBeAdaptedInDeleteRemoteObjects['duration'];
				 }  
				 listOfElementsToBeDeleted.removeItem(elementToBeDeleted);
				 createAndLoadURLRequest(nightScoutTreatmentsUrl, URLRequestMethod.PUT,null,JSON.stringify(remoteElementToBeAdaptedInDeleteRemoteObjects),updateRemoteElements,true);
			 }
			 updateRemoteElements();
		 }
		 
		 private function getAllEvents(event:Event = null):void {
			 if (debugMode)
				 trace("NightScoutSync.as : start method getAllEvents");
			 var remoteElement:Object;
			 var localElement:Object;
			 var newBloodGlucoseLevel:Number;
			 if (event != null) {
				 removeEventListeners();
				 var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
				 if (eventAsJSONObject is Array) {
					 var arrayOfTreatmentsAtNS:Array = eventAsJSONObject as Array;
					 for (var arrayCounter:int = 0; arrayCounter < arrayOfTreatmentsAtNS.length; arrayCounter++) {
						 remoteElement = arrayOfTreatmentsAtNS[arrayCounter];
						 remoteElements.addItem(remoteElement);
						 if (!remoteElement.helpdiabetes) {
							 var helpDiabetesObject:Object = new Object();
							 helpDiabetesObject["lastmodifiedtimestamp"] = (new Date()).valueOf();
							 remoteElement["helpdiabetes"] = helpDiabetesObject;
							 remoteElement["tobeupdatedatns"] = "true";//we added helpdiabetes so it needs to be updated
							 remoteElement["eventTime"] = DateTimeUtilities.createDateFromNSCreatedAt(remoteElement.created_at).valueOf();
						 }
						 // strip off selectedfooditems in the notes, if any
						 if (remoteElement.notes)
							 if ((remoteElement.notes as String).length > 0)
								 remoteElement.notes = (remoteElement.notes as String).split("Food :")[0];
						 
					 }
				 } else {
					 //TODO TODO what if eventAsJSONObject is not an array
				 }
				 /*if (eventHasError(event,getAllEvents))
				 NEEDED ????
				 return;*/
				 
				 //get the events in the trackinglist and store them in localelements
				 for (var i:int = 0; i < trackingList.length; i++) {
					 if ((trackingList.getItemAt(i) as TrackingViewElement).timeStamp >= asOfTimeStamp)
						 if ((trackingList.getItemAt(i) as TrackingViewElement).lastModifiedTimestamp >= lastSyncTimeStamp)
							 localElements.addItem(trackingList.getItemAt(i));
				 }
				 
				 //so we have the remoteelements
				 //for each we try to find an element in the tracking list that has a matching eventid (starting with)
				 for (var k:int = 0; k < remoteElements.length; k++) {
					 var remoteElementFoundLocally:Boolean = false;
					 var notesUpdated:Boolean = false;
					 var splitted:Array;
					 var indexInListOfElementsToBeDeleted:int;
					 remoteElement = remoteElements.getItemAt(k);
					 for (var j:int = 0; j < trackingList.length; j++) {
						 localElement = trackingList.getItemAt(j);
						 if (localElement is ExerciseEvent ||
							 localElement is BloodGlucoseEvent ||
							 localElement is MedicinEvent ||
							 localElement is MealEvent) {
							 if ((localElement as TrackingViewElement).eventid.indexOf(remoteElement._id) > -1) {//we might have stored the event locally as eventid + carbs/glucose/insulin
								 //got a matching item
								 remoteElementFoundLocally = true;
								 if (new Number(remoteElement.helpdiabetes.lastmodifiedtimestamp) != (localElement as TrackingViewElement).lastModifiedTimestamp) {
									 if (new Number(remoteElement.helpdiabetes.lastmodifiedtimestamp) < (localElement as TrackingViewElement).lastModifiedTimestamp) {
										 //the local element is updated more recently
										 remoteElement.eventTime = (localElement as TrackingViewElement).timeStamp;
										 delete remoteElement['created_at'];//don't need that because not used by ns api
										 if (localElement is BloodGlucoseEvent) {
											 //check first if localElement is in list of elements to be deleted, if yes then there's two possibilities :
											 //or the remote element has no other values, so it needs to be deleted completely, so we keep it in list of elements to be deleted
											 //or the remote element has other values, so we just remove the glucose value, and remove it from list of elements to be deleted
											 indexInListOfElementsToBeDeleted = listOfElementsToBeDeleted.getItemIndex(localElement);
											 if (indexInListOfElementsToBeDeleted > -1) {
												 if (remoteElement.carbs || remoteElement.duration || remoteElement.insulin) {
													 //glucose is not the last useful element in this remoteobject, so we remove it and it will be updated remotely
													 delete remoteElement['glucose'];
													 remoteElement.tobeupdatedatns = "true";
													 //it can also be deleted from listOfElementsToBeDeleted
													 listOfElementsToBeDeleted.removeItemAt(indexInListOfElementsToBeDeleted);
												 } else {
													 // if (remoteElement.tobeupdatedatns)
													 //	 delete remoteElement['tobeupdatedatns'];
													 //... removed that because if tobeudpatedatns is true then it's because it needs update
												 }
											 } else {
												 //change the applicable values of the remoteElement
												 //we're not changing the units of the remote element but we change the blood glucose value accordingly
												 newBloodGlucoseLevel = (localElement as BloodGlucoseEvent).bloodGlucoseLevel;
												 if ((remoteElement.units as String).toUpperCase().indexOf(ModelLocator.resourceManagerInstance.getString('general','mgperdl').toUpperCase()) > -1) {
													 if (Settings.getInstance().getSetting(Settings.SettingsBLOODGLUCOSE_UNIT) == "mmoll") {
														 newBloodGlucoseLevel = Math.round((localElement as BloodGlucoseEvent).bloodGlucoseLevel/(new Number(0.0555)));//convert from mgperdlto mmol
													 } 
												 } else {
													 if (Settings.getInstance().getSetting(Settings.SettingsBLOODGLUCOSE_UNIT) == "mgperdl") {
														 newBloodGlucoseLevel = Math.round((localElement as BloodGlucoseEvent).bloodGlucoseLevel*(new Number(0.0555))*10)/10;
													 }
												 }
												 remoteElement.glucose = newBloodGlucoseLevel;
												 remoteElement.helpdiabetes.lastmodifiedtimestamp = (localElement as BloodGlucoseEvent).lastModifiedTimestamp;
												 if ((localElement as BloodGlucoseEvent).comment.length > 0) {
													 //if there's already a list of selectedfooditems in the list, then move them to the end
													 if (!notesUpdated)
														 remoteElement.notes = (localElement as BloodGlucoseEvent).comment;
													 else {
														 splitted= (remoteElement.notes as String).split("Food :<br>");
														 remoteElement.notes = splitted[0] + splitted.length > 1 ? "":"<br>" + (localElement as BloodGlucoseEvent).comment;
														 if (splitted.length > 1)
															 remoteElement.notes  += "<br>Food :<br>" + splitted[1];
													 }
													 notesUpdated = true;
												 }
												 remoteElement.tobeupdatedatns = "true";
											 }
										 } else if (localElement is MedicinEvent) {
											 //check first if localElement is in list of elements to be deleted, if yes then there's two possibilities :
											 //or the remote element has no other values, so it needs to be deleted completely, so we keep it in list of elements to be deleted
											 //or the remote element has other values, so we just remove the glucose value, and remove it from list of elements to be deleted
											 indexInListOfElementsToBeDeleted = listOfElementsToBeDeleted.getItemIndex(localElement);
											 if (indexInListOfElementsToBeDeleted > -1) {
												 if (remoteElement.carbs || remoteElement.duration || remoteElement.glucose) {
													 //insulin is not the last useful element in this remoteobject, so we remove it and it will be updated remotely
													 delete remoteElement['insulin'];
													 remoteElement.tobeupdatedatns = "true";
													 //it can also be deleted from listOfElementsToBeDeleted
													 listOfElementsToBeDeleted.removeItemAt(indexInListOfElementsToBeDeleted);
												 } else {
													 // if (remoteElement.tobeupdatedatns)
													 //	 delete remoteElement['tobeupdatedatns'];
												 }
											 } else {
												 if ((localElement as MedicinEvent).amount == 0)
													 remoteElement.insulin = new Number(0.1);//just a little workaround because nightscout doesn't accept a value of 0, user shouldn't create a bolus with value 0
												 else 
													 remoteElement.insulin = (localElement as MedicinEvent).amount;
												 
												 remoteElement.helpdiabetes.lastmodifiedtimestamp = (localElement as MedicinEvent).lastModifiedTimestamp;
												 if ((localElement as MedicinEvent).comment.length > 0) {
													 if (!notesUpdated)
														 remoteElement.notes = (localElement as MedicinEvent).comment;
													 else {
														 splitted= (remoteElement.notes as String).split("Food :");
														 remoteElement.notes = splitted[0] + splitted.length > 1 ? "":"<br>" +  (localElement as MedicinEvent).comment;
														 if (splitted.length > 1)
															 remoteElement.notes  += "<br>Food :" + splitted[1];
													 }
													 notesUpdated = true;
												 }
												 remoteElement.tobeupdatedatns = "true";
											 }
										 } else if (localElement is MealEvent) {
											 //check first if localElement is in list of elements to be deleted, if yes then there's two possibilities :
											 //or the remote element has no other values, so it needs to be deleted completely, so we keep it in list of elements to be deleted
											 //or the remote element has other values, so we just remove the glucose value, and remove it from list of elements to be deleted
											 indexInListOfElementsToBeDeleted = listOfElementsToBeDeleted.getItemIndex(localElement);
											 if (indexInListOfElementsToBeDeleted > -1) {
												 if (remoteElement.duration || remoteElement.insulin || remoteElement.glucose) {
													 //insulin is not the last useful element in this remoteobject, so we remove it and it will be updated remotely
													 delete remoteElement['carbs'];
													 remoteElement.tobeupdatedatns = "true";
													 //it can also be deleted from listOfElementsToBeDeleted
													 listOfElementsToBeDeleted.removeItemAt(indexInListOfElementsToBeDeleted);
												 } else {
													 //if (remoteElement.tobeupdatedatns)
													 //	 delete remoteElement['tobeupdatedatns'];
												 }
											 } else {
												 if ((localElement as MealEvent).comment.length > 0) {
													 if (!notesUpdated)
														 remoteElement.notes = (localElement as MealEvent).comment;
													 else
														 remoteElement.notes += "<br>" + (localElement as MealEvent).comment;
													 notesUpdated = true;
												 }
												 //don't add : (localElement as MealEvent).calculatedInsulinAmount;
												 //don't add : (localElement as MealEvent).correctionFactor;
												 //don't add : (localElement as MealEvent).insulinRatio;
												 //not changing the eventType
												 var selectedFoodItemText:String = "Food :<br>"; 
												 for (var foodItemCntr:int = 0; foodItemCntr < (localElement as MealEvent).selectedFoodItems.length; foodItemCntr++) {
													 var selectedFoodItem:SelectedFoodItem = (localElement as MealEvent).selectedFoodItems.getItemAt(foodItemCntr) as SelectedFoodItem;
													 selectedFoodItemText += selectedFoodItem.chosenAmount + " " + selectedFoodItem.unit.unitDescription + " " + selectedFoodItem.itemDescription;
													 if (foodItemCntr < (localElement as MealEvent).selectedFoodItems.length - 1)
														 selectedFoodItemText += "<br>";
												 }
												 if (selectedFoodItemText.length > 0) {
													 if (!notesUpdated)
														 remoteElement.notes = selectedFoodItemText;
													 else
														 remoteElement.notes += "<br>" + selectedFoodItemText;
													 notesUpdated = true;
												 }
												 remoteElement.carbs = ((Math.round((localElement as MealEvent).totalCarbs * 10))/10);
												 remoteElement.helpdiabetes.lastmodifiedtimestamp = (localElement as MealEvent).lastModifiedTimestamp;
												 remoteElement.tobeupdatedatns = "true";
											 }
										 } else if (localElement is ExerciseEvent) {
											 //check first if localElement is in list of elements to be deleted, if yes then there's two possibilities :
											 //or the remote element has no other values, so it needs to be deleted completely, so we keep it in list of elements to be deleted
											 //or the remote element has other values, so we just remove the glucose value, and remove it from list of elements to be deleted
											 indexInListOfElementsToBeDeleted = listOfElementsToBeDeleted.getItemIndex(localElement);
											 if (indexInListOfElementsToBeDeleted > -1) {
												 if (remoteElement.carbs || remoteElement.insulin || remoteElement.glucose) {
													 //insulin is not the last useful element in this remoteobject, so we remove it and it will be updated remotely
													 delete remoteElement['duration'];
													 remoteElement.tobeupdatedatns = "true";
													 //it can also be deleted from listOfElementsToBeDeleted
													 listOfElementsToBeDeleted.removeItemAt(indexInListOfElementsToBeDeleted);
												 } else {
													 //if (remoteElement.tobeupdatedatns)
													 //	 delete remoteElement['tobeupdatedatns'];
												 }
											 } else {
												 if ((localElement as ExerciseEvent).comment.length > 0) {
													 if (!notesUpdated)
														 remoteElement.notes = (localElement as ExerciseEvent).comment;
													 else {
														 remoteElement.notes = splitted[0] + splitted.length > 1 ? "":"<br>" + "<br>" + (localElement as ExerciseEvent).comment;
													 }
													 notesUpdated = true;
												 }
												 remoteElement.helpdiabetes.lastmodifiedtimestamp = (localElement as ExerciseEvent).lastModifiedTimestamp;
												 remoteElement.tobeupdatedatns = "true";
											 }
										 }
									 } else {
										 //the remote element is updated more recently
										 //delete remoteElement['tobeupdatedatns'];
										 var newCreationTimeStamp:Number = DateTimeUtilities.createDateFromNSCreatedAt(remoteElement.created_at).valueOf();
										 var lastModifiedTimeStamp:Number = remoteElement.helpdiabetes.lastmodifiedtimestamp;
										 var newComment:String = removeBRInNotes(remoteElement.notes);
										 if (localElement is BloodGlucoseEvent) {
											 if (remoteElement.glucose) {
												 //we're not changing the units of the local element but we change the blood glucose value accordingly
												 newBloodGlucoseLevel = (remoteElement.glucose as Number);
												 if ((remoteElement.units as String).toUpperCase().indexOf(ModelLocator.resourceManagerInstance.getString('general','mgperdl').toUpperCase()) > -1) {
													 if (Settings.getInstance().getSetting(Settings.SettingsBLOODGLUCOSE_UNIT) == ModelLocator.resourceManagerInstance.getString('general','mmoll')) {
														 newBloodGlucoseLevel = Math.round((remoteElement.glucose as Number)/(new Number(0.0555)));
													 }
												 } else {
													 if (Settings.getInstance().getSetting(Settings.SettingsBLOODGLUCOSE_UNIT) == ModelLocator.resourceManagerInstance.getString('general','mgperdl')) {
														 newBloodGlucoseLevel = Math.round((remoteElement.glucose as Number)*(new Number(0.0555))*10)/10;
													 }
												 }
												 (localElement as BloodGlucoseEvent).updateBloodGlucoseEvent(
													 (localElement as BloodGlucoseEvent).unit,
													 newBloodGlucoseLevel,
													 newCreationTimeStamp,
													 newComment,
													 lastModifiedTimeStamp);
												 ModelLocator.trackingViewRedrawNecessary = true;
											 } else {
												 //there's no glucose
												 //local element should be deleted
												 //can this happen ?
											 }
											 localElementsUpdated = true;
										 } else if (localElement is ExerciseEvent) {
											 if (remoteElement.duration) {
												 (localElement as ExerciseEvent).updateExerciseEvent(
													 remoteElement.duration,
													 newCreationTimeStamp,
													 lastModifiedTimeStamp,
													 newComment);
												 ModelLocator.trackingViewRedrawNecessary = true;
											 } else {
												 //there's no duration
												 //local element should be deleted
												 //can this happen ?
											 }
											 localElementsUpdated = true;
										 } else if (localElement is MedicinEvent) {
											 if (remoteElement.insulin) {
												 (localElement as MedicinEvent).updateMedicinEvent(
													 (localElement as MedicinEvent).bolustype, //assuming bolustype will not change, in fact we will not even upload long duration bolusses to ns
													 (localElement as MedicinEvent).bolusDurationInMinutes,//see remark above
													 (localElement as MedicinEvent).medicinName,
													 (localElement as MedicinEvent).amount,
													 newComment,
													 newCreationTimeStamp,
													 lastModifiedTimeStamp
												 );
												 ModelLocator.trackingViewRedrawNecessary = true;
											 } else {
												 //there's no insulin
												 //local element should be deleted
												 //can this happen ?
											 }
											 localElementsUpdated = true;
										 } else if (localElement is MealEvent) {
											 // don't update a local mealevent, it seems to be creating conflicts, probably happens when two devices are syncing almost at the same time
											 // for instance, one device has uploaded un update to nightscout, but almost in parallel another devices syncs with google, but that update was not there on time
											 // but it sees to update at ns, so it downloads the carbs and creates a "item from ns".
											 /*if (remoteElement.carbs) {
											 //we're replacing the carbs, we will not start analyzing the notes field (which may contain a list of selected fooditems) 
											 //to see which selectedfooditems need to be deleted - we'll just delete them all and add a new one
											 //let's first add the dummy selecteditem
											 var dummySelectedItem:SelectedFoodItem = createDummySelectedFoodItem(new Number(remoteElement.carbs));
											 var theMealEvent:MealEvent = (localElement as MealEvent);
											 theMealEvent.addSelectedFoodItem(dummySelectedItem);
											 for (var selfooditemctr:int = 0; selfooditemctr < theMealEvent.selectedFoodItems.length; selfooditemctr++) {
											 var selectedFoodItemToCheck = theMealEvent.selectedFoodItems.getItemAt(selfooditemctr) as SelectedFoodItem;
											 if (! (selectedFoodItemToCheck.eventid == dummySelectedItem.eventid)) {
											 Synchronize.getInstance().addObjectToBeDeleted(selectedFoodItemToCheck);
											 theMealEvent.removeSelectedFoodItem(selectedFoodItemToCheck);
											 }
											 }
											 theMealEvent.updateMealEvent(
											 (localElement as MealEvent).mealName, 
											 newComment,
											 (localElement as MealEvent).insulinRatio,
											 (localElement as MealEvent).correctionFactor,
											 lastModifiedTimeStamp,
											 newCreationTimeStamp
											 );
											 } else {
											 //there's no carbs
											 //local element should be deleted
											 //can this happen ?
											 }*/
											 //localElementsUpdated = true;
										 }
									 }
								 } else {
									 //we found a matching event, and the lastmodifiedtimestamps are equal, so the contents are equal
									 //but there could still be other events with the same starting eventid and with different lastmodifiedtimestamp so we're not breaking the loop
								 }
								 //the localelement is found remotely, so we will not upload it anymore to ns
								 //so it can be removed from localelemeents
								 var indexOfLocalElement:int = localElements.getItemIndex(localElement);
								 if (indexOfLocalElement > -1) {
									 localElements.removeItemAt(indexOfLocalElement);
								 }
							 }
							 
						 } //else we're not interested in, eg daylineitem
					 }
					 //WE NEED TO CHECK HERE IF WE FOUND THE REMOTE ELEMENT IN THE LOCALELEMENTS, IF NOT IT IS ONE TO add
					 if (!remoteElementFoundLocally) {
						 var elementIsInDeletionList:Boolean = false;
						 //delete remoteElement['tobeupdatedatns'];actually if tobeupdatedatns is there, then it's because it needs update, it could be for example that helpdiabetes (with lastmodifiedtimestamp) has been added
						 if (remoteElement.glucose) {
							 //check if the element is in list of objects to be deleted, if so no need to re-add it to the local list
							 for (var i:int = 0; i < listOfElementsToBeDeleted.length; i++) {
								 if (listOfElementsToBeDeleted.getItemAt(i) is TrackingViewElement) {
									 if ((listOfElementsToBeDeleted.getItemAt(i) as TrackingViewElement).eventid == remoteElement._id + "-glucose") {
										 elementIsInDeletionList = true;
										 break;
									 }
								 }
							 }
							 if (!elementIsInDeletionList) {
								 var newGlucose:Number = new Number(remoteElement.glucose);
								 var newUnit:String = ModelLocator.resourceManagerInstance.getString('general',Settings.getInstance().getSetting(Settings.SettingsBLOODGLUCOSE_UNIT));
								 if ((remoteElement.units as String).toUpperCase().indexOf(ModelLocator.resourceManagerInstance.getString('general','mgperdl').toUpperCase()) > -1 && newUnit == 
									 ModelLocator.resourceManagerInstance.getString('general','mmoll')) {
									 newGlucose = Math.round(newGlucose*(new Number(0.0555))*10)/10;
								 } else if ((remoteElement.units as String).toUpperCase().indexOf(ModelLocator.resourceManagerInstance.getString('general','mgperdl').toUpperCase()) == -1 && newUnit == 
									 ModelLocator.resourceManagerInstance.getString('general','mgperdl')) {
									 newGlucose = Math.round(newGlucose/(new Number(0.0555)));
								 }
								 
								 ModelLocator.trackingList.addItem(
								 new BloodGlucoseEvent(
									 newGlucose,
									 newUnit,
									 remoteElement._id + "-glucose",
									 removeBRInNotes(remoteElement.notes as String),
									 DateTimeUtilities.createDateFromNSCreatedAt(remoteElement.created_at).valueOf(),
									 new Number(remoteElement.helpdiabetes.lastmodifiedtimestamp),
									 true,
									 true
								 )); 
								 localElementsUpdated = true;
							 }
						 } 
						 if (remoteElement.carbs) {
							 //check if the element is in list of objects to be deleted, if so no need to re-add it to the local list
							 for (var i:int = 0; i < listOfElementsToBeDeleted.length; i++) {
								 if (listOfElementsToBeDeleted.getItemAt(i) is TrackingViewElement) {
									 if ((listOfElementsToBeDeleted.getItemAt(i) as TrackingViewElement).eventid == remoteElement._id + "-carbs") {
										 elementIsInDeletionList = true;
										 break;
									 }
								 }
							 }
							 if (!elementIsInDeletionList) {
								 
								 //calculate insulinratio
								 var timeStampAsDate:Date = DateTimeUtilities.createDateFromNSCreatedAt(remoteElement.created_at);
								 var insulinRatio:Number;
								 var nowAsNumber:Number = (timeStampAsDate.hours * 3600 + timeStampAsDate.minutes * 60 + timeStampAsDate.seconds)*1000;
								 if (nowAsNumber < new Number(Settings.getInstance().getSetting(Settings.SettingBREAKFAST_UNTIL))) {
									 insulinRatio = new Number(Settings.getInstance().getSetting(Settings.SettingINSULIN_RATIO_BREKFAST));
								 } else if (nowAsNumber < new Number(Settings.getInstance().getSetting(Settings.SettingLUNCH_UNTIL))) {
									 insulinRatio = new Number(Settings.getInstance().getSetting(Settings.SettingINSULIN_RATIO_LUNCH));
								 } else if (nowAsNumber < new Number(Settings.getInstance().getSetting(Settings.SettingSNACK_UNTIL))) {
									 insulinRatio = new Number(Settings.getInstance().getSetting(Settings.SettingINSULIN_RATIO_SNACK));
								 } else {
									 insulinRatio = new Number(Settings.getInstance().getSetting(Settings.SettingINSULIN_RATIO_SUPPER));
								 }
								 var correctionFactorList:FromtimeAndValueArrayCollection = FromtimeAndValueArrayCollection.createList(Settings.getInstance().getSetting(Settings.SettingsCorrectionFactor));
								 
								 var newMealEvent:MealEvent = new MealEvent(//in contradiction to medicin/bloodglucose and exerciseevents, I must add new mealevents to the trackinglist, because if i don't, the adding of selectedfooditems would fail because I wouldn't find the mealevent
									 "Meal from NightScout",
									 insulinRatio,
									 correctionFactorList.getValue(Number.NaN,"",timeStampAsDate),
									 timeStampAsDate.valueOf(),
									 null,
									 remoteElement._id + "-carbs",
									 removeBRInNotes(remoteElement.notes as String),
									 new Number(remoteElement.helpdiabetes.lastmodifiedtimestamp),
									 true, null, null, false);
								 newMealEvent.addSelectedFoodItem(createDummySelectedFoodItem(new Number((remoteElement.carbs))));
								 ModelLocator.addMeal(new Meal(null,newMealEvent,Number.NaN));
								 ModelLocator.trackingList.addItem(newMealEvent);
								 localElementsUpdated = true;
							 }
						 } 
						 if (remoteElement.duration) {
							 //check if the element is in list of objects to be deleted, if so no need to re-add it to the local list
							 for (var i:int = 0; i < listOfElementsToBeDeleted.length; i++) {
								 if (listOfElementsToBeDeleted.getItemAt(i) is TrackingViewElement) {
									 if ((listOfElementsToBeDeleted.getItemAt(i) as TrackingViewElement).eventid == remoteElement._id + "-exercise") {
										 elementIsInDeletionList = true;
										 break;
									 }
								 }
							 }
							 
							 if (!elementIsInDeletionList) {
								 ModelLocator.trackingList.addItem(
								 new ExerciseEvent(remoteElement.duration,
									 removeBRInNotes(remoteElement.notes as String),
									 remoteElement._id + "-exercise",
									 DateTimeUtilities.createDateFromNSCreatedAt(remoteElement.created_at).valueOf(),
									 new Number(remoteElement.helpdiabetes.lastmodifiedtimestamp),
									 true)
								 );
								 localElementsUpdated = true;
							 }
						 }
						 if (remoteElement.insulin) {
							 //check if the element is in list of objects to be deleted, if so no need to re-add it to the local list
							 for (var i:int = 0; i < listOfElementsToBeDeleted.length; i++) {
								 if (listOfElementsToBeDeleted.getItemAt(i) is TrackingViewElement) {
									 if ((listOfElementsToBeDeleted.getItemAt(i) as TrackingViewElement).eventid == remoteElement._id + "-medicin") {
										 elementIsInDeletionList = true;
										 break;
									 }
								 }
							 }
							 if (!elementIsInDeletionList) {
								 ModelLocator.trackingList.addItem(
								 new MedicinEvent(new Number(remoteElement.insulin),
									 Settings.getInstance().getSetting(Settings.SettingsInsulinType1),
									 remoteElement._id + "-medicin",
									 removeBRInNotes(remoteElement.notes as String),
									 DateTimeUtilities.createDateFromNSCreatedAt(remoteElement.created_at).valueOf(),
									 new Number(remoteElement.helpdiabetes.lastmodifiedtimestamp),
									 true,
									 ModelLocator.resourceManagerInstance.getString('editmedicineventview',MedicinEvent.BOLUS_TYPE_NORMAL),
									 new Number(0))
								 );
								 ModelLocator.recalculateActiveInsulin();
								 localElementsUpdated = true;
							 }
						 }
					 }
				 }
				 //ok so we end up with two lists, remoteElements, the ones with tobeupdatedatns = true need to be updated remotely
				 //the second list is localelements, those also need to be stored remotely,
				 updateRemoteElements();
			 } else {
				 //call to nightscout
				 //we will restrict to all treatments less than 1 day old, because I haven't succeeded yet in filtering on lastmodifiedtimestamp
				 //this field is added anyway by the api
				 var urlVariables:URLVariables = new URLVariables();
				 urlVariables["find[created_at][$gte]"] = DateTimeUtilities.createNSFormattedDateAndTime(new Date((new Date()).valueOf() - 3600 * 24 * 1000));
				 createAndLoadURLRequest(nightScoutTreatmentsUrl, URLRequestMethod.GET,urlVariables,null,getAllEvents,true);
			 }
		 }
		 
		 private function updateRemoteElements(event:Event = null):void {
			 //we start with the first element of localelements, as long as it's not empty
			 //then we continue with the first element of remotelements, as long as it's not empty
			 //note that there could be elements here that already exist remotely, but that's not a problem. Doing a PUT for an object with an _id that already exists will simply update this object remotely.
			 //
			 if (debugMode)
				 trace("NightScoutSync.as : start method updateRemoteElements");
			 if (event != null) {
				 removeEventListeners();
				 //TODOTODOTODO need to see here what we need to check
				 //if it was successful then :
				 if (localElements.length > 0)
					 localElements.removeItemAt(0);
				 else if (remoteElements.length > 0)
					 remoteElements.removeItemAt(0);
				 else 
					 deleteRemoteItems();
			 }
			 
			 if (localElements.length > 0) {
				 //start preparing the json object and do the put
				 var newElement:Object = new Object();
				 var localElement:Object = localElements.getItemAt(0);
				 if ((localElement as TrackingViewElement).eventid.length < 24 || (localElement as TrackingViewElement).eventid.indexOf("HelpDiabet") > -1) {
					 //we will not update these , it's been created with older version of helpdiabetes
					 //events with HelpDiabet in the eventid, should actually not happen, just happened with me because for some time I was using that as eventid
					 localElements.removeItemAt(0);
					 updateRemoteElements();
				 } else {
					 var eventId:String = (localElement as TrackingViewElement).eventid;
					 var indexOfDash:int = eventId.indexOf("-");
					 if (indexOfDash > -1) {
						 //strip off anyting like -carbs, -exercise, ...
						 eventId = eventId.substring(0,indexOfDash);
					 }
					 newElement["_id"] = eventId;
					 newElement["eventTime"] = (localElement as TrackingViewElement).timeStamp;
					 var helpDiabetesObject:Object = new Object();
					 //helpDiabetesObject["deleted"] = "false"; not really useful because nightscout itself will not take this field into account - better to use google sync for that and to delete the object at NS effectively in stead of marking it as deleted
					 helpDiabetesObject["lastmodifiedtimestamp"] = (new Date((localElement as TrackingViewElement).lastModifiedTimestamp)).valueOf();
					 newElement["helpdiabetes"] = helpDiabetesObject;
					 newElement["upload"] = "true";
					 
					 
					 if (localElement is BloodGlucoseEvent) {
						 //newElement[""] = (localElement ad BloodGlucoseEvent).;
						 newElement["glucose"] = (localElement as BloodGlucoseEvent).bloodGlucoseLevel;
						 newElement["eventType"] = "BG Check";
						 newElement["glucoseType"] = "Finger";
						 newElement["notes"] = (localElement as BloodGlucoseEvent).comment;
						 newElement["units"] = 
							 (localElement as BloodGlucoseEvent).unit == ModelLocator.resourceManagerInstance.getString('general','mgperdl') ?
							 "mg/dl":"mmol";
					 } else if (localElement is ExerciseEvent) {
						 newElement["notes"] = "Level = " + (localElement as ExerciseEvent).level;
						 if ((localElement as ExerciseEvent).comment) 
							 if ((localElement as ExerciseEvent).comment.length > 0)
								 newElement["notes"] += "<br>" + (localElement as ExerciseEvent).comment;
						 newElement["duration"] = 30; 
						 newElement["eventType"] = "Exercise";
					 } else if (localElement is MedicinEvent) {
						 //we will only upload medicinevents of type insulintype1
						 //and no lon duration bolusses
						 var medicinEvent:MedicinEvent = (localElement as MedicinEvent);
						 if (medicinEvent.medicinName != Settings.getInstance().getSetting(Settings.SettingsInsulinType1) || 
							 medicinEvent.bolustype != ModelLocator.resourceManagerInstance.getString('editmedicineventview',MedicinEvent.BOLUS_TYPE_NORMAL)) {
							 //don't upload
							 newElement["upload"] = "false";
						 } else {
							 newElement["eventType"] = "Bolus";
							 if (medicinEvent.amount == 0)
								 newElement["insulin"] = new Number(0.1);//just a little workaround because nightscout doesn't accept a value of 0, user shouldn't create a bolus with value 0
							 else 
								 newElement["insulin"] = medicinEvent.amount;
							 newElement["notes"] = medicinEvent.comment;
						 }
					 } else if (localElement is MealEvent) {
						 newElement["eventType"] = (localElement as MealEvent).mealName;
						 var selectedFoodItemText:String = ""; 
						 for (var foodItemCntr:int = 0; foodItemCntr < (localElement as MealEvent).selectedFoodItems.length; foodItemCntr++) {
							 var selectedFoodItem:SelectedFoodItem = (localElement as MealEvent).selectedFoodItems.getItemAt(foodItemCntr) as SelectedFoodItem;
							 selectedFoodItemText += selectedFoodItem.chosenAmount + " " + selectedFoodItem.unit.unitDescription + " " + selectedFoodItem.itemDescription;
							 if (foodItemCntr < (localElement as MealEvent).selectedFoodItems.length - 1)
								 selectedFoodItemText += "<br>";
						 }
						 if (selectedFoodItemText.length > 0) {
							 newElement["notes"] = "Food :<br>" + selectedFoodItemText;
						 }
						 newElement.carbs = ((Math.round((localElement as MealEvent).totalCarbs * 10))/10);
					 } 
					 if (newElement.upload == "true") {
						 delete newElement['upload'];
						 createAndLoadURLRequest(nightScoutTreatmentsUrl, URLRequestMethod.PUT,null,JSON.stringify(newElement),updateRemoteElements,true);
					 } else {
						 localElements.removeItemAt(0);
						 updateRemoteElements();
					 }
				 }
			 } else if (remoteElements.length > 0) {
				 var remoteElement:Object = remoteElements.getItemAt(0);
				 if (remoteElement.tobeupdatedatns) {
					 delete remoteElement['tobeupdatedatns'];
					 createAndLoadURLRequest(nightScoutTreatmentsUrl, URLRequestMethod.PUT,null,JSON.stringify(remoteElement),updateRemoteElements,true);
				 } else {
					 //just remove the element, no update needed
					 remoteElements.removeItemAt(0);
					 updateRemoteElements();
				 }
			 } else 
				 deleteRemoteItems();
		 }
		 
		 /**
		  * cheks if functionToRemoveFromEventListner != null and if not removed from Event.COMPLETE<br>
		  * removes eventlistener nightScoutAPICallFailed from IOErrorEvent.IO_ERROR
		  */
		 private function removeEventListeners():void  {
			 
			 if (functionToRecall != null)
				 loader.removeEventListener(Event.COMPLETE,functionToRecall);
			 loader.removeEventListener(IOErrorEvent.IO_ERROR,nightScoutAPICallFailed);
		 }
		 
		 private function nightScoutAPICallFailed(event:Event):void {
			 if (debugMode) {
				 trace("NightScoutSync.as : in nightScoutAPICallFailed");
				 trace("Synchronize.as : in nightscoutapicall failed : event.target.data = " + event.target.data as String);
			 }
			 removeEventListeners();
			 var syncError:String = event.target.data;
			 if (syncError.length == 0)
				 syncError = "You may have to check your nightscout url : " + Settings.getInstance().getSetting(Settings.SettingsNightScoutWebsiteURL);
			 syncErrorList.addItem((new Date()).toLocaleString() + " " + syncError);
			 syncFinished(false);
		 }
		 
		 /**
		  * creates URL request and loads it<br>
		  * if paramFunctionToRecall != null then <br>
		  * - eventlistener is registered for that function for Event.COMPLETE<br>
		  * - paramFunctionToRecall is assigned to variable functionToRemoveFromEventListener<br>
		  * - paramFunctionToRecall is assigned to variable functionToRecall<br>
		  * if addIOErrorListener then a listener will be added for the event IOErrorEvent.IO_ERROR, with function googleAPICallFailed<br>
		  * urlVariables or data needs to be supplied, not both.
		  */
		 private function createAndLoadURLRequest(url:String,requestMethod:String,urlVariables:URLVariables, data:String, paramFunctionToRecall:Function,addIOErrorListener:Boolean):void {
			 var request:URLRequest = new URLRequest(url);
			 loader = new URLLoader();
			 if (debugMode) {
				 trace ("in createAndLoadURLRequest");
			 }
			 
			 request.requestHeaders.push(new URLRequestHeader("api-secret", hashedApiSecret));
			 request.requestHeaders.push(new URLRequestHeader("Content-type", "application/json"));
			 //request.requestHeaders.push(new URLRequestHeader("Accept", "application/json"));
			 
			 request.contentType = "application/json";
			 
			 if (!requestMethod)
				 requestMethod = URLRequestMethod.GET;
			 request.method = requestMethod;
			 
			 if (data != null)
				 request.data = data;
			 else if (urlVariables != null)
				 request.data = urlVariables;
			 
			 if (paramFunctionToRecall != null) {
				 loader.addEventListener(Event.COMPLETE,paramFunctionToRecall);
				 functionToRecall = paramFunctionToRecall;
			 }
			 
			 if (addIOErrorListener)
				 loader.addEventListener(IOErrorEvent.IO_ERROR,nightScoutAPICallFailed);
			 
			 loader.load(request);
			 if (debugMode)
				 trace("NightScoutSync.as : loader : url = " + request.url + ", method = " + request.method + ", request.data = " + request.data); 
		 }
		 
		 private function createDummySelectedFoodItem(chosenAmount:Number):SelectedFoodItem {
			 return new SelectedFoodItem(DateTimeUtilities.createEventId(), 
				 "item from NS", 
				 new Unit(ModelLocator.resourceManagerInstance.getString('general','gram_long'),1,0,0,1,0), 
				 chosenAmount,
				 (new Date()).valueOf());
			 
		 }
		 
		 /**
		  * to call when sync has finished 
		  */
		 private function syncFinished(success:Boolean = true):void {
			 
			 trace("NightScoutSync.as : in NightScout syncFinished with success = " + success + "\n\n\n");
			 var localdispatcher:EventDispatcher = new EventDispatcher();
			 
			 if (success) {
				 Settings.getInstance().setSetting(Settings.SettingsLastNightScoutSyncTimeStamp,currentSyncTimeStamp.toString());
				 lastSyncTimeStamp = currentSyncTimeStamp;
			 } else
				 currentSyncTimeStamp = currentSyncTimeStamp - (secondsBetweenTwoSync * 1000 + 1);
			 
			 if (localElementsUpdated) {
				 localElementsUpdated = false;
				 Synchronize.getInstance().startSynchronize(true);
			 }
			 
			 if (rerunNecessary) {
				 currentSyncTimeStamp = new Date().valueOf();
				 asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;
				 nightScoutSyncRunning = true;
				 rerunNecessary = false;
				 synchronize();
			 } else {
				 nightScoutSyncRunning = false;
			 }
		 }
		 
		 private function removeBRInNotes(notes:String):String {
			 if (notes == null) return notes;
			 if ((notes as String).length === 0) return notes;
			 var returnValue:String = notes as String;
			 var pattern:RegExp = /<br>/g;
			 returnValue = returnValue.replace(pattern,"");
			 return returnValue;
		 }
	 }
 }