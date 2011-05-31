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
	import mx.core.mx_internal;

	/**
	 * a name for the meal and a mealevent that can be null<br>
	 * This class is in the first place created to hold the meals from which the user can chose when adding an item<br>
	 * 
	 * I could also have used a MealEvent  but there could be meals for which no mealevent exists yet<br> 
	 * 
	 * When the first selectedFoodItem is being added, then the MealEvent will be created, and that's also the moment that the carbohydrate
	 * ratio to be used will be calculated. So in theory, it may happen that mealname = breakfast, while insulinratio will be dinner, that may happen
	 * if the time between creating the meal, and adding the first selectedfooditem is too long, due to which the period changes<br>
	 * 
	 */
	public class Meal
	{
		private var _mealName:String;//normally it will be dinner, lunch, ...
		private var _mealEvent:MealEvent;
		
		/**
		 * A meal can be created either with mealName - in which case MealEvent should be null - or with a MealEvent - in which case mealName should be null<br>
		 * At least one parameter should be null, at least one should not be null
		 */
		public function Meal(mealName:String = null,mealEvent:MealEvent)
		{
			if ((mealName == null) && (mealEvent == null) || (mealName != null) && (mealEvent != null))
			 	throw new Error("Meal must be craeted with either mealName or MealEvent equal to null. At least one parameter must be not null");	
            if (mealName != null) 
				_mealName = mealName;
			if (mealEvent != null) {
				_mealName = mealEvent.mealName;
				_mealEvent = mealEvent;
			}
		}

		public function get mealName():String
		{
			return _mealName;
		}

		public function set mealName(value:String):void
		{
			_mealName = value;
		}

		internal function get mealEvent():MealEvent
		{
			return _mealEvent;
		}

		internal function set mealEvent(value:MealEvent):void
		{
			_mealEvent = value;
		}
		
		public function addSelectedFoodItem(selectedFoodItem:SelectedFoodItem):void {
			var now:Date = new Date();
			var insulinRatio:Number;
			now.setFullYear(1970,1,1);
			if ( now.getTime() < Settings.SettingBREAKFAST_UNTIL) {
				insulinRatio = Settings.SettingINSULIN_RATIO_BREKFAST;
			} else if ( now.getTime() < Settings.SettingLUNCH_UNTIL) {
				insulinRatio = Settings.SettingINSULIN_RATIO_LUNCH;
			} else if ( now.getTime() < Settings.SettingSNACK_UNTIL) {
				insulinRatio = Settings.SettingINSULIN_RATIO_SNACK;
			} else {
				insulinRatio = Settings.SettingINSULIN_RATIO_SUPPER;
			} 
			
			if (mealEvent == null) {
				previous bg level nog controleren
				mealEvent = new mealEvent(mealName,insulinRatio,Settings.SettingCORRECTION_FACTOR, previousBGlevel);
			
		    mealEvent.addSelectedFoodItem(selectedFoodItem,null);
		}


	}
}
