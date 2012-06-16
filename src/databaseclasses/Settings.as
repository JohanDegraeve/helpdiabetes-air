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
		 * id to be used when adding a new meal event<br>
		 * only to be used within the database class therefore package private
		 */
		internal static const SettingNEXT_MEALEVENT_ID:int=2;
		/**
		 * id to be used when adding a new selected item<br>
		 * only to be used within the database class therefore package private
		 */
		internal static const SettingNEXT_SELECTEDITEM_ID:int=3;
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
			"en_US,nl_NL,fr_FR"//just a default value  
		];
		
		private static var instance:Settings = new Settings();
		
		public function Settings()
		{
			if (instance != null) {
				throw new Error("Settings class can only be accessed through Settings.getInstance()");	
			}
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
			return settings[settingId];
		}
		
		/**
		 * Set the setting specified by the setting id, database will also be updated asynchronously<br>
		 */
		public function setSetting(settingId:int, newValue:String):void {
			var dispatcher:EventDispatcher = new EventDispatcher();
			dispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,settingInsertionFailure);
			
			var oldValue:String = settings[settingId];
			
			settings[settingId] = newValue;
			Database.getInstance().updateSetting(settingId,newValue,dispatcher);
			
			function settingInsertionFailure(se:Event):void {
				settings[settingId] = oldValue;
			}
		}
		
		/**
		 * get the number of settings
		 */
		public function getNumberOfSettings():Number {
			return settings.length;
		}
		
		public function setSettingWithoutDatabaseUpdate(settingId:int, newValue:String):void {
			settings[settingId] = newValue;
		}
		
		private function getAmountOfSettings():int {
			return settings.length;
		}
	}
}