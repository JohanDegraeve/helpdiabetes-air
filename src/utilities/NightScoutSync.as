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
		 private static var createdAtNSDateTimePattern:String = "yyyy-MM-ddTHH:mm:ss.SSSZ";
		 private static var createdAtNSDateTimeFormatter:spark.formatters.DateTimeFormatter;
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
		  * how many minutes between two synchronisations, normal value
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
		 private var nightScoutSyncActive:Boolean = true;
		 private var trackingListAlreadyModified:Boolean;
		 private var previousTrackingEventToShow:String;
		 
		 private static const apiSecret:String = "06c882c27a21a8981bf90def2da89db49068cf12";
		 private static const nightScoutTreatmentsUrl:String = "https://testhdsync.azurewebsites.net/api/v1/treatments";
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
			 createdAtNSDateTimeFormatter = new DateTimeFormatter();
			 createdAtNSDateTimeFormatter.dateTimePattern = createdAtNSDateTimePattern;
			 createdAtNSDateTimeFormatter.useUTC = true;
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
			 if (timer2 != null) {
				 if (timer2.hasEventListener(TimerEvent.TIMER))
					 timer2.removeEventListener(TimerEvent.TIMER,startNightScoutSync);
				 timer2.stop();
				 timer2 = null;
			 }
			 
			 trace("NightScoutSync.as : in startNightScoutSync");
			 //to make sure there's at least one complete resync per day
			 if ((new Date()).date != new Number(Settings.getInstance().getSetting(Settings.SettingsDayOfLastCompleteNightScoutSync))) {
				 Settings.getInstance().setSetting(Settings.SettingsLastNightScoutSyncTimeStamp,
					 ( (
						 (new Date()).valueOf() 
						 - 
						 new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000
					 ).toString()
					 )
				 );
				 Settings.getInstance().setSetting(Settings.SettingsDayOfLastCompleteNightScoutSync,(new Date()).date.toString());
			 }
			 
			 var timeSinceLastSyncMoreThanXMinutes:Boolean = (new Date().valueOf() - currentSyncTimeStamp) > normalValueForSecondsBetweenTwoSync * 1000;
			 if ((nightScoutSyncRunning && (timeSinceLastSyncMoreThanXMinutes))  || (!nightScoutSyncRunning && (immediateRunNecessary || timeSinceLastSyncMoreThanXMinutes))) {
				 localElementsUpdated  = false;
				 retrievalCounter = 0;
				 trackingList = ModelLocator.getInstance().trackingList;
				 currentSyncTimeStamp = new Date().valueOf();
				 lastSyncTimeStamp = new Number(Settings.getInstance().getSetting(Settings.SettingsLastNightScoutSyncTimeStamp));
				 if (debugMode) 
					 trace("NightScoutSync.as : lastsynctimestamp = " + new DateTimeFormatter().format(new Date(lastSyncTimeStamp)));
				 asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;
				 rerunNecessary = false;
				 nightScoutSyncRunning = true;
				 currentSyncTimeStamp = new Date().valueOf();
				 asOfTimeStamp = currentSyncTimeStamp - new Number(Settings.getInstance().getSetting(Settings.SettingsMAXTRACKINGSIZE)) * 24 * 3600 * 1000;
				 
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
		 
		 /**
		  * TO BE COMPLETED
		  * checks if there's an error, if yes then <br>
		  * - calls googleAPICallFailed with event as parameter <br>
		  * - sets functionToReCall to functionToRecallIfError<br>
		  * returns true if there's an error, returns false if no error
		  */
		 private function eventHasError(event:Event,functionToRecallIfError:Function):Boolean  {
			 var eventAsJSONObject:Object = JSON.parse(event.target.data as String);
			 if  (eventAsJSONObject.error) {
				 if (eventAsJSONObject.error.message == nightScoutError_Invalid_Credentials && !secondAttempt) {
					 secondAttempt = true;
					 functionToRecall = functionToRecallIfError;
					 nightScoutAPICallFailed(event);
					 return true;
				 } else {
					 return true;
				 }
			 }
			 else 
				 return false;
		 }
		 
		 /**
		  * 
		  */
		 //corresponds to stratSync in Synchronize.as
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
			 if (nightScoutSyncActive)
				 listOfElementsToBeDeleted.addItem(object);
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
					 for (var i = 0; i < trackingList.length; i++) {
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
							 //helpDiabetesObject["deleted"] = "false"; not really useful because nightscout itself will not take this field into account - better to use google sync for that and to delete the object at NS effectively in stead of marking it as deleted
							 helpDiabetesObject["lastmodifiedtimestamp"] = DateTimeUtilities.createDateFromNSCreatedAt(remoteElement.created_at).valueOf();
							 helpDiabetesObject["lastmodifiedatns"] = helpDiabetesObject["lastmodifiedtimestamp"];
							 remoteElement["helpdiabetes"] = helpDiabetesObject;
							 remoteElement["tobeupdatedatns"] = "true";//to check later on, if true we will put it to NS, but remove that attribute first
							 remoteElement["eventtime"] = DateTimeUtilities.createDateFromNSCreatedAt(remoteElement.created_at).valueOf();
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
													 if (remoteElement.tobeupdatedatns)
														 delete remoteElement['tobeupdatedatns'];
												 }
											 } else {
												 //change the applicable values of the remoteElement
												 //we're not changing the units of the remote element but we change the blood glucose value accordingly
												 newBloodGlucoseLevel = (localElement as BloodGlucoseEvent).bloodGlucoseLevel;
												 if ((remoteElement.units as String).toUpperCase().indexOf(ResourceManager.getInstance().getString('general','mgperdl').toUpperCase()) > -1) {
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
													 if (remoteElement.tobeupdatedatns)
														 delete remoteElement['tobeupdatedatns'];
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
													 if (remoteElement.tobeupdatedatns)
														 delete remoteElement['tobeupdatedatns'];
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
													 if (remoteElement.tobeupdatedatns)
														 delete remoteElement['tobeupdatedatns'];
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
										 var newCreationTimeStamp:Number = DateTimeUtilities.createDateFromNSCreatedAt(remoteElement.created_at).valueOf();
										 var lastModifiedTimeStamp:Number = remoteElement.helpdiabetes.lastmodifiedtimestamp;
										 var newComment:String = removeBRInNotes(remoteElement.notes);
										 if (localElement is BloodGlucoseEvent) {
											 if (remoteElement.glucose) {
												 //we're not changing the units of the local element but we change the blood glucose value accordingly
												 if ((remoteElement.units as String).toUpperCase().indexOf(ResourceManager.getInstance().getString('general','mgperdl').toUpperCase()) > -1) {
													 if (Settings.getInstance().getSetting(Settings.SettingsBLOODGLUCOSE_UNIT) == ResourceManager.getInstance().getString('general','mmoll')) {
														 newBloodGlucoseLevel = Math.round((remoteElement.glucose as Number)/(new Number(0.0555)));
													 }
												 } else {
													 if (Settings.getInstance().getSetting(Settings.SettingsBLOODGLUCOSE_UNIT) == ResourceManager.getInstance().getString('general','mgperdl')) {
														 newBloodGlucoseLevel = Math.round((remoteElement.glucose as Number)*(new Number(0.0555))*10)/10;
													 }
												 }
												 (localElement as BloodGlucoseEvent).updateBloodGlucoseEvent(
													 (localElement as BloodGlucoseEvent).unit,
													 newBloodGlucoseLevel,
													 newCreationTimeStamp,
													 newComment,
													 lastModifiedTimeStamp);
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
											 } else {
												 //there's no insulin
												 //local element should be deleted
												 //can this happen ?
											 }
											 localElementsUpdated = true;
										 } else if (localElement is MealEvent) {
											 if (remoteElement.carbs) {
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
												 //there's no insulin
												 //local element should be deleted
												 //can this happen ?
											 }
											 localElementsUpdated = true;
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
								 var newUnit:String = ResourceManager.getInstance().getString('general',Settings.getInstance().getSetting(Settings.SettingsBLOODGLUCOSE_UNIT));
								 if ((remoteElement.units as String).toUpperCase().indexOf(ResourceManager.getInstance().getString('general','mgperdl').toUpperCase()) > -1 && newUnit == 
									 ResourceManager.getInstance().getString('general','mmoll')) {
									 newGlucose = Math.round(newGlucose*(new Number(0.0555))*10)/10;
								 } else if ((remoteElement.units as String).toUpperCase().indexOf(ResourceManager.getInstance().getString('general','mgperdl').toUpperCase()) == -1 && newUnit == 
									 ResourceManager.getInstance().getString('general','mgperdl')) {
									 newGlucose = Math.round(newGlucose/(new Number(0.0555)));
								 }
								 
								 new BloodGlucoseEvent(
									 newGlucose,
									 newUnit,
									 remoteElement._id + "-glucose",
									 removeBRInNotes(remoteElement.notes as String),
									 DateTimeUtilities.createDateFromNSCreatedAt(remoteElement.created_at).valueOf(),
									 new Number(remoteElement.helpdiabetes.lastmodifiedtimestamp),
									 true
								 ); 
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
								 var theMealEvent:MealEvent = new MealEvent(//in contradiction to medicin/bloodglucose and exerciseevents, I must add new mealevents to the trackinglist, because if i don't, the adding of selectedfooditems would fail because I wouldn't find the mealevent
									 "Meal from NightScout",
									 0,
									 0,
									 DateTimeUtilities.createDateFromNSCreatedAt(remoteElement.created_at).valueOf(),
									 null,
									 remoteElement._id + "-carbs",
									 removeBRInNotes(remoteElement.notes as String),
									 new Number(remoteElement.helpdiabetes.lastmodifiedtimestamp),
									 true);
								 theMealEvent.addSelectedFoodItem(createDummySelectedFoodItem(new Number((remoteElement.carbs))));
								 //trackingList.addItem(theMealEvent);
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
								 new ExerciseEvent(remoteElement.duration,
									 removeBRInNotes(remoteElement.notes as String),
									 remoteElement._id + "-exercise",
									 DateTimeUtilities.createDateFromNSCreatedAt(remoteElement.created_at).valueOf(),
									 new Number(remoteElement.helpdiabetes.lastmodifiedtimestamp),
									 true);
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
								 new MedicinEvent(new Number(remoteElement.insulin),
									 Settings.getInstance().getSetting(Settings.SettingsInsulinType1),
									 remoteElement._id + "-medicin",
									 removeBRInNotes(remoteElement.notes as String),
									 DateTimeUtilities.createDateFromNSCreatedAt(remoteElement.created_at).valueOf(),
									 new Number(remoteElement.helpdiabetes.lastmodifiedtimestamp),
									 true,
									 ResourceManager.getInstance().getString('editmedicineventview',MedicinEvent.BOLUS_TYPE_NORMAL),
									 new Number(0));
								 localElementsUpdated = true;
							 }
						 }
					 }
				 }
				 //ok so we end up with two lists, remoteElements, the ones with tobeupdatedatns = true need to be updated remotely
				 //the second list is localelements, those also need to be stored remotely,
				 updateRemoteElements();
			 } else {
				 //still need to make the call to nightscout
				 createAndLoadURLRequest(nightScoutTreatmentsUrl, URLRequestMethod.GET,null,null,getAllEvents,true);
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
				 if ((localElement as TrackingViewElement).eventid.length < 24) {
					 //we will not update these , it's been created with older version of helpdiabetes
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
					 newElement["enteredBy"] = "helpdiabetes";
					 var helpDiabetesObject:Object = new Object();
					 //helpDiabetesObject["deleted"] = "false"; not really useful because nightscout itself will not take this field into account - better to use google sync for that and to delete the object at NS effectively in stead of marking it as deleted
					 helpDiabetesObject["lastmodifiedtimestamp"] = (new Date((localElement as TrackingViewElement).lastModifiedTimestamp)).valueOf();
					 var lastModifiedAtNS:String = ((new Date()).valueOf() - (localElement as TrackingViewElement).lastModifiedTimestamp > 10000 
						 ? 
						 (new Date()).valueOf().toString() 
						 :
						 (localElement as TrackingViewElement).lastModifiedTimestamp.toString());
					 helpDiabetesObject["lastmodifiedatns"] = lastModifiedAtNS;
					 newElement["helpdiabetes"] = helpDiabetesObject;
					 
					 
					 if (localElement is BloodGlucoseEvent) {
						 //newElement[""] = (localElement ad BloodGlucoseEvent).;
						 newElement["glucose"] = (localElement as BloodGlucoseEvent).bloodGlucoseLevel;
						 newElement["eventType"] = "BG Check";
						 newElement["glucoseType"] = "Finger";
						 newElement["notes"] = (localElement as BloodGlucoseEvent).comment;
						 newElement["units"] = 
							 (localElement as BloodGlucoseEvent).unit == ResourceManager.getInstance().getString('general','mgperdl') ?
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
							 medicinEvent.bolustype != ResourceManager.getInstance().getString('editmedicineventview',MedicinEvent.BOLUS_TYPE_NORMAL)) {
							 //don't upload
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
					 createAndLoadURLRequest(nightScoutTreatmentsUrl, URLRequestMethod.PUT,null,JSON.stringify(newElement),updateRemoteElements,true);
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
			 
			 request.requestHeaders.push(new URLRequestHeader("api-secret", apiSecret));
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
				 trace("NightScoutSync.as : loader : url = " + request.url + ", request.data = " + request.data); 
		 }
		 
		 private function copyTrackingListIfNotDoneYet():void {
			 if (!trackingListAlreadyModified) {
				 trackingListAlreadyModified = true;
				 previousTrackingEventToShow = ModelLocator.getInstance().trackingEventToShow;
				 ModelLocator.getInstance().trackingEventToShow = (ModelLocator.getInstance().infoTrackingList.getItemAt(0) as TrackingViewElement).eventid;
				 ModelLocator.getInstance().copyOfTrackingList = ModelLocator.getInstance().infoTrackingList;
				 TrackingView.recalculateActiveInsulin();
			 }			
		 }
		 
		 private function createDummySelectedFoodItem(chosenAmount:Number):SelectedFoodItem {
			 return new SelectedFoodItem(DateTimeUtilities.createEventId(), 
				 "item from NS", 
				 new Unit(ResourceManager.getInstance().getString('general','gram_long'),1,0,0,1,0), 
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
				 copyTrackingListIfNotDoneYet();//this may be the case, eg when adding remote elements to local database, we don't update the trackinglist, but still elementsupdated = true
				 ModelLocator.getInstance().trackingList = new ArrayCollection();
				 localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,getAllEventsAndFillUpMealsFinished);
				 localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,getAllEventsAndFillUpMealsFinished);//don't see what to do in case of error
				 Database.getInstance().getAllEventsAndFillUpMeals(localdispatcher);
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
			 
			 function getAllEventsAndFillUpMealsFinished(event:Event):void
			 {
				 localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT, getAllEventsAndFillUpMealsFinished);
				 localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT, getAllEventsAndFillUpMealsFinished);
				 ModelLocator.getInstance().trackingList.refresh();
				 
				 ModelLocator.getInstance().refreshMeals();
				 ModelLocator.getInstance().copyOfTrackingList = ModelLocator.getInstance().trackingList;
				 ModelLocator.getInstance().trackingEventToShow = previousTrackingEventToShow;//could be a problem if that previous event was just deleted
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