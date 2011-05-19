	<!--
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
	
	-->

package databaseclasses
{
	/**
	 * Each time a new settings is defined, an additional constant should be defined, with default value and the array must be extended.
	 * The first constant is 0;
	 * It's a singleton, at first creation, all settings will be intialized with default values.
	 * Each time a new value is stored, the value will be written to the database. 
	 * All settings can be set and get , as string representation.
	 */
	public class Settings
		
	{
		/** EXTEND LIST OF CONSTANTS IN CASE NEW SETTING NEEDS TO BE DEFINED  */
		/**
		 * the meal id where the last fooditem was stored
		 */ 
		public var const SettingLAST_MEAL_ID:int = 0; 
		/**
		 * the time in milliseconds since midnight January 1, 1970, universal time, when the last fooditem was added
		 */ 
		public var const SettingTIME_OF_LAST_MEAL_ADDITION = 1;
		
		/** EXTEND ARRAY WITH DEFAULT VALUES IN CASE NEW SETTING NEEDS TO BE DEFINED */
		private var settings:Array = [
			"none",// initially there will be no meal too which the last  fooditem has been added
			new Date(0).valueOf().toString();
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
		public function setSetting(settingId:int, newValue:String) {
			settings[settingId] = newValue;
			... store in database;
		}
		
		/**
		 * get the number of settings
		 */
		public function getNumberOfSettings():Number {
			return settings.length;
		}
	}
}