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
	import flash.events.EventDispatcher;
	
	import flashx.textLayout.tlf_internal;
	
	import mx.core.mx_internal;
	
	import myComponents.IListElement;

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
	public class Meal implements IListElement
	{
		private var _mealName:String;//normally it will be dinner, lunch, ...
		private var _mealEvent:MealEvent;
		private var _timeStamp:Number;//needed because it implements IListElement
		
		/**
		 * A meal can be created either with mealName - in which case MealEvent should be null - or with a MealEvent - in which case mealName should be null<br>
		 * At least one parameter should be null, at least one should not be null<br>
		 * <br>
		 * timeStamp will only be used if mealEvent = null, otherwise _timeStamp is set to mealEvent.timestamp<br>
		 * if mealEvent = null, and if also timeStamp = null, then _timeStamp is set to now - but in fact, timeStamp should then not be null
		 */
		public function Meal(mealName:String = null,mealEvent:MealEvent = null,timeStamp:Number = null)
		{
			if ((mealName == null) && (mealEvent == null) || (mealName != null) && (mealEvent != null))
			 	throw new Error("Meal must be craeted with either mealName or MealEvent equal to null. At least one parameter must be not null");	
            if (mealName != null) {
				_mealName = mealName;
				if (timeStamp != null)
					_timeStamp = timeStamp;
				else
					_timeStamp = (new Date()).valueOf();
			}
			if (mealEvent != null) {
				_mealName = mealEvent.mealName;
				_mealEvent = mealEvent;
				_timeStamp = mealEvent.timeStamp;
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
		
		/**
		 * adds a selected food item, if there's no mealevent yet then it will be created here<br>
		 * It is here also that the insulinratio to be used is defined,  this will be redefined each time a selectedfooditem is added<br>
		 * Also the previous blood glucose event is checked, if any. If the time difference is less than Settings.<br>
		 * <br>
		 * timeStamp is optional<br>
		 * if timeStamp is not null, then this meal.timeStamp and also if a new mealevent is created, the mealevent's timestamp is set to the timestamp value
		 * 
		 */
		public function addSelectedFoodItem(selectedFoodItem:SelectedFoodItem,timeStamp:Number = null):void {
			var now:Date = new Date();
			var previousBGlevel:Number = null;
			var insulinRatio:Number;
			var localdispatcher:EventDispatcher = new EventDispatcher();
			
			if (timeStamp != null)
				this._timeStamp = timeStamp;
			else ;//no need to set or change the timestamp because it's already been set during meal creation
			
			

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
			now = new Date();
			
			//let's find the last blood glucose event
			if (Settings.SettingLAST_BLOODGLUCOSE_EVENT_ID > 0) {
				var dispatcher:EventDispatcher = new EventDispatcher();
				dispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,previousBloodGlucoseEventRetrieved);
				dispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,previousBloodGlucoseEventRetrievalFailed);
				Database.getInstance().getPreviousGlucoseEvent(dispatcher);
			} else 
				previousBloodGlucoseEventRetrieved(null);
			
			function previousBloodGlucoseEventRetrieved(de:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,previousBloodGlucoseEventRetrieved);
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,previousBloodGlucoseEventRetrievalFailed);
			
				var previousBGEvent:BloodGlucoseEvent = null;
				if (de != null) {
					if (de.data != null) {
						previousBGEvent = (de.data as BloodGlucoseEvent);
						if (now.date.valueOf() - previousBGEvent.creationTimeStamp < Settings.SettingMAX_TIME_DIFFERENCE_LATEST_BGEVENT_AND_START_OF_MEAL) {
							previousBGlevel = previousBGEvent.bloodGlucoseLevel;
						}
					}
				} 
				if (mealEvent == null) {
					localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,mealEventCreated);
					localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationError);
					mealEvent = new mealEvent(mealName,insulinRatio,Settings.SettingCORRECTION_FACTOR, previousBGlevel,timeStamp,localdispatcher);
				}
			}
			
			function mealEventCreated(de:DatabaseEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,mealEventCreated);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationError);
				//de.lastInsertRowID - not interested
				mealEvent.addSelectedFoodItem(selectedFoodItem,null);
				Settings.SettingTIME_OF_LAST_MEAL_ADDITION = (new Date()).valueOf();
			}
				
		    function mealEventCreationError(de:DatabaseEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,mealEventCreated);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationError);
				trace("Error while creating mealeevent. Meal.as 0002");
			}
			
			function previousBloodGlucoseEventRetrievalFailed(de:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,previousBloodGlucoseEventRetrieved);
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,previousBloodGlucoseEventRetrievalFailed);
				trace("Error while getting bloodglucoseevent. Meal.as 0001");
			}
			
		}

		/**
		 * as Meal implements IListElement, it shoud have a timestamp<br>
		 */
		public function get timeStamp():Number
		{
			return _timeStamp;
		}
	}
}
