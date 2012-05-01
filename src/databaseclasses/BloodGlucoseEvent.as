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
	import mx.core.ClassFactory;
	
	import myComponents.BloodGlucoseEventItemRenderer;
	import myComponents.IListElement;
	import myComponents.TrackingViewElement;

	public class BloodGlucoseEvent extends TrackingViewElement implements IListElement
	{
		private var _timeStamp:Number;
		private var _bloodGlucoseLevel:int;
		private var _eventid:Number;
		
		internal function get eventid():Number
		{
			return _eventid;
		}
		
		internal function set eventid(value:Number):void
		{
			_eventid = value;
		}
		
		private var _unit:String;

		public function get unit():String
		{
			return _unit;
		}

		public function set unit(value:String):void
		{
			_unit = value;
		}

		
		/**
		 * creates a bloodglucose event and stores it immediately in the database if storeInDatabase = true<br>
		 * unit is a textstring denoting the unit used, mgperdl, or ... <br>
		 * if creationTimeStamp = null, then curren date and time is used
		 */
		public function BloodGlucoseEvent(glucoseLevel:int, unit:String, creationTimeStamp:Number = NaN, storeInDatabase:Boolean = true, bloodglucoseEventId:Number = Number.NaN)
		{
			this._bloodGlucoseLevel = glucoseLevel;	
			this._unit = unit;
			this.eventid = bloodglucoseEventId;
			if (!isNaN(creationTimeStamp))
				_timeStamp = creationTimeStamp;
			else
				_timeStamp = (new Date()).valueOf();
			if (storeInDatabase)
				Database.getInstance().createNewBloodGlucoseEvent(glucoseLevel,_timeStamp,unit,null,bloodglucoseEventId);
		}
		
		
		public function get bloodGlucoseLevel():int
		{
			return _bloodGlucoseLevel;
		}

		private function set bloodGlucoseLevel(value:int):void
		{
			_bloodGlucoseLevel = value;
		}

		public function get timeStamp():Number
		{
			return _timeStamp;
		}

		public function set timeStamp(value:Number):void
		{
			_timeStamp = value;
		}
		
		/**
		 * will update the exerciseevent in the database with the new values for level and comment and amount<br>
		 * if newComment = null then an empty string will be used<br>
		 * if newCreationTimeStamp = null or Number.NaN then (creation)timeStamp is not updated
		 */
		public function updateBloodGlucoseEvent(newUnit:String,newBloodGlucoseLevel:int,newCreationTimeStamp:Number = Number.NaN):void {
			unit = newUnit;
			_bloodGlucoseLevel = newBloodGlucoseLevel;
			if (!isNaN(newCreationTimeStamp)) {
				timeStamp = newCreationTimeStamp;
			}
			Database.getInstance().updateBloodGlucoseEvent(this.eventid,unit,_bloodGlucoseLevel, timeStamp);
		}
		
		public function listElementRendererFunction():ClassFactory
		{
			return new ClassFactory(BloodGlucoseEventItemRenderer);
		}
		
		/**
		 * delete the event from the database<br>
		 * once delted this event should not be used anymore
		 */
		public function deleteEvent():void {
			Database.getInstance().deleteMedicinEvent(this.eventid);
		}
	}
}