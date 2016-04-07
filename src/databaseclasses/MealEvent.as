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
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.core.ClassFactory;
	
	import model.ModelLocator;
	
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
		private var _comment:String;
		
		private var _activeInsulin:Number;
		
		public function get comment():String
		{
			return (_comment == null ? "":_comment);
		}
		
		internal var _mealName:String;//made internal because meal.as failed to use mealName - no explanation
		/**
		 * the insulinratio used in this mealevent, if 0 then not used<br>
		 */
		private var _insulinRatio:Number;
		private var _correctionFactor:Number;
		
		private var _meal:Meal;
		
		private static var recalculateInsulinAmountRunning:Boolean = false;
		private static var rerunrecalculateInsulinAmountNecessary:Boolean = false;
		private static var trackingListCounter:int = -1;
		
		/**
		 * the meal that will hod this mealEvent<br> 
		 */
		public function get meal():Meal
		{
			return _meal;
		}
		
		/**
		 * @private
		 */
		public function set meal(value:Meal):void
		{
			_meal = value;
		}
		
		
		[Bindable]
		private var _selectedFoodItems:ArrayCollection;
		
		/**
		 * the selected fooditems
		 */
		public function get selectedFoodItems():ArrayCollection
		{
			return _selectedFoodItems;
		}
		
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
		 * if timeStamp = null then current time is used as timeStamp for the mealevent, otherwise the supplied timeStamp is used.<br>
		 * 
		 * databaseStorage = indicates of the MealEvent needs to be stored in the database, default = true<br>
		 * databaseStorage needs to be true in general, false is only used when reading MealEvents from the database, in which case database storage is not necessary<br>
		 * if databaseStorage = false then selectedFoodItems must be not null<br>
		 * if databaseStorage = false then lastModifiedTimeStamp must be not null<br>
		 * if databaseStorage = false then creationTimeStamp must be not null<br>
		 * new mealEventId is created if databaseStorage = true.
		 */
		public function MealEvent(mealName:String, insulinRatio:Number, correctionFactor:Number,timeStamp:Number,dispatcher:EventDispatcher, mealEventId:String, newcomment:String, newLastModifiedTimeStamp:Number, databaseStorage:Boolean, selectedFoodItems:ArrayCollection,mealThatHoldsThisMealEvent:Meal, recalculateInsulinAmountNecessary) {
			this._mealName = mealName;
			if (isNaN(insulinRatio))
				this._insulinRatio = 0;
			else
				this._insulinRatio = insulinRatio;
			this._totalFat = 0;
			this._totalProtein = 0;
			this._totalCarbs = 0;
			this._totalKilocalories = 0;
			this._correctionFactor = correctionFactor;
			this._meal = mealThatHoldsThisMealEvent;
			this._comment = newcomment;
			
			if (!isNaN(newLastModifiedTimeStamp))
				lastModifiedTimestamp = newLastModifiedTimeStamp;
			else
				lastModifiedTimestamp = (new Date()).valueOf();
			
			if (!isNaN(timeStamp)) {
				this._timeStamp = timeStamp
			}
			else {
				this._timeStamp = lastModifiedTimestamp;
			}
			
			eventid = mealEventId;
			
			if (!databaseStorage) {
				this._selectedFoodItems = selectedFoodItems;
				recalculateTotals(recalculateInsulinAmountNecessary);
			}
			else  {				
				_selectedFoodItems = new ArrayCollection();
				
				var localDispatcher:EventDispatcher = new EventDispatcher();
				localDispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,mealEventCreationFailed);
				localDispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,mealEventCreated);
				Database.getInstance().createNewMealEvent(eventid,
					mealName,
					lastModifiedTimestamp.valueOf(),
					insulinRatio,
					correctionFactor,
					_timeStamp.valueOf(),
					_comment,
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
				trace("Error while storing mealevent in database. MealEvent.as 0001");
				if (dispatcher != null) {
					dispatcher.dispatchEvent(new DatabaseEvent(DatabaseEvent.ERROR_EVENT));
				}
			}
		}
		
		public function addSelectedFoodItem(selectedFoodItem:SelectedFoodItem,dispatcher:EventDispatcher = null):void {
			_selectedFoodItems.addItem(selectedFoodItem);
			//selectedFoodItem.eventid = new Date().valueOf();
			selectedFoodItem.mealEventId = this.eventid;
			
			//update also the lastmodifiedtimestamp of the mealevent if the selectedfooditem lastmodifiedtimestamp is more recent - which will always be the case here but check it anyway
			//this for nightscoutsync.as, because that one only gets a list of modified mealevents, not modified selectedfooditems
			//if we update the lastmodifiedtimestamp, then it will cause an update at nightscout also if needed
			if (lastModifiedTimestamp < selectedFoodItem.lastModifiedTimestamp) {
				lastModifiedTimestamp = selectedFoodItem.lastModifiedTimestamp;
			}
			
			var localDispatcher:EventDispatcher = new EventDispatcher();
			localDispatcher.addEventListener(DatabaseEvent.ERROR_EVENT,selectedItemCreationFailed);
			localDispatcher.addEventListener(DatabaseEvent.RESULT_EVENT,selectedItemCreated);
			
			Database.getInstance().createNewSelectedItem(
				selectedFoodItem.eventid,
				this.eventid,
				selectedFoodItem.itemDescription,
				selectedFoodItem.unit.unitDescription,
				selectedFoodItem.unit.standardAmount,
				selectedFoodItem.unit.kcal,
				selectedFoodItem.unit.protein,
				selectedFoodItem.unit.carbs,
				selectedFoodItem.unit.fat,
				selectedFoodItem.chosenAmount,
				selectedFoodItem.lastModifiedTimestamp,
				localDispatcher);
			//Settings.getInstance().setSetting(Settings.SettingNEXT_SELECTEDITEM_ID, (selectedFoodItem.selectedItemId +1).toString() );
			
			function selectedItemCreated(event:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,selectedItemCreationFailed);
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,selectedItemCreated);
				recalculateTotals(true);
			}
			
			function selectedItemCreationFailed (errorEvent:DatabaseEvent):void {
				localDispatcher.removeEventListener(DatabaseEvent.ERROR_EVENT,selectedItemCreationFailed);
				localDispatcher.removeEventListener(DatabaseEvent.RESULT_EVENT,selectedItemCreated);
				//Settings.getInstance().setSetting(Settings.SettingNEXT_SELECTEDITEM_ID, selectedFoodItem.selectedItemId.toString() );
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
		 * as MealEvent implements Itimestamp, it shoud have a timestamp<br>
		 * the value will be assigned at creation, 
		 */
		override public function set timeStamp(timeStamp:Number):void
		{
			if (_timeStamp == timeStamp)
				return;
			
			if (new Number(Settings.getInstance().getSetting(Settings.SettingsLastGoogleSyncTimeStamp)) > lastModifiedTimestamp)
				Settings.getInstance().setSetting(Settings.SettingsLastGoogleSyncTimeStamp,lastModifiedTimestamp.toString());
			
			lastModifiedTimestamp = (new Date()).valueOf();
			updateMealEvent(mealName, _comment,insulinRatio,_correctionFactor,lastModifiedTimestamp,timeStamp);
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
		
		public function set comment(value:String):void {
			if (_comment == value)
				return;
			
			this._comment = value;
			var newLastModifiedTimeStamp:Number = new Date().valueOf();
			if (new Number(Settings.getInstance().getSetting(Settings.SettingsLastGoogleSyncTimeStamp)) > lastModifiedTimestamp)
				Settings.getInstance().setSetting(Settings.SettingsLastGoogleSyncTimeStamp,lastModifiedTimestamp.toString());
			lastModifiedTimestamp = newLastModifiedTimeStamp;
			
			Database.getInstance().updateMealEvent(this.eventid,_mealName,_insulinRatio,_correctionFactor,lastModifiedTimestamp,_timeStamp, _comment, null);
		}
		
		/**
		 * the insulineratio, if null then there was no insuline ratio for the period in which the meal was created or modified
		 */
		public function get insulinRatio():Number
		{
			return _insulinRatio;
		}
		
		/**
		 * insulinratio = used in this mealevent, if 0 then not used<br><br>
		 * set will update a mealevent , updates the insulinratio, also the corresponding database element will be updated<br>
		 * also the database will be updated<br><br>
		 * newInsulinRatioValue = the new insulinratio to be 	assigned<br>
		 * if value == null or value == Number.NaN then insulinratio is set to 0
		 * 
		 */
		public function set insulinRatio(value:Number):void {
			
			if (isNaN(value)) {
				if (_insulinRatio == 0)
					return;
				this._insulinRatio = 0;
			}
			else {
				if (_insulinRatio == value)
					return;
				this._insulinRatio = value;
			}
			var newLastModifiedTimeStamp:Number = new Date().valueOf();
			if (new Number(Settings.getInstance().getSetting(Settings.SettingsLastGoogleSyncTimeStamp)) > lastModifiedTimestamp)
				Settings.getInstance().setSetting(Settings.SettingsLastGoogleSyncTimeStamp,lastModifiedTimestamp.toString());
			lastModifiedTimestamp = newLastModifiedTimeStamp;
			
			Database.getInstance().updateMealEvent(this.eventid,_mealName,_insulinRatio,_correctionFactor,lastModifiedTimestamp,_timeStamp,_comment,null);
			recalculateInsulinAmount();
		}
		
		/**
		 * the correction factor, if null then correction will be applied
		 */
		public function get correctionFactor():Number
		{
			return _correctionFactor;
		}
		
		public function set correctionFactor(value:Number):void
		{
			if (value == _correctionFactor)
				return;
			
			this._correctionFactor = value;
			
			if (new Number(Settings.getInstance().getSetting(Settings.SettingsLastGoogleSyncTimeStamp)) > lastModifiedTimestamp)
				Settings.getInstance().setSetting(Settings.SettingsLastGoogleSyncTimeStamp,lastModifiedTimestamp.toString());
			
			lastModifiedTimestamp = (new Date()).valueOf();
			updateMealEvent(mealName, _comment,insulinRatio,_correctionFactor,lastModifiedTimestamp,timeStamp);
			
			recalculateInsulinAmount();
		}
		
		/**
		 * recalculates insulinamount<br>
		 * returns string that can be used to show details about the calculation<br>
		 * {carb_amount} = ...<br>
		 * {calculated_insulinamount} = ...<br>
		 * {insulin_ratio} = ...<br>
		 * {previous_bg_level} = ...<br>
		 * {correction_factor} = ...<br>
		 * {correction} = ...<br>
		 * {targetbglevel} = ...<br>
		 * {active_insulin} = ... <br>
		 * 
		 */public function recalculateInsulinAmount(trackingViewRedrawNecessary:Boolean = true):String {
			 var previousCalculatedInsulinAmount:Number = this._calculatedInsulinAmount; 
			 this._calculatedInsulinAmount = Number.NaN;
			 var diff:Number = Number.NaN;
			 var activeInsulin:Number = Number.NaN;
			 var correctionUnits:Number = Number.NaN;
			 var previousBGEvent:BloodGlucoseEvent = null;
			 var returnValue:String = "";
			 if (!isNaN(_insulinRatio)) {
				 if (!(_insulinRatio == 0)) {
					 this._calculatedInsulinAmount = this._totalCarbs/this._insulinRatio;
					 if (_correctionFactor > 0) {
						 //find previous bloodglucoseevent
						 var indexOfpreviousBGEvent:int = ModelLocator.trackingList.getItemIndex(this);
						 if (indexOfpreviousBGEvent == -1)
							 //this mealevent is not yet added in the trackinglist, 
							 indexOfpreviousBGEvent = ModelLocator.trackingList.length - 1;
						 else
							 indexOfpreviousBGEvent--;
						 
						 while (indexOfpreviousBGEvent > -1) {
							 if (timeStamp > (ModelLocator.trackingList.getItemAt(indexOfpreviousBGEvent) as TrackingViewElement).timeStamp)
								 if (ModelLocator.trackingList.getItemAt(indexOfpreviousBGEvent) is BloodGlucoseEvent) {
									 break;
								 }
							 if (!(timeStamp - (ModelLocator.trackingList.getItemAt(indexOfpreviousBGEvent) as TrackingViewElement).timeStamp < (new Number(Settings.getInstance().getSetting(Settings.SettingMAX_TIME_DIFFERENCE_LATEST_BGEVENT_AND_START_OF_MEAL))) * 1000))
								 break;
							 indexOfpreviousBGEvent--;
						 }
						 
						 if (indexOfpreviousBGEvent > -1) {
							 if (ModelLocator.trackingList.getItemAt(indexOfpreviousBGEvent) is BloodGlucoseEvent) {
								 previousBGEvent = ModelLocator.trackingList.getItemAt(indexOfpreviousBGEvent) as BloodGlucoseEvent;
								 if (timeStamp - previousBGEvent.timeStamp < (new Number(Settings.getInstance().getSetting(Settings.SettingMAX_TIME_DIFFERENCE_LATEST_BGEVENT_AND_START_OF_MEAL))) * 1000) {
									 diff = previousBGEvent.bloodGlucoseLevel - new Number(Settings.getInstance().getSetting(Settings.SettingsTARGET_BLOODGLUCOSELEVEL));
									 correctionUnits = diff/correctionFactor;
									 _calculatedInsulinAmount = _calculatedInsulinAmount + correctionUnits;
								 }
							 }
						 }
					 }
					 
					 
					 returnValue += "{carb_amount} = " + ((Math.round(totalCarbs * 10))/10).toString() + "\n";
					 returnValue += "{insulin_ratio} = " + _insulinRatio.toString() + "\n";
					 if (!isNaN(diff)) {
						 returnValue += "{correction_factor} = " + ((Math.round(correctionFactor * 10))/10).toString() + "\n";
						 returnValue += "{previous_bg_level} = " + previousBGEvent.bloodGlucoseLevel.toString() + "\n";
						 returnValue += "{targetbglevel} = " + Settings.getInstance().getSetting(Settings.SettingsTARGET_BLOODGLUCOSELEVEL) + "\n";
						 returnValue += "{correction} = (" +
							 ((Math.round(previousBGEvent.bloodGlucoseLevel * 10))/10).toString() + " - " + 
							 ((Math.round(new Number(Settings.getInstance().getSetting(Settings.SettingsTARGET_BLOODGLUCOSELEVEL)) * 10))/10).toString() + ") / " + 
							 ((Math.round(correctionFactor * 10))/10).toString() + " = " + 
							 
							 ((Math.round(correctionUnits * 10))/10).toString() + "\n";
					 }
					 returnValue += "{calculated_insulinamount} = " + 
						 ((Math.round(totalCarbs * 10))/10).toString() + " / " + 
						 ((Math.round(insulinRatio * 10))/10).toString() + 
						 
						 ( !isNaN(correctionUnits) ?
							 
							 (correctionUnits < 0 ? " ":" + ") + 
							 ((Math.round(correctionUnits * 10))/10).toString()  
							 :
							 ""
						 )
						 + " = " +
						 ((Math.round(_calculatedInsulinAmount * 10))/10).toString() + "\n";
					 
					 //now substract the active insulin
					 activeInsulin = ModelLocator.calculateActiveInsulin(timeStamp);
					 
					 if (activeInsulin > 0) {
						 returnValue += "{active_insulin}* = " + ((Math.round(activeInsulin * 10))/10).toString() + "\n";
						 returnValue += "{calculated_insulinamount} = " + ((Math.round(_calculatedInsulinAmount * 10))/10).toString() + " - " +
							 ((Math.round(activeInsulin * 10))/10).toString();
						 _calculatedInsulinAmount -= activeInsulin;
						 returnValue += " = " + ((Math.round(_calculatedInsulinAmount * 10))/10).toString() + "\n";
					 }
					 
					 //get the timestamp of the last added selecteditem
					 var timeOfLastMealChange:Number = timeStamp;
					 for (var selcntr:int = 0;selcntr < selectedFoodItems.length;selcntr++) {
						 if ((selectedFoodItems.getItemAt(selcntr) as SelectedFoodItem).lastModifiedTimestamp > timeOfLastMealChange)
							 timeOfLastMealChange = (selectedFoodItems.getItemAt(selcntr) as SelectedFoodItem).lastModifiedTimestamp;
					 }
					 //calculate how much was given during the meal
					 var insulinGivenDuringMeal:Number = 0;
					 for (var trackcntr:int = ModelLocator.trackingList.length - 1 ;trackcntr >= 0 ;trackcntr--) {
						 if ((ModelLocator.trackingList.getItemAt(trackcntr) as TrackingViewElement).timeStamp < timeStamp)
							 break;
						 if (ModelLocator.trackingList.getItemAt(trackcntr) is MedicinEvent) {
							 if (ModelLocator.resourceManagerInstance.getString('editmedicineventview','listofnormalbolustypes').indexOf((ModelLocator.trackingList.getItemAt(trackcntr) as MedicinEvent).bolustype) > -1) {
								 var timeStampOfThatMedicinEvent:Number = (ModelLocator.trackingList.getItemAt(trackcntr) as MedicinEvent).timeStamp; 
								 if (timeStampOfThatMedicinEvent < timeOfLastMealChange ) {
									 insulinGivenDuringMeal += (ModelLocator.trackingList.getItemAt(trackcntr) as MedicinEvent).amount;
								 }
							 }
						 }
					 }
					 if (insulinGivenDuringMeal > 0) {
						 returnValue += "{bolus_already_given}** = " + ((Math.round(insulinGivenDuringMeal * 10))/10).toString() + "\n";
						 
						 returnValue += "{calculated_insulinamount} = " + 
							 ((Math.round(_calculatedInsulinAmount * 10))/10).toString() + 
							 " - " +
							 ((Math.round(insulinGivenDuringMeal * 10))/10).toString();
						 _calculatedInsulinAmount = _calculatedInsulinAmount - insulinGivenDuringMeal;
						 returnValue += " = " + ((Math.round(_calculatedInsulinAmount * 10))/10).toString() + "\n";
					 }
					 
					 if (activeInsulin > 0 || insulinGivenDuringMeal > 0) {
						 returnValue += "\n\n";
						 if (activeInsulin > 0) {
							 returnValue += "*{active_insulin} = {explanation_activeinsulin}\n";
						 }
						 if (insulinGivenDuringMeal > 0) {
							 returnValue += "**{bolus_already_given} = {explanation_insulingivenduringmeal}";
						 }
					 }
					 
				 } else {
					 returnValue = "{calculated_insulinamount} = ...\n";
					 //return returnValue;
				 }
			 } else {
				 returnValue = "{calculated_insulinamount} = ...\n";
				 //return returnValue;
			 }
			 if (previousCalculatedInsulinAmount != this._calculatedInsulinAmount && trackingViewRedrawNecessary) {
				 ModelLocator.trackingViewRedrawNecessary = true;
			 }
			 return returnValue; 
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
		 * recalculates total carbs, kilocalories, protein and fat<br>
		 * also recalculates insulinamount if recalculateInsulinAmountNecessary is true<br>
		 * <br>
		 * if one of the selectedmeals has a kilocalorie, protein or fat value equal to -1, then the corresponding totals will be set to -1<br>
		 * Carb value should never be -1
		 */
		private function recalculateTotals(recalculateInsulinAmountNecessary:Boolean):void {
			_totalCarbs = 0;
			_totalKilocalories = 0;
			_totalProtein = 0;
			_totalFat = 0;
			for (var i:int = 0;i < _selectedFoodItems.length; i++) {
				var selectedFoodItem:SelectedFoodItem = (_selectedFoodItems.getItemAt(i) as SelectedFoodItem);
				_totalCarbs += selectedFoodItem.unit.carbs/selectedFoodItem.unit.standardAmount*selectedFoodItem.chosenAmount;
				
				if (selectedFoodItem.unit.kcal == -1 || _totalKilocalories == -1) 
					_totalKilocalories = -1;
				else 
					_totalKilocalories += selectedFoodItem.unit.kcal/selectedFoodItem.unit.standardAmount*selectedFoodItem.chosenAmount;
				
				if (selectedFoodItem.unit.protein == -1 || _totalProtein == -1) 
					_totalProtein = -1;
				else 
					_totalProtein += selectedFoodItem.unit.protein/selectedFoodItem.unit.standardAmount*selectedFoodItem.chosenAmount;
				
				if (selectedFoodItem.unit.fat == -1 || _totalFat == -1) 
					_totalFat = -1;
				else 
					_totalFat += selectedFoodItem.unit.fat/selectedFoodItem.unit.standardAmount*selectedFoodItem.chosenAmount;
			}
			if (recalculateInsulinAmountNecessary)
				recalculateInsulinAmount();
		}
		
		/**
		 * updates the chosenAmount of a specific selectedFoodItem, which causes also update in the database for the selectedfooditem<br>
		 * Also insulinAmount is recalculated
		 */
		public function updateSelectedFoodItemChosenAmount(selectedFoodItem:SelectedFoodItem,newAmount:Number):void {
			selectedFoodItem.updateChosenAmount(newAmount, this);
			//update also the lastmodifiedtimestamp of the mealevent if the selectedfooditem lastmodifiedtimestamp is more recent - which will always be the case here but check it anyway
			//this for nightscoutsync.as, because that one only gets a list of modified mealevents, not modified selectedfooditems
			//if we update the lastmodifiedtimestamp, then it will cause an update at nightscout also if needed
			if (lastModifiedTimestamp < selectedFoodItem.lastModifiedTimestamp) {
				lastModifiedTimestamp = selectedFoodItem.lastModifiedTimestamp;
			}
			recalculateTotals(true);
			/*			//find the id
			for (var ij:int=0;ij < _selectedFoodItems.length; ij++) {
			if ((_selectedFoodItems.getItemAt(ij) as SelectedFoodItem) == selectedFoodItem) {
			(_selectedFoodItems.getItemAt(ij) as SelectedFoodItem).chosenAmount = newAmount;
			recalculateTotals();
			ij = _selectedFoodItems.length;
			
			}
			}*/
		}
		
		/**
		 * deletes the selectedFoodItem, also deletes from database<br>
		 */
		public function removeSelectedFoodItem(selectedFoodItemToRemove:SelectedFoodItem, newLastModifiedTimestamp:Number = Number.NaN):void {
			Database.getInstance().deleteSelectedFoodItem(selectedFoodItemToRemove.eventid,null);
			_selectedFoodItems.removeItem(selectedFoodItemToRemove);
			recalculateTotals(true);
			//update also the lastmodifiedtimestamp of the mealevent if the selectedfooditem lastmodifiedtimestamp is more recent - which will always be the case here but check it anyway
			//this for nightscoutsync.as, because that one only gets a list of modified mealevents, not modified selectedfooditems
			//if we update the lastmodifiedtimestamp, then it will cause an update at nightscout also if needed
			if (isNaN(newLastModifiedTimestamp)) {
				newLastModifiedTimestamp = (new Date()).valueOf()
			}
			lastModifiedTimestamp = newLastModifiedTimestamp;
		}
		
		/**
		 * deletes all selectedfooditems and then also the mealevent, from database <br>
		 * There's no call to synchronize from here, because this function should only get called from database.as (during startup) or from synchronize itself 
		 * (when a local event needs to be deleted)
		 */
		override public function deleteEvent(trackingListPointer:Number = Number.NaN):void {
			if (isNaN(trackingListPointer))
				trackingListPointer = ModelLocator.trackingList.getItemIndex(this);
			
			while (_selectedFoodItems.length > 0) {
				Database.getInstance().deleteSelectedFoodItem((_selectedFoodItems.getItemAt(0) as SelectedFoodItem).eventid,null);
				_selectedFoodItems.removeItemAt(0);
			}
			Database.getInstance().deleteMealEvent(eventid,null);
			
			ModelLocator.trackingList.removeItemAt(trackingListPointer);
		}
		
		/**
		 * updates the mealevent, also in the database<br>
		 * none of the values should be null 
		 */
		public function updateMealEvent(newMealName:String, newcomment:String, newInsulinRatio:Number,newCorrectionFactor:Number,newLastModifiedTimeStamp:Number,newCreationTimeStamp:Number) :void {
			_mealName = newMealName;
			_insulinRatio = newInsulinRatio;
			_correctionFactor = newCorrectionFactor;
			_comment = newcomment;
			
			if (new Number(Settings.getInstance().getSetting(Settings.SettingsLastGoogleSyncTimeStamp)) > lastModifiedTimestamp)
				Settings.getInstance().setSetting(Settings.SettingsLastGoogleSyncTimeStamp,lastModifiedTimestamp.toString());
			lastModifiedTimestamp = newLastModifiedTimeStamp;
			
			recalculateTotals(true);
			
			var oldTimeStamp:Number = new Number(_timeStamp);
			if (!isNaN(newCreationTimeStamp))
				_timeStamp = newCreationTimeStamp;
			if (oldTimeStamp != newCreationTimeStamp)//if timestamp has changed, recalculate for all events as of the oldest itmestamp of the two
				ModelLocator.asyncrecalculateInsulinAmoutInAllYoungerMealEvents(Math.max(oldTimeStamp,newCreationTimeStamp), true);
			
			
			Database.getInstance().updateMealEvent(this.eventid,newMealName,newInsulinRatio,newCorrectionFactor,newLastModifiedTimeStamp,newCreationTimeStamp,_comment,null);
		}
		
		/**
		 * to be used in asyncRecalculateInsulinAmountForAllMealEvents only
		 */
		private static var startTimeStamp:Number = 0;
		/**
		 * to be used in asyncRecalculateInsulinAmountForAllMealEvents only
		 */
		private static var maxCalculationDurationInms:Number;
		/**
		 * to be used in asyncRecalculateInsulinAmountForAllMealEvents only
		 */
		private static var timerForAsyncRecalculateTimerFunction:Timer;
		public static function asyncRecalculateInsulinAmountForAllMealEvents(event:Event,newstart:Boolean = false):void {
			if (recalculateInsulinAmountRunning && newstart) {
				rerunrecalculateInsulinAmountNecessary = true;
				return;
			}
			if (!recalculateInsulinAmountRunning && trackingListCounter == -1) {
				trackingListCounter = ModelLocator.trackingList.length - 1;
			}
			recalculateInsulinAmountRunning = true;
			if (trackingListCounter == -1) {//stop calculation
				recalculateInsulinAmountRunning = false;
				startTimeStamp = 0;
				if (rerunrecalculateInsulinAmountNecessary) {
					rerunrecalculateInsulinAmountNecessary = false;
					asyncRecalculateInsulinAmountForAllMealEvents(null,false);
				} else {
					ModelLocator.trackingViewRedrawNecessary = true;
				}
			} else {
				//here we run the actual recalculation
				//but if startTimeStamp = 0 it means asyncRecalculateInsulinAmountForAllMealEvents was called by another function, timer still needs to be set
				if (startTimeStamp == 0) {
					startTimeStamp = (new Date()).valueOf();
					maxCalculationDurationInms = (1 / ModelLocator.frameRate * 1000 / 3);//taking maximum one third of the frame period per block of recalculations 
				} 
				if (ModelLocator.trackingList.length > trackingListCounter) {
					if (ModelLocator.trackingList.getItemAt(trackingListCounter) is MealEvent) {
						(ModelLocator.trackingList.getItemAt(trackingListCounter) as MealEvent).recalculateInsulinAmount(false);
					}
				}
				trackingListCounter--;
				if (((startTimeStamp + maxCalculationDurationInms) < (new Date()).valueOf())) {
					startTimeStamp = 0;
					timerForAsyncRecalculateTimerFunction = new Timer(1 / ModelLocator.frameRate * 1000, 1);
					timerForAsyncRecalculateTimerFunction.addEventListener(TimerEvent.TIMER,asyncRecalculateInsulinAmountForAllMealEvents);
					timerForAsyncRecalculateTimerFunction.start();
				} else {
					asyncRecalculateInsulinAmountForAllMealEvents(null, false);						
				}
			}
		}
	}
}