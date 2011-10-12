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
	
	import myComponents.IListElement;
	import myComponents.MealEventItemRenderer;
	import myComponents.TrackingViewElement;
	

	/**
	 * this is a meal event,<br>
	 * creation of a meal event, destroying a mealevent (? possible ?), modification of a meal event all affects database,<br>
	 * ie a database update or insertion will be done behind the scene. That's why MealEvent is part of package databaseclasses.<br>
	 * In general the methods do not handle database update errors. The classes will exist or be modified but in case a database update occurs, there's no method to inform the client
	 * <br>
	 * Also the selected Food Items are stored in here.<br>
	 */ 
	public class MealEvent extends TrackingViewElement implements IListElement
	{
		internal var _mealName:String;//made internal because meal.as failed to use mealName - no explanation
		/**
		 * the insulinratio used in this mealevent, if 0 then not used<br>
		 */
		private var _insulinRatio:Number;
		private var _correctionFactor:Number;
		/**
		 * previous bloodglucose level, if null then no correction will be applied<br>
		 * this value needs to be assigned :<br>
		 * - during creation of the mealevent, if there's a bg event withint the predefined timeframe, then assign previousBGlevel to the previoius bloodglucoseevent level<br>
		 * - each time that a bloodglucoseevent is created, it needs to be checked if there's a mealevent after, within the predefined timeframe, and if so assign<br>
		 * - the most recent bloodglucsoeevent before the mealevent is used
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

		/**
		 * the selected fooditems
		 */
		public function get selectedFoodItems():ArrayCollection
		{
			return _selectedFoodItems;
		}

		
		/**
		 * value will be creationtimestamp, must be named _timeStamp because the class implements IListElement
		 */
		private var _timeStamp:Number;
		
		/**
		 * the calculated amount, in fact a redundant value because it can be derived from other values here<br>
		 * null if no calculation is possible eg because no insulinratio defined
		 */
		private var _calculatedInsulinAmount:Number;
		
		private var _totalFat:Number;
		private var _totalKilocalories:Number;
		private var _totalProtein:Number;
		private var _totalCarbs:Number;
		
		/**
		 * defines if selected meals are shown in tracking view
		 */
		private var _extendedInTrackingView:Boolean = false;

		/**
		 * defines if selected meals are shown in tracking view
		 */
		public function get extendedInTrackingView():Boolean
		{
			return _extendedInTrackingView;
		}

		/**
		 * defines if selected meals are shown in tracking view
		 */
		public function set extendedInTrackingView(value:Boolean):void
		{
			_extendedInTrackingView = value;
		}
		
		
		/**
		 * mealEvent will be created and automatically inserted into the database if databaseStorage = true<br>
		 * insulinRatio,  correctionFactor can Number.NAN which means there's no settings for the defined period<br>
		 * previousBGlevel can also be null meaning theres no bloodglucose event within the predefined timeframe<br>
		 * if timeStamp = null then current time is used as timeStamp for the mealevent, otherwise the supplied timeStamp is used.<br>
		 * 
		 * databaseStorage = indicates of the MealEvent needs to be stored in the database, default = true<br>
		 * databaseStorage needs to be true in general, false is only used when reading MealEvents from the database, in which case database storage is not necessary<br>
		 * if databaseStorage = false then selectedFoodItems must be not null<br>
		 * if databaseStorage = false then lastModifiedTimeStamp must be not null<br>
		 * if databaseStorage = false then creationTimeStamp must be not null<br>
		 * new mealEventId is created if databaseStorage = true.
		 */
		public function MealEvent(mealName:String, insulinRatio:Number, correctionFactor:Number,previousBGlevel:Number,timeStamp:Number,dispatcher:EventDispatcher, databaseStorage:Boolean = true, selectedFoodItems:ArrayCollection = null, mealEventId:Number = Number.NaN,  lastModifiedTimeStamp:Number = Number.NaN) {
			this._mealName = mealName;
			if (isNaN(insulinRatio))
				this._insulinRatio = 0;
			else
				this._insulinRatio = insulinRatio;
			this._previousBGlevel = previousBGlevel;
			this._totalFat = 0;
			this._totalProtein = 0;
			this._totalCarbs = 0;
			this._totalKilocalories = 0;
			this._correctionFactor = correctionFactor;
			
			if (!isNaN(lastModifiedTimeStamp))
				this._lastModifiedTimeStamp = lastModifiedTimeStamp;
			else
				this._lastModifiedTimeStamp = (new Date()).valueOf();
			
			if (!isNaN(timeStamp)) {
				this._timeStamp = timeStamp
			}
			else {
				this._timeStamp = _lastModifiedTimeStamp;
			}

			if (!databaseStorage) {
				this._mealEventId = mealEventId;
				this._selectedFoodItems = selectedFoodItems;
				recalculateTotals();
				recalculateInsulinAmount();
			}
			else  {
				_mealEventId = new Number(Settings.getInstance().getSetting(Settings.SettingNEXT_MEALEVENT_ID));
				_selectedFoodItems = new ArrayCollection();
								
				var localDispatcher:EventDispatcher = new EventDispatcher();
				localDispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationFailed);
				localDispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,mealEventCreated);
				Settings.getInstance().setSetting(Settings.SettingNEXT_MEALEVENT_ID, (_mealEventId + 1).toString());
				Database.getInstance().createNewMealEvent(_mealEventId,
					mealName,
					_lastModifiedTimeStamp.valueOf().toString(),
					insulinRatio,
					correctionFactor,
					previousBGlevel,
					_timeStamp.valueOf(),
					localDispatcher);
			}
			
			function mealEventCreated(successEvent:DatabaseEvent):void  {
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,mealEventCreated);
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationFailed);
				if (dispatcher != null) {
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.RESULT_EVENT));
				}
			}
			
			function mealEventCreationFailed (errorEvent:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,mealEventCreated);
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationFailed);
				Settings.getInstance().setSetting(Settings.SettingNEXT_MEALEVENT_ID, _mealEventId.toString());
				trace("Error while storing mealevent in database. MealEvent.as 0001");
				if (dispatcher != null) {
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
				}
			}
		}
		
		internal function addSelectedFoodItem(selectedFoodItem:SelectedFoodItem,dispatcher:EventDispatcher = null):void {
			_selectedFoodItems.addItem(selectedFoodItem);
			selectedFoodItem.selectedItemId = new Number(Settings.getInstance().getSetting(Settings.SettingNEXT_SELECTEDITEM_ID));
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
			Settings.getInstance().setSetting(Settings.SettingNEXT_SELECTEDITEM_ID, (selectedFoodItem.selectedItemId +1).toString() );
			
			function selectedItemCreated(event:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,selectedItemCreationFailed);
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,selectedItemCreated);
				localDispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,timeStampUpdateFailed);
				localDispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,timeStampUpdated);
				
				/* recalculate totals */
				/*_totalCarbs += selectedFoodItem.unit.carbs/selectedFoodItem.unit.standardAmount*selectedFoodItem.chosenAmount;
				_totalKilocalories += selectedFoodItem.unit.kcal/selectedFoodItem.unit.standardAmount*selectedFoodItem.chosenAmount;
				_totalProtein += selectedFoodItem.unit.protein/selectedFoodItem.unit.standardAmount*selectedFoodItem.chosenAmount;
				_totalFat += selectedFoodItem.unit.fat/selectedFoodItem.unit.standardAmount*selectedFoodItem.chosenAmount;
				*/
				recalculateTotals();
				recalculateInsulinAmount();
				
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
				Settings.getInstance().setSetting(Settings.SettingNEXT_SELECTEDITEM_ID, selectedFoodItem.selectedItemId.toString() );
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
		public function get mealName():String
		{
			return _mealName;
		}

		/**
		 * @private
		 */
		public function set mealName(value:String):void
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
			recalculateInsulinAmount();
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
		public function set timeStamp(timeStamp:Number):void
		{
			this._timeStamp = timeStamp;
		}
		
		public function listElementRendererFunction():ClassFactory
		{
			return new ClassFactory(MealEventItemRenderer);
		}

		/**
		 * total number of fat,<br>
		 * calculated during creation of the mealevent and/or adding selectedfooditems<br>
		 * not stored in the database
		 */
		public function get totalFat():Number
		{
			return _totalFat;
		}

		/**
		 * total number of kilocalories,<br>
		 * calculated during creation of the mealevent and/or adding selectedfooditems<br>
		 * not stored in the database
		 */
		public function get totalKilocalories():Number
		{
			return _totalKilocalories;
		}

		/**
		 * total number of protein,<br>
		 * calculated during creation of the mealevent and/or adding selectedfooditems<br>
		 * not stored in the database
		 */
		public function get totalProtein():Number
		{
			return _totalProtein;
		}

		/**
		 * total number of carbs,<br>
		 * calculated during creation of the mealevent and/or adding selectedfooditems<br>
		 * not stored in the database
		 */
		public function get totalCarbs():Number
		{
			return _totalCarbs;
		}

		/**
		 * the insulineratio, if null then there was no insuline ratio for the period in which the meal was created or modified
		 */
		public function get insulinRatio():Number
		{
			return _insulinRatio;
		}

		/**
		 * insulinratio =  used in this mealevent, if 0 then not used<br><br>
		 * set will update a mealevent , updates the insulinratio, also the corresponding database element will be updated<br>
		 * also the database will be updated<br><br>
		 * newInsulinRatioValue = the new insulinratio to be 	assigned<br>
		 * if value == null or value == Number.NaN then insulinratio is set to 0
		 * 
		 */
		public function set  insulinRatio(value:Number):void {
			if (isNaN(_insulinRatio))
				this._insulinRatio = 0;
			else
				this._insulinRatio = value;
			Database.getInstance().updateInsulineRatio(this.mealEventId,value,null);
			recalculateInsulinAmount();
		}

		/**
		 * the correction factor, if null then correction will be applied
		 */
		public function get correctionFactor():Number
		{
			return _correctionFactor;
		}
		
		private function recalculateInsulinAmount():void {
			this._calculatedInsulinAmount = Number.NaN;
			if (!isNaN(_insulinRatio))
				if (!(_insulinRatio == 0)) {
					this._calculatedInsulinAmount = this._totalCarbs/this._insulinRatio;
					if (!isNaN(_correctionFactor))
						if (_correctionFactor != 0)
							if (!isNaN(previousBGlevel))
								if (previousBGlevel != 0)
									this._calculatedInsulinAmount += (this._previousBGlevel - parseInt(Settings.getInstance().getSetting(Settings.SettingsTARGET_BLOODGLUCOSELEVEL)))/this._correctionFactor;
				}
		}

		private function set correctionFactor(value:Number):void
		{
			_correctionFactor = value;
			recalculateInsulinAmount();
		}

		/**f
		 * the calculated amount, in fact a redundant value because it can be derived from other values here<br>
		 * null if no calculation is possible eg because no insulinratio defined
		 */
		public function get calculatedInsulinAmount():Number
		{
			return _calculatedInsulinAmount;
		}

		/**
		 * the mealeventid
		 */
		public function get mealEventId():Number
		{
			return _mealEventId;
		}
		
		private function recalculateTotals():void {
			_totalCarbs = 0;
			_totalKilocalories = 0;
			_totalProtein = 0;
			_totalFat = 0;
			for (var i:int = 0;i < _selectedFoodItems.length; i++) {
				var selectedFoodItem:SelectedFoodItem = (_selectedFoodItems.getItemAt(i) as SelectedFoodItem);
				_totalCarbs += selectedFoodItem.unit.carbs/selectedFoodItem.unit.standardAmount*selectedFoodItem.chosenAmount;
				_totalKilocalories += selectedFoodItem.unit.kcal/selectedFoodItem.unit.standardAmount*selectedFoodItem.chosenAmount;
				_totalProtein += selectedFoodItem.unit.protein/selectedFoodItem.unit.standardAmount*selectedFoodItem.chosenAmount;
				_totalFat += selectedFoodItem.unit.fat/selectedFoodItem.unit.standardAmount*selectedFoodItem.chosenAmount;
			}
		}
		
		public function updateSelectedFoodItemChosenAmount(selectedFoodItem:SelectedFoodItem,newAmount:Number):void {
			//find the id
			for (var ij:int=0;ij < _selectedFoodItems.length; ij++) {
				if ((_selectedFoodItems.getItemAt(ij) as SelectedFoodItem) == selectedFoodItem) {
					(_selectedFoodItems.getItemAt(ij) as SelectedFoodItem).chosenAmount = newAmount;
					recalculateInsulinAmount();
					recalculateTotals();
					ij = _selectedFoodItems.length;
				}
			}
		}
	}
}