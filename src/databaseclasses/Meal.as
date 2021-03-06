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
 
 */
package databaseclasses
{
	import flash.events.EventDispatcher;
	
	import mx.core.ClassFactory;
	
	import databaseclasses.MealEvent;
	
	import model.ModelLocator;
	
	import myComponents.IListElement;
	import myComponents.MealItemRenderer;
	
	import utilities.DateTimeUtilities;
	import utilities.FromtimeAndValueArrayCollection;
	import utilities.Synchronize;
	import utilities.Trace;
	
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
		private var thisMeal:Meal;
		
		/**
		 * A meal can be created either with mealName - in which case MealEvent should be null - or with a MealEvent - in which case mealName should be null<br>
		 * At least one parameter should be null, at least one should not be null<br>
		 * <br>
		 * timeStamp will only be used if mealEvent = null, otherwise _timeStamp is set to mealEvent.timestamp<br>
		 * if mealEvent = null, and if also timeStamp = null, then _timeStamp is set to now - but in fact, timeStamp should then not be null
		 */
		public function Meal(newMealName:String = null,newMealEvent:MealEvent = null,newTimeStamp:Number = Number.NaN)
		{
			if (((newMealName == null) && (newMealEvent == null)) || ((newMealName != null) && (newMealEvent != null)))
				throw new Error("Meal must be craeted with either mealName or MealEvent equal to null. At least one parameter must be not null");	
			if (newMealName != null) {
				_mealName = newMealName;
				if (!isNaN(newTimeStamp)) {
					_timeStamp = newTimeStamp;
				}
				else {
					_timeStamp = (new Date()).valueOf();
				}
			}
			if (newMealEvent != null) {
				_mealEvent = newMealEvent;
				_timeStamp = _mealEvent.timeStamp;
				_mealName = _mealEvent._mealName;
				newMealEvent.meal = this;
			}
			thisMeal = this;
		}
		
		public function get mealName():String
		{
			return _mealName;
		}
		
		public function set mealName(value:String):void
		{
			_mealName = value;
		}
		
		public function get mealEvent():MealEvent
		{
			return _mealEvent;
		}
		
		internal function set mealEvent(value:MealEvent):void
		{
			_mealEvent = value;
			_mealEvent.meal = this;
		}
		
		/**
		 * adds a selected food item, if there's no mealevent yet then it will be created here<br>
		 * It is here also that the insulinratio to be used is defined,  this will be redefined each time a selectedfooditem is added<br>
		 */
		public function addSelectedFoodItem(selectedFoodItem:SelectedFoodItem):void {
			var previousBGlevel:Number = Number.NaN;
			var insulinRatio:Number;
			var localdispatcher:EventDispatcher = new EventDispatcher();
			var timeStampAsDate:Date = new Date(_timeStamp);
			
			if (_mealEvent == null) {
				//it's the first selectedfooditem, and if no timestamp was supplied then set _timestamp to current time
				//correction 2012-12-09, this was a residu from a previous version where timestamp was a parameter  in addSelectedFoodItem
				//but now timeStamp points to meal.timeStamp, which is never nan.
				/*if (isNaN(timeStamp)) {
				if (((new Date()).valueOf() - _timeStamp) > 0) {
				_timeStamp = (new Date()).valueOf();
				}
				}*/
				
				//added 2015 01 24
				//correction calculation insulinratio, should use timestamp of the meal, not the current time
				//also correctionfactor used in call to new MealEvent, is now taking current timestamp
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
				
				localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,mealEventCreated);
				localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationError);
				var correctionFactorList:FromtimeAndValueArrayCollection = FromtimeAndValueArrayCollection.createList(Settings.getInstance().getSetting(Settings.SettingsCorrectionFactor));
				_mealEvent = new MealEvent(mealName,insulinRatio, correctionFactorList.getValue(Number.NaN,"",timeStampAsDate),timeStampAsDate.valueOf(),localdispatcher,DateTimeUtilities.createEventId() + "-carbs", "",new Date().valueOf(),true,null,thisMeal, true);
			} else
				mealEventCreated(null);
			
			function mealEventCreated(de:DatabaseEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,mealEventCreated);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationError);
				
				//just adding the selectedfooditem without waiting for the result
				_mealEvent.addSelectedFoodItem(selectedFoodItem,null);
				
				//if de not null, then mealEventCreated was called after having created a new mealevent, that needs to be 
				//added in the trackinglist.
				if (de != null) {
					ModelLocator.trackingList.addItem(_mealEvent);
					ModelLocator.trackingList.refresh();
				}
				Settings.getInstance().setSetting(Settings.SettingTIME_OF_LAST_MEAL_ADDITION, (new Date()).valueOf().toString());
				Settings.getInstance().setSetting(Settings.SettingLAST_MEAL_ID,_mealEvent.eventid.toString());
			}
			
			function mealEventCreationError(de:DatabaseEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,mealEventCreated);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationError);
				Trace.myTrace("Error while creating mealeevent. Meal.as 0002");
			}
		}
		
		/**
		 * deletes a selected food item from the meal, if it is the last selectedfooditem in the mealevent then also the mealevent will be deleted<br>
		 * Also deletion from database <br>
		 * <br>
		 * Also triggers the synchronization, so that deleted is set to true in remote database<br>
		 * The same applies for mealevent, if mealevent is deleted<br>
		 * <br>
		 * - selectedFoodItem : the selectedfooditem to be deleted<br>
		 * If the  meal does not have the specified selectedfooditem then this function does nothing but trace an error<br>
		 * - dispatcher is used to dispatch the result
		 */
		public function deleteSelectedFoodItem(selectedFoodItem:SelectedFoodItem, dispatcher:EventDispatcher = null):void {
			var localdispatcher:EventDispatcher = new EventDispatcher();
			if (_mealEvent == null) {
				trace ("error in deletedSelectedFoodItem, the  meal does not have a mealEvent");
				return;
			}
			if (_mealEvent.selectedFoodItems == null) {
				trace ("error in deletedSelectedFoodItem, the meal has a mealEvent but the selectedFOodItems array is nul");
				return;
			}
			if (selectedFoodItem.mealEventId != _mealEvent.eventid) {
				trace ("error in deletedSelectedFoodItem, the specified selectedfooditem does not belong to the  mealevent in this meal");
				return;
			}
			
			Synchronize.getInstance().addObjectToBeDeleted(selectedFoodItem);
			Synchronize.getInstance().startSynchronize(true,false);
			_mealEvent.removeSelectedFoodItem(selectedFoodItem);
			
			if (_mealEvent.selectedFoodItems.length == 0) {
				localdispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,mealEventDeletedFromDB);
				localdispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,mealEventDeletionFromDBFailed);
				Database.getInstance().deleteMealEvent(_mealEvent.eventid,localdispatcher);
				ModelLocator.trackingList.removeItemAt(ModelLocator.trackingList.getItemIndex(_mealEvent));
				ModelLocator.trackingList.refresh();
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			} else {
				mealEventDeletedFromDB(null);
			}
			
			function mealEventDeletedFromDB(de:DatabaseEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,mealEventDeletedFromDB);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventDeletionFromDBFailed);
				if (de != null) {
					Synchronize.getInstance().addObjectToBeDeleted(_mealEvent);
					Synchronize.getInstance().startSynchronize(true,false);
					//_mealEvent = null;
				} else {
				}
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			function mealEventDeletionFromDBFailed(de:DatabaseEvent):void {
				localdispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,mealEventDeletedFromDB);
				localdispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventDeletionFromDBFailed);
				Trace.myTrace("Error while deleting mealeventin meal.as");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
		}
		
		/**
		 * as Meal implements IListElement, it shoud have a timestamp<br>
		 * it doesn't necessarly be to be equal to the time of creation, it can also be created as future meal, in which case the value will be entered by the user
		 */
		public function get timeStamp():Number
		{
			return _timeStamp;
		}
		
		public function set timeStamp(timeStamp:Number):void {
			this._timeStamp = timeStamp;
			if (_mealEvent != null)
				_mealEvent.timeStamp = timeStamp;
		}
		
		/**
		 * returns true of this meal has a mealevent
		 */
		public function hasMealEvent():Boolean {
			return (_mealEvent != null);
		}
		
		/**
		 * function defined in IListElement<br>
		 * here it will return a ClassFactory with MealEventItemRenderer
		 */
		public function listElementRendererFunction():ClassFactory
		{
			return new ClassFactory(MealItemRenderer);
		}
		
	}
}
