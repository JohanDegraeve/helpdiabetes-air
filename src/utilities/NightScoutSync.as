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
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.formatters.DateFormatter;
	import mx.resources.ResourceManager;
	
	import databaseclasses.Settings;
	
	import model.ModelLocator;

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
		private var syncRunning:Boolean;
		private var rerunNecessary:Boolean;
		private var alReadyGATracked:Boolean;
		private var timer2:Timer;
		private var localElementsUpdated:Boolean;
		private var retrievalCounter:int;
		private var nightScoutError_Invalid_Credentials:String = "TO BE COMPLETED";
		private var secondAttempt:Boolean;
		/**
		 * when a function tries to access nightscout api, but that fails ... to be completed
		 * copies from google sync which works with access_tokens that need to be refreshed, not necessary here
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



		public function NightScoutSync()
		{
			if (instance != null) {
				throw new Error("NightScoutSync class can only be accessed through NightScoutSync.getInstance()");	
			}
			debugMode = ModelLocator.debugMode;
			
			syncRunning = false;
			
			rerunNecessary = false;
			
			alReadyGATracked = false;//only one google analytics tracking per instance
			listOfElementsToBeDeleted = new ArrayList();
			instance = this;
			currentSyncTimeStamp = 0;

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
		public function startNightScoutSync(immediateRunNecessary:Boolean = false, event:Event = null):void {
			if (timer2 != null) {
				if (timer2.hasEventListener(TimerEvent.TIMER))
					timer2.removeEventListener(TimerEvent.TIMER,startNightScoutSync);
				timer2.stop();
				timer2 = null;
			}
			
			trace("in startNightScoutSync");
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
			if ((syncRunning && (timeSinceLastSyncMoreThanXMinutes))  || (!syncRunning && (immediateRunNecessary || timeSinceLastSyncMoreThanXMinutes))) {
				localElementsUpdated  = false;
				retrievalCounter = 0;
				trackingList = ModelLocator.getInstance().trackingList;
				currentSyncTimeStamp = new Date().valueOf();
				lastSyncTimeStamp = new Number(Settings.getInstance().getSetting(Settings.SettingsLastGoogleSyncTimeStamp));
				if (debugMode)
					trace("lastsynctimestamp = " + new DateFormatter().format(new Date(lastSyncTimeStamp)));
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
		
		private function synchronize():void {
			localElements = new ArrayList();
			
			remoteElements = new ArrayList();
			remoteElementIds = new ArrayList();
			secondAttempt = false;
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
		


	}
}