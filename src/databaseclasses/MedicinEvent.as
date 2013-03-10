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
	
	import myComponents.IListElement;
	import myComponents.MedicinEventItemRenderer;
	import myComponents.TrackingViewElement;
	
	public class MedicinEvent extends TrackingViewElement implements IListElement
	{
		private var _comment:String;

		public function get comment():String
		{
			return _comment;
		}
		
		private function set comment(value:String):void
		{
			_comment = value;
		}

		private var _timeStamp:Number;
		
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
		 * creates a medicin event and stores it immediately in the database if storeInDatabase = true<br>
		 * if creationTimeStamp = null, then current date and time is used<br>
		 * if newLastModifiedTimestamp = null, then current date and time is used
		 */
		public function MedicinEvent( amount:Number, medicin:String, medicineventid:Number, newcomment:String, creationTimeStamp:Number = Number.NaN, newLastModifiedTimeStamp:Number = Number.NaN,storeInDatabase:Boolean = true)
		{
			this._medicinName = medicin;
			this.eventid = medicineventid;
			this._amount = amount;
			this._comment = newcomment;
			if (!isNaN(creationTimeStamp))
				_timeStamp = creationTimeStamp;
			else
				_timeStamp = (new Date()).valueOf();
			
			if (!isNaN(newLastModifiedTimeStamp))
				_lastModifiedTimestamp = newLastModifiedTimeStamp;
			else
				_lastModifiedTimestamp = (new Date()).valueOf();
			
			if (storeInDatabase)
				Database.getInstance().createNewMedicinEvent(amount, medicin, _timeStamp,_lastModifiedTimestamp,medicineventid, _comment, null);
		}
		
		public function get timeStamp():Number
		{
			return _timeStamp;
		}
		
		public function set timeStamp(value:Number):void
		{
			_timeStamp = value;
		}
		
		public function listElementRendererFunction():ClassFactory
		{
			return new ClassFactory(MedicinEventItemRenderer);
		}
		
		/**
		 * will update the medicinevent in the database with the new values for medicinName and amount<br>
		 */
		public function updateMedicinEvent(newMedicinName:String,newAmount:Number, newComment:String, newCreationTimeStamp:Number , newLastModifiedTimeStamp:Number):void {
			_amount = newAmount;
			_medicinName = newMedicinName;
			_comment = newComment;
			if (new Number(Settings.getInstance().getSetting(Settings.SettingsLastSyncTimeStamp)) > _lastModifiedTimestamp)
				Settings.getInstance().setSetting(Settings.SettingsLastSyncTimeStamp,_lastModifiedTimestamp.toString());
			_lastModifiedTimestamp = newLastModifiedTimeStamp;
			
			if (!isNaN(newCreationTimeStamp))
				_timeStamp = newCreationTimeStamp;
			Database.getInstance().updateMedicinEvent(this.eventid,_amount,_medicinName,timeStamp,_lastModifiedTimestamp, _comment);
		}
		
		/**
		 * delete the event from the database<br>
		 * once deleted this event should not be used anymore
		 */
		public function deleteEvent():void {
			Database.getInstance().deleteMedicinEvent(this.eventid);
		}
	}
}