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
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.core.UIComponent;
	import mx.resources.ResourceManager;
	
	/**
	 * Each time a new settings is defined, an additional constant should be defined, with default value and the array must be extended.<br>
	 * The first constant is 0;<br>
	 * It's a singleton, at first creation, all settings will be intialized with default values.<br>
	 * Each time a new value is stored, the value will be written to the database. <br>
	 * All settings can be set and get , as string representation.<br>
	 */
	public class Settings
		
	{
		[ResourceBundle("editmedicineventview")]
		[ResourceBundle("editexerciseeventview")]
		
		/** EXTEND LIST OF CONSTANTS IN CASE NEW SETTING NEEDS TO BE DEFINED  */
		/**
		 * the meal id where the last fooditem was stored
		 */ 
		public  static const SettingLAST_MEAL_ID:int = 0; 
		/**
		 * the time in milliseconds since midnight January 1, 1970, universal time, when the last fooditem was added
		 */ 
		public static const SettingTIME_OF_LAST_MEAL_ADDITION:int = 1;
		/**
		 * not used anymore
		 */
		internal static const SettingNEXT_MEALEVENT_ID:int=2;
		/**
		 * creationtimestamp of the last event that was uploaded to google excel logbook
		 */
		public static const SettingLastUploadedEventTimeStamp:int=3;
		/**
		 * insulinratio breakfast, amount of carbs per unit of insulin
		 */ 
		public static const SettingINSULIN_RATIO_BREKFAST:int=4;
		/**
		 * insulinratio lunch, amount of carbs per unit of insulin
		 */ 
		public static const SettingINSULIN_RATIO_LUNCH:int=5;
		/**
		 * insulinratio snack, amount of carbs per unit of insulin
		 */ 
		public static const SettingINSULIN_RATIO_SNACK:int=6;
		/**
		 * insulinratio supper, amount of carbs per unit of insulin
		 */ 
		public static const SettingINSULIN_RATIO_SUPPER:int=7;
		/**
		 * switch time breakfast to lunch, local time
		 */
		public static const SettingBREAKFAST_UNTIL: int =  8;
		/**
		 * switch time lunch to snack, local time
		 */
		public static const SettingLUNCH_UNTIL:int = 9;
		/**
		 * switch time snack to supper , , local time
		 */
		public static const SettingSNACK_UNTIL:int = 10;
		/**
		 * correction factor to be used when calculating insulindose
		 */
		public static const SettingCORRECTION_FACTOR:int=11
		/**
		 * id of last bloodglucose event
		 */
		public static const SettingLAST_BLOODGLUCOSE_EVENT_ID:int = 12;
		/**
		 * maximum time difference between a meal and the last bloodglucose event for calculating the correction factor<br>
		 * in seconds 
		 */
		public static const SettingMAX_TIME_DIFFERENCE_LATEST_BGEVENT_AND_START_OF_MEAL:int= 13;
		/**
		 * unit to use for bloodglucose values<br>
		 * initial value = mgperdl 
		 */
		public static const SettingsBLOODGLUCOSE_UNIT:int = 14;
		
		/**
		 * the target bloodglucoselevel to use for applying the correction factor
		 */
		public static const SettingsTARGET_BLOODGLUCOSELEVEL:int = 15;
		/**
		 * what is the important value for the user : carbs, kilocalories, fat or protein
		 */
		public static const SettingsIMPORTANT_VALUE_FOR_USER:int = 16;
		
		/**
		 * the string for the first insulin type , default value taken from resources
		 */
		public static const SettingsInsulinType1:int = 17;
		/**
		 * the string for the second insulin type  , default value taken from resources
		 */
		public static const SettingsInsulinType2:int = 18;
		/**
		 * the string for the third insulin type  , default value taken from resources
		 */
		public static const SettingsInsulinType3:int = 19;
		/**
		 * the string for the fourth insulin type  , default value taken from resources
		 */
		public static const SettingsInsulinType4:int = 20;
		/**
		 * the string for the fifth insulin type  , default value taken from resources
		 */
		public static const SettingsInsulinType5:int = 21;
		
		/**
		 * denotes the default medicin, value is int 17, 18, 19, 20 or 21, denoting type 1, ... 5 respectively<br>
		 * default value = 17
		 */
		public static const SettingsDefaultMedicin:int = 22;
		/**
		 * the string for exercise type, default value taken from resources 
		 */
		public static const SettingsExerciseType1:int = 23;
		/**
		 * the string for exercise type, default value taken from resources 
		 */
		public static const SettingsExerciseType2:int = 24;
		/**
		 * the string for exercise type, default value taken from resources 
		 */
		public static const SettingsExerciseType3:int = 25;
		/**
		 * the string for exercise type, default value taken from resources 
		 */
		public static const SettingsExerciseType4:int = 26;
		/**
		 * the string for exercise type, default value taken from resources 
		 */
		public static const SettingsExerciseType5:int = 27;
		/**
		 * denotes the default exercise, value is int 23, 24, 25, 26 or 27, denoting type 1, ... 5 respectively<br>
		 * default value = 23
		 */
		public static const SettingsDefaultExercise:int = 28;
		/**
		 * maximum size of trackingview, in days, default value  = 30;
		 */
		public static const SettingsMAXTRACKINGSIZE:int = 29;
		/**
		 * localeChain to be used for choosing translations. The locale chain is a string here <br>
		 * Example if localeChain = ["en_US","nl_NL"], then the setting here is "en_US,nl_NL"
		 */
		public static const SettingsLOCALECHAIN_asString:int = 30;
		/**
		 * to maintain the first startup of the app, never is never started up before
		 */
		public static const SettingsFirstStartUp:int=31;
		
		/** help setings **/
		/** if false, help text will not be shown **/
		public static const SettingsHelpTextAddFoodItemViewSelectUnitButton:int=32;
		public static const SettingsHelpTextAddFoodItemViewSelectMealButton:int=33;
		public static const SettingsHelpTextAddFoodItemViewAmountButtonsWhenComingFromFoodCounterView:int=34;
		public static const SettingsHelpTextAddFoodItemViewAmountButtonsWhenComingFromTrackingView:int=35;
		public static const SettingsHelpTextAddFoodItemViewOkButton:int=36;
		public static const SettingsHelpTextChangeMealDateAndTimeViewButtons:int=37;
		public static const SettingsHelpTextAddFoodItemViewTrashButton:int=38;
		public static const SettingsHelpTextEditMealEventViewEditSelectedItem:int=39;
		public static const SettingsHelpTextEditBGEventViewChangeAmount:int=40;
		public static const SettingsHelpTextEditBGEventViewChangeDateAndTime:int=41;
		public static const SettingsHelpTextEditMedicinEventViewChangeMedicinType:int=42;
		public static const SettingsHelpTextEditMedicinEventViewChangeAmount:int=43;
		public static const SettingsHelpTextEditExerciseEventViewChangeExerciseType:int=44;
		public static const SettingsHelpTextBolusCalculationViewChangeCarbRatio:int=45;
		public static const SettingsHelpTextMealTimesViewChangeMealTimes:int=46;
		public static const SettingsHelpTextMedicinViewChangeMedicinType:int=47;
		public static const SettingsHelpTextExerciseViewChangeMedicinType:int=48;
		public static const SettingsHelpTextDatabaseViewChangeStorage:int=49;
		public static const SettingsHelpTextEditMedicinEventViewOkButton:int=50;
		public static const SettingsHelpTextEditExerciseEventViewOkButton:int=51;
		public static const SettingsHelpTextEditBGEventViewOkButton:int=52;
		public static const SettingsHelpTextEditMealEventViewEditDateAndTime:int=53;
		public static const SettingsHelpTextOwnFoodItemView:int=54;
		public static const SettingsHelpText55:int=55;
		public static const SettingsHelpText56:int=56;
		public static const SettingsHelpText57:int=57;
		public static const SettingsHelpText58:int=58;
		public static const SettingsHelpText59:int=59;
		public static const SettingsHelpText60:int=60;
		public static const SettingsHelpText61:int=61;
		public static const SettingsHelpText62:int=62;
		public static const SettingsHelpText63:int=63;
		public static const SettingsHelpText64:int=64;
		public static const SettingsHelpText65:int=65;
		public static const SettingsHelpText66:int=66;
		public static const SettingsHelpText67:int=67;
		public static const SettingsHelpText68:int=68;
		public static const SettingsHelpText69:int=69;
		public static const SettingsHelpText70:int=70;
		public static const SettingsHelpText71:int=71;
		public static const SettingsHelpText72:int=72;
		public static const SettingsHelpText73:int=73;
		public static const SettingsHelpText74:int=74;
		public static const SettingsHelpText75:int=75;
		public static const SettingsHelpText76:int=76;
		public static const SettingsHelpText77:int=77;
		public static const SettingsHelpText78:int=78;
		public static const SettingsHelpText79:int=79;
		public static const SettingsHelpText80:int=80;
		public static const SettingsHelpText81:int=81;
		public static const SettingsHelpText82:int=82;
		public static const SettingsHelpText83:int=83;
		public static const SettingsHelpText84:int=84;
		public static const SettingsHelpText85:int=85;
		public static const SettingsHelpText86:int=86;
		public static const SettingsHelpText87:int=87;
		public static const SettingsHelpText88:int=88;
		public static const SettingsHelpText89:int=89;
		public static const SettingsHelpText90:int=90;
		public static const SettingsHelpText91:int=91;
		public static const SettingsHelpText92:int=92;
		public static const SettingsHelpText93:int=93;
		public static const SettingsHelpText94:int=94;
		public static const SettingsHelpText95:int=95;
		public static const SettingsHelpText96:int=96;
		public static const SettingsHelpText97:int=97;
		public static const SettingsHelpText98:int=98;
		public static const SettingsHelpText99:int=99;
		public static const SettingsHelpText100:int=100;
		/**
		 * access_token for Google sync 
		 */
		public static const SettingsAccessToken:int=101;
		/**
		 * refresh_token for Google sync
		 */
		public static const SettingsRefreshToken:int=102;
		public static const SettingsLastSyncTimeStamp:int=103;
		/**
		 * index to array of column names in the foodtable in google docs, index points to the next column that needs to be created<br>
		 * 0 = first one , 1 = second, ... if > size of array of column names, then all column names are created 
		 */
		public static const SettingsNextColumnToAddInFoodTable:int=104;
				/**
		 * A user may have installed this app on several devices. Only one device will upload the foodtable to google docs.<br>
		 * This setting indicates if the foodtable has been or is being created by this instance. 
		 */
		public static const SettingsIMtheCreateorOfGoogleExcelFoodTable:int=105;
		/**
		 * index to fooditems table in the foodtable in google docs, index points to the next row that needs to be inserted<br>
		 * 0 = first one , 1 = second, ... if > size of foodtable in the database installed here, then all rows are uploaded<br>
		 * Once upload is finished, this value may not match anymore, because user may have downloaded a new database with a different size,
		 * therefor the next setting is also important
		 */
		public static const SettingsNextRowToAddInFoodTable:int=106;
		public static const SettingsAllFoodItemsUploadedToGoogleExcel:int=107;
		/**
		 * index to array of column names in the logbook in google docs, index points to the next column that needs to be created<br>
		 * 0 = first one , 1 = second, ... if > size of array of column names, then all column names are created 
		 */
		public static const SettingsNextColumnToAddInLogBook:int=108;
		
		/** EXTEND ARRAY WITH DEFAULT VALUES IN CASE NEW SETTING NEEDS TO BE DEFINED */
		private var settings:Array = [
			"none",// initially there will be no meal too which the last  fooditem has been added
			new Date(0).valueOf().toString(), //midnight January 1, 1970, universal time,
			"1", //the first meal id to be used
			"1", //first selected item id to be used
			"0", //insulin ratio breakfast
			"0", //lunch
			"0", //snack
			"0", //supper
			"37800000", // January 1, 1970, 10h30 Hr in ms, local time,
			"55800000", // January 1, 1970, 15h30 Hr in ms, local time,
			"61200000", // January 1, 1970, 17 Hr in ms, local time,
			"0", //correction factor
			"0", //the first blood glucose event id to be used
			"999999", // a high value for maximum time difference last bloodglucose event and meal
			"mgperdl", //unit for bloodglucose metering, this value must be known in locale/general.properties
			"120",
			"carbs",//possible values are "carbs", "protein", "fat", "kilocalories"
			"insulin type 1 defined in constructor",
			"insulin type 2 defined in constructor",
			"insulin type 3 defined in constructor",
			"insulin type 4 defined in constructor",
			"insulin type 5 defined in constructor",
			"17",//default insulin type, meaning insulin type 1
			"exercise type 1 defined in constructor",
			"exercise type 2 defined in constructor",
			"exercise type 3 defined in constructor",
			"exercise type 4 defined in constructor",
			"exercise type 5 defined in constructor",
			"23",//default exercise type, meaning exercise type 1
			"30",//default length of trackingview, in days
			"en_US,nl_NL,fr_FR",//just a default value,  
			"firsttartuptime defined in constructor",//firststartuptime, will be set in constructor
			"true",//SettingsAddFoodItemViewSelectUnitButton
			"true",//SettingsHelpTextAddFoodItemViewSelectMealButton
			"true",//SettingsHelpTextAddFoodItemViewAmountButtons
			"true",//SettingsHelpTextAddFoodItemViewAmountButtonsWhenComingFromTrackingView
			"true",//SettingsHelpTextAddFoodItemViewOkButton
			"true",
			"true",//SettingsHelpTextAddFoodItemViewTrashButton
			"true",//SettingsHelpTextEditMealEventViewEditSelectedItem
			"true",//SettingsHelpTextEditBGEventViewChangeAmount
			"true",//SettingsHelpTextEditBGEventViewChangeDateAndTime
			"true",//SettingsHelpTextEditMedicinEventViewChangeMedicinType
			"true",//SettingsHelpTextEditMedicinEventViewChangeAmount
			"true",//SettingsHelpTextEditExerciseEventViewChangeMedicinType
			"true",//SettingsHelpTextBolusCalculationViewChangeCarbRatio
			"true",//SettingsHelpTextMealTimesViewChangeMealTimes
			"true",//SettingsHelpTextMedicinViewChangeMedicinType
			"true",//SettingsHelpTextExerciseViewChangeMedicinType
			"true",//SettingsHelpTextDatabaseViewChangeStorage
			"true",//ok buttons for medicin event, exercise event and bloodglucoseevent
			"true",
			"true",
			"true",//number 53
			"true",//SettingsHelpTextOwnFoodItemView, 54
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",//default access token
			"",//default refresh token
			"0",//lastsynctimestamp
			"0",//index to column names for google excel foodtable
			"false",//creator of foodtable on google excel
			"0",//SettingsNextRowToAdd
			"false",//all fooditmes uploaded or not
			"0"
		];
		
		/** array with lastmodifiedtimestamp<br> 
		 * initialisation in the same way as settingsitself<br>
		 */
		private var settingsLastModifiedTimeStamp:Array;
		
		private static var instance:Settings = new Settings();
		
		public function Settings()
		{
			if (instance != null) {
				throw new Error("Settings class can only be accessed through Settings.getInstance()");	
			}
			//all settings are being set to initial values, be aware that in case there are already settings in the database
			//then the settings array will be reset during database opening.
			//There's already a database if it's not the first startup
			// in other words, if this is the first startup, then these are the values
			settings[SettingsInsulinType1] = ResourceManager.getInstance().getString('editmedicineventview','insulintype1');
			settings[SettingsInsulinType2] = ResourceManager.getInstance().getString('editmedicineventview','insulintype2');
			settings[SettingsInsulinType3] = ResourceManager.getInstance().getString('editmedicineventview','insulintype3');
			settings[SettingsInsulinType4] = ResourceManager.getInstance().getString('editmedicineventview','insulintype4');
			settings[SettingsInsulinType5] = ResourceManager.getInstance().getString('editmedicineventview','insulintype5');
			settings[SettingsExerciseType1] = ResourceManager.getInstance().getString('editexerciseeventview','exercisetype1');
			settings[SettingsExerciseType2] = ResourceManager.getInstance().getString('editexerciseeventview','exercisetype2');
			settings[SettingsExerciseType3] = ResourceManager.getInstance().getString('editexerciseeventview','exercisetype3');
			settings[SettingsExerciseType4] = ResourceManager.getInstance().getString('editexerciseeventview','exercisetype4');
			settings[SettingsExerciseType5] = ResourceManager.getInstance().getString('editexerciseeventview','exercisetype5');
			settings[SettingsFirstStartUp] = (new Date()).valueOf().toString();
			
			settingsLastModifiedTimeStamp = new Array(settings.length);
			for (var i:int = 0;i < settingsLastModifiedTimeStamp.length;i++)
				settingsLastModifiedTimeStamp[i] = new Number(0);
			
			instance = this;
		}
		
		public static function getInstance():Settings {
			if (instance == null) instance = new Settings();
			return instance;
		}
		
		/**
		 * get the setting specified by the Setting id
		 */
		public function getSetting(settingId:int):String {
			//trace("setting retrieved = " + settingId);
			return settings[settingId];
		}
		
		/**
		 * get the lastmodifiedtimestamp for the setting specified by the Setting id
		 */
		public function getSettingLastModifiedTimeStamp(settingId:int):Number {
			return settingsLastModifiedTimeStamp[settingId];
		}
		
		/**
		 * Set the setting specified by the setting id, database will also be updated asynchronously<br>
		 * If the settingid is the maxtrackingsize, then also lastsynctimestamp will be reset to current date - maxtrackingsize<br>
		 * if lastModifiedTimeStamp == null then current date and time are used
		 */
		public function setSetting(settingId:int, newValue:String,lastModifiedTimeStamp:Number = Number.NaN):void {
			var dispatcher:EventDispatcher = new EventDispatcher();
			dispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,settingInsertionFailure);
			dispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,settingInsertionSuccess);
			
			var oldValue:String = settings[settingId];
			var oldLastModifiedTimeStamp:Number = settingsLastModifiedTimeStamp[settingId] ;
			
			if (isNaN(lastModifiedTimeStamp))
				lastModifiedTimeStamp = (new Date()).valueOf();
			settingsLastModifiedTimeStamp[settingId] = lastModifiedTimeStamp; 
				
			settings[settingId] = newValue;
			
			Database.getInstance().updateSetting(settingId, newValue, lastModifiedTimeStamp, dispatcher);
			
			function settingInsertionFailure(se:Event):void {
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,settingInsertionFailure);
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,settingInsertionSuccess);
				settings[settingId] = oldValue;
				settingsLastModifiedTimeStamp[settingId] = oldLastModifiedTimeStamp;
			}
			
			function settingInsertionSuccess(se:Event):void {
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,settingInsertionFailure);
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,settingInsertionSuccess);
			}
		}
		
		/**
		 * get the number of settings
		 */
		public function getNumberOfSettings():Number {
			return settings.length;
		}
		
		public function setSettingWithoutDatabaseUpdate(settingId:int, newValue:String, lastModifiedTimeStamp:Number = Number.NaN):void {
			if (isNaN(lastModifiedTimeStamp))
				lastModifiedTimeStamp = (new Date()).valueOf();
			
			settings[settingId] = newValue;
			settingsLastModifiedTimeStamp[settingId] = lastModifiedTimeStamp;
		}
		
		private function getAmountOfSettings():int {
			return settings.length;
		}
	}
}