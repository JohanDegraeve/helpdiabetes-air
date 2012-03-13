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
	
	import myComponents.IListElement;
	import myComponents.MedicinEventItemRenderer;
	import myComponents.TrackingViewElement;
	
	public class MedicinEvent extends TrackingViewElement implements IListElement
	{
		private var _timeStamp:Number;
		
		private var _medicinName:String;
		
		private var _eventid:Number;

		internal function get eventid():Number
		{
			return _eventid;
		}

		internal function set eventid(value:Number):void
		{
			_eventid = value;
		}
		
		

		public function get medicinName():String
		{
			return _medicinName;
		}

		private var _amount:int;

		public function get amount():int
		{
			return _amount;
		}

		
		/**
		 * creates a medicin event and stores it immediately in the database if storeInDatabase = true<br>
		 * if creationTimeStamp = null, then current date and time is used
		 */
		public function MedicinEvent( amount:int, medicin:String, creationTimeStamp:Number = NaN, storeInDatabase:Boolean = true, medicineventid:Number = NaN)
		{
			this._medicinName = medicin;
			this.eventid = medicineventid;
			this._amount = amount;
			if (!isNaN(creationTimeStamp))
				_timeStamp = creationTimeStamp;
			else
				_timeStamp = (new Date()).valueOf();
			
			if (storeInDatabase)
				Database.getInstance().createNewMedicinEvent(amount, medicin, _timeStamp,null,medicineventid);
		}
		
		public function get timeStamp():Number
		{
			return _timeStamp;
		}
		
		private function set timeStamp(value:Number):void
		{
			_timeStamp = value;
		}
		
		public function listElementRendererFunction():ClassFactory
		{
			return new ClassFactory(MedicinEventItemRenderer);
		}
		
		/**
		 * will update the medicinevent in the database with the new values for timeStamp, medicinName and amount
		 */
		public function updateMedicinEvent(newMedicinName:String,newAmount:int):void {
			_amount = newAmount;
			_medicinName = newMedicinName;
			Database.getInstance().updateMedicinEvent(this.eventid,/*_timeStamp,*/_amount,_medicinName);
		}
	}
}