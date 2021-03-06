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
	import mx.core.ClassFactory;
	
	import model.ModelLocator;
	
	import myComponents.IListElement;
	import myComponents.MedicinEventItemRenderer;
	import myComponents.TrackingViewElement;
	
	import utilities.FromtimeAndValueArrayCollection;
	
	public class MedicinEvent extends TrackingViewElement implements IListElement
	{
		/**
		 * constant string for normal bolus type, equals "normal",
		 * if you change this value, then also change the entry in editmedicineventview.properties
		 */
		public static const BOLUS_TYPE_NORMAL:String = "normal";
		
		/**
		 * constant string for square bolus type, equals "square" 
		 */
		public static const BOLUS_TYPE_SQUARE_WAVE:String = "square";

		private var _comment:String;

		public function get comment():String
		{
			return (_comment == null ? "":_comment);
		}
		
		private function set comment(value:String):void
		{
			_comment = value;
		}

		private var _medicinName:String;
		
		public function get medicinName():String
		{
			return _medicinName;
		}
		
		private var _amount:Number;
		
		public function get amount():Number
		{
			return _amount;
		}
		
		private var _bolustype:String;

		/**
		 * type can be normal or squarewave 
		 */
		public function get bolustype():String
		{
			return _bolustype;
		}

		private function set bolustype(value:String):void
		{
			_bolustype = value;
		}

		
		private var _bolusDurationInMinutes:Number;

		 /**
		  * used only for square wave bolus, duration in minutes
		  */
		 public function get bolusDurationInMinutes():Number
		 {
			 return _bolusDurationInMinutes;
		 }

		 /**
		  * @private
		  */
		 private function set bolusDurationInMinutes(value:Number):void
		 {
			 _bolusDurationInMinutes = value;
		 }
		 
		 public function bolusDurationInMilliSeconds():Number {
			 return _bolusDurationInMinutes * 60 * 1000;
		 }
		 
		 private var _activeInsulinAmount:Number;

		 public function get activeInsulinAmount():Number
		 {
			 return _activeInsulinAmount;
		 }

		/**
		 * creates a medicin event and stores it immediately in the database if storeInDatabase = true<br>
		 * if creationTimeStamp = null, then current date and time is used<br>
		 * if newLastModifiedTimestamp = null, then current date and time is used<br>
		 * 
		 */
		public function MedicinEvent(amount:Number, medicin:String, medicineventid:String, newcomment:String, creationTimeStamp:Number, newLastModifiedTimeStamp:Number,storeInDatabase:Boolean, bolusType:String, bolusDuration:Number, recalculateInsulinAmount:Boolean = true)
		{
			this._medicinName = medicin;
			this._bolustype = bolusType;
			this._bolusDurationInMinutes = bolusDuration;
			this.eventid = medicineventid;
			this._amount = amount;
			this._comment = newcomment;
			if (!isNaN(creationTimeStamp))
				_timeStamp = creationTimeStamp;
			else
				_timeStamp = (new Date()).valueOf();
			
			if (!isNaN(newLastModifiedTimeStamp))
				lastModifiedTimestamp = newLastModifiedTimeStamp;
			else
				lastModifiedTimestamp = (new Date()).valueOf();
			
			if (storeInDatabase) {
				Database.getInstance().createNewMedicinEvent(bolusType,bolusDuration, amount, medicin, _timeStamp,lastModifiedTimestamp,medicineventid, _comment, null);
				_activeInsulinAmount = calculateActiveInsulinAmount(Number.NaN, true);
			} else {
				//it's tricky : if storeInDatabase is false, it means this is actually being called while openening the database (initial startup)
				//so there's no need to do a calculateactiveinsulinamount each time
				_activeInsulinAmount = calculateActiveInsulinAmount(Number.NaN, false);
			}
			if (recalculateInsulinAmount) {
				ModelLocator.asyncrecalculateInsulinAmoutInAllYoungerMealEvents(_timeStamp, true);
				ModelLocator.recalculateActiveInsulin();
			}
		}
		
		public function listElementRendererFunction():ClassFactory
		{
			return new ClassFactory(MedicinEventItemRenderer);
		}
		
		/**
		 * will update the medicinevent in the database with the new values for medicinName and amount<br>
		 */
		public function updateMedicinEvent(bolusType:String, bolusDuration:Number, newMedicinName:String,newAmount:Number, newComment:String, newCreationTimeStamp:Number , newLastModifiedTimeStamp:Number, recalculateInsulinAmount:Boolean = true):void {
			var recalculateActiveInsulinNecessary:Boolean = false;
			if (_bolustype != bolusType) {
				_bolustype = bolusType;
				recalculateActiveInsulinNecessary  = true
			}
			if (_amount != newAmount) {
				recalculateActiveInsulinNecessary  = true
				_amount = newAmount;
			}
			if (_medicinName != medicinName) {
				_medicinName = newMedicinName;
				recalculateActiveInsulinNecessary  = true
			}
			_comment = newComment;
			if (_bolusDurationInMinutes != bolusDuration) {
				_bolusDurationInMinutes = bolusDuration;
				recalculateActiveInsulinNecessary  = true
			}
			if (new Number(Settings.getInstance().getSetting(Settings.SettingsLastGoogleSyncTimeStamp)) > lastModifiedTimestamp)
				Settings.getInstance().setSetting(Settings.SettingsLastGoogleSyncTimeStamp,lastModifiedTimestamp.toString());
			lastModifiedTimestamp = newLastModifiedTimeStamp;
			
			var previousTimeStamp:Number = _timeStamp;
			if (!isNaN(newCreationTimeStamp)) {
				if (newCreationTimeStamp != _timeStamp) {
					_timeStamp = newCreationTimeStamp;
					recalculateActiveInsulinNecessary  = true
				}
			}
			Database.getInstance().updateMedicinEvent(this._bolustype, this._bolusDurationInMinutes, this.eventid,_amount,_medicinName,timeStamp,lastModifiedTimestamp, _comment);
			_activeInsulinAmount = calculateActiveInsulinAmount(Number.NaN, true);
			if (recalculateInsulinAmount)
				ModelLocator.asyncrecalculateInsulinAmoutInAllYoungerMealEvents(Math.max(_timeStamp, previousTimeStamp), true);
			if (recalculateActiveInsulinNecessary)
				ModelLocator.recalculateActiveInsulin();
		}
		
		/**
		 * delete the event from the database<br>
		 * once deleted this event should not be used anymore<br>
		 * if trackingListPointer then it points to the position in the trackinglist, if it's null then we still need to search it
		 */
		override public function deleteEvent(trackingListPointer:Number = Number.NaN):void {
			if (isNaN(trackingListPointer))
				trackingListPointer = ModelLocator.trackingList.getItemIndex(this);
			ModelLocator.trackingList.removeItemAt(trackingListPointer);
			Database.getInstance().deleteMedicinEvent(this.eventid);
			ModelLocator.asyncrecalculateInsulinAmoutInAllYoungerMealEvents(_timeStamp, true);
			ModelLocator.recalculateActiveInsulin();
		}
		
		/**
		 * For a specific medicin event, calculates active insulin at the specified time, time in milliseconds<br>
		 * If time = NaN then now is used and also then the calculated result will be stored in _activeInsulinAmount
		 */
		public function calculateActiveInsulinAmount(time:Number = Number.NaN, trackingViewRedrawNecessary:Boolean = true):Number {
			var previousActiveInsulin:Number = (Math.round(_activeInsulinAmount * 10))/10;
			var updatePreviousActiveInsulin:Boolean = false;
			var itsAFutureEvent:Boolean = false;
			if (isNaN(time)) {
				updatePreviousActiveInsulin = true;				
				time = (new Date()).valueOf();
				if (time < timeStamp)
					itsAFutureEvent = true;
			}
			
			var maxInsulinDurationInSeconds:Number = new Number(Settings.getInstance().getSetting(Settings.SettingsMaximumInsulinDurationInSeconds));
			var additionalMaxDurationInSeconds:Number = 0;
			if (ModelLocator.resourceManagerInstance.getString('editmedicineventview','listofsquarewavebolustypes').indexOf(_bolustype) > -1) {
				additionalMaxDurationInSeconds = _bolusDurationInMinutes * 60;
			}
			if (timeStamp + (maxInsulinDurationInSeconds  + additionalMaxDurationInSeconds) * 1000 < time)
				return new Number(0);
			//let's find if the name of the medicinevent that matches one of the medicins in the settings hh
			var tempActiveInsulin:Number = new Number(0);
			if (!itsAFutureEvent) {
				for (var medicincntr:int = 0;medicincntr <  5;medicincntr++) {
					if (Settings.getInstance().getSetting( Settings.SettingsInsulinType1 + medicincntr) == medicinName)  {
						if (Settings.getInstance().getSetting(Settings.SettingsMedicin1_AOBActive + medicincntr) == "true")  {
							//..zien welke range we moeten nemen
							var x_valueasString:String = (Settings.getInstance().getSetting(Settings.SettingsMedicin1_range1_AOBChart + medicincntr * 4).split("-")[0] as String).split(":")[1];
							var y_valueasString:String = (Settings.getInstance().getSetting(Settings.SettingsMedicin1_range2_AOBChart + medicincntr * 4).split("-")[0] as String).split(":")[1];
							var z_valueasString:String = (Settings.getInstance().getSetting(Settings.SettingsMedicin1_range3_AOBChart + medicincntr * 4).split("-")[0] as String).split(":")[1];
							var x_value:Number = Number(x_valueasString);
							var y_value:Number = Number(y_valueasString);
							var z_value:Number = Number(z_valueasString);
							var settingToUse:int;	
							if (amount < x_value)
								settingToUse = Settings.SettingsMedicin1_range1_AOBChart + medicincntr * 4;
							else if (amount < y_value)
								settingToUse = Settings.SettingsMedicin1_range2_AOBChart + medicincntr * 4;
							else if (amount < z_value)
								settingToUse = Settings.SettingsMedicin1_range3_AOBChart + medicincntr * 4;
							else 
								settingToUse = Settings.SettingsMedicin1_range4_AOBChart + medicincntr * 4;
							var fromTimeAndValueArrayCollection:FromtimeAndValueArrayCollection = FromtimeAndValueArrayCollection.createList(Settings.getInstance().getSetting(settingToUse));
							if (ModelLocator.resourceManagerInstance.getString('editmedicineventview','listofsquarewavebolustypes').indexOf(_bolustype) > -1) {
								//split over 0.1 unit per injection
								var amountOfInjections:int = amount / ModelLocator.BOLUS_AMOUNT_FOR_SQUARE_WAVE_BOLUSSES;
								var intervalBetweenInjections:Number = _bolusDurationInMinutes / amountOfInjections;
								var injectionsCntr:int;
								var timeStampOfInjection:Number;
								for (injectionsCntr = 0;injectionsCntr < amountOfInjections;injectionsCntr++) {
									timeStampOfInjection = (timeStamp + injectionsCntr * intervalBetweenInjections * 60 * 1000);
									if (timeStampOfInjection < time) {
										var percentage:Number = fromTimeAndValueArrayCollection.getValue((time - timeStampOfInjection)/1000);
										tempActiveInsulin += ModelLocator.BOLUS_AMOUNT_FOR_SQUARE_WAVE_BOLUSSES *  percentage / 100;
									} else 
										break;
								}
							} else {
								tempActiveInsulin = amount * fromTimeAndValueArrayCollection.getValue((time - timeStamp)/1000) / 100;
							}
						} else {
							//there's a medicinevent found with type of insulin that has a not-enbled profile
						}
						medicincntr = 5;
					}
				}
			}
			if (updatePreviousActiveInsulin) {
				_activeInsulinAmount = tempActiveInsulin;
				if (previousActiveInsulin != (Math.round(tempActiveInsulin * 10))/10 && trackingViewRedrawNecessary) {
					ModelLocator.trackingViewRedrawNecessary = true;
				}
			}
			return tempActiveInsulin;
		}
	}
}