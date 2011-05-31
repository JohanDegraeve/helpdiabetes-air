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
	

	/**
	 * this is a meal event,<br>
	 * creation of a meal event, destroying a mealevent (? possible ?), modification of a meal event all affects database,<br>
	 * ie a database update or insertion will be done behind the scene. That's why MealEvent is part of package databaseclasses.<br>
	 * In general the methods do not handle database update errors. The classes will exist or be modified but in case a database update occurs, there's no method to inform the client
	 * <br>
	 * Also the selected Food Items are stored in here.<br>
	 */ 
	public class MealEvent
	{
		private var _mealName:String;
		/**
		 * the insulineratio, if null then there was no insuline ratio for the period in which the meal was created or modified
		 */ 
		private var insulineRatio:Number;
		/**
		 * the correction factor, if null then there was no correction factor for the period in which the meal was created or modified
		 */ 
		private var correctionFactor:Number;
		/**
		 * previous bloodglucose level
		 */ 
		private var _previousBGlevel:int;
		/**
		 * the mealeventid
		 */ 
		private var mealeventId:Number;
		/**
		 * the lastmodifiedtimestamp
		 */ 
		private var lastModifiedTimestamp:Date;
		
		private var selectedFoodItems:ArrayCollection;
		
		/**
		 * mealEvent will be created and automatically inserted into the database<br>
		 * insulinRatio, previousBGlevel and correctionFactor can be null which means there's no settings for the defined period
		 */
		public function MealEvent(mealName:String, insulinRatio:Number, correctionFactor:Number,previousBGlevel:Number) {
			this._mealName = mealName;
			this.insulineRatio = insulinRatio;
			this._previousBGlevel = previousBGlevel;
			mealeventId = new Number(Settings.getInstance().getSetting(Settings.SettingNEXT_MEALEVENT_ID));
			selectedFoodItems = new ArrayCollection();
			lastModifiedTimestamp = new Date();
			
			var dispatcher:EventDispatcher = new EventDispatcher();
			dispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationFailed);
			Database.getInstance().createNewMealEvent(mealName,lastModifiedTimestamp.valueOf().toString(),insulinRatio,correctionFactor,previousBGlevel,dispatcher);
			Settings.getInstance().setSetting(Settings.SettingNEXT_MEALEVENT_ID, mealeventId + 1);
			
			function mealEventCreationFailed (errorEvent:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationFailed);
				Settings.getInstance().setSetting(Settings.SettingNEXT_MEALEVENT_ID, mealeventId);
				trace("Error while storing mealevent in database. MealEvent.as 0001");
			}
		}
		
		internal function addSelectedFoodItem(selectedFoodItem:SelectedFoodItem,dispatcher:EventDispatcher = null):void {
			selectedFoodItems.addItem(selectedFoodItem);
			selectedFoodItem.selectedItemId = Settings.getInstance().getSetting(Settings.SettingNEXT_SELECTEDITEM_ID);
			
			var dispatcher:EventDispatcher = new EventDispatcher();
			dispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,selectedItemCreationFailed);
			dispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,selectedItemCreated);
			
			Database.getInstance().createNewSelectedItem(
				selectedFoodItem._selectedItemId,
				this.mealeventId,
				selectedFoodItem.itemDescription,
				selectedFoodItem.unit.unitDescription,
				selectedFoodItem.unit.standardAmount,
				selectedFoodItem.unit.kcal,
				selectedFoodItem.unit.protein,
				selectedFoodItem.unit.carbs,
				selectedFoodItem.unit.fat,
				selectedFoodItem.chosenAmount,
				dispatcher);
			Settings.getInstance().setSetting(Settings.SettingNEXT_SELECTEDITEM_ID, selectedFoodItem.selectedItemId +1 );
			
			function selectedItemCreated(event:DatabaseEvent):void {
				update the timestamp	
				and dispatch even timestampupdate is successful
			}
			
			function selectedItemCreationFailed (errorEvent:DatabaseEvent):void {
				dispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,selectedItemCreationFailed);
				Settings.getInstance().setSetting(Settings.SettingNEXT_SELECTEDITEM_ID, selectedFoodItem.selectedItemId );
				trace("Error while storing selected food Item in database. MealEvent.as 0002");
				if (dispatcher != null) {
					var event:DatabaseEvent = new DatabaseEvent(DatabaseEvent.ERROR_EVENT);
					dispatcher.dispatchEvent(event);
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
		internal function set 
		internal function get previousBGlevel():int
		{
			return _previousBGlevel;
		}

		internal function set previousBGlevel(value:int):void
		{
			_previousBGlevel = value;
		}

mealName(value:String):void
		{
			_mealName = value;
		}


	}
}