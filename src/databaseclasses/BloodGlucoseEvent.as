/**
 Copyright (C) 2013  hippoandfriends
 
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
		private var _bloodGlucoseLevel:Number;
		private var _comment:String;

		public function get comment():String
		{
			return _comment;
		}

		private function set comment(value:String):void
		{
			_comment = value;
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

		private var _lastModifiedTimestamp:Number;
		
		public function get lastModifiedTimestamp():Number
		{
			return _lastModifiedTimestamp;
		}
		
		internal function set lastModifiedTimestamp(value:Number):void
		{
			_lastModifiedTimestamp = value;
		}
		
		
		/**
		 * creates a bloodglucose event and stores it immediately in the database if storeInDatabase = true<br>
		 * unit is a textstring denoting the unit used, mgperdl, or ... <br>
		 * if creationTimeStamp = null, then current date and time is used<br>
		 * if newLastModifiedTimestamp = null, then current date and time is used
		 */
		public function BloodGlucoseEvent(glucoseLevel:Number, unit:String, bloodglucoseEventId:Number, newcomment:String, creationTimeStamp:Number = Number.NaN, newLastModifiedTimeStamp:Number = Number.NaN, storeInDatabase:Boolean = true )
		{
			this._bloodGlucoseLevel = glucoseLevel;	
			this._unit = unit;
			this._comment = newcomment;
			this.eventid = bloodglucoseEventId;
			if (!isNaN(creationTimeStamp))
				_timeStamp = creationTimeStamp;
			else
				_timeStamp = (new Date()).valueOf();

			if (!isNaN(newLastModifiedTimeStamp))
				_lastModifiedTimestamp = newLastModifiedTimeStamp;
			else
				_lastModifiedTimestamp = (new Date()).valueOf();

			if (storeInDatabase)
				Database.getInstance().createNewBloodGlucoseEvent(glucoseLevel,_timeStamp,_lastModifiedTimestamp,unit,bloodglucoseEventId,_comment,null);
		}
		
		
		public function get bloodGlucoseLevel():Number
		{
			return _bloodGlucoseLevel;
		}

		private function set bloodGlucoseLevel(value:Number):void
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
		 */
		public function updateBloodGlucoseEvent(newUnit:String,newBloodGlucoseLevel:Number,newCreationTimeStamp:Number,newcomment:String,  newLastModifiedTimeStamp:Number):void {
			unit = newUnit;
			_bloodGlucoseLevel = newBloodGlucoseLevel;
			_comment = newcomment;

				if (new Number(Settings.getInstance().getSetting(Settings.SettingsLastSyncTimeStamp)) > _lastModifiedTimestamp)
					Settings.getInstance().setSetting(Settings.SettingsLastSyncTimeStamp,_lastModifiedTimestamp.toString());
				_lastModifiedTimestamp = newLastModifiedTimeStamp;

			if (!isNaN(newCreationTimeStamp)) {
				timeStamp = newCreationTimeStamp;
			}
			Database.getInstance().updateBloodGlucoseEvent(this.eventid,unit,_bloodGlucoseLevel, timeStamp,_lastModifiedTimestamp,_comment);
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
			Database.getInstance().deleteBloodGlucoseEvent(this.eventid);
		}
		
		public function toString():String {
			var returnValue:String;
			returnValue += "eventid = " + eventid + "\n";
			returnValue = "timeStamp = " + timeStamp+ "\n";
			returnValue += "ladmodifiedtimestamp = " + _lastModifiedTimestamp+ "\n";
			returnValue += "bloodglucoselevel = " + _bloodGlucoseLevel.toString() + "\n";
			returnValue += "unit = " + unit+ "\n";
			returnValue += "comment = " + _comment + "\n";
			 
			return returnValue;
		}
	}
}