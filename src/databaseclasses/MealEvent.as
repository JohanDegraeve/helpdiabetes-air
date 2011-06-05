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
	import flash.events.ErrorEvent;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.core.ClassFactory;
	
	import myComponents.ITrackingElement;
	import myComponents.MealEventItemRenderer;
	

	/**
	 * this is a meal event,<br>
	 * creation of a meal event, destroying a mealevent (? possible ?), modification of a meal event all affects database,<br>
	 * ie a database update or insertion will be done behind the scene. That's why MealEvent is part of package databaseclasses.<br>
	 * In general the methods do not handle database update errors. The classes will exist or be modified but in case a database update occurs, there's no method to inform the client
	 * <br>
	 * Also the selected Food Items are stored in here.<br>
	 */ 
	public class MealEvent implements ITrackingElement
	{
		private var _mealName:String;
		/**
		 * the insulineratio, if null then there was no insuline ratio for the period in which the meal was created or modified
		 */ 
		private var _insulinRatio:Number;
		/**
		 * the correction factor, if null then correction will be applied
		 */ 
		private var _correctionFactor:Number;
		/**
		 * previous bloodglucose level, if null then no correction will be applied
		 */ 
		private var _previousBGlevel:int;
		/**
		 * the mealeventid
		 */ 
		private var _mealEventId:Number;
		/**
		 * the lastmodifiedtimestamp
		 */ 
		private var _lastModifiedTimeStamp:Number;
		
		private var _selectedFoodItems:ArrayCollection;
		
		private var _timeStamp:Number;
		
		/**
		 * mealEvent will be created and automatically inserted into the database<br>
		 * insulinRatio, previousBGlevel and correctionFactor can be null which means there's no settings for the defined period
		 */
		public function MealEvent(mealName:String, insulinRatio:Number, correctionFactor:Number,previousBGlevel:Number,dispatcher:EventDispatcher) {
			this._mealName = mealName;
			this._insulinRatio = insulinRatio;
			this._previousBGlevel = previousBGlevel;
			_mealEventId = new Number(Settings.getInstance().getSetting(Settings.SettingNEXT_MEALEVENT_ID));
			_selectedFoodItems = new ArrayCollection();
			_lastModifiedTimeStamp = new Date();
			timeStamp = _lastModifiedTimeStamp;//this is actually the creationTimeStamp
			
			var localDispatcher:EventDispatcher = new EventDispatcher();
			localDispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationFailed);
			Database.getInstance().createNewMealEvent(mealName,
														_lastModifiedTimeStamp.valueOf().toString(),
														insulinRatio,correctionFactor,
														previousBGlevel,
														timeStamp.valueOf().toString(),
														localDispatcher);
			Settings.getInstance().setSetting(Settings.SettingNEXT_MEALEVENT_ID, _mealEventId + 1);
			
			
			function mealEventCreationFailed (errorEvent:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationFailed);
				Settings.getInstance().setSetting(Settings.SettingNEXT_MEALEVENT_ID, _mealEventId);
				trace("Error while storing mealevent in database. MealEvent.as 0001");
				if (dispatcher != null) {
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.RESULT_EVENT));
				}
			}
		}
		
		/**
		 * as MealEvent implements Itimestamp, it shoud have a timestamp<br>
		 * the value will be assigned at creation, 
		 */
		public function get timeStamp():Number
		{
			return _timeStamp;
		}

		internal function addSelectedFoodItem(selectedFoodItem:SelectedFoodItem,dispatcher:EventDispatcher = null):void {
			_selectedFoodItems.addItem(selectedFoodItem);
			selectedFoodItem.selectedItemId = Settings.getInstance().getSetting(Settings.SettingNEXT_SELECTEDITEM_ID);
			selectedFoodItem.mealEventId = this._mealEventId;
			
			var localDispatcher:EventDispatcher = new EventDispatcher();
			localDispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,selectedItemCreationFailed);
			localDispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,selectedItemCreated);
			
			Database.getInstance().createNewSelectedItem(
				selectedFoodItem._selectedItemId,
				this._mealEventId,
				selectedFoodItem.itemDescription,
				selectedFoodItem.unit.unitDescription,
				selectedFoodItem.unit.standardAmount,
				selectedFoodItem.unit.kcal,
				selectedFoodItem.unit.protein,
				selectedFoodItem.unit.carbs,
				selectedFoodItem.unit.fat,
				selectedFoodItem.chosenAmount,
				localDispatcher);
			Settings.getInstance().setSetting(Settings.SettingNEXT_SELECTEDITEM_ID, selectedFoodItem.selectedItemId +1 );
			
			function selectedItemCreated(event:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,selectedItemCreationFailed);
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,selectedItemCreated);
				localDispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,timeStampUpdateFailed);
				localDispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,timeStampUpdated);
				_lastModifiedTimeStamp = (new Date()).valueOf();
				Database.getInstance().updateMealEventLastModifiedTimeStamp(_lastModifiedTimeStamp,_mealEventId,localDispatcher);	
			}
				
			function timeStampUpdated(event:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,timeStampUpdateFailed);
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,timeStampUpdated);
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.RESULT_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function timeStampUpdateFailed(event:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,timeStampUpdateFailed);
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,timeStampUpdated);
				trace("Error while updating itmestamp. MealEvent.as 0003");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
			
			function selectedItemCreationFailed (errorEvent:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,selectedItemCreationFailed);
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,selectedItemCreated);
				Settings.getInstance().setSetting(Settings.SettingNEXT_SELECTEDITEM_ID, selectedFoodItem.selectedItemId );
				trace("Error while creation selected item. MealEvent.as 0002");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
				}
			}
		}

		/**
		 * the mealType
		 */
		internal function get mealName():String
		{
			return _mealName;
		}

		/**
		 * @private
		 */
		internal function set mealName(value:String):void
		{
			_mealName = value;
		}
		

		internal function get previousBGlevel():int
		{
			return _previousBGlevel;
		}

		internal function set previousBGlevel(value:int):void
		{
			_previousBGlevel = value;
		}

		/**
		 * as MealEvent implements Itimestamp, it shoud have a timestamp<br>
		 * the value will be assigned at creation, 
		 */
		public function get timeStamp():Number
		{
			return _timeStamp;
		}
		
		/**
		 * as MealEvent implements Itimestamp, it shoud have a timestamp<br>
		 * the value will be assigned at creation, 
		 */
		private function set timeStamp():Number
		{
			return _timeStamp;
		}
		
		/**
		 * creates a mealevent without storing in the database<br>
		 * Uses the classfactory class, and simply assigns all parameters to the corresponding fields off the new instance.
		 */
		internal static function createMealEventWithoutDBStorage(
			mealName:String, 
			mealEventId:Number,
			lastModifiedTimeStamp:Number,
			creationTimeStamp:Number,
			insulinRatio:Number, 
			correctionFactor:Number,
			previousBGlevel:Number,
			selectedFoodItems:ArrayCollection):MealEvent 
		{
			var creator:ClassFactory = new ClassFactory(MealEvent);
			creator.properties = {
				_mealName:mealName,
				_insulinRatio:insulinRatio,
				_correctionFactor:correctionFactor,
				_previousBGlevel:previousBGlevel,
				_mealEventId:mealEventId,
				_lastModifiedTimestamp:lastModifiedTimeStamp,
				_selectedFoodItems:selectedFoodItems,
				_timeStamp:creationTimeStamp
			};
			return creator.newInstance();	
			
		}
		
		public function trackingItemRendererFunction():ClassFactory
		{
			return new ClassFactory(MealEventItemRenderer);
		}
		

	}
}