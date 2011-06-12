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

	/**
	 * Each time a new settings is defined, an additional constant should be defined, with default value and the array must be extended.<br>
	 * The first constant is 0;<br>
	 * It's a singleton, at first creation, all settings will be intialized with default values.<br>
	 * Each time a new value is stored, the value will be written to the database. <br>
	 * All settings can be set and get , as string representation.<br>
	 */
	public class Settings
		
	{
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
		 * switch time breakfast to lunch
		 */
		public static const SettingBREAKFAST_UNTIL: int =  8;
		/**
		 * switch time lunch to snack
		 */
		public static const SettingLUNCH_UNTIL:int = 9;
		/**
		 * switch time snack to supper 
		 */
		public static const SettingSNACK_UNTIL:int = 10;
		/**
		 * correction factor to be used when calculating insulindose
		 */
		public static const SettingCORRECTION_FACTOR:int=11;
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
		 * initial value = mg/dl 
		 */
		public static const SettingsBLOODGLUCOSE_UNIT:int = 14;
		
		/**
		 * the target bloodglucoselevel to use for applying the correction factor
		 */
		public static const SettingsTARGET_BLOODGLUCOSELEVEL:int = 15;
		
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
			"32400000", // January 1, 1970, 9 Hr in ms
			"50400000", // January 1, 1970, 14 Hr in ms
			"61200000", // January 1, 1970, 17 Hr in ms
			"0", //correction factor
			"0", //the first blood glucose event id to be used
			"999999", // a high value for maximum time difference last bloodglucose event and meal
			"mg/dL", //unit for bloodglucose metering
			"120"
		];
		
		private static var instance:Settings = new Settings();
		
		public function Settings()
		{
			if (instance != null) {
				throw new Error("Settings class can only be accessed through Settings.getInstance()");	
			}
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
		 * Set the setting specified by the setting id, database will also be updated asynchronously
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
		
		internal function setSettingWithoutDatabaseUpdate(settingId:int, newValue:String):void {
			settings[settingId] = newValue;
		}
		
		private function getAmountOfSettings():int {
			return settings.length;
		}
	}
}